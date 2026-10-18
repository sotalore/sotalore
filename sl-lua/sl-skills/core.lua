-- core.lua: loaded first. Creates this plugin's one global table, SotaLoreSkills, and the few helpers the other
-- files use.
--
-- This is SotaLore Skills (folder and slug sl-skills), the plugin for players: it lets them copy their trained
-- skills into the SotaLore site's skill planner. The site's admin tools are a separate plugin, sl-admin, with
-- its own global table (SotaLoreAdmin). All add-ons share one global environment, so the two must never use the same
-- global name, and this plugin must not rely on anything from the other: most players will not have it.
--
-- The files run in the order the manifest lists them and share one environment; everything else is local, and
-- files reach each other only through SotaLoreSkills. The game's Shroud... functions don't exist while a file
-- loads, so files only define things at load time. main.lua is last and holds the ShroudOn... callbacks.

local ScriptName = "SotaLore Skills"
local Version = "0.2.0"
local CreatorName = "Gravidy"
local Description = "Copy your skill levels to the SotaLore website (www.sotalore.com) to plan them there. Open it with /slskills."

SotaLoreSkills = {}
SotaLoreSkills.version = Version

-- Names of the files the plugin writes into the game's Lua folder.
SotaLoreSkills.files = {
    skills = "sotalore-skills.json",
}

local util = {}
SotaLoreSkills.util = util

-- JSON writing, by hand: Lua values to JSON text.
local ESCAPES = { ['"'] = '\\"', ['\\'] = '\\\\', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }

function util.jstr(s)
    local escaped = tostring(s):gsub('[%c"\\]', function(c)
        return ESCAPES[c] or string.format("\\u%04x", c:byte())
    end)
    return '"' .. escaped .. '"'
end

-- A number, or null for a missing or non-finite value.
function util.jnum(v)
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return "null" end
    return tostring(v)
end

-- The opening of every file the plugin writes, without the closing brace: the game's API version, which plugin
-- and version wrote it, and what kind of file it is.
function util.header(kind)
    return '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"plugin":"sl-skills"'
        .. ',"pluginVersion":' .. util.jstr(Version)
        .. ',"type":' .. util.jstr(kind)
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
