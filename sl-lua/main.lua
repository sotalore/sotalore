local ScriptName = "SotaLore"
local Version = "0.5.0"
local CreatorName = "Gravidy"
local Description = "Recipe browser and data export for the SotaLore fansite."

local UI = Shroud.UI

local MAX_ROWS = 60      -- pooled buttons in the list; refine the search to see more
local MAX_DETAIL = 6     -- add-ons may own 8 windows; 1 is the list
local ALL = "All"

local recipes = {}       -- sorted list from ShroudGetKnownRecipes
local filtered = {}
local search = ""
local category = ALL

local listWin, searchField, catDrop, countLabel
local rows = {}
local details = {}      -- recipe id -> { win, body }
local detailOrder = {}   -- recipe ids, oldest first

local function clip(text, n)
    if #text > n then return text:sub(1, n - 1) .. "…" end
    return text
end

-- JSON export ------------------------------------------------------------
-- Writes Lua/sl-recipes-export.json: one entry per known recipe, no character data.
-- Runs a slice per frame so a big recipe book never trips the watchdog.

local EXPORT_BATCH = 10   -- group slots make a recipe table big
local EXPORT_FILE = "sl-recipes-export.json"
local ONE_FILE = "sl-recipes-one.json"
local exportState = nil
local exportButton, exportAllButton

local ESCAPES = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

local function jstr(s)
    local escaped = tostring(s):gsub('[%c"\\]', function(c)
        return ESCAPES[c] or string.format("\\u%04x", c:byte())
    end)
    return '"' .. escaped .. '"'
end

