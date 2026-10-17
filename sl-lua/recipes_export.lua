-- recipes_export.lua: turns the recipes the character knows into JSON files for the site.
--
-- Writes Lua/sotalore-export.json (many recipes) or sotalore-one.json (one recipe); the format is
-- described in EXPORT-FORMAT.md. No character data is exported. It reads a few recipes per frame
-- (see step) so a big recipe book never trips the game's watchdog.
--
-- Used by: recipes_ui.lua (the buttons), main.lua (the /slore commands and the per-frame step).

local util = SotaLore.util
local jstr, jnum, jlist = util.jstr, util.jnum, util.jlist

local M = {}
SotaLore.RecipeExport = M

local EXPORT_BATCH = 10   -- recipes read per frame; group slots make a recipe table big
local state = nil         -- the export in progress, or nil

-- The UI sets this to hear about progress: fn(text) while running, fn(nil) when it is over.
M.onProgress = nil

-- The UI sets this to hear when recipes were marked as exported (after a file is written, or a baseline).
M.onDone = nil

local function progress(text)
    if M.onProgress then M.onProgress(text) end
end

-- Encoding one recipe ----------------------------------------------------------------------

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

-- Item keys ("item:" + 32 hex digits, API 37) are the game's own item ids.
-- A group slot (any metal sheet, any board...) lists its groupKey, size and each member's
-- key and stats here; member names go once into the top-level "groups" catalog.
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

-- Groups -----------------------------------------------------------------------------------

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

-- What has been exported already ----------------------------------------------------------

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

-- The recipes already exported, as a set: set[tostring(recipe id)] is true. A recipe that is not in
-- it is what "Export new" would export.
function M.exportedSet()
    return loadExported()
end

-- Running an export ------------------------------------------------------------------------

local function finish()
    local st = state
    state = nil
    progress(nil)

    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"scope":' .. jstr(st.scope)
        .. ',"count":' .. #st.parts
        .. ',"recipes":[\n' .. table.concat(st.parts, ",\n") .. '\n]'
        .. ',"groups":' .. jgroups(st.groups) .. '}\n'

    local path, err = util.writeFile(st.file, body)
    if not path then
        ShroudConsoleLog("Export failed: " .. tostring(err))
        return
    end
    markExported(st.ids)
    ShroudConsoleLog("Exported " .. #st.parts .. " recipes to " .. path .. " (type /lua path to open the folder)")
    if st.unreadable then
        local shown = {}
        for i = 1, math.min(#st.unreadable, 8) do shown[i] = st.unreadable[i] end
        ShroudConsoleLog("WARNING: " .. #st.unreadable .. " recipes could not be read and are NOT in the file: "
            .. table.concat(shown, ", ") .. (#st.unreadable > 8 and ", ..." or ""))
    end
    if M.onDone then M.onDone() end
end

-- mode "new": only recipes not exported before. "all": everything.
-- "baseline": mark everything as exported without writing (after a manual sync).
-- With `only` (a recipe table), exports just that recipe to its own file.
function M.start(mode, only)
    if state then return end
    if only then
        state = { list = { only }, i = 1, parts = {}, ids = {}, groups = {}, file = SotaLore.files.oneRecipe, scope = "one" }
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
        if M.onDone then M.onDone() end
        return
    end
    if #list == 0 then
        ShroudConsoleLog(mode == "all" and "No known recipes to export." or "No new recipes since the last export.")
        return
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    state = { list = list, i = 1, parts = {}, ids = {}, groups = {}, file = SotaLore.files.recipes, scope = mode }
end

-- Checking that every known recipe can be read ------------------------------------------------

local check = nil   -- the check in progress, or nil

-- Starts a check (the /slore checkrecipes command): reads every known recipe, a few per frame, and
-- reports in chat the ones ShroudGetRecipe cannot read, and whether the recipe book can.
function M.check()
    if check then return end
    local known = ShroudGetKnownRecipes() or {}
    check = { list = known, i = 1, bad = {} }
    ShroudConsoleLog("Recipe check started: " .. #known .. " known recipes")
end

local function stepCheck()
    local c = check
    if not c then return end
    local last = math.min(c.i + EXPORT_BATCH - 1, #c.list)
    for i = c.i, last do
        local k = c.list[i]
        if not ShroudGetRecipe(k.id) then c.bad[#c.bad + 1] = k end
    end
    c.i = last + 1
    if c.i <= #c.list then return end

    check = nil
    ShroudConsoleLog("Recipe check: " .. #c.list .. " known, " .. #c.bad .. " cannot be read with ShroudGetRecipe")
    for i = 1, math.min(#c.bad, 8) do
        local k = c.bad[i]
        ShroudConsoleLog("  " .. tostring(k.name) .. "  id=" .. tostring(k.id) .. "  " .. tostring(k.categoryKey))
    end
    if #c.bad > 0 and ShroudGetRecipeBook then
        local first = c.bad[1]
        local ok, book = pcall(ShroudGetRecipeBook, first.categoryKey)
        local found = false
        if ok and type(book) == "table" then
            for _, b in ipairs(book) do if b.id == first.id then found = true end end
        end
        ShroudConsoleLog("  ShroudGetRecipeBook(" .. tostring(first.categoryKey) .. "): "
            .. (ok and (type(book) == "table" and (#book .. " recipes") or tostring(book)) or ("error: " .. tostring(book)))
            .. "; contains " .. tostring(first.name) .. ": " .. tostring(found))
    end
end

-- Called every frame (from main.lua's ShroudOnUpdate); does nothing unless an export or check is running.
function M.step()
    stepCheck()
    local st = state
    if not st then return end
    local last = math.min(st.i + EXPORT_BATCH - 1, #st.list)
    for i = st.i, last do
        local entry = st.list[i]
        local r = util.getRecipe(entry.id, entry.categoryKey)
        if r then
            st.parts[#st.parts + 1] = jrecipe(r)
            st.ids[#st.ids + 1] = r.id
            noteGroups(st.groups, r)
        else
            -- Not exported (and so not marked exported either); say so rather than lose it quietly.
            st.unreadable = st.unreadable or {}
            st.unreadable[#st.unreadable + 1] = tostring(entry.name or entry.id)
        end
    end
    st.i = last + 1
    if st.i > #st.list then
        finish()
    else
        progress("Exporting " .. math.floor(100 * (st.i - 1) / #st.list) .. "%")
    end
end

-- Forgets any export in progress (used when the plugin starts).
function M.reset()
    state = nil
end
