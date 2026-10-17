-- finds_data.lua: what the player finds, scene by scene. No windows here: finds_ui.lua shows it.
--
-- The find list is a table, scene name -> { raw, info, items, creatures, nodes }, kept in the account
-- saved variable "finds" and written out as Lua/sotalore-finds.json (format in EXPORT-FORMAT.md).
--
--   items      what arrived in the bags (ShroudOnItemsGained, the game's "Recently Looted" rule: loot,
--              purchases, harvests, mail, trades, and items taken out of a bank or chest. NOT items you
--              already owned, moves between bags, equipping, login or scene changes). Gains while the
--              crafting window is open are ignored, since crafting results are not finds.
--   creatures  the API can't list what is in a scene, so a creature is recorded when it shows up in
--              your combat lines. Only creatures you actually fight are seen. PvP scenes are skipped
--              because the opponents are players.
--   nodes      gathering actions you finish (ShroudOnGatherResults): the node's name and what its
--              loot window held. Field dressing a corpse reports the creature's name as the node. An
--              interrupted harvest sends nothing.
--
-- Used by: finds_ui.lua (the window), main.lua (the callbacks call the record... functions).

local util = SotaLore.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLore.Finds = M

M.tracking = true     -- recording on or off (the window's Tracking toggle)
M.onChange = nil      -- the window sets this: called whenever the list changes

local finds = {}      -- scene name -> { raw, info, items = {...}, creatures = {...}, nodes = {...} }
local dirty = false   -- changed since the last save to the saved variables
local lastSave = 0
local seenKeys = {}   -- creature keys already counted on this visit to the scene
local gatherLog = true

local function changed()
    dirty = true
    if M.onChange then M.onChange() end
end

-- Saving and loading -----------------------------------------------------------------------

-- Writes the list to the saved variables. Without `force` it waits at least 5 seconds between saves.
function M.save(force)
    if not dirty then return end
    if not force and ShroudTime - lastSave < 5 then return end
    local started = util.clock()
    ShroudSetSavedVar("finds", finds, "account")
    util.slow("saving the find list", started)
    dirty = false
    lastSave = ShroudTime
end

function M.load()
    local t = ShroudGetSavedVar("finds", "account")
    finds = type(t) == "table" and t or {}
    M.tracking = ShroudGetSavedVar("track", "account") ~= false
    seenKeys = {}
    dirty, lastSave = false, 0
end

function M.setTracking(on)
    M.tracking = on and true or false
    ShroudSetSavedVar("track", M.tracking, "account")
end

-- Empties the list.
function M.reset()
    finds = {}
    seenKeys = {}
    dirty = true
    M.save(true)
    if M.onChange then M.onChange() end
end

-- A new visit to a scene: its creatures count again.
function M.newVisit()
    seenKeys = {}
end

-- Turns the chat line for every gather result on or off. Returns the new state.
function M.toggleGatherLog()
    gatherLog = not gatherLog
    return gatherLog
end

-- Totals for the window.
function M.counts()
    local c = { scenes = 0, items = 0, quantity = 0, creatures = 0, nodes = 0, harvests = 0 }
    local itemIds, creatureNames, nodeNames = {}, {}, {}
    for _, s in pairs(finds) do
        c.scenes = c.scenes + 1
        for name, n in pairs(s.nodes or {}) do
            if not nodeNames[name] then nodeNames[name] = true; c.nodes = c.nodes + 1 end
            c.harvests = c.harvests + (n.harvests or 0)
        end
        for id, e in pairs(s.items or {}) do
            if not itemIds[id] then itemIds[id] = true; c.items = c.items + 1 end
            c.quantity = c.quantity + (e.quantity or 0)
        end
        for name in pairs(s.creatures or {}) do
            if not creatureNames[name] then creatureNames[name] = true; c.creatures = c.creatures + 1 end
        end
    end
    return c
end

-- Recording --------------------------------------------------------------------------------

-- The scene's entry in the find list, created on first use; scene details are refreshed each
-- time (a scene's caps can change with the game).
local function sceneEntry(scene)
    local s = finds[scene.name]
    if not s then
        s = { raw = scene.rawName, items = {}, creatures = {} }
        finds[scene.name] = s
    end
    s.items = s.items or {}
    s.creatures = s.creatures or {}
    s.nodes = s.nodes or {}
    s.info = {
        isOverworld = scene.isOverworld and true or false,
        isDungeon = scene.isDungeon and true or false,
        isBasement = scene.isBasement and true or false,
        isSiege = scene.isSiege and true or false,
        isBattleground = scene.isBattleground and true or false,
        isPvp = scene.isPvp and true or false,
        isPot = scene.isPot and true or false,
        maxPlayers = scene.maxPlayers,
        levelCap = scene.levelCap,
        skillCap = scene.skillCap,
        craftingSkillCap = scene.craftingSkillCap,
    }
    return s
end

-- The scene the player is in, or nil while there is none (login screen, loading).
local function currentScene()
    local scene = ShroudGetSceneInfo()
    if not scene or not scene.loaded or scene.name == "" then return nil end
    return scene
end

-- The gain callback gives name, quantity and icon but no key; take the key from the bag.
local function matchInventory(bag, gained)
    local byName
    for _, it in ipairs(bag) do
        if it.name == gained.name then
            if gained.icon == nil or it.icon == gained.icon then return it end
            byName = byName or it
        end
    end
    return byName
end

-- Items that arrived in the bags (from ShroudOnItemsGained).
function M.recordItems(items)
    local scene = currentScene()
    if not scene then return end
    local crafting = ShroudGetCraftingState()
    if crafting and crafting.open then return end

    local bag = ShroudGetInventoryItems() or {}
    local s = sceneEntry(scene)
    for _, g in ipairs(items or {}) do
        local match = matchInventory(bag, g)
        local id = (match and match.key) or ("name:" .. g.name)
        local e = s.items[id]
        if not e then
            e = { name = g.name, quantity = 0, times = 0 }
            s.items[id] = e
        end
        e.quantity = e.quantity + g.quantity
        e.times = e.times + 1
        if match then
            e.key, e.weight, e.value = match.key, util.perItem(match, "weight"), util.perItem(match, "value")
        end
    end
    changed()
end

-- Combat lines that show an opponent. Heals, falls and anything without a name are left out.
local FIGHT = {
    hit = true, critical = true, glancing = true, block = true, parry = true,
    dodge = true, noDamage = true, outOfReach = true, death = true,
}

-- Level of the creature you are targeting, when Animal Lore lets the game print it.
local function targetLevel(name)
    if not ShroudHasTarget() or ShroudGetTargetName() ~= name then return nil end
    local lvl = ShroudGetTargetStatValueByName("AdventurerLevel")
    if type(lvl) == "number" and lvl > 0 then return lvl end
    return nil
end

-- Creatures you fight (from ShroudOnCombatEvents).
function M.recordCreatures(events)
    local scene = currentScene()
    if not scene then return end
    if scene.isPvp or scene.isBattleground then return end

    local me = ShroudGetPlayerName()
    local any = false
    for _, e in ipairs(events or {}) do
        if FIGHT[e.kind] then
            local name, key
            if e.fromYou or e.fromYourPet then
                name, key = e.target, e.targetKey
            elseif e.toYou or e.toYourPet then
                name, key = e.source, e.sourceKey
            end
            if name and name ~= "" and name ~= me and key and key ~= 0 then
                local s = finds[scene.name]
                local c = s and s.creatures and s.creatures[name]
                if not seenKeys[key] then
                    seenKeys[key] = true
                    s = sceneEntry(scene)
                    c = s.creatures[name]
                    if not c then
                        c = { seen = 0 }
                        s.creatures[name] = c
                    end
                    c.seen = c.seen + 1
                    any = true
                end
                if c then
                    local lvl = targetLevel(name)
                    if lvl then
                        c.levelMin = math.min(c.levelMin or lvl, lvl)
                        c.levelMax = math.max(c.levelMax or lvl, lvl)
                        any = true
                    end
                end
            end
        end
    end
    if any then changed() end
end

-- The loot window lists the experience reward as an item ("60 Producer Experience"), once per
-- swing. It is not an item; the experience total is already in the result's own field.
local function isExperience(name)
    return name:match("Experience$") ~= nil
end

-- Finished gathering actions (from ShroudOnGatherResults).
function M.recordGathers(results)
    local scene = currentScene()
    if not scene then return end

    local s
    for _, r in ipairs(results or {}) do
        local name = r.node
        if name and name ~= "" then
            if gatherLog then
                local got = {}
                for _, it in ipairs(r.items or {}) do
                    if not isExperience(it.name) then got[#got + 1] = it.quantity .. " " .. it.name end
                end
                ShroudConsoleLog("SotaLore gather: node=" .. name .. (r.failed and " (failed)" or "")
                    .. " xp=" .. tostring(r.experience) .. " items=" .. table.concat(got, ", "))
            end
            s = s or sceneEntry(scene)
            local n = s.nodes[name]
            if not n then
                n = { harvests = 0, failed = 0, experience = 0, items = {} }
                s.nodes[name] = n
            end
            n.harvests = n.harvests + 1
            if r.failed then n.failed = n.failed + 1 end
            n.experience = n.experience + (r.experience or 0)
            for _, it in ipairs(r.items or {}) do
                if not isExperience(it.name) then
                    n.items[it.name] = (n.items[it.name] or 0) + it.quantity
                end
            end
        end
    end
    if s then changed() end
end

-- Writing the file -------------------------------------------------------------------------

local function jitems(s)
    local list = {}
    for _, e in pairs(s.items or {}) do list[#list + 1] = e end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    local parts = {}
    for _, e in ipairs(list) do
        parts[#parts + 1] = '{"key":' .. (e.key and jstr(e.key) or 'null')
            .. ',"name":' .. jstr(e.name)
            .. ',"quantity":' .. jnum(e.quantity) .. ',"times":' .. jnum(e.times)
            .. ',"weight":' .. jnum(e.weight) .. ',"value":' .. jnum(e.value) .. '}'
    end
    return table.concat(parts, ',')
end

local function jcreatures(s)
    local list = {}
    for cname, c in pairs(s.creatures or {}) do list[#list + 1] = { name = cname, c = c } end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    local parts = {}
    for _, cc in ipairs(list) do
        parts[#parts + 1] = '{"name":' .. jstr(cc.name) .. ',"seen":' .. jnum(cc.c.seen)
            .. ',"levelMin":' .. jnum(cc.c.levelMin) .. ',"levelMax":' .. jnum(cc.c.levelMax) .. '}'
    end
    return table.concat(parts, ',')
end

local function jnodes(s)
    local list = {}
    for nname, n in pairs(s.nodes or {}) do list[#list + 1] = { name = nname, n = n } end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    local parts = {}
    for _, nn in ipairs(list) do
        local inames = {}
        for iname in pairs(nn.n.items) do inames[#inames + 1] = iname end
        table.sort(inames, function(a, b) return a:lower() < b:lower() end)
        local iparts = {}
        for _, iname in ipairs(inames) do
            iparts[#iparts + 1] = '{"name":' .. jstr(iname) .. ',"quantity":' .. jnum(nn.n.items[iname]) .. '}'
        end
        parts[#parts + 1] = '{"name":' .. jstr(nn.name) .. ',"harvests":' .. jnum(nn.n.harvests)
            .. ',"failed":' .. jnum(nn.n.failed) .. ',"experience":' .. jnum(nn.n.experience)
            .. ',"items":[' .. table.concat(iparts, ',') .. ']}'
    end
    return table.concat(parts, ',')
end

local function jinfo(i)
    if not i then return 'null' end
    return '{"isOverworld":' .. tostring(i.isOverworld) .. ',"isDungeon":' .. tostring(i.isDungeon)
        .. ',"isBasement":' .. tostring(i.isBasement) .. ',"isSiege":' .. tostring(i.isSiege)
        .. ',"isBattleground":' .. tostring(i.isBattleground) .. ',"isPvp":' .. tostring(i.isPvp)
        .. ',"isPot":' .. tostring(i.isPot) .. ',"maxPlayers":' .. jnum(i.maxPlayers)
        .. ',"levelCap":' .. jnum(i.levelCap) .. ',"skillCap":' .. jnum(i.skillCap)
        .. ',"craftingSkillCap":' .. jnum(i.craftingSkillCap) .. '}'
end

-- Writes Lua/sotalore-finds.json. The list is kept; use reset() to empty it.
function M.export()
    local started = util.clock()
    M.save(true)
    local names = {}
    for n in pairs(finds) do names[#names + 1] = n end
    table.sort(names)
    if #names == 0 then
        ShroudConsoleLog("No finds recorded yet.")
        return
    end

    local scenes = {}
    for _, n in ipairs(names) do
        local s = finds[n]
        scenes[#scenes + 1] = '{"scene":' .. jstr(n) .. ',"rawName":' .. jstr(s.raw or "")
            .. ',"info":' .. jinfo(s.info)
            .. ',"items":[' .. jitems(s) .. ']'
            .. ',"creatures":[' .. jcreatures(s) .. ']'
            .. ',"nodes":[' .. jnodes(s) .. ']}'
    end
    local body = util.header("finds")
        .. ',"scenes":[\n' .. table.concat(scenes, ",\n") .. '\n]}\n'

    local path, err = util.writeFile(SotaLore.files.finds, body)
    util.slow("writing the finds file", started)
    if not path then
        ShroudConsoleLog("Finds export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Saved finds for " .. #names .. " scenes to " .. path .. " (type /lua path to open the folder)")
end
