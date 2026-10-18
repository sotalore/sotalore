-- main.lua: loaded last. The only file with the game's ShroudOn... callbacks; each hands over to another file.
--
--   core.lua       the SotaLoreSkills table and its few helpers (JSON, files)
--   skills.lua     the trained skills, the skills file and the code to paste into the site
--   skills_ui.lua  the "SotaLore Skills" window
--
-- The files run in the order the manifest lists them.

local Skills = SotaLoreSkills.Skills
local SkillsUI = SotaLoreSkills.SkillsUI

-- The /slskills command: "file" saves the skills file, anything else opens or closes the window. The key
-- binding does the same as the bare command.
local function handleCommand(args)
    if args == "file" then
        Skills.export()
    else
        SkillsUI.toggle()
    end
end

-- Runs once when the plugin loads: builds the window and registers the command and key binding.
function ShroudOnStart()
    SkillsUI.build()

    local ok, reason = Shroud.Command{
        name = "slskills",
        help = "Open SotaLore Skills: your trained skills as a code to paste into the site. /slskills file saves them.",
        run = handleCommand,
    }
    if not ok then
        ShroudConsoleLog("/slskills unavailable (" .. tostring(reason) .. ")")
    end

    Shroud.Keybind{ id = "toggle", label = "SotaLore Skills: toggle window", onPress = function() handleCommand("") end }
end

-- A skill level changed (levelsChanged is false when only experience moved): keep an open window up to date.
function ShroudOnSkillsChanged(levelsChanged)
    if levelsChanged then SkillsUI.refreshIfShown() end
end
