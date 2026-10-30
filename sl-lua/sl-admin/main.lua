-- main.lua: loaded last. The only file with the game's ShroudOn... callbacks, so read this first
-- to see what the plugin does and when. Each callback just hands over to the file that knows how.
--
--   core.lua            the SotaLoreAdmin table and shared helpers (JSON, files, text)
--   recipes_export.lua  known recipes -> JSON files for the site
--   items.lua           bag items -> item catalog file
--   finds_data.lua      the per-scene find list: items, creatures, gathering nodes
--   finds_ui.lua        the small finds window
--   items_ui.lua        the small items window: capture and the item exports
--   recipes_ui.lua      the recipe browser windows
--   toolbar_ui.lua      the toolbar that opens the three windows above
--   item_details.lua    what item tooltips say (quest item, tool, salvage...), captured by hovering (/sladmin capture)
--   gear_samples.lua    what expanded gear tooltips say it is made of (components, enchantments, masterworks, sockets)
--   hoverlog.lua        a diagnostic: writes an item's tooltip text to chat (/sladmin hoverlog)
--   targetlog.lua       a diagnostic: writes what the game says about each new target to chat (/sladmin targetlog)
--   game_skills.lua     every skill in the game -> a file for the repo (/sladmin gameskills)
--
-- The files run in the order the manifest lists them.

local RecipeExport = SotaLoreAdmin.RecipeExport
local Items = SotaLoreAdmin.Items
local Finds = SotaLoreAdmin.Finds
local FindsUI = SotaLoreAdmin.FindsUI
local RecipesUI = SotaLoreAdmin.RecipesUI
local ItemsUI = SotaLoreAdmin.ItemsUI
local ToolbarUI = SotaLoreAdmin.ToolbarUI
local HoverLog = SotaLoreAdmin.HoverLog
local TargetLog = SotaLoreAdmin.TargetLog
local ItemDetails = SotaLoreAdmin.ItemDetails
local GearSamples = SotaLoreAdmin.GearSamples
local GameSkills = SotaLoreAdmin.GameSkills

-- The /sladmin command: a word picks an action, any other text searches the recipes, and nothing at
-- all opens or closes the toolbar. The key binding does the same as the bare command.
local function handleCommand(args)
    if args == "recipes" then
        RecipesUI.toggle()
    elseif args == "export" then
        RecipeExport.start("new")
    elseif args == "exportall" then
        RecipeExport.start("all")
    elseif args == "baseline" then
        RecipeExport.start("baseline")
    elseif args == "new" then
        RecipesUI.showNew()
    elseif args == "capture" then
        ItemDetails.toggle()
    elseif args == "hoverlog" then
        ShroudConsoleLog("Hover log " .. (HoverLog.toggle() and "on: point at items" or "off"))
    elseif args == "targetlog" then
        ShroudConsoleLog("Target log " .. (TargetLog.toggle() and "on: each new target is written to chat once per scene visit" or "off"))
    elseif args == "checkrecipes" then
        RecipeExport.check()
    elseif args == "items" then
        Items.start("new")
    elseif args == "itemsall" then
        Items.start("all")
    elseif args == "baselineitems" then
        Items.start("baseline")
    elseif args == "finds" then
        FindsUI.toggle()
    elseif args == "savefinds" then
        Finds.export()
    elseif args == "clearfinds" then
        Finds.reset()
        ShroudConsoleLog("Cleared all recorded finds.")
    elseif args == "gameskills" then
        GameSkills.export()
    elseif args == "gatherlog" then
        ShroudConsoleLog("Gather log " .. (Finds.toggleGatherLog() and "on" or "off"))
    elseif args and args ~= "" then
        RecipesUI.showSearch(args)
    else
        ToolbarUI.toggle()
    end
end

-- Runs once when the plugin loads: builds the windows and registers the command and key binding.
function ShroudOnStart()
    RecipeExport.reset()
    Items.reset()
    Finds.load()
    RecipesUI.build()
    FindsUI.build()
    ItemsUI.build()
    ToolbarUI.build()
    RecipesUI.load()
    FindsUI.update()

    -- Every SotaLore plugin's command is /sl<name> for the package sl-<name> (/sotalore itself is refused:
    -- "sota" is a reserved prefix).
    local ok, reason = Shroud.Command{
        name = "sladmin",
        help = "Open the SotaLore Admin toolbar. /sladmin <text> searches recipes. Also: recipes finds new items capture gameskills",
        run = handleCommand,
    }
    if not ok then
        ShroudConsoleLog("/sladmin unavailable (" .. tostring(reason) .. ")")
    end

    Shroud.Keybind{ id = "toggle", label = "SotaLore Admin: toggle toolbar", onPress = function() handleCommand("") end }

    -- Last, so everything above is set up even if this is slow: read the recipe books that some recipes need
    -- (too slow for a normal callback; the game allows the start 5 seconds) and keep copies for the exports.
    SotaLoreAdmin.util.readNeededBooks(2.0)
end

-- Every frame.
function ShroudOnUpdate()
    RecipeExport.step()
    Items.step()
    HoverLog.tick()
    ItemDetails.tick()
    GearSamples.save(false)
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
    TargetLog.newVisit()
    FindsUI.update()
end

-- The player's target changed (id -1 when it cleared): a creature seen, for the find list, and a line for the
-- target log while it is on.
function ShroudOnTargetChanged(id, name)
    if Finds.tracking and FindsUI.isBuilt() then Finds.recordTarget(id, name) end
    TargetLog.onChange(id, name)
end

-- The find list is saved to the saved variables on these.
function ShroudOnLogOut()
    ItemDetails.save(true)
    GearSamples.save(true)
    Finds.save(true)
end

function ShroudOnDisableScript()
    ItemDetails.save(true)
    GearSamples.save(true)
    Finds.save(true)
end

-- The character's recipes or bags changed. These can fire before ShroudOnStart has built the windows.
function ShroudOnRecipesChanged()
    SotaLoreAdmin.util.clearRecipeCache()
    if not RecipesUI.isBuilt() then return end
    RecipesUI.load()
    RecipesUI.refreshDetails()
end

function ShroudOnInventoryChanged()
    if ItemsUI.isBuilt() then ItemsUI.update() end
    if not RecipesUI.isBuilt() then return end
    RecipesUI.refreshDetails()
end
