local ScriptName = "SL Recipes"
local Version = "0.2.0"
local CreatorName = "Gravidy"
local Description = "Searchable list of known recipes with a detail window per recipe."

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
        exportState = { list = { only }, i = 1, parts = {}, ids = {}, groups = {}, file = ONE_FILE }
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
    exportState = { list = list, i = 1, parts = {}, ids = {}, groups = {}, file = EXPORT_FILE }
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

local function exportItems()
    local bags, worn = ShroudGetInventoryItems(), ShroudGetEquipmentItems()
    if not bags and not worn then
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
                catalog[it.key] = { name = it.name, weight = it.weight, value = it.value }
            else
                skipped = skipped + 1
            end
        end
    end
    take(bags)
    take(worn)
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

    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local path = root .. "/" .. ITEMS_FILE
    local f, err = io.open(path, "w")
    if not f then
        ShroudConsoleLog("Item export failed: " .. tostring(err))
        return
    end
    f:write(body)
    f:close()
    ShroudConsoleLog("Items: " .. added .. " new, " .. #keys .. " total in " .. path
        .. (skipped > 0 and (" (" .. skipped .. " without a key skipped)") or "")
        .. " (type /lua path to open the folder)")
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
        title = "Known Recipes",
        width = 340, height = 480,
        x = 20, y = 80,
        escCloses = true,
        children = {
            UI.Row{ children = { searchField, catDrop } },
            countLabel,
            UI.Row{ children = { exportButton, exportAllButton } },
            UI.Button{
                text = "Export my items",
                tooltip = "Add bag and worn items (key, name, weight, value) to " .. ITEMS_FILE,
                onClick = exportItems,
            },
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

    buildList()
    loadRecipes()

    local ok, reason = Shroud.Command{
        name = "recipes",
        help = "Open the recipe browser. /recipes <text> searches.",
        run = toggleList,
    }
    if not ok then
        ShroudConsoleLog("/recipes unavailable (" .. tostring(reason) .. "), using /slrecipes")
        Shroud.Command{
            name = "slrecipes",
            help = "Open the recipe browser. /slrecipes <text> searches.",
            run = toggleList,
        }
    end

    Shroud.Keybind{ id = "toggle", label = "SL Recipes: toggle list", onPress = function() toggleList("") end }
end

function ShroudOnUpdate()
    if exportState then stepExport() end
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
