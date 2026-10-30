-- core.lua: loaded first. Creates the one global table, SotaLoreAdmin, and the small helpers every
-- other file uses.
--
-- How this plugin is organised: the manifest lists the files in the order the game runs them, and
-- they all share one environment. Everything else in a file is `local`; the only way files talk to
-- each other is through the SotaLoreAdmin table. Each file adds one piece to it (SotaLoreAdmin.RecipeExport,
-- SotaLoreAdmin.Finds, ...) and starts by saying what that piece is for. main.lua is the last file and the
-- only one with the ShroudOn... callbacks, so read it first to see what happens when.
--
-- Files can't load each other (no require), and the Shroud... functions don't exist yet while a
-- file is loading. So files only define things at load time and use the game's API inside functions.

local ScriptName = "SotaLore Admin"
local Version = "0.15.0"
local CreatorName = "Gravidy"
local Description = "SotaLore site admin tools: recipe, item and find exports for upload to the site."

-- This is the admin plugin (folder and slug sl-admin). The skills export for players is a separate plugin,
-- sl-skills, with its own global table (SotaLoreSkills): all add-ons share one global environment, so the two
-- must never use the same global name.

SotaLoreAdmin = {}

-- Names of the files the plugin writes into the game's Lua folder.
SotaLoreAdmin.files = {
    recipesNew = "sotalore-recipes-new.json",   -- the names follow the site's navigation (Recipes, Items, Scene Finds)
    recipesAll = "sotalore-recipes-all.json",
    oneRecipe = "sotalore-recipes-one.json",
    items = "sotalore-item-catalog.json",
    finds = "sotalore-scene-finds.json",
    gameSkills = "sotalore-game-skills.json",    -- not for upload: copied into the repo for the app's code
    hoverLog = "sotalore-hoverlog.txt",          -- not for upload: the hover log's full tooltips, to read
}

local util = {}
SotaLoreAdmin.util = util

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
SotaLoreAdmin.version = Version

-- The opening of every file the plugin writes, without the closing brace: the game's API version, the
-- plugin's version, and what kind of file it is ("recipes", "items" or "finds"). The site uses them to
-- refuse a file uploaded to the wrong place and to tell files from older plugin versions apart.
function util.header(kind)
    return '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"plugin":"sl-admin"'
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

-- Writes a file into the game's Lua folder. Returns the path, or nil and the error. (The game does not let an
-- add-on add to the end of a file, mode "a": that fails, so a growing file has to be written whole each time.)
function util.writeFile(name, body)
    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local path = root .. "/" .. name
    local f, err = io.open(path, "w")
    if not f then return nil, err end
    f:write(body)
    f:close()
    return path
end

-- What a file in the game's Lua folder holds, or nil when it can't be read (missing, or not allowed).
function util.readFile(name)
    local root = ShroudLuaPath:gsub("[/\\]+$", "")
    local ok, f = pcall(io.open, root .. "/" .. name, "r")
    if not ok or not f then return nil end
    local body = f:read("*a")   -- "*a", not "a": the game's Lua is 5.2-style
    f:close()
    return body
end

-- A short fingerprint of a text: 8 hex digits. Only arithmetic (no bit operators), so it is the same on every Lua.
function util.hash(s)
    local h = 5381
    for i = 1, #s do
        h = (h * 33 + s:byte(i)) % 4294967296
    end
    return string.format("%08x", math.floor(h))
end

-- Saved variables. The game writes an add-on's saved data to disk only at logout, when the add-on is unloaded (which
-- /lua reload and every scene change do) or on ShroudFlushSavedVars, and it refuses a scope's file whose JSON is over
-- 256 KB: that file is then not written at all, so every change since the last good write is lost, with only a line
-- in the add-on console (2026-10-24: the account file had reached 256,011 bytes, and a day's captures vanished at a
-- reload). util.flush writes now and says so in chat when the game refused.
local flushFailed = false

function util.flush()
    if not ShroudFlushSavedVars then return true end
    local ok = ShroudFlushSavedVars()
    if ok == false then
        if not flushFailed then
            ShroudConsoleLog("SotaLore Admin: WARNING, the game did not save the add-on's data (a saved file is over its "
                .. "256 KB limit). New captures will be lost at the next reload.")
        end
        flushFailed = true
    elseif flushFailed then
        flushFailed = false
        ShroudConsoleLog("SotaLore Admin: the add-on's data is being saved again.")
    end
    return ok ~= false
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

