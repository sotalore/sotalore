-- item_details.lua: what the game's tooltips say about items, which the API has no fields for.
--
-- The API gives no quest, tool, trade or salvage information for an item, but the tooltip shows it. While
-- capture is on (/sladmin capture), pointing the mouse at an item in the bags saves what its tooltip says,
-- under the item's key, in the account saved variable "itemDetails". items.lua adds it to the item file.
-- Sweep the mouse over the bags to fill it in. Holding Ctrl expands a tooltip; the longer text is then
-- captured too. The game has a hotkey that switches tooltips off; while they are off, the API reports
-- nothing under the mouse and this sees nothing (it cannot tell the difference from not pointing at an item).
--
-- The tooltip is plain English text, so the lines recognised here depend on the game language:
--   "Quest Item", "Tool", "No Trade", "Cannot be sold to merchants", "No Value", "Durability: Indestructible",
--   "Crafted by <name>", "Salvage or Reshape Yields: ...", and the "Salvage Components" list
--   ("Metal Scrap  1 - 50  90.5%": what it gives back, how many, how often).
-- A crafting component's "Material Crafting Bonus" (what it adds to gear made with it) is kept as "craftingBonus".
-- A crafted item's tooltip is about that one item, so only its salvage list is kept here (that part is the
-- same for the kind of item); what an expanded gear tooltip says the piece is made of goes to gear_samples.lua,
-- which takes gear pointed at anywhere, not only in the bags.
--
-- Uses: gear_samples.lua. Used by: items.lua (the item file), main.lua (the command, the per-frame tick, saving).

local util = SotaLoreAdmin.util
local jstr, jnum = util.jstr, util.jnum
local GearSamples = SotaLoreAdmin.GearSamples

local M = {}
SotaLoreAdmin.ItemDetails = M

local MAX_TEXT = 2000    -- characters of tooltip text kept per item

local on = false
local details = nil      -- item key -> what was captured; read from the saved variable on first use
local dirty, lastSave = false, 0
local lastSeen = nil     -- the last tooltip handled, so one hover captures once
local captured = 0       -- captures this session
local unmatched = 0      -- hovers that could not be tied to a bag item
local sampled = 0        -- new gear samples this session (gear_samples.lua)
local compact            -- (defined below) an entry as it is stored

-- Before sl-admin 0.13.1 a tooltip titled "Necklace, Common (L)" could be saved under the key of "Necklace, Common"
-- when both were in the bags. A wrong entry shows itself: not crafted, and a title with a bracket that the entry's name
-- lacks. Only a crafted item's title has a bracket its name lacks.
local function savedUnderTwin(d)
    if d.crafted or d.cleared or not d.name then return false end
    local title = d.title or (d.text and d.text:match("^[^\n]*"))
    if not title or not title:match("%b()%s*$") then return false end
    return title ~= (d.name:gsub("%[/?%a+%]", ""))
end

-- What such an entry becomes: no details, and a new revision, so the next "New items" export replaces them, and so
-- does the export after the item is pointed at again.
local function cleared(d)
    return { name = d.name, rev = (d.rev or 0) + 1, fp = "cleared", cleared = true }
end