local function jlist(list, encode)
    local parts = {}
    for _, it in ipairs(list or {}) do parts[#parts + 1] = encode(it) end
    return '[' .. table.concat(parts, ',') .. ']'
end

-- Item keys ("item:" + 32 hex digits, API 37) are the game's own item ids.
-- A group slot (any metal sheet, any board...) lists its groupKey, size and each member's
-- key and stats here; member names go once into the top-level "groups" catalog.
local function jnum(v)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return "null" end
    return tostring(v)
end

-- stats rows: { key, value [, name] }. For an ingredient they are its weight and what the
-- recipe's quantity of it adds to the finished item (so they depend on the recipe); for a
-- result they are the item's base values.
local function jstats(stats)
    local parts = {}
    for _, s in ipairs(stats or {}) do
        local row = '{"key":' .. jstr(s.key) .. ',"value":' .. jnum(s.value)
        if s.name then row = row .. ',"name":' .. jstr(s.name) end
        parts[#parts + 1] = row .. '}'
    end
    return '[' .. table.concat(parts, ',') .. ']'
end

-- A group member's stats are per recipe, so they sit in the recipe, keyed by item.
local function jchoice(c)
    return '{"key":' .. jstr(c.key or "") .. ',"stats":' .. jstats(c.stats) .. '}'
end

local function jingredient(it)
    local s = '{"name":' .. jstr(it.name) .. ',"quantity":' .. tostring(it.quantity)
        .. ',"optional":' .. tostring(it.optional and true or false)
        .. ',"tool":' .. tostring(it.tool and true or false)
    if it.key then s = s .. ',"key":' .. jstr(it.key) end
    if it.stats then s = s .. ',"stats":' .. jstats(it.stats) end
    if it.group then
        s = s .. ',"group":true,"groupKey":' .. jstr(it.groupKey or "")
            .. ',"choiceCount":' .. tostring(it.choiceCount or 0)
            .. ',"choices":' .. jlist(it.choices, jchoice)
    end
    return s .. '}'
end

local function jresult(it)
    local s = '{"name":' .. jstr(it.name) .. ',"quantity":' .. tostring(it.quantity)
    if it.key then s = s .. ',"key":' .. jstr(it.key) end
    if it.stats then s = s .. ',"stats":' .. jstats(it.stats) end
    return s .. '}'
end

local function jrecipe(r)
    local s = '{"id":' .. tostring(r.id)
        .. ',"name":' .. jstr(r.name)
        .. ',"category":' .. jstr(r.category)
        .. ',"categoryKey":' .. jstr(r.categoryKey)
        .. ',"requiredLevel":' .. tostring(r.requiredLevel)
        .. ',"refine":' .. tostring(r.refine and true or false)
    if r.station then s = s .. ',"station":' .. jstr(r.station) end
    if r.locations then s = s .. ',"locations":' .. jlist(r.locations, jstr) end
    s = s .. ',"ingredients":' .. jlist(r.ingredients, jingredient)
    if r.results then s = s .. ',"results":' .. jlist(r.results, jresult) end
    return s .. '}'
end

-- Collect every group slot's members, merged across recipes.
local function noteGroups(groups, r)
    for _, it in ipairs(r.ingredients or {}) do
        if it.group and it.groupKey then
            local g = groups[it.groupKey]
            if not g then
                g = { name = it.name, choiceCount = 0, members = {} }
                groups[it.groupKey] = g
            end
            g.choiceCount = math.max(g.choiceCount, it.choiceCount or 0)
            for _, c in ipairs(it.choices or {}) do
                if c.key then g.members[c.key] = c.name end
            end
        end
    end
end

-- "complete" is false when the game gave fewer members than the group has
-- (a slot lists at most 30, and a very large group lists only what you carry).
local function jgroups(groups)
    local keys = {}
    for k in pairs(groups) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local g = groups[k]
        local mkeys = {}
        for mk in pairs(g.members) do mkeys[#mkeys + 1] = mk end
        table.sort(mkeys)
        local members = {}
        for _, mk in ipairs(mkeys) do
            members[#members + 1] = '{"key":' .. jstr(mk) .. ',"name":' .. jstr(g.members[mk]) .. '}'
        end
        parts[#parts + 1] = '{"groupKey":' .. jstr(k)
            .. ',"name":' .. jstr(g.name)
            .. ',"choiceCount":' .. tostring(g.choiceCount)
            .. ',"memberCount":' .. #mkeys
            .. ',"complete":' .. tostring(#mkeys >= g.choiceCount)
            .. ',"members":[' .. table.concat(members, ',') .. ']}'
    end
    return '[\n' .. table.concat(parts, ',\n') .. '\n]'
end

-- Recipes already exported are remembered (account-wide) so "new" only sends the rest.
local function loadExported()
    local t = ShroudGetSavedVar("exported", "account")
    if type(t) ~= "table" then t = {} end
    return t
end

local function markExported(ids)
    local t = loadExported()
    for _, id in ipairs(ids) do t[tostring(id)] = true end
    ShroudSetSavedVar("exported", t, "account")
end

local function resetExportButtons()
    exportButton:SetText("Export new")
    exportAllButton:SetText("Export all")
end

local function finishExport()
    local st = exportState
    exportState = nil
    resetExportButtons()

    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local path = root .. "/" .. st.file
    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"scope":' .. jstr(st.scope)
        .. ',"count":' .. #st.parts
        .. ',"recipes":[\n' .. table.concat(st.parts, ",\n") .. '\n]'
        .. ',"groups":' .. jgroups(st.groups) .. '}\n'

    local f, err = io.open(path, "w")
    if not f then
        ShroudConsoleLog("Export failed: " .. tostring(err))
        return
    end
    f:write(body)
    f:close()
    markExported(st.ids)
    ShroudConsoleLog("Exported " .. #st.parts .. " recipes to " .. path .. " (type /lua path to open the folder)")
end

-- mode "new": only recipes not exported before. "all": everything.
-- "baseline": mark everything as exported without writing (after a manual sync).
-- With `only` (a recipe table), exports just that recipe to its own file.
local function startExport(mode, only)
    if exportState then return end
    if only then
        exportState = { list = { only }, i = 1, parts = {}, ids = {}, groups = {}, file = ONE_FILE, scope = "one" }
        return
    end
    local known = ShroudGetKnownRecipes() or {}
    local done = (mode == "all") and {} or loadExported()
    local list = {}
    for _, r in ipairs(known) do
        if not done[tostring(r.id)] then list[#list + 1] = r end
    end

    if mode == "baseline" then
        local ids = {}
        for _, r in ipairs(list) do ids[#ids + 1] = r.id end
        markExported(ids)
        ShroudConsoleLog("Marked " .. #ids .. " recipes as already exported.")
        return
    end
    if #list == 0 then
        ShroudConsoleLog(mode == "all" and "No known recipes to export." or "No new recipes since the last export.")
        return
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    exportState = { list = list, i = 1, parts = {}, ids = {}, groups = {}, file = EXPORT_FILE, scope = mode }
end

local function stepExport()
    local st = exportState
    if not st then return end
    local last = math.min(st.i + EXPORT_BATCH - 1, #st.list)
    for i = st.i, last do
        local r = ShroudGetRecipe(st.list[i].id)
        if r then
            st.parts[#st.parts + 1] = jrecipe(r)
            st.ids[#st.ids + 1] = r.id
            noteGroups(st.groups, r)
        end
    end
    st.i = last + 1
    if st.i > #st.list then
        finishExport()
    else
        local pct = "Exporting " .. math.floor(100 * (st.i - 1) / #st.list) .. "%"
        exportButton:SetText(pct)
        exportAllButton:SetText(pct)
    end
end

-- Item catalog -----------------------------------------------------------
-- Bags and worn gear carry the same item key as recipes (API 37). Each press adds what the
-- character holds to an account-wide catalog and rewrites the whole file, so it grows over
-- time. Only fields of the item kind are kept (no durability, crafter, etc.).

local ITEMS_FILE = "sl-recipes-items.json"
local FINDS_FILE = "sl-recipes-finds.json"

-- Writes a file into the Lua folder. Returns the path, or nil and the error.
local function writeFile(name, body)
    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local path = root .. "/" .. name
    local f, err = io.open(path, "w")
    if not f then return nil, err end
    f:write(body)
    f:close()
    return path
end

-- The API documents weight and value as "one item", but a bag item's numbers are for its whole
-- stack (seen: Animal Hide 31 at 12.4 where a recipe says 0.4 each). Divide by the stack size.
local function perItem(it, field)
    local v = it[field]
    local q = it.quantity
    if type(v) ~= "number" then return nil end
    if type(q) ~= "number" or q < 1 then return v end
    return math.floor(v / q * 10000 + 0.5) / 10000
end

local function exportItems()
    local bags = ShroudGetInventoryItems()
    if not bags then
        ShroudConsoleLog("Items are not loaded yet.")
        return
    end

    local catalog = ShroudGetSavedVar("items", "account")
    if type(catalog) ~= "table" then catalog = {} end

    local added, skipped = 0, 0
    local function take(list)
        for _, it in ipairs(list or {}) do
            if it.key then
                if not catalog[it.key] then added = added + 1 end
                catalog[it.key] = { name = it.name, weight = perItem(it, "weight"), value = perItem(it, "value") }
            else
                skipped = skipped + 1
            end
        end
    end
    take(bags)
    ShroudSetSavedVar("items", catalog, "account")

    local keys = {}
    for k in pairs(catalog) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local it = catalog[k]
        parts[#parts + 1] = '{"key":' .. jstr(k) .. ',"name":' .. jstr(it.name)
            .. ',"weight":' .. jnum(it.weight) .. ',"value":' .. jnum(it.value) .. '}'
    end
    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"count":' .. #keys .. ',"items":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'

    local path, err = writeFile(ITEMS_FILE, body)
    if not path then
        ShroudConsoleLog("Item export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Items: " .. added .. " new, " .. #keys .. " total in " .. path
        .. (skipped > 0 and (" (" .. skipped .. " without a key skipped)") or "")
        .. " (type /lua path to open the folder)")
end

-- Finds per scene -------------------------------------------------------
-- ShroudOnItemsGained is the game's "Recently Looted" rule: loot, purchases, crafting and
-- harvest results, mail, trades, and items taken out of a bank or chest. It does NOT fire for
-- locked items you already had, moving items between bags, equipping, logging in or changing
-- scenes. Each gain is credited to the scene you are in. Gains while the crafting window is
-- open are ignored (crafting results are not finds).
--
-- Creatures: the API cannot list what is in a scene, so a creature is recorded when it shows
-- up in your combat lines (you or your pet hit it, or it hit you or your pet). Only creatures
-- you actually fight are seen. PvP scenes are skipped because the opponents are players.

local finds = {}          -- scene name -> { raw, info, items = { id -> {...} }, creatures = { name -> {...} } }
local findsDirty, lastSave = false, 0
local tracking = true
local findsWin, trackToggle, resetButton, sceneLabel, itemsLabel, creaturesLabel, nodesLabel, scenesLabel
local seenKeys = {}       -- creature keys already counted on this visit to the scene
local resetArmedUntil = nil

local function saveFinds(force)
    if not findsDirty then return end
    if not force and ShroudTime - lastSave < 5 then return end
    ShroudSetSavedVar("finds", finds, "account")
    findsDirty = false
    lastSave = ShroudTime
end

local function updateFindsWindow()
    if not findsWin then return end
    local scenes, kinds, qty, creatures, nodes, harvests = 0, 0, 0, 0, 0, 0
    local itemIds, creatureNames, nodeNames = {}, {}, {}
    for _, s in pairs(finds) do
        scenes = scenes + 1
        for name, n in pairs(s.nodes or {}) do
            if not nodeNames[name] then nodeNames[name] = true; nodes = nodes + 1 end
            harvests = harvests + (n.harvests or 0)
        end
        for id, e in pairs(s.items or {}) do
            if not itemIds[id] then itemIds[id] = true; kinds = kinds + 1 end
            qty = qty + (e.quantity or 0)
        end
        for name in pairs(s.creatures or {}) do
            if not creatureNames[name] then creatureNames[name] = true; creatures = creatures + 1 end
        end
    end
    local scene = ShroudGetSceneInfo()
    local here = (scene and scene.loaded and scene.name ~= "") and scene.name or "(no scene)"
    sceneLabel:SetText(clip(here, 30))
    itemsLabel:SetText("Items: " .. kinds .. " distinct (" .. qty .. " total)")
    creaturesLabel:SetText("Creatures: " .. creatures .. " distinct")
    nodesLabel:SetText("Nodes: " .. nodes .. " distinct (" .. harvests .. " harvests)")
    scenesLabel:SetText("Scenes in list: " .. scenes)
end

local function loadFinds()
    local t = ShroudGetSavedVar("finds", "account")
    finds = type(t) == "table" and t or {}
    tracking = ShroudGetSavedVar("track", "account") ~= false
    findsDirty, lastSave = false, 0
end

local function resetFinds()
    finds = {}
    seenKeys = {}
    findsDirty = true
    saveFinds(true)
    updateFindsWindow()
end

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

local function recordFinds(items)
    local scene = ShroudGetSceneInfo()
    if not scene or not scene.loaded or scene.name == "" then return end
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
            e.key, e.weight, e.value = match.key, perItem(match, "weight"), perItem(match, "value")
        end
    end
    findsDirty = true
    updateFindsWindow()
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

local function recordCreatures(events)
    local scene = ShroudGetSceneInfo()
    if not scene or not scene.loaded or scene.name == "" then return end
    if scene.isPvp or scene.isBattleground then return end

    local me = ShroudGetPlayerName()
    local changed = false
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
                    changed = true
                end
                if c then
                    local lvl = targetLevel(name)
                    if lvl then
                        c.levelMin = math.min(c.levelMin or lvl, lvl)
                        c.levelMax = math.max(c.levelMax or lvl, lvl)
                        changed = true
                    end
                end
            end
        end
    end
    if changed then
        findsDirty = true
        updateFindsWindow()
    end
end

-- Resource nodes you finish (mining, logging, field dressing a carcass if the game counts it as
-- one...): the node's name and what its loot window held. Whether field dressing arrives here
-- is not known yet, so each result is also written to chat while gatherLog is on.
local gatherLog = true

-- The loot window lists the experience reward as an item ("60 Producer Experience"), once per
-- swing. It is not an item; the experience total is already in the result's own field.
local function isExperience(name)
    return name:match("Experience$") ~= nil
end

local function recordGathers(results)
    local scene = ShroudGetSceneInfo()
    if not scene or not scene.loaded or scene.name == "" then return end

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
    if s then
        findsDirty = true
        updateFindsWindow()
    end
end

local function exportFinds()
    saveFinds(true)
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

        local clist = {}
        for cname, c in pairs(s.creatures or {}) do clist[#clist + 1] = { name = cname, c = c } end
        table.sort(clist, function(a, b) return a.name:lower() < b.name:lower() end)
        local cparts = {}
        for _, cc in ipairs(clist) do
            cparts[#cparts + 1] = '{"name":' .. jstr(cc.name) .. ',"seen":' .. jnum(cc.c.seen)
                .. ',"levelMin":' .. jnum(cc.c.levelMin) .. ',"levelMax":' .. jnum(cc.c.levelMax) .. '}'
        end

        local nlist = {}
        for nname, n in pairs(s.nodes or {}) do nlist[#nlist + 1] = { name = nname, n = n } end
        table.sort(nlist, function(a, b) return a.name:lower() < b.name:lower() end)
        local nparts = {}
        for _, nn in ipairs(nlist) do
            local inames = {}
            for iname in pairs(nn.n.items) do inames[#inames + 1] = iname end
            table.sort(inames, function(a, b) return a:lower() < b:lower() end)
            local iparts = {}
            for _, iname in ipairs(inames) do
                iparts[#iparts + 1] = '{"name":' .. jstr(iname) .. ',"quantity":' .. jnum(nn.n.items[iname]) .. '}'
            end
            nparts[#nparts + 1] = '{"name":' .. jstr(nn.name) .. ',"harvests":' .. jnum(nn.n.harvests)
                .. ',"failed":' .. jnum(nn.n.failed) .. ',"experience":' .. jnum(nn.n.experience)
                .. ',"items":[' .. table.concat(iparts, ',') .. ']}'
        end

        local i = s.info
        local info = 'null'
        if i then
            info = '{"isOverworld":' .. tostring(i.isOverworld) .. ',"isDungeon":' .. tostring(i.isDungeon)
                .. ',"isBasement":' .. tostring(i.isBasement) .. ',"isSiege":' .. tostring(i.isSiege)
                .. ',"isBattleground":' .. tostring(i.isBattleground) .. ',"isPvp":' .. tostring(i.isPvp)
                .. ',"isPot":' .. tostring(i.isPot) .. ',"maxPlayers":' .. jnum(i.maxPlayers)
                .. ',"levelCap":' .. jnum(i.levelCap) .. ',"skillCap":' .. jnum(i.skillCap)
                .. ',"craftingSkillCap":' .. jnum(i.craftingSkillCap) .. '}'
        end
        scenes[#scenes + 1] = '{"scene":' .. jstr(n) .. ',"rawName":' .. jstr(s.raw or "")
            .. ',"info":' .. info
            .. ',"items":[' .. table.concat(parts, ',') .. ']'
            .. ',"creatures":[' .. table.concat(cparts, ',') .. ']'
            .. ',"nodes":[' .. table.concat(nparts, ',') .. ']}'
    end
    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"scenes":[\n' .. table.concat(scenes, ",\n") .. '\n]}\n'

    local path, err = writeFile(FINDS_FILE, body)
    if not path then
        ShroudConsoleLog("Finds export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Saved finds for " .. #names .. " scenes to " .. path .. " (type /lua path to open the folder)")
end

-- Reset needs a second click within a few seconds, so a stray click on a window left up
-- during play cannot throw the list away.
local function onResetClick()
    if resetArmedUntil and ShroudTime < resetArmedUntil then
        resetArmedUntil = nil
        resetButton:SetText("Reset")
        resetFinds()
        ShroudConsoleLog("Find list reset.")
    else
        resetArmedUntil = ShroudTime + 4
        resetButton:SetText("Click again")
    end
end

local function buildFindsWindow()
    sceneLabel = UI.Label{ text = "", class = "heading" }
    itemsLabel = UI.Label{ text = "" }
    creaturesLabel = UI.Label{ text = "" }
    nodesLabel = UI.Label{ text = "" }
    scenesLabel = UI.Label{ text = "", class = "dim" }
    trackToggle = UI.Toggle{
        text = "Tracking",
        value = tracking,
        tooltip = "Turn off while banking or shopping: those gains look like loot",
        onChange = function(_, on)
            tracking = on and true or false
            ShroudSetSavedVar("track", tracking, "account")
        end,
    }
    resetButton = UI.Button{ text = "Reset", tooltip = "Clear the find list (click twice)", onClick = onResetClick }
    findsWin = UI.Window{
        id = "sotalorefinds",
        title = "SotaLore Finds",
        width = 230, height = 220,
        x = 20, y = 540,
        children = {
            sceneLabel,
            itemsLabel,
            creaturesLabel,
            nodesLabel,
            scenesLabel,
            trackToggle,
            UI.Row{ children = {
                UI.Button{ text = "Save", tooltip = "Write " .. FINDS_FILE .. " (keeps the list)", onClick = exportFinds },
                resetButton,
            } },
        },
    }
end

local function toggleFindsWindow()
    if findsWin:IsShown() then findsWin:Hide() else findsWin:Show() end
end

-- Detail window ----------------------------------------------------------

local function fillDetail(id)
    local d = details[id]
    if not d then return end
    local body = d.body
    body:Clear()

    local r = ShroudGetRecipe(id)
    if not r then
        body:Add(UI.Label{ text = "You no longer know this recipe.", class = "warning" })
        return
    end

    d.win:SetTitle(clip(r.name, 40))
    body:Add(UI.Label{ text = r.name, class = "title" })
    local kind = r.refine and "Refining" or "Crafting"
    body:Add(UI.Label{ text = r.category .. "  |  " .. kind .. "  |  Level " .. r.requiredLevel, class = "dim" })
    if r.station then
        local where = ""
        if r.locations and not (#r.locations == 1 and r.locations[1] == "any") and #r.locations > 0 then
            where = "  |  only at " .. table.concat(r.locations, ", ")
        end
        body:Add(UI.Label{ text = r.station .. where, class = "dim" })
    end

    body:Add(UI.Label{ text = "Makes", class = "heading" })
    if r.results == nil then
        body:Add(UI.Label{ text = "Not available (needs Lua API 24, this client has " .. tostring(ShroudLuaApiVersion) .. ")", class = "dim" })
    elseif #r.results > 0 then
        for _, res in ipairs(r.results) do
            body:Add(UI.Label{ text = res.quantity .. " x " .. res.name })
        end
    else
        body:Add(UI.Label{ text = "Varies (random from a list)", class = "dim" })
    end

    body:Add(UI.Label{ text = "Ingredients", class = "heading" })
    for _, ing in ipairs(r.ingredients or {}) do
        local tag = ""
        if ing.tool then tag = " (tool)" elseif ing.optional then tag = " (optional)" end
        if ing.group then tag = tag .. " (any of " .. tostring(ing.choiceCount or "?") .. ")" end
        local ok = ing.have >= ing.quantity
        body:Add(UI.Label{
            text = ing.name .. " x" .. ing.quantity .. tag .. "   [" .. ing.have .. " carried]",
            class = ok and "good" or "bad",
        })
    end
end

local function openDetail(id)
    local d = details[id]
    if not d then
        if #detailOrder >= MAX_DETAIL then
            local oldest = table.remove(detailOrder, 1)
            details[oldest].win:Destroy()
            details[oldest] = nil
        end
        local n = #detailOrder
        local body = UI.Scroll{ style = { flexGrow = 1 } }
        local win = UI.Window{
            id = "recipe" .. id,
            title = "Recipe",
            width = 320, height = 380,
            x = 380 + n * 28, y = 80 + n * 28,
            escCloses = true,
            children = {
                body,
                UI.Button{
                    text = "Save this recipe to file",
                    tooltip = "Writes " .. ONE_FILE .. " in the Lua folder",
                    onClick = function() startExport("one", { id = id }) end,
                },
            },
        }
        d = { win = win, body = body }
        details[id] = d
        detailOrder[#detailOrder + 1] = id
    end
    fillDetail(id)
    d.win:Show()
end

local function refreshDetails()
    for id, d in pairs(details) do
        if d.win:IsShown() then fillDetail(id) end
    end
end

-- List window ------------------------------------------------------------

local function applyFilter()
    filtered = {}
    local needle = search:lower()
    for _, r in ipairs(recipes) do
        if (category == ALL or r.category == category)
            and (needle == "" or r.name:lower():find(needle, 1, true)) then
            filtered[#filtered + 1] = r
        end
    end

    for i, row in ipairs(rows) do
        local r = filtered[i]
        if r then
            row:SetText((r.favorite and "* " or "") .. clip(r.name, 34) .. "  (L" .. r.requiredLevel .. ")")
            row:SetVisible(true)
        else
            row:SetVisible(false)
        end
    end

    local total = #filtered
    if total > MAX_ROWS then
        countLabel:SetText("Showing " .. MAX_ROWS .. " of " .. total .. " - refine the search")
    else
        countLabel:SetText(total .. " of " .. #recipes .. " recipes")
    end
end

local function loadRecipes()
    recipes = {}
    local seen, cats = {}, { ALL }
    for _, r in ipairs(ShroudGetKnownRecipes() or {}) do
        recipes[#recipes + 1] = r
        if not seen[r.category] then
            seen[r.category] = true
            cats[#cats + 1] = r.category
        end
    end
    table.sort(recipes, function(a, b) return a.name:lower() < b.name:lower() end)
    table.sort(cats, function(a, b)
        if a == ALL then return b ~= ALL end
        if b == ALL then return false end
        return a < b
    end)

    if category ~= ALL and not seen[category] then category = ALL end
    catDrop:SetChoices(cats)
    catDrop:SetValue(category)
    applyFilter()
end

local function buildList()
    searchField = UI.TextField{
        placeholder = "Search recipes",
        style = { flexGrow = 1 },
        onChange = function(_, text)
            search = text or ""
            applyFilter()
        end,
    }
    catDrop = UI.Dropdown{
        choices = { ALL },
        value = ALL,
        onChange = function(_, value)
            category = value
            applyFilter()
        end,
    }
    countLabel = UI.Label{ text = "", class = "dim" }

    exportButton = UI.Button{ text = "Export new", tooltip = "Write only recipes not exported before", onClick = function() startExport("new") end }
    exportAllButton = UI.Button{ text = "Export all", tooltip = "Write every known recipe", onClick = function() startExport("all") end }

    local scroll = UI.Scroll{ style = { flexGrow = 1 } }
    for i = 1, MAX_ROWS do
        local row = UI.Button{
            text = "",
            visible = false,
            onClick = function()
                local r = filtered[i]
                if r then openDetail(r.id) end
            end,
        }
        rows[i] = row
        scroll:Add(row)
    end

    listWin = UI.Window{
        id = "recipelist",
        title = "SotaLore: Known Recipes",
        width = 340, height = 480,
        x = 20, y = 80,
        escCloses = true,
        children = {
            UI.Row{ children = { searchField, catDrop } },
            countLabel,
            UI.Row{ children = { exportButton, exportAllButton } },
            UI.Row{ children = {
                UI.Button{
                    text = "Finds window",
                    tooltip = "Show or hide the small window that tracks items and creatures per scene",
                    onClick = toggleFindsWindow,
                },
                UI.Button{
                    text = "Export my items",
                    tooltip = "Add bag items (key, name, weight, value) to " .. ITEMS_FILE,
                    onClick = exportItems,
                },
            } },
            scroll,
        },
    }
end

local function toggleList(args)
    if args == "export" then
        startExport("new")
    elseif args == "exportall" then
        startExport("all")
    elseif args == "items" then
        exportItems()
    elseif args == "finds" then
        toggleFindsWindow()
    elseif args == "gatherlog" then
        gatherLog = not gatherLog
        ShroudConsoleLog("Gather log " .. (gatherLog and "on" or "off"))
    elseif args == "savefinds" then
        exportFinds()
    elseif args == "clearfinds" then
        resetFinds()
        ShroudConsoleLog("Cleared all recorded finds.")
    elseif args == "baseline" then
        startExport("baseline")
    elseif args and args ~= "" then
        search = args
        searchField:SetText(args)
        applyFilter()
        listWin:Show()
    elseif listWin:IsShown() then
        listWin:Hide()
    else
        listWin:Show()
    end
end

-- Callbacks --------------------------------------------------------------

function ShroudOnStart()
    rows, details, detailOrder, exportState = {}, {}, {}, nil
    search, category = "", ALL

    loadFinds()
    seenKeys, resetArmedUntil = {}, nil
    buildList()
    buildFindsWindow()
    loadRecipes()
    updateFindsWindow()

    -- /sotalore is refused ("sota" is a reserved prefix), so the command is /slore.
    local ok, reason = Shroud.Command{
        name = "slore",
        help = "Open SotaLore. /slore <text> searches; export, exportall, items, finds (window), savefinds, clearfinds, gatherlog.",
        run = toggleList,
    }
    if not ok then
        ShroudConsoleLog("/slore unavailable (" .. tostring(reason) .. ")")
    end

    Shroud.Keybind{ id = "toggle", label = "SotaLore: toggle list", onPress = function() toggleList("") end }
end

function ShroudOnUpdate()
    if exportState then stepExport() end
    if resetArmedUntil and ShroudTime >= resetArmedUntil then
        resetArmedUntil = nil
        resetButton:SetText("Reset")
    end
    saveFinds(false)
end

function ShroudOnItemsGained(items)
    if tracking and findsWin then recordFinds(items) end
end

function ShroudOnGatherResults(results)
    if tracking and findsWin then recordGathers(results) end
end

function ShroudOnCombatEvents(events)
    if tracking and findsWin then recordCreatures(events) end
end

function ShroudOnSceneLoaded()
    seenKeys = {}
    if findsWin then updateFindsWindow() end
end

function ShroudOnLogOut()
    saveFinds(true)
end

function ShroudOnDisableScript()
    saveFinds(true)
end

-- Change callbacks can fire before ShroudOnStart has built the windows.
function ShroudOnRecipesChanged()
    if not catDrop then return end
    loadRecipes()
    refreshDetails()
end

function ShroudOnInventoryChanged()
    if not catDrop then return end
    refreshDetails()
end
