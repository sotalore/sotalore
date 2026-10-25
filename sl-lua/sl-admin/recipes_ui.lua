-- recipes_ui.lua: the recipe browser. A searchable list of the recipes the character knows, and a
-- window for each recipe you click, with its station, what it makes and its ingredients.
--
-- The list window also holds the buttons for the recipe exports (recipes_export.lua). It only shows data: the
-- game reads it with ShroudGetKnownRecipes and ShroudGetRecipe.
--
-- An add-on may own 8 windows: the toolbar, the finds and items windows and this list are 4, so up to 4 recipe
-- windows stay open at once (opening a 5th closes the oldest).
--
-- Used by: toolbar_ui.lua (the Recipes button), main.lua.

local UI = Shroud.UI
local util = SotaLoreAdmin.util
local clip = util.clip
local RecipeExport = SotaLoreAdmin.RecipeExport

local M = {}
SotaLoreAdmin.RecipesUI = M

local MAX_ROWS = 60      -- pooled buttons in the list; refine the search to see more
local MAX_DETAIL = 4     -- recipe windows open at once (8 windows in all: the toolbar, finds, items, the list and these)
local ALL = "All"

local recipes = {}       -- known recipes, sorted by name
local filtered = {}      -- the ones matching the search and category
local search = ""
local category = ALL
local newOnly = false    -- show only recipes "Export new" would export

local listWin, searchField, catDrop, countLabel, newToggle
local exportButton, exportAllButton
local rows = {}          -- the pooled list buttons
local details = {}       -- recipe id -> { win, body }
local detailOrder = {}   -- recipe ids, oldest first

function M.isBuilt()
    return catDrop ~= nil
end

-- A recipe's window ------------------------------------------------------------------------

-- The entry for a recipe id in the list of known recipes (it carries the category key).
local function knownEntry(id)
    for _, r in ipairs(recipes) do
        if r.id == id then return r end
    end
    return { id = id }
end

local function fillDetail(id)
    local d = details[id]
    if not d then return end
    local body = d.body
    body:Clear()

    local r = util.getRecipe(id, knownEntry(id).categoryKey)
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
                    tooltip = "Writes " .. SotaLoreAdmin.files.oneRecipe .. " in the Lua folder",
                    onClick = function() RecipeExport.start("one", knownEntry(id)) end,
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

-- Redraws the recipe windows that are open (their carried counts change as the bags do).
function M.refreshDetails()
    for id, d in pairs(details) do
        if d.win:IsShown() then fillDetail(id) end
    end
end

-- The list ---------------------------------------------------------------------------------

local function applyFilter()
    filtered = {}
    local needle = search:lower()
    -- "New" means not exported yet: the same test "Export new" uses.
    local exported = newOnly and RecipeExport.exportedSet() or nil
    for _, r in ipairs(recipes) do
        if (category == ALL or r.category == category)
            and (needle == "" or r.name:lower():find(needle, 1, true))
            and not (exported and exported[tostring(r.id)]) then
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
    elseif newOnly then
        countLabel:SetText(total .. " new (not exported yet), of " .. #recipes .. " recipes")
    else
        countLabel:SetText(total .. " of " .. #recipes .. " recipes")
    end
end

-- Reads the character's known recipes again and refreshes the list and the category dropdown.
function M.load()
    local started = util.clock()
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
    util.slow("reading the known recipes", started)
end

-- Creates the list window (it starts closed).
function M.build()
    rows, details, detailOrder = {}, {}, {}
    search, category, newOnly = "", ALL, false

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
    newToggle = UI.Toggle{
        text = "New only",
        value = false,
        tooltip = "Show only the recipes that Export new would export",
        onChange = function(_, on)
            newOnly = on and true or false
            applyFilter()
        end,
    }
    -- A finished export (or baseline) changes which recipes are new.
    RecipeExport.onDone = function()
        if newOnly then applyFilter() end
    end

    exportButton = UI.Button{ text = "New recipes", tooltip = "Write only recipes not exported before", onClick = function() RecipeExport.start("new") end }
    exportAllButton = UI.Button{ text = "All recipes", tooltip = "Write every known recipe", onClick = function() RecipeExport.start("all") end }
    -- While an export runs, show its progress on both buttons.
    RecipeExport.onProgress = function(text)
        exportButton:SetText(text or "New recipes")
        exportAllButton:SetText(text or "All recipes")
    end

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
        title = "SotaLore Recipes",
        width = 340, height = 480,
        x = 20, y = 110,
        escCloses = true,
        children = {
            UI.Row{ children = { searchField, catDrop } },
            newToggle,
            countLabel,
            UI.Row{ children = { exportButton, exportAllButton } },
            scroll,
        },
    }
end

-- Open or close the list window.
function M.toggle()
    if listWin:IsShown() then listWin:Hide() else listWin:Show() end
end

-- Open the list window with this text in the search box.
function M.showSearch(text)
    search = text
    searchField:SetText(text)
    applyFilter()
    listWin:Show()
end

-- Open the list window showing only the new (not yet exported) recipes.
function M.showNew()
    newOnly = true
    newToggle:SetValue(true)
    applyFilter()
    listWin:Show()
end
