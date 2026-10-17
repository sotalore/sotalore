-- items.lua: the item catalog.
--
-- Bag items carry the same item key as recipes (API 37). Each export adds what the character holds
-- to an account-wide catalog (saved variable "items") and rewrites the whole file
-- Lua/sl-recipes-items.json, so it grows over time. Only fields of the item kind are kept (key,
-- name, weight, value): no durability, crafter and so on. The API gives no "locked" flag, so locked
-- items can't be left out.
--
-- Used by: recipes_ui.lua (the "Export my items" button), main.lua (/slore items).

local util = SotaLore.util
local jstr, jnum = util.jstr, util.jnum

local M = {}
SotaLore.Items = M

function M.export()
    local bags = ShroudGetInventoryItems()
    if not bags then
        ShroudConsoleLog("Items are not loaded yet.")
        return
    end

    local catalog = ShroudGetSavedVar("items", "account")
    if type(catalog) ~= "table" then catalog = {} end

    local added, skipped = 0, 0
    for _, it in ipairs(bags) do
        if it.key then
            if not catalog[it.key] then added = added + 1 end
            catalog[it.key] = {
                name = it.name,
                weight = util.perItem(it, "weight"),
                value = util.perItem(it, "value"),
            }
        else
            skipped = skipped + 1
        end
    end
    ShroudSetSavedVar("items", catalog, "account")

    local keys = {}
    for k in pairs(catalog) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        local it = catalog[k]
        parts[#parts + 1] = '{"key":' .. jstr(k) .. ',"name":' .. jstr(it.name)
            .. ',"weight":' .. jnum(it.weight) .. ',"value":' .. jnum(it.value) .. '}'
    end
    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"count":' .. #keys .. ',"items":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'

    local path, err = util.writeFile(SotaLore.files.items, body)
    if not path then
        ShroudConsoleLog("Item export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Items: " .. added .. " new, " .. #keys .. " total in " .. path
        .. (skipped > 0 and (" (" .. skipped .. " without a key skipped)") or "")
        .. " (type /lua path to open the folder)")
end
