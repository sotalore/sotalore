-- toolbar_ui.lua: the "SotaLore Admin" toolbar, the window /sladmin and the key binding open.
--
-- Three buttons, each opening or closing one of the add-on's windows: Finds (finds_ui.lua, what a scene holds),
-- Items (items_ui.lua, the item catalog and capture) and Recipes (recipes_ui.lua, the recipe list and its exports).
--
-- An add-on may own 8 windows: this toolbar, the finds, items and recipe list windows, and up to 4 recipe windows.
--
-- Used by: main.lua (build, toggle).

local UI = Shroud.UI
local FindsUI = SotaLoreAdmin.FindsUI
local ItemsUI = SotaLoreAdmin.ItemsUI
local RecipesUI = SotaLoreAdmin.RecipesUI

local M = {}
SotaLoreAdmin.ToolbarUI = M

local win

function M.isBuilt()
    return win ~= nil
end

function M.build()
    win = UI.Window{
        id = "sotaloretoolbar",
        title = "SotaLore Admin",
        width = 260, height = 80,
        x = 20, y = 20,
        escCloses = true,
        children = {
            UI.Row{ children = {
                UI.Button{ text = "Finds", tooltip = "What you find in this scene: items, creatures, gathering nodes",
                    style = { flexGrow = 1 }, onClick = FindsUI.toggle },
                UI.Button{ text = "Items", tooltip = "The item catalog: capture tooltips and gear, export items",
                    style = { flexGrow = 1 }, onClick = ItemsUI.toggle },
                UI.Button{ text = "Recipes", tooltip = "Your known recipes: search them, export them",
                    style = { flexGrow = 1 }, onClick = RecipesUI.toggle },
            } },
        },
    }
end

function M.toggle()
    if win:IsShown() then win:Hide() else win:Show() end
end
