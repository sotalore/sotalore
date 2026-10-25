-- gear_samples.lua: what gear's expanded tooltips say it is made of, as samples for the site.
--
-- A weapon's or armour piece's tooltip, expanded by holding Ctrl, lays out where each of its effects comes from,
-- in sections separated by blank lines:
--   the components it was made from ("Bronze Weapon Blade", "Elven Hilt", "Bronze Sheet (2)"), each with its effects;
--   "Exceptional (+1)" and what that added; "Enchantment(s):" and "Masterwork(s):", one line each with what it cost
--   in maximum durability ("+6.8 Dexterity (-20 Maximum Durability)"), and failures ("(3) Enchantment Failure (-75
--   Max Durability)"); "Socket: Blades (2)" and its effects; "Item Effects" (what the kind of item has itself);
--   "On Hit (10%): Tremor"; and the durability line "Durability: 48/49 (Max 165-135+30)" (base, lost, gained).
-- Not expanded ("Hold control to expand"), the tooltip only shows all the effects added together, which says
-- nothing about where they came from, so such a tooltip is not kept.
--
-- A tooltip is about one piece, and pieces can't be told apart (copies share the item key, and often the name), so
-- each different breakdown is one sample, whichever piece it came from. What the site learns from the samples is
-- about kinds: what each component, socket, enchantment and masterwork can add, and what failures cost.
--
-- While capture is on (/sladmin capture), item_details.lua hands this file every tooltip pointed at, in the bags,
-- worn, or in any other container. The samples are kept in the character's saved variable "gearSamples" (a list;
-- each has the tooltip text, the item key when the item was found in the bags or worn, and whether it has been
-- exported), and items.lua writes them into the item file under "craftedSamples". Character, not account: the game
-- refuses to save a scope's data over 256 KB (see util.flush), and the account's is mostly taken by the item
-- details; a sample takes about 1 KB.
--
-- Used by: item_details.lua (capturing), items.lua (the item file), main.lua (saving).

local util = SotaLoreAdmin.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLoreAdmin.GearSamples = M

local samples = nil      -- the list of samples; read from the saved variable on first use
local byFp = nil         -- fingerprint -> sample, to tell a new breakdown from a known one
local dirty, lastSave = false, 0

-- Reading a tooltip -------------------------------------------------------------------------

local function trim(s)
    return (s:match("^%s*(.-)%s*$"))
end

-- An effect line: "+3 Melee and Ranged Damage", "-190 Maximum Durability", "50 Durability (+50 Maximum Durability)".
local function isEffect(line)
    return line:match("^[%+%-]%d") ~= nil or line:match("^%d[%d%.]*%%? %a") ~= nil
end

-- The lines of the weapon's or armour's own figures.
local STATS = { "^Hits %d", "^Damage:", "^Critical:", "^Charge:", "^Strength Bonus:", "^Parry:", "^Damage Resistance:",
    "^Damage Avoidance:", "^Durability Multiplier:" }

local function isStat(line)
    for _, p in ipairs(STATS) do
        if line:match(p) then return true end
    end
    return false
end

-- Lines after which no section goes on.
local function endsSections(line)
    return line:match("^Bonuses do not apply") or line:match("^Salvage") or line:match("^Hold ")
        or line == "Material Crafting Bonus"
end

-- "Bronze Sheet (2)" -> "Bronze Sheet", 2; "Elven Hilt" -> "Elven Hilt", 1.
local function nameCount(text)
    local name, n = text:match("^(.-)%s*%((%d+)%)$")
    if name then return name, tonumber(n) end
    return text, 1
end

