-- items.lua: the item catalog.
--
-- Bag items carry the same item key as recipes (API 37). Each export adds what the character holds
-- to an account-wide catalog (saved variable "items") and rewrites the whole file
-- Lua/sotalore-items.json, so it grows over time. Kept per item: key, name, weight, value, createdBy
-- (the API's field of that name; in play it is empty even for crafted items, so it can't be used to spot
-- them) and "details": what the item's tooltip said when it was captured (see item_details.lua), or null.
-- The API gives no "locked", "quest item" or item-type flag; the details are the only source for those.
--
-- Used by: recipes_ui.lua (the "Export my items" button), main.lua (/slore items).

local util = SotaLore.util
local jstr, jnum = util.jstr, util.jnum
local ItemDetails = SotaLore.ItemDetails

local M = {}
SotaLore.Items = M

local function jitem(key, name, weight, value, createdBy)
    return '{"key":' .. jstr(key) .. ',"name":' .. jstr(name)
        .. ',"weight":' .. jnum(weight) .. ',"value":' .. jnum(value)
        .. ',"createdBy":' .. jstr(createdBy or "")
        .. ',"details":' .. ItemDetails.toJson(key) .. '}'
end

function M.export()
    local bags = ShroudGetInventoryItems()
    if not bags then
        ShroudConsoleLog("Items are not loaded yet.")
        return
    end

    -- Entries are keyed by the item key, plus the crafter for a crafted item, so crafted items of
    -- one kind stay apart from each other and from the plain item.
    local catalog = ShroudGetSavedVar("items", "account")
    if type(catalog) ~= "table" then catalog = {} end

    local added, skipped = 0, 0
    for _, it in ipairs(bags) do
        if it.key then
            local maker = it.createdBy or ""
            local id = (maker == "") and it.key or (it.key .. "|" .. maker)
            if not catalog[id] then added = added + 1 end
            catalog[id] = {
                key = it.key,
                name = it.name,
                weight = util.perItem(it, "weight"),
                value = util.perItem(it, "value"),
                createdBy = maker,
            }
        else
            skipped = skipped + 1
        end
    end
    ShroudSetSavedVar("items", catalog, "account")

    local ids = {}
    for id in pairs(catalog) do ids[#ids + 1] = id end
    table.sort(ids)
    local parts = {}
    local listed = {}   -- item keys that have an entry
    for _, id in ipairs(ids) do
        local it = catalog[id]
        local key = it.key or id
        listed[key] = true
        parts[#parts + 1] = jitem(key, it.name, it.weight, it.value, it.createdBy)
    end

    -- Items whose tooltip was captured but that are no longer in the catalog's bags.
    local extra = {}
    for key in pairs(ItemDetails.all()) do
        if not listed[key] then extra[#extra + 1] = key end
    end
    table.sort(extra)
    for _, key in ipairs(extra) do
        parts[#parts + 1] = jitem(key, ItemDetails.all()[key].name or key, nil, nil, "")
    end

    local body = '{"apiVersion":' .. tostring(ShroudLuaApiVersion)
        .. ',"count":' .. #parts .. ',"items":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'

    local path, err = util.writeFile(SotaLore.files.items, body)
    if not path then
        ShroudConsoleLog("Item export failed: " .. tostring(err))
        return
    end
    ShroudConsoleLog("Items: " .. added .. " new, " .. #parts .. " total in " .. path
        .. (skipped > 0 and (" (" .. skipped .. " without a key skipped)") or "")
        .. " (type /lua path to open the folder)")
end
