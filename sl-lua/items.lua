-- items.lua: the items file, for the items in the character's bags.
--
-- Bag items carry the same item key as recipes (API 37). The bags are full of things that never leave (gear,
-- quest items, tools), so most exports would repeat them. Like the recipe export, this one can send only what
-- is new or changed:
--   "new"      items not exported before, or changed since (the weight or value, or newly captured details)
--   "all"      every item
--   "baseline" marks everything in the bags as already exported, without writing a file
-- What was last exported is remembered per item as a short fingerprint, in the account saved variable
-- "itemSigs" (no catalog of items is kept between exports, so it stays small however many items turn up).
--
-- Kept per item: key, name, weight, value, createdBy (the API's field of that name; in play it is empty even
-- for crafted items, so it can't be used to spot them) and "details": what the item's tooltip said when it
-- was captured (see item_details.lua), or null. The API gives no "locked", "quest item" or item-type flag;
-- the details are the only source for those.
--
-- The work is cut into slices of a fraction of a second per frame (like the recipe export), because the game
-- stops a callback that runs over a second, and a character can carry thousands of items.
--
-- Used by: recipes_ui.lua (the item buttons), main.lua (the /slore commands and the per-frame step).

local util = SotaLore.util
local jstr, jnum = util.jstr, util.jnum
local ItemDetails = SotaLore.ItemDetails

local M = {}
SotaLore.Items = M

local MAX_PER_SLICE = 400   -- most items handled in one frame; a slice also stops after util.sliceLimit seconds
local state = nil           -- the export in progress, or nil

-- The UI sets this to hear about progress: fn(text) while running, fn(nil) when it is over.
M.onProgress = nil

local function progress(text)
    if M.onProgress then M.onProgress(text) end
end

local function jitem(e)
    return '{"key":' .. jstr(e.key) .. ',"name":' .. jstr(e.name)
        .. ',"weight":' .. jnum(e.weight) .. ',"value":' .. jnum(e.value)
        .. ',"createdBy":' .. jstr(e.createdBy or "")
        .. ',"details":' .. ItemDetails.toJson(e.key) .. '}'
end

-- A short text that changes when anything about the item that the file carries changes.
local function fingerprint(e)
    return table.concat({ tostring(e.name), tostring(e.weight), tostring(e.value), tostring(e.createdBy or ""),
        tostring(ItemDetails.revOf(e.key)) }, "|")
end

local function loadSigs()
    local t = ShroudGetSavedVar("itemSigs", "account")
    if type(t) ~= "table" then t = {} end
    return t
end

-- Starting ---------------------------------------------------------------------------------

-- mode "new", "all" or "baseline" (see the top of this file).
function M.start(mode)
    if state then return end
    local bags = ShroudGetInventoryItems()
    if not bags then
        ShroudConsoleLog("Items are not loaded yet.")
        return
    end

    -- One entry per kind of item (and per crafter, for a crafted one), in a steady order.
    local entries, order, skipped = {}, {}, 0
    local keys = {}
    for _, it in ipairs(bags) do
        if it.key then
            local maker = it.createdBy or ""
            local id = (maker == "") and it.key or (it.key .. "|" .. maker)
            if not entries[id] then
                entries[id] = {
                    key = it.key,
                    name = it.name,
                    weight = util.perItem(it, "weight"),
                    value = util.perItem(it, "value"),
                    createdBy = maker,
                }
                order[#order + 1] = id
                keys[it.key] = true
            end
        else
            skipped = skipped + 1
        end
    end
    -- Items whose tooltip was captured but that are no longer in the bags.
    for key, d in pairs(ItemDetails.all()) do
        if not keys[key] and not entries[key] then
            entries[key] = { key = key, name = d.name or key, createdBy = "" }
            order[#order + 1] = key
        end
    end
    table.sort(order)

    -- Memory of the old whole-catalog design, no longer used.
    ShroudDeleteSavedVar("items", "account")

    state = { mode = mode, entries = entries, order = order, i = 1, sigs = loadSigs(), out = {}, newSigs = {},
        skipped = skipped, total = #order }
end

-- Running ----------------------------------------------------------------------------------

local function finish()
    local st = state
    state = nil
    progress(nil)

    -- Items are stored by id as they are handled, so the file lists each once, in order.
    local parts, sent = {}, {}
    for _, id in ipairs(st.order) do
        if st.out[id] then
            parts[#parts + 1] = st.out[id]
            sent[#sent + 1] = id
        end
    end

    if st.mode == "baseline" then
        for id, sig in pairs(st.newSigs) do st.sigs[id] = sig end
        ShroudSetSavedVar("itemSigs", st.sigs, "account")
        ShroudConsoleLog("Marked " .. st.total .. " items as already exported.")
        return
    end

    if #parts == 0 then
        ShroudConsoleLog("No new or changed items since the last export (" .. st.total .. " in your bags).")
        return
    end

    local body = util.header("items")
        .. ',"scope":' .. jstr(st.mode)
        .. ',"count":' .. #parts .. ',"items":[\n' .. table.concat(parts, ",\n") .. '\n]}\n'
    local path, err = util.writeFile(SotaLore.files.items, body)
    if not path then
        ShroudConsoleLog("Item export failed: " .. tostring(err))
        return
    end
    for _, id in ipairs(sent) do st.sigs[id] = st.newSigs[id] end
    ShroudSetSavedVar("itemSigs", st.sigs, "account")
    ShroudConsoleLog("Items: " .. #parts .. " of " .. st.total .. " written to " .. path
        .. (st.skipped > 0 and (" (" .. st.skipped .. " without a key skipped)") or "")
        .. " (type /lua path to open the folder)")
end

-- Called every frame (from ShroudOnUpdate); does nothing unless an export is running.
function M.step()
    local st = state
    if not st then return end

    -- All handled: writing the file is a frame of its own.
    if st.i > #st.order then
        local started = util.clock()
        finish()
        util.slow("writing the items file", started)
        return
    end

    local started = util.clock()
    local count = 0
    while st.i <= #st.order and count < MAX_PER_SLICE and (count == 0 or util.clock() - started < util.sliceLimit) do
        local id = st.order[st.i]
        local e = st.entries[id]
        local sig = fingerprint(e)
        st.newSigs[id] = sig
        if st.mode == "all" or (st.mode == "new" and st.sigs[id] ~= sig) then
            st.out[id] = jitem(e)
        end
        st.i = st.i + 1
        count = count + 1
    end
    util.slow("a slice of the items export", started)
    progress("Items " .. math.floor(100 * (st.i - 1) / #st.order) .. "%")
end

-- Forgets any export in progress (used when the plugin starts).
function M.reset()
    state = nil
end
