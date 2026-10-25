-- finds_ui.lua: the small "SotaLore Finds" window, meant to stay up during play.
--
-- Shows the current scene and how many distinct items, creatures and gathering nodes are on the find
-- list (the list itself lives in finds_data.lua), and has Save (writes the file, keeps the list),
-- Reset (empties the list, after a second click) and a Tracking toggle.
--
-- Used by: toolbar_ui.lua (the Finds button), main.lua (build, update, toggle, tick).

local UI = Shroud.UI
local util = SotaLoreAdmin.util
local Finds = SotaLoreAdmin.Finds

local M = {}
SotaLoreAdmin.FindsUI = M

local win, trackToggle, resetButton
local sceneLabel, itemsLabel, creaturesLabel, nodesLabel, scenesLabel
local resetArmedUntil = nil   -- ShroudTime until which a second Reset click confirms

function M.isBuilt()
    return win ~= nil
end

-- Refreshes the labels from the find list and the current scene.
function M.update()
    if not win then return end
    local c = Finds.counts()
    local scene = ShroudGetSceneInfo()
    local here = (scene and scene.loaded and scene.name ~= "") and scene.name or "(no scene)"
    sceneLabel:SetText(util.clip(here, 30))
    itemsLabel:SetText("Items: " .. c.items .. " distinct (" .. c.quantity .. " total)")
    creaturesLabel:SetText("Creatures: " .. c.creatures .. " fought, " .. c.seenOnly .. " only seen")
    nodesLabel:SetText("Nodes: " .. c.nodes .. " distinct (" .. c.harvests .. " harvests)")
    scenesLabel:SetText("Scenes in list: " .. c.scenes)
end

-- Reset needs a second click within a few seconds, so a stray click on a window left up
-- during play cannot throw the list away.
local function onResetClick()
    if resetArmedUntil and ShroudTime < resetArmedUntil then
        resetArmedUntil = nil
        resetButton:SetText("Reset")
        Finds.reset()
        ShroudConsoleLog("Find list reset.")
    else
        resetArmedUntil = ShroudTime + 4
        resetButton:SetText("Click again")
    end
end

-- Called every frame (from ShroudOnUpdate): un-arms Reset when the confirmation time has passed.
function M.tick()
    if resetArmedUntil and ShroudTime >= resetArmedUntil then
        resetArmedUntil = nil
        resetButton:SetText("Reset")
    end
end

function M.build()
    resetArmedUntil = nil
    Finds.onChange = M.update

    sceneLabel = UI.Label{ text = "", class = "heading" }
    itemsLabel = UI.Label{ text = "" }
    creaturesLabel = UI.Label{ text = "" }
    nodesLabel = UI.Label{ text = "" }
    scenesLabel = UI.Label{ text = "", class = "dim" }
    trackToggle = UI.Toggle{
        text = "Tracking",
        value = Finds.tracking,
        tooltip = "Turn off while banking or shopping: those gains look like loot",
        onChange = function(_, on) Finds.setTracking(on) end,
    }
    resetButton = UI.Button{ text = "Reset", tooltip = "Clear the find list (click twice)", onClick = onResetClick }
    win = UI.Window{
        id = "sotalorefinds",
        title = "SotaLore Finds",
        width = 230, height = 220,
        x = 20, y = 540,
        children = {
            sceneLabel,
            itemsLabel,
            creaturesLabel,
            nodesLabel,
            scenesLabel,
            trackToggle,
            UI.Row{ children = {
                UI.Button{
                    text = "Save",
                    tooltip = "Write " .. SotaLoreAdmin.files.finds .. " (keeps the list)",
                    onClick = Finds.export,
                },
                resetButton,
            } },
        },
    }
end

function M.toggle()
    if win:IsShown() then win:Hide() else win:Show() end
end
