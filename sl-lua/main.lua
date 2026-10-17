-- main.lua: loaded last. The only file with the game's ShroudOn... callbacks, so read this first
-- to see what the plugin does and when. Each callback just hands over to the file that knows how.
--
--   core.lua            the SotaLore table and shared helpers (JSON, files, text)
--   recipes_export.lua  known recipes -> JSON files for the site
--   items.lua           bag items -> item catalog file
--   finds_data.lua      the per-scene find list: items, creatures, gathering nodes
--   finds_ui.lua        the small finds window
--   recipes_ui.lua      the recipe browser windows
--
-- The files run in the order the manifest lists them.

local RecipeExport = SotaLore.RecipeExport
local Items = SotaLore.Items
local Finds = SotaLore.Finds
local FindsUI = SotaLore.FindsUI
local RecipesUI = SotaLore.RecipesUI

-- The /slore command: a word picks an action, any other text searches the recipes, and nothing at
-- all opens or closes the recipe window. The key binding does the same as the bare command.
local function handleCommand(args)
    if args == "export" then
        RecipeExport.start("new")
    elseif args == "exportall" then
        RecipeExport.start("all")
    elseif args == "baseline" then
        RecipeExport.start("baseline")
    elseif args == "items" then
        Items.export()
    elseif args == "finds" then
        FindsUI.toggle()
    elseif args == "savefinds" then
        Finds.export()
    elseif args == "clearfinds" then
        Finds.reset()
        ShroudConsoleLog("Cleared all recorded finds.")
    elseif args == "gatherlog" then
        ShroudConsoleLog("Gather log " .. (Finds.toggleGatherLog() and "on" or "off"))
    elseif args and args ~= "" then
        RecipesUI.showSearch(args)
    else
        RecipesUI.toggle()
    end
end

-- Runs once when the plugin loads: builds the windows and registers the command and key binding.
function ShroudOnStart()
    RecipeExport.reset()
    Finds.load()
    RecipesUI.build()
    FindsUI.build()
    RecipesUI.load()
    FindsUI.update()

    -- /sotalore is refused ("sota" is a reserved prefix), so the command is /slore.
    local ok, reason = Shroud.Command{
        name = "slore",
        help = "Open SotaLore. /slore <text> searches; export, exportall, items, finds (window), savefinds, clearfinds, gatherlog.",
        run = handleCommand,
    }
    if not ok then
        ShroudConsoleLog("/slore unavailable (" .. tostring(reason) .. ")")
    end

    Shroud.Keybind{ id = "toggle", label = "SotaLore: toggle list", onPress = function() handleCommand("") end }
end

-- Every frame.
function ShroudOnUpdate()
    RecipeExport.step()
    FindsUI.tick()
    Finds.save(false)
end

-- Things that happen in the world, recorded on the find list while tracking is on.
function ShroudOnItemsGained(items)
    if Finds.tracking and FindsUI.isBuilt() then Finds.recordItems(items) end
end

function ShroudOnGatherResults(results)
    if Finds.tracking and FindsUI.isBuilt() then Finds.recordGathers(results) end
end

function ShroudOnCombatEvents(events)
    if Finds.tracking and FindsUI.isBuilt() then Finds.recordCreatures(events) end
end

function ShroudOnSceneLoaded()
    Finds.newVisit()
    FindsUI.update()
end

-- The find list is saved to the saved variables on these.
function ShroudOnLogOut()
    Finds.save(true)
end

function ShroudOnDisableScript()
    Finds.save(true)
end

-- The character's recipes or bags changed. These can fire before ShroudOnStart has built the windows.
function ShroudOnRecipesChanged()
    if not RecipesUI.isBuilt() then return end
    RecipesUI.load()
    RecipesUI.refreshDetails()
end

function ShroudOnInventoryChanged()
    if not RecipesUI.isBuilt() then return end
    RecipesUI.refreshDetails()
end