-- The saved data has a size limit (256 KB for all of the account's, see util.flush), so an item that has its tooltip
-- text stored keeps little else: everything is worked out from the text again when the file is written. Entries
-- stored before sl-admin 0.12.0 also kept every flag and list and a long fingerprint (about 210 KB for 286 items);
-- they are made small when first read.
local function all()
    if details == nil then
        local t = ShroudGetSavedVar("itemDetails", "account")
        details = type(t) == "table" and t or {}
        local wrong = {}
        for key, d in pairs(details) do
            local small = compact(d)
            if savedUnderTwin(d) then
                small = cleared(d)
                wrong[#wrong + 1] = d.name
            end
            if small ~= d then
                details[key] = small
                dirty = true
            end
        end
        if #wrong > 0 then
            table.sort(wrong)
            ShroudConsoleLog("Item capture: cleared the tooltips of " .. #wrong .. " items, saved from a similarly named "
                .. "item. Point at them again: " .. table.concat(wrong, ", "))
        end
    end
    return details
end

-- Everything captured so far: item key -> entry.
function M.all()
    return all()
end

-- The revision number of what was captured for this item (0 when nothing was).
function M.revOf(key)
    local d = all()[key]
    return d and d.rev or 0
end

function M.save(force)
    if not dirty then return end
    if not force and ShroudTime - lastSave < 5 then return end
    local started = util.clock()
    ShroudSetSavedVar("itemDetails", all(), "account")
    util.flush()
    util.slow("saving the item details", started)
    dirty = false
    lastSave = ShroudTime
end

-- Reading a tooltip -------------------------------------------------------------------------

local looksLikeType = util.looksLikeType

-- A number as the tooltip writes it: thousands separators are commas ("6,380").
local function num(s)
    return tonumber((tostring(s):gsub(",", "")))
end

local function round4(x)
    return math.floor(x * 10000 + 0.5) / 10000
end

-- One tooltip's text -> what it says. Lines are separated by newlines.
local function parse(desc)
    local d = {
        crafted = false, questItem = false, artifact = false, tool = false, consumable = false,
        noTrade = false, noSell = false, noValue = false, indestructible = false,
        salvage = {}, effects = {}, types = {}, craftingBonus = {},
    }
    local seenTypes = {}
    local lines = {}
    local inSalvage, inEffects, inBonus = false, false, false
    for raw in tostring(desc or ""):gmatch("[^\r\n]+") do
        local line = raw:match("^%s*(.-)%s*$")
        if line ~= "" then
            lines[#lines + 1] = line
            if #lines == 1 then d.title = line end
            if looksLikeType(line, #lines) and not seenTypes[line] then
                seenTypes[line] = true
                d.types[#d.types + 1] = line
                if line == "Artifact" or line:match(" Artifact$") then d.artifact = true end
            end
            -- A stack shows how many there are, and the whole stack's weight and value.
            local q = line:match("^Quantity:%s*([%d,]+)$")
            if q then d.stackQuantity = num(q) end
            local sw = line:match("^Stack Weight:%s*([%d,%.]+)$")
            if sw then d.stackWeight = num(sw) end
            local sv = line:match("^Stack Value:%s*([%d,]+)$")
            if sv then d.stackValue = num(sv) end

            if line:match("^Crafted by ") then d.crafted = true
            elseif line == "Quest Item" then d.questItem = true
            elseif line == "Tool" then d.tool = true
            elseif line == "Consumable" then d.consumable = true
            elseif line == "No Trade" then d.noTrade = true
            elseif line == "Cannot be sold to merchants" then d.noSell = true
            elseif line == "No Value" then d.noValue = true
            elseif line == "Durability: Indestructible" then d.indestructible = true
            elseif line:match("^Salvage or Reshape Yields:") then d.yields = line:match(":%s*(.*)$")
            elseif line:match("^Merchant pays:") then
                -- "Merchant pays: 100 - 125" (a range) or "Merchant pays: 40"; for a stack it is the whole
                -- stack's price (made per item below)
                local lo, hi = line:match("([%d,]+)%s*%-%s*([%d,]+)")
                if not lo then lo = line:match("([%d,]+)"); hi = lo end
                if lo then d.merchantPays = { min = num(lo), max = num(hi) } end
            end

            -- The lists that run over several lines end at the next section heading.
            local endsList = line == "Salvage Components" or line:match("^Salvage") or line:match("^Hold ")
                or line:match("^Bonuses do not apply")
            if line == "Item Effects" then
                inEffects = true
            elseif inEffects then
                if endsList then inEffects = false else d.effects[#d.effects + 1] = line end
            end
            -- A crafting component (a hilt, a blade, a bow string, cloth...) lists what it adds to the gear made
            -- with it under "Material Crafting Bonus".
            if line == "Material Crafting Bonus" then
                inBonus = true
            elseif inBonus then
                if endsList then inBonus = false else d.craftingBonus[#d.craftingBonus + 1] = line end
            end

            if line == "Salvage Components" then
                inSalvage = true
            elseif inSalvage then
                if line:match("^Hold ") or line:match("^Salvage") then
                    inSalvage = false
                else
                    -- "Metal Scrap  1 - 50  90.5%" (a range) or "Bronze Hilt  1  5.7%" (one number)
                    local name, lo, hi, pct = line:match("^(.-)%s+([%d,]+)%s*%-%s*([%d,]+)%s+([%d%.]+)%%$")
                    if not name then
                        name, lo, pct = line:match("^(.-)%s+([%d,]+)%s+([%d%.]+)%%$")
                        hi = lo
                    end
                    if name then
                        d.salvage[#d.salvage + 1] = { name = name, min = num(lo), max = num(hi), chance = tonumber(pct) }
                    end
                end
            end
        end
    end
    -- A stack's numbers are for the whole stack. Per item: the value is a whole number, so it is exact; the
    -- weight is shown to about one decimal, so it is only worked out when the stack is heavy enough for that
    -- not to matter (a stack of 6 fireworks at 0.01 shows "0.1").
    local qty = d.stackQuantity
    if qty and qty >= 1 then
        if d.stackValue then d.valueEach = round4(d.stackValue / qty) end
        if d.stackWeight and d.stackWeight >= 10 then d.weightEach = round4(d.stackWeight / qty) end
        if d.merchantPays and qty > 1 then
            d.merchantPays = { min = round4(d.merchantPays.min / qty), max = round4(d.merchantPays.max / qty) }
        end
    end

    local text = table.concat(lines, "\n")
    if #text > MAX_TEXT then text = text:sub(1, MAX_TEXT) end
    d.text = text
    return d
end
-- The weight or value of one item (field "weight" or "value") of a bag item. The bag list's numbers are for
-- the whole stack (util.perItem divides them), but some stacks report no size; for those the captured tooltip
-- ("Quantity: 638 | Stack Weight: 191.4 | Stack Value: 6,380") gives it. nil when neither can tell.
function M.perItem(it, field)
    local v = util.perItem(it, field)
    if v ~= nil then return v end
    local d = it.key and all()[it.key]
    if not d or d.crafted or not d.text then return nil end
    local fresh = parse(d.text)
    if field == "weight" then return fresh.weightEach end
    if field == "value" then return fresh.valueEach end
    return nil
end

-- A short code that changes whenever anything worth exporting about the item changes (not the quantities and
-- durabilities in the tooltip text, which differ every time). Used to number the revisions of an item.
-- (Before sl-admin 0.12.0 the text itself was stored; compact turns such a text into its code, which is the same
-- code this gives for an unchanged item, so loading old entries does not count as a change.)
local function fingerprint(d)
    local bits = { tostring(d.crafted), table.concat(d.types or {}, ","), tostring(d.questItem), tostring(d.artifact),
        tostring(d.tool), tostring(d.consumable), tostring(d.noTrade), tostring(d.noSell), tostring(d.noValue),
        tostring(d.indestructible), tostring(d.yields or ""), tostring(d.title or "") }
    if d.merchantPays then bits[#bits + 1] = d.merchantPays.min .. "-" .. d.merchantPays.max end
    bits[#bits + 1] = table.concat(d.effects or {}, ",")
    for _, s in ipairs(d.salvage or {}) do
        bits[#bits + 1] = tostring(s.name) .. ":" .. tostring(s.min) .. ":" .. tostring(s.max) .. ":" .. tostring(s.chance)
    end
    -- last, and only when there is one, so the code of an item without a bonus is what it was before 0.12.0
    if d.craftingBonus and #d.craftingBonus > 0 then bits[#bits + 1] = table.concat(d.craftingBonus, ",") end
    return util.hash(table.concat(bits, "|"))
end

-- The fields an entry is stored with. A crafted item has no text (only its title, salvage and yields are kept); any
-- other item has its text, and its salvage and yields only when the text was cut short (they may be past the cut).
local KEEP = { name = true, crafted = true, title = true, text = true, salvage = true, yields = true, fp = true, rev = true,
    cleared = true }

compact = function(d)
    local clipped = d.text and #d.text >= MAX_TEXT
    local needed = d.crafted or clipped or not d.text
    local small = { name = d.name, rev = d.rev, fp = d.fp, cleared = d.cleared }
    if d.crafted then
        small.crafted, small.title = true, d.title
    else
        small.text = d.text
    end
    if needed then small.salvage, small.yields = d.salvage, d.yields end
    if type(small.fp) == "string" and #small.fp > 8 then small.fp = util.hash(small.fp) end

    -- unchanged when it already was that small
    local same = small.fp == d.fp
    for k in pairs(d) do
        if not KEEP[k] or (small[k] == nil) then same = false end
    end
    if same then return d end
    return small
end

-- A short description of what was captured, for the chat line.
local function summary(d)
    local bits = {}
    if d.crafted then bits[#bits + 1] = "crafted" end
    for _, ty in ipairs(d.types) do bits[#bits + 1] = ty:lower() end
    if d.noTrade then bits[#bits + 1] = "no trade" end
    if d.noSell then bits[#bits + 1] = "can't sell" end
    if #d.salvage > 0 then bits[#bits + 1] = #d.salvage .. " salvage" end
    return table.concat(bits, ", ")
end

-- Capturing --------------------------------------------------------------------------------

-- The UI sets these to hear when capture is switched on or off (including by the /sladmin command), and when
-- something was captured.
M.onToggle = nil
M.onChange = nil

function M.isOn()
    return on
end

-- How capture is going: items with a captured tooltip (stored), and since capture was last switched on the items
-- captured, the new gear samples and the items skipped because they were not in the bags.
function M.counts()
    local n = 0
    for _ in pairs(all()) do n = n + 1 end
    return { stored = n, captured = captured, sampled = sampled, unmatched = unmatched }
end

-- A line for chat: how capture went, and how much is stored.
local function report()
    local c = M.counts()
    return c.captured .. " captured this time, " .. c.unmatched .. " not in your bags (skipped), " .. c.stored
        .. " items stored; " .. c.sampled .. " new gear samples, " .. GearSamples.count() .. " stored"
end

-- Turns capture on or off, and says so in chat. Returns the new state.
function M.toggle()
    on = not on
    lastSeen = nil
    if on then
        captured, unmatched, sampled = 0, 0, 0
        ShroudConsoleLog("Item capture on: point at items in your bags, and at gear anywhere (hold Ctrl for the full tooltip). "
            .. "The game's tooltips must be switched on, or nothing is seen.")
    else
        M.save(true)
        ShroudConsoleLog("Item capture off: " .. report())
    end
    if M.onToggle then M.onToggle(on) end
    return on
end

-- Called every frame (from ShroudOnUpdate): captures the tooltip of the item under the mouse.
function M.tick()
    M.save(false)
    if not on then return end
    if ShroudGetKindUnderMouse() ~= "item" then
        lastSeen = nil
        return
    end
    local name = ShroudGetNameUnderMouse()
    if name == "" then return end
    local desc = ShroudGetDescriptionUnderMouse()
    local signature = name .. "\n" .. desc
    if signature == lastSeen then return end
    lastSeen = signature

    -- The key comes from the bag item of that name; an item that is not in the bags can't be tied to one. Only a
    -- crafted item's title can have a bracket its name lacks: for anything else the whole name must match, or an
    -- "(L)" item in a chest would be saved under its twin in the bags.
    local exactOnly = not ("\n" .. desc):find("\n%s*Crafted by ")
    local it = util.itemsNamed(ShroudGetInventoryItems, name, exactOnly)[1]

    -- An expanded gear tooltip is also kept as a sample of what gear is made of (gear_samples.lua). That needs no
    -- key, so it works for gear anywhere: worn, in a chest, in the bank.
    local worn = not it and util.itemsNamed(ShroudGetEquipmentItems, name, exactOnly)[1]
    local sample = GearSamples.capture(desc, (it and it.key) or (worn and worn.key) or nil)
    if sample == "new" then sampled = sampled + 1 end

    if not it or not it.key then
        if sample == "new" then
            ShroudConsoleLog("Captured gear sample: " .. tostring(name))
        elseif not sample then
            unmatched = unmatched + 1
        end
        if M.onChange then M.onChange() end
        return
    end

    local d = parse(desc)
    local entry
    if d.crafted then
        entry = { name = it.name, crafted = true, title = d.title, salvage = d.salvage, yields = d.yields }
    else
        d.name = it.name
        entry = d
    end
    -- Number the revisions of this item: a new capture of something that changed is a new revision, so the
    -- item file can send just the items that changed since they were last exported (items.lua).
    local old = all()[it.key]
    entry.fp = fingerprint(d)
    if not old then
        entry.rev = 1
    elseif old.fp ~= entry.fp then
        entry.rev = (old.rev or 0) + 1
    else
        entry.rev = old.rev or 1
    end
    all()[it.key] = compact(entry)
    dirty = true
    captured = captured + 1
    local what = summary(d)
    if sample == "new" then
        what = what .. (what ~= "" and ", " or "") .. "gear sample"
    elseif d.crafted and not sample and desc:find("Hold control to expand", 1, true) then
        what = what .. (what ~= "" and ", " or "") .. "hold Ctrl for what it is made of"
    end
    ShroudConsoleLog("Captured: " .. tostring(it.name) .. (what ~= "" and (" (" .. what .. ")") or ""))
    if M.onChange then M.onChange() end
end

-- Writing it to the item file --------------------------------------------------------------

local function jsalvage(list)
    local parts = {}
    for _, s in ipairs(list or {}) do
        parts[#parts + 1] = '{"name":' .. jstr(s.name) .. ',"min":' .. jnum(s.min) .. ',"max":' .. jnum(s.max)
            .. ',"chance":' .. jnum(s.chance) .. '}'
    end
    return '[' .. table.concat(parts, ',') .. ']'
end

-- What was captured for this item key, as JSON, or null when nothing was.
function M.toJson(key)
    local d = all()[key]
    if not d or d.cleared then return "null" end
    if not d.crafted and d.text then
        -- Read the stored tooltip again with today's rules, so what an older plugin version captured gets
        -- later improvements without hovering the item again. (The stored text can be cut short, so the
        -- salvage list and yields line saved at capture time are kept when the re-read finds none.)
        local fresh = parse(d.text)
        fresh.name = d.name
        fresh.title = fresh.title or d.title
        if #fresh.salvage == 0 then fresh.salvage = d.salvage or {} end
        fresh.yields = fresh.yields or d.yields
        d = fresh
    end
    local s = '{"crafted":' .. tostring(d.crafted and true or false)
        .. ',"title":' .. (d.title and jstr(d.title) or "null")
    if not d.crafted then
        s = s .. ',"types":' .. util.jlist(d.types, jstr)
            .. ',"questItem":' .. tostring(d.questItem and true or false)
            .. ',"artifact":' .. tostring(d.artifact and true or false)
            .. ',"tool":' .. tostring(d.tool and true or false)
            .. ',"consumable":' .. tostring(d.consumable and true or false)
            .. ',"noTrade":' .. tostring(d.noTrade and true or false)
            .. ',"noSell":' .. tostring(d.noSell and true or false)
            .. ',"noValue":' .. tostring(d.noValue and true or false)
            .. ',"indestructible":' .. tostring(d.indestructible and true or false)
            .. ',"merchantPays":' .. (d.merchantPays and ('{"min":' .. jnum(d.merchantPays.min) .. ',"max":' .. jnum(d.merchantPays.max) .. '}') or "null")
            .. ',"effects":' .. util.jlist(d.effects, jstr)
            .. ',"craftingBonus":' .. util.jlist(d.craftingBonus, jstr)
            .. ',"text":' .. jstr(d.text or "")
    end
    s = s .. ',"yields":' .. (d.yields and jstr(d.yields) or "null")
        .. ',"salvage":' .. jsalvage(d.salvage) .. '}'
    return s
end
