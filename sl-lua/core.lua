-- core.lua: loaded first. Creates the one global table, SotaLore, and the small helpers every
-- other file uses.
--
-- How this plugin is organised: the manifest lists the files in the order the game runs them, and
-- they all share one environment. Everything else in a file is `local`; the only way files talk to
-- each other is through the SotaLore table. Each file adds one piece to it (SotaLore.RecipeExport,
-- SotaLore.Finds, ...) and starts by saying what that piece is for. main.lua is the last file and the
-- only one with the ShroudOn... callbacks, so read it first to see what happens when.
--
-- Files can't load each other (no require), and the Shroud... functions don't exist yet while a
-- file is loading. So files only define things at load time and use the game's API inside functions.

local ScriptName = "SotaLore"
local Version = "0.7.3"
local CreatorName = "Gravidy"
local Description = "Recipe browser and data export for the SotaLore fansite."

SotaLore = {}

-- Names of the files the plugin writes into the game's Lua folder.
SotaLore.files = {
    recipes = "sotalore-export.json",
    oneRecipe = "sotalore-one.json",
    items = "sotalore-items.json",
    finds = "sotalore-finds.json",
}

local util = {}
SotaLore.util = util

-- Shortens text to n characters, ending with an ellipsis.
function util.clip(text, n)
    if #text > n then return text:sub(1, n - 1) .. "…" end
    return text
end

-- JSON writing. The plugin builds its JSON by hand: these turn Lua values into JSON text.
local ESCAPES = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

function util.jstr(s)
    local escaped = tostring(s):gsub('[%c"\\]', function(c)
        return ESCAPES[c] or string.format("\\u%04x", c:byte())
    end)
    return '"' .. escaped .. '"'
end

-- The version of the plugin, written into every file it makes (see util.header).
SotaLore.version = Version

-- The opening of every file the plugin writes, without the closing brace: the game's API version, the
-- plugin's version, and what kind of file it is ("recipes", "items" or "finds"). The site uses them to
-- refuse a file uploaded to the wrong place and to tell files from older plugin versions apart.
function util.header(kind)
    return '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"pluginVersion":' .. util.jstr(Version)
        .. ',"type":' .. util.jstr(kind)
end

-- A number, or null for a missing or non-finite value.
function util.jnum(v)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return "null" end
    return tostring(v)
end

-- A JSON list made by calling `encode` on every entry of a Lua list.
function util.jlist(list, encode)
    local parts = {}
    for _, it in ipairs(list or {}) do parts[#parts + 1] = encode(it) end
    return '[' .. table.concat(parts, ',') .. ']'
end

-- Writes a file into the game's Lua folder. Returns the path, or nil and the error.
function util.writeFile(name, body)
    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local path = root .. "/" .. name
    local f, err = io.open(path, "w")
    if not f then return nil, err end
    f:write(body)
    f:close()
    return path
end

-- Time. The game stops any callback that runs longer than 1 second (5 seconds while the plugin starts), so
-- long jobs are cut into slices of a fraction of a second, one slice per frame (util.sliceLimit), and any
-- step that runs unusually long says so in chat (util.slow) so the slow one can be found.
util.clock = os.clock or function() return 0 end
util.sliceLimit = 0.15     -- seconds of work per frame for a sliced job

-- Says in chat when something that started at `since` (a util.clock() value) took a long time.
function util.slow(what, since)
    local took = util.clock() - since
    if took > 0.3 then
        ShroudConsoleLog(string.format("SotaLore slow: %s took %.0f ms (the game stops a callback at 1000 ms)", what, took * 1000))
    end
end

-- Reading one recipe. ShroudGetRecipe(id) sometimes returns nothing for a recipe that
-- ShroudGetKnownRecipes lists (seen with newly learned recipes). Fall back to the recipe book
-- (API 37), which returns the same tables, read once per crafting skill and kept until
-- clearRecipeCache() (called when the recipes or bags change).
local bookCache = {}   -- categoryKey -> { recipe id -> recipe }

function util.clearRecipeCache()
    bookCache = {}
end

function util.getRecipe(id, categoryKey)
    local r = ShroudGetRecipe(id)
    if r then return r end
    if not categoryKey or not ShroudGetRecipeBook then return nil end
    local byId = bookCache[categoryKey]
    if not byId then
        byId = {}
        local started = util.clock()
        local ok, book = pcall(ShroudGetRecipeBook, categoryKey)
        util.slow("reading the recipe book for " .. categoryKey, started)
        if ok and type(book) == "table" then
            for _, b in ipairs(book) do byId[b.id] = b end
        end
        bookCache[categoryKey] = byId
    end
    return byId[id]
end

-- The items with this name from a list function such as ShroudGetInventoryItems. A name read from a
-- tooltip can differ from the list's: the list may add markers ("[u]Letter[/u]"), and a tooltip title
-- can end with the base item's name in brackets ("Boots +15 (Leather Boots +15)"). Several items can
-- share a name, so all matches are returned.
function util.itemsNamed(getList, name)
    local found = {}
    local short = name:gsub("%s*%b()%s*$", "")
    for _, it in ipairs(getList() or {}) do
        local plain = it.name and it.name:gsub("%[/?%a+%]", "")
        if it.name == name or plain == name or it.name == short or plain == short then
            found[#found + 1] = it
        end
    end
    return found
end

-- The API documents weight and value as "one item", but a bag item's numbers are for its whole
-- stack (seen: Animal Hide 31 at 12.4 where a recipe says 0.4 each). Divide by the stack size.
function util.perItem(it, field)
    local v = it[field]
    local q = it.quantity
    if type(v) ~= "number" then return nil end
    if type(q) ~= "number" or q < 1 then return v end
    return math.floor(v / q * 10000 + 0.5) / 10000
end