-- Recipes the game won't hand over.
--
-- ShroudGetRecipe(id) returns nothing for some recipes that ShroudGetKnownRecipes lists (about 100 of 1,234:
-- Alchemy gem recipes, Tanning trophies). The recipe book (ShroudGetRecipeBook, one craft skill at a time) has
-- them, but reading a whole skill's book can take longer than the 1 second the game allows a callback (Alchemy
-- took 1.8 s on 2026-10-18), and the game stops a call that slow part way. So:
--   * every recipe got from a book is kept (account saved variable "bookRecipes"), with a note of which recipes
--     need a book ("needBook"); later reads use that copy instead of reading the slow book again;
--   * a book is read at most once until clearRecipeCache() (each export starts with it): it is marked as tried
--     before the call, so a read the game stops is not tried again, and cannot pile up the repeated errors that
--     make the game switch a plugin off;
--   * readNeededBooks() reads the books those recipes need while the plugin starts, when the game allows 5
--     seconds instead of 1, which keeps the copies fresh: /lua reload runs it.
local bookCache = {}   -- categoryKey -> { recipe id -> recipe } once read; false once tried without a result

local function savedTable(name)
    local t = ShroudGetSavedVar(name, "account")
    if type(t) ~= "table" then t = {} end
    return t
end

-- Forgets the books read so far, so each is read again when next needed.
function util.clearRecipeCache()
    bookCache = {}
end

-- Reads one craft skill's recipe book (at most once until clearRecipeCache) and keeps the recipes that need it.
function util.readBook(categoryKey)
    if not categoryKey or not ShroudGetRecipeBook or bookCache[categoryKey] ~= nil then return end
    bookCache[categoryKey] = false
    local started = util.clock()
    local ok, book = pcall(ShroudGetRecipeBook, categoryKey)
    util.slow("reading the recipe book for " .. categoryKey, started)
    if not ok or type(book) ~= "table" then return end
    local byId = {}
    for _, b in ipairs(book) do byId[b.id] = b end
    bookCache[categoryKey] = byId

    local need, kept = savedTable("needBook"), savedTable("bookRecipes")
    for key, cat in pairs(need) do
        local r = (cat == categoryKey) and byId[tonumber(key)]
        if r then kept[key] = r end
    end
    ShroudSetSavedVar("bookRecipes", kept, "account")
end

-- Whether getting this recipe would mean reading a book that has not been tried yet (the recipe export gives
-- such a read a frame of its own). A recipe with a kept copy never needs one.
function util.bookPending(id, categoryKey)
    if not categoryKey or not ShroudGetRecipeBook or bookCache[categoryKey] ~= nil then return false end
    return savedTable("bookRecipes")[tostring(id)] == nil
end

-- A recipe ShroudGetRecipe did not hand over: from a book read since the last clearRecipeCache, else the kept
-- copy, else by reading the book now. Returns the recipe and where it came from ("book" or "kept"), or nil.
function util.fallbackRecipe(id, categoryKey)
    if not categoryKey then return nil end
    local key = tostring(id)
    local need = savedTable("needBook")
    if need[key] ~= categoryKey then
        need[key] = categoryKey
        ShroudSetSavedVar("needBook", need, "account")
    end

    local kept = savedTable("bookRecipes")
    local byId = bookCache[categoryKey]
    if byId and byId[id] then
        kept[key] = byId[id]
        ShroudSetSavedVar("bookRecipes", kept, "account")
        return byId[id], "book"
    end
    if kept[key] then return kept[key], "kept" end

    util.readBook(categoryKey)
    byId = bookCache[categoryKey]
    if byId and byId[id] then return byId[id], "book" end
    return nil
end

-- One recipe the character knows, however the game will give it. Returns the recipe and where it came from
-- ("game", "book" or "kept"), or nil.
function util.getRecipe(id, categoryKey)
    local r = ShroudGetRecipe(id)
    if r then return r, "game" end
    return util.fallbackRecipe(id, categoryKey)
end