-- An enchantment or masterwork line: what it added and what it did to the maximum durability.
local function addMod(g, list, failureField, line)
    local count, cost = line:match("^%((%d+)%)%s*%a+ Failure%s*%(([%+%-]?%d+) Max Durability%)$")
    if count then
        g[failureField] = { count = tonumber(count), durability = tonumber(cost) }
        return
    end
    local effect, change = line:match("^(.-)%s*%(([%+%-][%d%.]+) Maximum Durability%)$")
    list[#list + 1] = { effect = effect or line, durability = tonumber(change) }
end

-- One tooltip -> its breakdown, or nil when it is not an expanded gear tooltip with something to tell.
function M.parse(desc)
    desc = tostring(desc or "")
    if desc:find("Hold control to expand", 1, true) then return nil end
    local lines = {}
    for raw in (desc .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = trim((raw:gsub("\r", "")))
    end

    local g = { types = {}, stats = {}, itemEffects = {}, components = {}, enchantments = {}, masterworks = {},
        sockets = {}, onHit = {} }
    local section, current = nil, nil   -- the section being read, and the component or socket it is about
    local inHeader = true                -- before the "Value:" line: where the kinds of item are named
    for i, line in ipairs(lines) do
        if i == 1 then
            g.title = line
        elseif line == "" then
            section, current = nil, nil
        elseif line:match("^Crafted by ") then
            g.crafter = line:match("^Crafted by (.+)$")
        elseif line:match("^Durability:") then
            -- "(Max 165-135+30)": the kind's maximum, what enchantments, masterworks and failures took, what they gave
            local max = line:match("%(Max ([^%)]*)%)")
            if max then
                g.durability = { base = tonumber(max:match("^(%d+)")), lost = tonumber(max:match("%-(%d+)")) or 0,
                    gained = tonumber(max:match("%+(%d+)")) or 0 }
            end
        elseif line:match("^Value:") or line == "No Value" then
            inHeader = false
        elseif inHeader then
            if util.looksLikeType(line, i) then g.types[#g.types + 1] = line end
        elseif line == "Item Effects" then
            section = "itemEffects"
        elseif line:match("^Enchantment%(s%):") or line:match("^Masterwork%(s%):") then
            section = line:match("^Enchantment") and "enchantments" or "masterworks"
            -- a single one can be on the heading's line ("Enchantment(s):+3.4 Strength (-10 Maximum Durability)")
            local rest = trim(line:match(":(.*)$"))
            if rest ~= "" then
                addMod(g, g[section], section == "enchantments" and "enchantmentFailures" or "masterworkFailures", rest)
            end
        elseif line:match("^Socket:") then
            local name, n = nameCount(trim(line:match(":(.*)$")))
            current = { name = name, count = n, effects = {} }
            g.sockets[#g.sockets + 1] = current
            section = "effects"
        elseif line:match("^Exceptional %(%+%d+%)$") then
            current = { level = tonumber(line:match("%(%+(%d+)%)")), effects = {} }
            g.exceptional = current
            section = "effects"
        elseif line:match("^On Hit") then
            section = "onHit"
            g.onHit[#g.onHit + 1] = line
        elseif endsSections(line) then
            section, current = nil, nil
        elseif section == "itemEffects" then
            g.itemEffects[#g.itemEffects + 1] = line
        elseif section == "enchantments" then
            addMod(g, g.enchantments, "enchantmentFailures", line)
        elseif section == "masterworks" then
            addMod(g, g.masterworks, "masterworkFailures", line)
        elseif section == "effects" then
            current.effects[#current.effects + 1] = line
        elseif section == "onHit" then
            g.onHit[#g.onHit + 1] = line
        elseif isStat(line) then
            g.stats[#g.stats + 1] = line
        elseif not line:find(":", 1, true) and not isEffect(line) and isEffect(lines[i + 1] or "") then
            -- a name with effect lines under it: a component
            local name, n = nameCount(line)
            current = { name = name, count = n, effects = {} }
            g.components[#g.components + 1] = current
            section = "effects"
        end
    end

    if #g.components == 0 and #g.enchantments == 0 and #g.masterworks == 0 and #g.sockets == 0 and not g.exceptional
        and not g.enchantmentFailures and not g.masterworkFailures then
        return nil
    end
    return g
end

-- Writing a sample --------------------------------------------------------------------------

local function jeffects(o)
    return '{"name":' .. jstr(o.name) .. ',"count":' .. jnum(o.count) .. ',"effects":' .. util.jlist(o.effects, jstr) .. '}'
end

local function jmod(m)
    return '{"effect":' .. jstr(m.effect) .. ',"durability":' .. jnum(m.durability) .. '}'
end

local function jfailures(f)
    if not f then return "null" end
    return '{"count":' .. jnum(f.count) .. ',"durability":' .. jnum(f.durability) .. '}'
end

-- The breakdown as JSON fields, without the key and text: also what tells one sample from another.
local function body(g)
    local d = g.durability
    return '"title":' .. jstr(g.title)
        .. ',"crafter":' .. (g.crafter and jstr(g.crafter) or "null")
        .. ',"types":' .. util.jlist(g.types, jstr)
        .. ',"durability":' .. (d and ('{"base":' .. jnum(d.base) .. ',"lost":' .. jnum(d.lost) .. ',"gained":' .. jnum(d.gained) .. '}') or "null")
        .. ',"stats":' .. util.jlist(g.stats, jstr)
        .. ',"itemEffects":' .. util.jlist(g.itemEffects, jstr)
        .. ',"components":' .. util.jlist(g.components, jeffects)
        .. ',"exceptional":' .. (g.exceptional and ('{"level":' .. jnum(g.exceptional.level) .. ',"effects":' .. util.jlist(g.exceptional.effects, jstr) .. '}') or "null")
        .. ',"enchantments":' .. util.jlist(g.enchantments, jmod)
        .. ',"enchantmentFailures":' .. jfailures(g.enchantmentFailures)
        .. ',"masterworks":' .. util.jlist(g.masterworks, jmod)
        .. ',"masterworkFailures":' .. jfailures(g.masterworkFailures)
        .. ',"sockets":' .. util.jlist(g.sockets, jeffects)
        .. ',"onHit":' .. util.jlist(g.onHit, jstr)
end

-- Keeping them ------------------------------------------------------------------------------

local function all()
    if samples == nil then
        local t = ShroudGetSavedVar("gearSamples", "character")
        samples = type(t) == "table" and t or {}
        byFp = {}
        for _, s in ipairs(samples) do
            local g = M.parse(s.text)
            if g then byFp[body(g)] = s end
        end
    end
    return samples
end

function M.save(force)
    if not dirty then return end
    if not force and ShroudTime - lastSave < 5 then return end
    local started = util.clock()
    ShroudSetSavedVar("gearSamples", all(), "character")
    util.flush()
    util.slow("saving the gear samples", started)
    dirty = false
    lastSave = ShroudTime
end

-- A tooltip pointed at, with the item key when the item is known (nil otherwise). Returns "new" when it was a
-- breakdown not seen before, "known" when it was one already kept, nil when it is not a gear breakdown.
function M.capture(desc, key)
    local g = M.parse(desc)
    if not g then return nil end
    all()
    local fp = body(g)
    local old = byFp[fp]
    if old then
        if key and not old.key then
            old.key = key
            old.exported = false
            dirty = true
        end
        return "known"
    end
    local lines = {}
    for raw in (tostring(desc) .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = trim((raw:gsub("\r", ""))) end
    local s = { key = key, text = table.concat(lines, "\n"), exported = false }
    samples[#samples + 1] = s
    byFp[fp] = s
    dirty = true
    return "new"
end

-- How many samples are kept, and how many of them have not been exported yet.
function M.count()
    local waiting = 0
    for _, s in ipairs(all()) do
        if not s.exported then waiting = waiting + 1 end
    end
    return #all(), waiting
end

-- The samples for the item file: every one for "all", those not exported yet for "new". Returns a list of JSON
-- texts and the samples they came from (for markExported). The tooltip is read again with today's rules.
function M.forExport(mode)
    local out, sent = {}, {}
    for _, s in ipairs(all()) do
        if mode == "all" or not s.exported then
            local g = M.parse(s.text)
            if g then
                out[#out + 1] = '{"key":' .. (s.key and jstr(s.key) or "null") .. ',' .. body(g)
                    .. ',"text":' .. jstr(s.text) .. '}'
                sent[#sent + 1] = s
            end
        end
    end
    return out, sent
end

-- Marks these samples (from forExport, or every one when nil) as exported.
function M.markExported(list)
    for _, s in ipairs(list or all()) do s.exported = true end
    dirty = true
    M.save(true)
end
