-- game_skills.lua: every skill in the game, written to Lua/sotalore-game-skills.json with /sladmin gameskills.
--
-- Not for upload: the file is copied into the repo and the app's code is built from it. ShroudGetAllSkills (API 55)
-- is fixed game data, trained or not, the same for every character. It gives no experience costs, only each
-- skill's multiplier of the standard cost. The icons are left out: they are texture ids, which mean nothing outside
-- the game.
--
-- Used by: main.lua (the command).

local util = SotaLoreAdmin.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLoreAdmin.GameSkills = M

local function jskill(s)
    return '{"id":' .. jnum(s.id) .. ',"key":' .. jstr(s.key) .. ',"name":' .. jstr(s.name)
        .. ',"schoolKey":' .. jstr(s.schoolKey) .. ',"school":' .. jstr(s.school)
        .. ',"subcategory":' .. jstr(s.subcategory) .. ',"xpMultiplier":' .. jnum(s.xpMultiplier) .. '}'
end

-- Writes the file, and says in chat what happened.
function M.export()
    if not ShroudGetAllSkills then
        ShroudConsoleLog("Listing every skill needs Lua API 55, this client has " .. tostring(ShroudLuaApiVersion) .. ".")
        return
    end
    local started = util.clock()
    local skills = ShroudGetAllSkills()
    util.slow("reading every skill", started)
    if not skills then
        ShroudConsoleLog("The game is still loading its skills. Try again in a moment.")
        return
    end

    local parts = {}
    for _, s in ipairs(skills) do parts[#parts + 1] = jskill(s) end
    local body = util.header("gameSkills")
        .. ',"count":' .. #parts .. ',"skills":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'
    local path, err = util.writeFile(SotaLoreAdmin.files.gameSkills, body)
    if not path then
        ShroudConsoleLog("Skill export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Saved " .. #parts .. " skills to " .. path .. " (type /lua path to open the folder)")
end
