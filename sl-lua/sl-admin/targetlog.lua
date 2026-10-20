-- targetlog.lua: a diagnostic, switched on and off with /sladmin targetlog. Not part of the exports.
--
-- While it is on, each individual that becomes the player's target is written to chat once per scene visit,
-- with what the game tells an add-on about it. The aim is to learn whether the target can add creatures to the
-- finds list that the player never fights: the target follows the game's target frame (the locked target,
-- otherwise the closest combatant), so walking past a creature is enough.
--
-- Learned in the first test (2026-10-20, Serpent's Spine Foothills):
--   * creatures fighting each other, not the player, do become the target, so this sees what the combat lines miss;
--   * the target id stays the same for one individual, so it can be counted once;
--   * with several combatants near, the target switches between them a few times a second, hence once per visit;
--   * the level shows at once or not at all (no follow-up read needed); every creature has focus;
--   * NPCs ("Fighter") become the target too, and look like a creature Animal Lore cannot read (no level).
-- Still to learn: what other players look like.
--
-- When the log is switched off, or the player leaves the scene, a summary line says how many different targets
-- there were and how often each name came back.
--
-- Used by: main.lua (the command, ShroudOnTargetChanged and ShroudOnSceneLoaded).

local M = {}
SotaLoreAdmin.TargetLog = M

local NONE = -999         -- InvalidStatResult: a stat the game does not show for this target

local on = false
local seen = {}           -- target id -> true, for this scene visit
local names = {}          -- name -> { individuals = n, switches = n }, for this scene visit
local order = {}          -- names in the order first seen
local scene = nil         -- the scene of this visit, for the summary

local function stat(name)
    local v = ShroudGetTargetStatValueByName(name)
    if v == nil or v == NONE then return "-" end
    return tostring(v)
end

-- The stats Animal Lore can reveal, in the order of its tiers: the level (Basics), the attributes (Build),
-- magic resistance (Defenses). "-" for one the game does not show for this target.
local function readable()
    return "level " .. stat("AdventurerLevel") .. " str/dex/int " .. stat("Strength") .. "/" .. stat("Dexterity")
        .. "/" .. stat("Intelligence") .. " mres " .. stat("MagicResistance")
end

-- Notes on who the target might be: the player's own pet, or a member of the player's party.
local function whoNotes(name)
    local notes = {}
    local pet = ShroudGetPetInfo()
    if pet and pet.Name == name then notes[#notes + 1] = "your pet" end
    local count = ShroudGetPartyMemberCount() or 0
    for slot = 1, count - 1 do
        if ShroudGetPartyMemberName(slot) == name then notes[#notes + 1] = "party member" end
    end
    if #notes == 0 then return "" end
    return " (" .. table.concat(notes, ", ") .. ")"
end

-- Writes what this visit saw, then starts afresh.
local function summarise()
    if #order > 0 then
        local parts, individuals, switches = {}, 0, 0
        for _, name in ipairs(order) do
            local n = names[name]
            individuals = individuals + n.individuals
            switches = switches + n.switches
            parts[#parts + 1] = name .. " " .. n.individuals .. " (" .. n.switches .. "x)"
        end
        ShroudConsoleLog("targets in " .. tostring(scene) .. ": " .. individuals .. " different, " .. switches
            .. " switches. " .. table.concat(parts, ", "))
    end
    seen, names, order, scene = {}, {}, {}, nil
end

-- Turns the log on or off. Returns the new state.
function M.toggle()
    if on then summarise() end
    on = not on
    seen, names, order, scene = {}, {}, {}, nil
    return on
end

-- From ShroudOnSceneLoaded: a new visit, so every individual is new again.
function M.newVisit()
    if on then summarise() end
end

-- From ShroudOnTargetChanged.
function M.onChange(id, name)
    if not on or id == -1 or not ShroudHasTarget() then return end
    scene = scene or ShroudGetCurrentSceneName()
    local n = names[name]
    if not n then
        n = { individuals = 0, switches = 0 }
        names[name] = n
        order[#order + 1] = name
    end
    n.switches = n.switches + 1
    if seen[id] then return end
    seen[id] = true
    n.individuals = n.individuals + 1
    ShroudConsoleLog("target: " .. tostring(name) .. whoNotes(name)
        .. "  id " .. tostring(id)
        .. (ShroudIsTargetDead() and "  DEAD" or "")
        .. "  health " .. tostring(ShroudGetTargetMaxHealth()) .. (ShroudIsTargetHealthHidden() and " (hidden)" or "")
        .. "  focus " .. tostring(ShroudGetTargetMaxFocus())
        .. "  " .. readable())
end
