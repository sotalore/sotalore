-- item_details.lua: what the game's tooltips say about items, which the API has no fields for.
--
-- The API gives no quest, tool, trade or salvage information for an item, but the tooltip shows it. While
-- capture is on (/slore capture), pointing the mouse at an item in the bags saves what its tooltip says,
-- under the item's key, in the account saved variable "itemDetails". items.lua adds it to the item file.
-- Sweep the mouse over the bags to fill it in. Holding Ctrl expands a tooltip; the longer text is then
-- captured too. The game has a hotkey that switches tooltips off; while they are off, the API reports
-- nothing under the mouse and this sees nothing (it cannot tell the difference from not pointing at an item).
--
-- The tooltip is plain English text, so the lines recognised here depend on the game language:
--   "Quest Item", "Tool", "No Trade", "Cannot be sold to merchants", "No Value", "Durability: Indestructible",
--   "Crafted by <name>", "Salvage or Reshape Yields: ...", and the "Salvage Components" list
--   ("Metal Scrap  1 - 50  90.5%": what it gives back, how many, how often).
-- A crafted item's tooltip is about that one item, so only its salvage list is kept (that part is the
-- same for the kind of item); everything else about it is left out.
--
-- Used by: items.lua (the item file), main.lua (the command, the per-frame tick, saving).

local util = SotaLore.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLore.ItemDetails = M

local MAX_TEXT = 2000    -- characters of tooltip text kept per item

local on = false
local details = nil      -- item key -> what was captured; read from the saved variable on first use
local dirty, lastSave = false, 0
local lastSeen = nil     -- the last tooltip handled, so one hover captures once
local captured = 0       -- captures this session
local unmatched = 0      -- hovers that could not be tied to a bag item

local function all()
    if details == nil then
        local t = ShroudGetSavedVar("itemDetails", "account")
        details = type(t) == "table" and t or {}
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
    util.slow("saving the item details", started)
    dirty = false
    lastSave = ShroudTime
end

-- Reading a tooltip -------------------------------------------------------------------------

-- Tooltip lines that name a kind of item ("Quest Item", "Dread Artifact", "Necklace", "Leather Light Armor
-- (Head)", "Longsword - Bladed", "Fishing Bait"...) all become "types": one item can have several (the Shroud
-- of the Avatar is an artifact, a cloak and a quest item). There is no list of kinds to match against, so a
-- type line is recognised by its shape: short, not the title, no colon, number, percent, plus, comma, full stop, ! or ?,
-- and not one of the lines that are known not to be types. It is a heuristic; the tooltip is kept in "text".
local NOT_TYPES = {
    ["No Trade"] = true, ["No Value"] = true, ["Cannot be sold to merchants"] = true, ["Item Effects"] = true,
    ["Equipped"] = true, ["Salvage Components"] = true,
}

local function looksLikeType(line, index)
    if index == 1 or #line > 40 or NOT_TYPES[line] then return false end
    if line:match("[:%.%d%%%+,!%?\"]") then return false end
    if line:match("^Hold ") or line:match("^Double%-click") or line:match("^Salvage") or line:match("^Crafted by") then
        return false
    end
    return true
end

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
        salvage = {}, effects = {}, types = {},
    }
    local seenTypes = {}
    local lines = {}
    local inSalvage, inEffects = false, false
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

            -- The two lists that run over several lines end at the next section heading.
            local endsList = line == "Salvage Components" or line:match("^Salvage") or line:match("^Hold ")
                or line:match("^Bonuses do not apply")
            if line == "Item Effects" then
                inEffects = true
            elseif inEffects then
                if endsList then inEffects = false else d.effects[#d.effects + 1] = line end
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

-- A short text that changes whenever anything worth exporting about the item changes (not the quantities and
-- durabilities in the tooltip text, which differ every time). Used to number the revisions of an item.
local function fingerprint(d)
    local bits = { tostring(d.crafted), table.concat(d.types or {}, ","), tostring(d.questItem), tostring(d.artifact),
        tostring(d.tool), tostring(d.consumable), tostring(d.noTrade), tostring(d.noSell), tostring(d.noValue),
        tostring(d.indestructible), tostring(d.yields or ""), tostring(d.title or "") }
    if d.merchantPays then bits[#bits + 1] = d.merchantPays.min .. "-" .. d.merchantPays.max end
    bits[#bits + 1] = table.concat(d.effects or {}, ",")
    for _, s in ipairs(d.salvage or {}) do
        bits[#bits + 1] = tostring(s.name) .. ":" .. tostring(s.min) .. ":" .. tostring(s.max) .. ":" .. tostring(s.chance)
    end
    return table.concat(bits, "|")
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

-- The UI sets this to hear when capture is switched on or off (including by the /slore command).
M.onToggle = nil

function M.isOn()
    return on
end

-- A line for chat: how capture went, and how much is stored.
local function report()
    local n = 0
    for _ in pairs(all()) do n = n + 1 end
    return captured .. " captured this time, " .. unmatched .. " not in your bags (skipped), " .. n .. " items stored"
end

-- Turns capture on or off, and says so in chat. Returns the new state.
function M.toggle()
    on = not on
    lastSeen = nil
    if on then
        captured, unmatched = 0, 0
        ShroudConsoleLog("Item capture on: point at items in your bags (hold Ctrl for the full tooltip). "
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

    -- The key comes from the bag item of that name; an item that is not in the bags can't be tied to one.
    local it = util.itemsNamed(ShroudGetInventoryItems, name)[1]
    if not it or not it.key then
        unmatched = unmatched + 1
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
    all()[it.key] = entry
    dirty = true
    captured = captured + 1
    ShroudConsoleLog("Captured: " .. tostring(it.name) .. (summary(d) ~= "" and (" (" .. summary(d) .. ")") or ""))
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
    if not d then return "null" end
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
            .. ',"text":' .. jstr(d.text or "")
    end
    s = s .. ',"yields":' .. (d.yields and jstr(d.yields) or "null")
        .. ',"salvage":' .. jsalvage(d.salvage) .. '}'
    return s
end