-- Reads the books that the recipes noted in "needBook" need, starting no new read after `seconds`. Meant for
-- ShroudOnStart, which the game allows 5 seconds. Does nothing before a character is loaded (the book is nil).
function util.readNeededBooks(seconds)
    if not ShroudGetRecipeBook then return end
    util.clearRecipeCache()   -- a book that was too slow during play gets its chance here
    local cats, seen = {}, {}
    for _, cat in pairs(savedTable("needBook")) do
        if not seen[cat] then
            seen[cat] = true
            cats[#cats + 1] = cat
        end
    end
    table.sort(cats)
    local started = util.clock()
    for _, cat in ipairs(cats) do
        if util.clock() - started > seconds then break end
        util.readBook(cat)
    end
end

-- The items with this name from a list function such as ShroudGetInventoryItems. A name read from a
-- tooltip can differ from the list's: the list may add markers ("[u]Letter[/u]"), and a tooltip title
-- can end with the base item's name in brackets ("Boots +15 (Leather Boots +15)"). Several items can
-- share a name, so all matches are returned. A bracket can also be part of the name: "Focus Battery Necklace,
-- Common (L)" and "Focus Battery Necklace, Common" are two items. So the whole name is tried first, and without its
-- bracket only when nothing has the whole name and `exactOnly` is not set.
function util.itemsNamed(getList, name, exactOnly)
    local found, short = {}, {}
    local shortName = name:gsub("%s*%b()%s*$", "")
    for _, it in ipairs(getList() or {}) do
        local plain = it.name and it.name:gsub("%[/?%a+%]", "")
        if it.name == name or plain == name then
            found[#found + 1] = it
        elseif it.name == shortName or plain == shortName then
            short[#short + 1] = it
        end
    end
    if #found > 0 or exactOnly then return found end
    return short
end

-- Tooltip lines that name a kind of item ("Quest Item", "Dread Artifact", "Necklace", "Leather Light Armor
-- (Head)", "Longsword - Bladed", "Fishing Bait"...) all become "types": one item can have several (the Shroud
-- of the Avatar is an artifact, a cloak and a quest item). There is no list of kinds to match against, so a
-- type line is recognised by its shape: short, not the title, no colon, number, percent, plus, comma, full stop, ! or ?,
-- and not one of the lines that are known not to be types. It is a heuristic; the tooltip is kept in "text".
-- `index` is the line's place in the tooltip (1 is the title). Used by item_details.lua and gear_samples.lua.
local NOT_TYPES = {
    ["No Trade"] = true, ["No Value"] = true, ["Cannot be sold to merchants"] = true, ["Item Effects"] = true,
    ["Equipped"] = true, ["Salvage Components"] = true,
    ["Material Crafting Bonus"] = true,   -- a component's heading (was taken for a type before sl-admin 0.12.0)
}

function util.looksLikeType(line, index)
    if index == 1 or #line > 40 or NOT_TYPES[line] then return false end
    if line:match("[:%.%d%%%+,!%?\"]") then return false end
    if line:match("^Hold ") or line:match("^Double%-click") or line:match("^Salvage") or line:match("^Crafted by") then
        return false
    end
    return true
end

-- The weight or value of one item of a bag item (field "weight" or "value"), rounded to 4 decimals.
-- From API 41 the game gives one item's figures (and the stack's in totalWeight/totalValue), so they are used as
-- they are. Before API 41 the numbers were for the whole stack, although documented as "one item" (seen: Animal
-- Hide 31 at 12.4 where a recipe says 0.4 each), so they are divided by the stack size. Dividing on API 41 and
-- later was the bug in sl-admin 0.11.0 and earlier: one item's weight divided again, different for every stack size.
-- Before API 41, when the game reports no stack size (a missing or zero quantity: seen on three potion stacks,
-- whose weight and value were 319 potions' worth), the number can't be made per-item, so it is left out (nil,
-- null in the file) rather than passed on as if it were.
function util.perItem(it, field)
    local v = it[field]
    local q = it.quantity
    if type(v) ~= "number" then return nil end
    if (ShroudLuaApiVersion or 0) >= 41 then return math.floor(v * 10000 + 0.5) / 10000 end
    if type(q) ~= "number" or q < 1 then return nil end
    return math.floor(v / q * 10000 + 0.5) / 10000
end
