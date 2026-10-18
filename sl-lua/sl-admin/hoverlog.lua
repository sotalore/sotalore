-- hoverlog.lua: a diagnostic, switched on and off with /sladmin hoverlog. Not part of the exports.
--
-- While it is on, pointing the mouse at an item (in the bags, a chest, a vendor...) writes one line to
-- chat with what the game says about it: the tooltip's title and text, and, when the item is in the
-- bags, the fields ShroudGetInventoryItems has for it. The aim is to find out whether the tooltip text
-- says things the API does not offer as fields (quest item, tool, artifact, bound...).
--
-- Used by: main.lua (the command and the per-frame tick).

local util = SotaLoreAdmin.util

local M = {}
SotaLoreAdmin.HoverLog = M

local on = false
local lastShown = nil    -- "kind|name" of the last thing logged, so one hover logs one line
local MAX_TEXT = 700

-- Turns the log on or off. Returns the new state.
function M.toggle()
    on = not on
    lastShown = nil
    return on
end

local function oneLine(text)
    text = tostring(text or ""):gsub("%s*[\r\n]+%s*", " | ")
    if #text > MAX_TEXT then text = text:sub(1, MAX_TEXT) .. "..." end
    return text
end

-- Called every frame (from ShroudOnUpdate).
function M.tick()
    if not on then return end
    if ShroudGetKindUnderMouse() ~= "item" then
        lastShown = nil
        return
    end
    local name = ShroudGetNameUnderMouse()
    if name == "" or name == lastShown then return end
    lastShown = name

    local line = "hover: " .. name .. "\n  text: " .. oneLine(ShroudGetDescriptionUnderMouse())
    -- Each item of that name in the bag list and in the worn-gear list. Durability (now/primary/max)
    -- tells which one the tooltip is about.
    for _, source in ipairs({
        { "bag", ShroudGetInventoryItems },
        { "worn", ShroudGetEquipmentItems },
    }) do
        local items = util.itemsNamed(source[2], name)
        for i, it in ipairs(items) do
            if i > 4 then
                line = line .. "\n  " .. source[1] .. ": ... " .. (#items - 4) .. " more with this name"
                break
            end
            line = line .. "\n  " .. source[1] .. ": key=" .. tostring(it.key) .. " weight=" .. tostring(it.weight)
                .. " value=" .. tostring(it.value)
                .. " durability=" .. tostring(it.durability) .. "/" .. tostring(it.primaryDurability) .. "/" .. tostring(it.maxDurability)
                .. " createdBy=" .. tostring(it.createdBy) .. " created=" .. tostring(it.creationDate)
                .. " scene=" .. tostring(it.creationScene) .. " length=" .. tostring(it.length)
                .. " quantity=" .. tostring(it.quantity) .. " name=" .. tostring(it.name)
        end
    end
    ShroudConsoleLog(line)
end
