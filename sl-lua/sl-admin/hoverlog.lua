-- hoverlog.lua: a diagnostic, switched on and off with /sladmin hoverlog. Not part of the exports.
--
-- While it is on, pointing the mouse at an item (in the bags, a chest, a vendor...) writes one line to
-- chat with what the game says about it: the tooltip's title and text, and, when the item is in the
-- bags, the fields ShroudGetInventoryItems has for it. The aim is to find out whether the tooltip text
-- says things the API does not offer as fields (quest item, tool, artifact, bound...).
--
-- The chat line is cut short, so the whole tooltip, line by line, also goes to a text file in the game's Lua
-- folder (SotaLoreAdmin.files.hoverLog). The game doesn't let an add-on add to the end of a file, so the log
-- keeps the text in memory and writes the whole file again for each tooltip. Switching the log on reads what
-- the file already holds and adds a heading below it, so nothing logged before is lost; delete the file by
-- hand to start afresh. A tooltip that
-- changes while pointed at (held Ctrl expands it) is written again, so the expanded text is there too.
--
-- Used by: main.lua (the command and the per-frame tick).

local util = SotaLoreAdmin.util

local M = {}
SotaLoreAdmin.HoverLog = M

local on = false
local lastShown = nil    -- name and tooltip text of the last thing logged, so one hover logs once
local MAX_TEXT = 700
local written = 0        -- tooltips written to the file since the log was switched on
local parts = {}         -- the file's text, in pieces: what it held before, then each heading and tooltip
local failed = false     -- the file could not be written (said once in chat)

-- Writes the whole file again.
local function writeAll()
    local path, err = util.writeFile(SotaLoreAdmin.files.hoverLog, table.concat(parts))
    if not path and not failed then
        failed = true
        ShroudConsoleLog("Hover log: can't write the file: " .. tostring(err))
    end
    return path
end

-- Turns the log on or off. Returns the new state.
function M.toggle()
    on = not on
    lastShown = nil
    if on then
        -- Never empties the file: a reload (or a scene change, which reloads add-ons) switches the log off without
        -- a word, so the next /sladmin hoverlog switches it on again, and emptying then lost what had been logged.
        written, failed = 0, false
        parts = { util.readFile(SotaLoreAdmin.files.hoverLog) or "" }
        local when = os.date and os.date("%Y-%m-%d %H:%M:%S") or ""
        parts[#parts + 1] = "########## hover log on " .. when .. "\n\n"
        writeAll()
    else
        ShroudConsoleLog("Hover log: " .. written .. " tooltips in " .. SotaLoreAdmin.files.hoverLog)
    end
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
    if name == "" then return end
    local desc = ShroudGetDescriptionUnderMouse()
    local signature = name .. "\n" .. desc
    if signature == lastShown then return end
    lastShown = signature

    local line = "hover: " .. name .. "\n  text: " .. oneLine(desc)
    local fields = ""
    -- Each item of that name in the bag list and in the worn-gear list. Durability (now/primary/max)
    -- tells which one the tooltip is about.
    for _, source in ipairs({
        { "bag", ShroudGetInventoryItems },
        { "worn", ShroudGetEquipmentItems },
    }) do
        local items = util.itemsNamed(source[2], name)
        for i, it in ipairs(items) do
            if i > 4 then
                fields = fields .. "\n  " .. source[1] .. ": ... " .. (#items - 4) .. " more with this name"
                break
            end
            fields = fields .. "\n  " .. source[1] .. ": key=" .. tostring(it.key) .. " weight=" .. tostring(it.weight)
                .. " value=" .. tostring(it.value)
                .. " durability=" .. tostring(it.durability) .. "/" .. tostring(it.primaryDurability) .. "/" .. tostring(it.maxDurability)
                .. " createdBy=" .. tostring(it.createdBy) .. " created=" .. tostring(it.creationDate)
                .. " scene=" .. tostring(it.creationScene) .. " length=" .. tostring(it.length)
                .. " quantity=" .. tostring(it.quantity) .. " name=" .. tostring(it.name)
        end
    end
    ShroudConsoleLog(line .. fields)

    parts[#parts + 1] = "===== " .. name .. fields .. "\n" .. desc .. "\n\n"
    if writeAll() then written = written + 1 end
end
