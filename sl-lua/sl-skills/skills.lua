-- skills.lua: the character's trained skills, for the site's skill planner.
--
-- The site keeps, for every avatar, each skill's current level and a target level. The target lives only on
-- the site; the current level comes from the game: ShroudGetSkills() lists the skills the character has
-- trained (an untrained skill is not listed, so the site reads it as level 0).
--
-- Two ways out:
--   * a FILE (sotalore-skills.json): every field the site might need (id, key, name, school, subcategory,
--     levels, experience...). Meant for loading the skill catalog into the site once, and for checking sizes.
--   * a CODE the player copies from a text box and pastes into the site, with no file to find and upload.
--     A text box holds at most 1024 characters and Lua cannot reach the clipboard, so the code is cut into
--     pages of up to PAGE_CHARS characters; the player copies each page in turn. It carries only the skill id and
--     the level, packed in base 36 to keep it short, so one page holds a hundred or more skills.
--
-- The level sent is trainedLevel (the level the experience has bought), not `level`, which a scene's skill
-- cap can lower.
--
-- Used by: skills_ui.lua (the window), main.lua (the /slskills file command).

local util = SotaLoreSkills.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLoreSkills.Skills = M

local PAGE_CHARS = 1000      -- characters per page of the code; a text box holds 1024
local CODE_TAG = "SLS1"      -- starts every page: SotaLore Skills, format 1
local ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz"
local OFFSET = 2147483648    -- added to every id when any id is negative, so all are positive

-- Base 36 with a fixed number of digits (lower case).
local function base36(n, width)
    n = math.floor(n)
    local s = ""
    repeat
        local d = n % 36
        s = ALPHABET:sub(d + 1, d + 1) .. s
        n = math.floor(n / 36)
    until n == 0
    while #s < width do s = "0" .. s end
    return s
end

-- How many base 36 digits a number needs.
local function digits(n)
    return #base36(n, 1)
end

-- Reading ----------------------------------------------------------------------------------

-- The trained skills sorted by id, and the numbers worth knowing about them. nil before a character exists.
function M.read()
    local list = ShroudGetSkills()
    if not list then return nil end

    local skills = {}
    for _, s in ipairs(list) do skills[#skills + 1] = s end
    table.sort(skills, function(a, b) return a.id < b.id end)

    local info = {
        character = ShroudGetPlayerName() or "",
        skills = skills,
        count = #skills,
        minId = skills[1] and skills[1].id or 0,
        maxId = skills[#skills] and skills[#skills].id or 0,
        maxLevel = 0,
    }
    for _, s in ipairs(skills) do
        if (s.trainedLevel or 0) > info.maxLevel then info.maxLevel = s.trainedLevel end
    end
    return info
end

-- The code ---------------------------------------------------------------------------------

-- The code for these skills: a list of pages (strings of at most PAGE_CHARS characters each). Each page reads
--   SLS1|<page>/<pages>|<id digits>|<offset>|<character>|<entries>|<check>
-- where an entry is a skill id then its level, both base 36 with fixed widths (id digits, 2), and the check is
-- two base 36 digits made from the entries of that page, so a page that was cut short or mis-pasted is noticed.
function M.pages(info)
    local offset = (info.minId < 0) and OFFSET or 0
    local idWidth = math.max(3, digits(info.maxId + offset))
    local width = idWidth + 2

    local name = info.character:gsub("[|%c]", "")
    local overhead = #CODE_TAG + 1 + #"99/99" + 1 + #tostring(idWidth) + 1 + 1 + 1 + #name + 1 + 1 + 2
    local perPage = math.max(1, math.floor((PAGE_CHARS - overhead) / width))

    local chunks = {}
    for i = 1, info.count, perPage do
        local parts = {}
        for j = i, math.min(i + perPage - 1, info.count) do
            local s = info.skills[j]
            parts[#parts + 1] = base36(s.id + offset, idWidth) .. base36(math.min(s.trainedLevel or 0, 1295), 2)
        end
        chunks[#chunks + 1] = table.concat(parts)
    end
    if #chunks == 0 then chunks[1] = "" end

    local pages = {}
    for p, entries in ipairs(chunks) do
        local sum = 0
        for k = 1, #entries do sum = (sum * 31 + entries:byte(k)) % 1296 end
        pages[p] = table.concat({ CODE_TAG, p .. "/" .. #chunks, tostring(idWidth), (offset ~= 0) and "o" or "-",
            name, entries, base36(sum, 2) }, "|")
    end
    return pages
end

-- The file ---------------------------------------------------------------------------------

local function jskill(s)
    return '{"id":' .. jnum(s.id) .. ',"key":' .. jstr(s.key) .. ',"name":' .. jstr(s.name)
        .. ',"school":' .. jstr(s.school) .. ',"schoolKey":' .. jstr(s.schoolKey)
        .. ',"subcategory":' .. jstr(s.subcategory or "")
        .. ',"trainedLevel":' .. jnum(s.trainedLevel) .. ',"level":' .. jnum(s.level)
        .. ',"effectiveLevel":' .. jnum(s.effectiveLevel)
        .. ',"experience":' .. jnum(s.experience) .. ',"grandmaster":' .. tostring(s.grandmaster and true or false)
        .. ',"mode":' .. jstr(s.mode or "") .. '}'
end

-- Writes Lua/sotalore-skills.json and says in chat how big everything is. Returns the info table, or nil.
function M.export()
    local info = M.read()
    if not info then
        ShroudConsoleLog("SotaLore Skills: your skills aren't loaded yet.")
        return nil
    end
    local parts = {}
    for _, s in ipairs(info.skills) do parts[#parts + 1] = jskill(s) end
    local body = util.header("skills")
        .. ',"character":' .. jstr(info.character)
        .. ',"count":' .. info.count .. ',"skills":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'

    local path, err = util.writeFile(SotaLoreSkills.files.skills, body)
    if not path then
        ShroudConsoleLog("SotaLore Skills: could not save the file: " .. tostring(err))
        return info
    end

    ShroudConsoleLog(string.format("SotaLore Skills: saved %d skills to %s", info.count, path))
    return info
end
