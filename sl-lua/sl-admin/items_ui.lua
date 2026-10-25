-- items_ui.lua: the small "SotaLore Items" window, built like the finds window.
--
-- Shows what the item catalog would be made from: the items in the bags, the items whose tooltip was captured
-- (item_details.lua) and the gear samples (gear_samples.lua), with how many of those are waiting for an export,
-- and how the current capture is going. Has the Capture switch (the same as /sladmin capture) and the two export
-- buttons, New items and All items (items.lua), which show the export's progress while it runs.
--
-- Used by: toolbar_ui.lua (the Items button), main.lua (build, update).

local UI = Shroud.UI
local Items = SotaLoreAdmin.Items
local ItemDetails = SotaLoreAdmin.ItemDetails
local GearSamples = SotaLoreAdmin.GearSamples

local M = {}
SotaLoreAdmin.ItemsUI = M

local win, captureToggle, newButton, allButton
local bagsLabel, detailsLabel, samplesLabel, sessionLabel

function M.isBuilt()
    return win ~= nil
end

-- Refreshes the labels. Only while the window is up: the counts walk every stored tooltip.
function M.update()
    if not win or not win:IsShown() then return end
    local inBags = 0
    for _, it in ipairs(ShroudGetInventoryItems() or {}) do
        if it.key then inBags = inBags + 1 end
    end
    local c = ItemDetails.counts()
    local samples, waiting = GearSamples.count()
    bagsLabel:SetText("Bags: " .. inBags .. " items")
    detailsLabel:SetText("Tooltips captured: " .. c.stored .. " items")
    samplesLabel:SetText("Gear samples: " .. samples .. " (" .. waiting .. " not exported)")
    if ItemDetails.isOn() then
        sessionLabel:SetText("This capture: " .. c.captured .. " items, " .. c.sampled .. " gear samples, "
            .. c.unmatched .. " skipped")
    else
        sessionLabel:SetText("Capture is off")
    end
end

function M.build()
    bagsLabel = UI.Label{ text = "", class = "heading" }
    detailsLabel = UI.Label{ text = "" }
    samplesLabel = UI.Label{ text = "" }
    sessionLabel = UI.Label{ text = "", class = "dim" }

    -- Item capture (item_details.lua): while on, pointing at an item saves its tooltip. The same switch as
    -- /sladmin capture, so the toggle follows the command.
    captureToggle = UI.Toggle{
        text = "Capture",
        value = ItemDetails.isOn(),
        tooltip = "Point at items in your bags, and at gear anywhere (hold Ctrl), to save what their tooltips say",
        onChange = function(_, on)
            if on ~= ItemDetails.isOn() then ItemDetails.toggle() end
        end,
    }
    ItemDetails.onToggle = function(on)
        captureToggle:SetValue(on)
        M.update()
    end
    ItemDetails.onChange = M.update

    newButton = UI.Button{ text = "New items", tooltip = "Write only items and gear samples not exported before, or changed since",
        onClick = function() Items.start("new") end }
    allButton = UI.Button{ text = "All items", tooltip = "Write every item in your bags, every captured item and every gear sample",
        onClick = function() Items.start("all") end }
    -- While an export runs, show its progress on both buttons.
    Items.onProgress = function(text)
        newButton:SetText(text or "New items")
        allButton:SetText(text or "All items")
    end
    Items.onDone = M.update

    win = UI.Window{
        id = "sotaloreitems",
        title = "SotaLore Items",
        width = 260, height = 220,
        x = 260, y = 540,
        children = {
            bagsLabel,
            detailsLabel,
            samplesLabel,
            sessionLabel,
            captureToggle,
            UI.Row{ children = { newButton, allButton } },
        },
    }
end

function M.toggle()
    if win:IsShown() then
        win:Hide()
    else
        win:Show()
        M.update()
    end
end
