-- skills_ui.lua: the "SotaLore Skills" window: the skill code in a text box to copy.
--
-- The player clicks the text box, presses Ctrl+A then Ctrl+C, and pastes into the site. When the code is more
-- than one page (a text box holds 1024 characters), Next and Previous move between the pages and the player
-- copies each in turn. The window is also where the sizes are shown: how many skills, how many pages.
--
-- Used by: recipes_ui.lua (the "Skills window" button), main.lua (the /slore skills command).

local UI = Shroud.UI
local Skills = SotaLore.Skills

local M = {}
SotaLore.SkillsUI = M

local win, summaryLabel, pageLabel, codeBox
local pages = {}
local page = 1

local function showPage()
    if not win then return end
    codeBox:SetText(pages[page] or "")
    pageLabel:SetText("Page " .. page .. " of " .. #pages .. "  (" .. #(pages[page] or "") .. " characters)")
end

-- Reads the skills again and fills the window.
function M.refresh()
    if not win then return end
    local info = Skills.read()
    if not info then
        summaryLabel:SetText("Skills are not loaded yet.")
        pages = {}
        page = 1
        showPage()
        return
    end
    pages = Skills.pages(info)
    page = 1
    summaryLabel:SetText(info.count .. " trained skills for " .. info.character .. ". Ids " .. info.minId .. " to "
        .. info.maxId .. ", highest level " .. info.maxLevel)
    showPage()
end

function M.build()
    pages, page = {}, 1
    summaryLabel = UI.Label{ text = "", class = "dim" }
    pageLabel = UI.Label{ text = "" }
    codeBox = UI.TextField{ text = "", maxLength = 1024 }
    win = UI.Window{
        id = "sotaloreskills",
        title = "SotaLore Skills",
        width = 380, height = 260,
        x = 400, y = 120,
        escCloses = true,
        children = {
            summaryLabel,
            UI.Label{ text = "Click the box, press Ctrl+A then Ctrl+C, and paste it into the site.", class = "dim" },
            codeBox,
            pageLabel,
            UI.Row{ children = {
                UI.Button{ text = "Previous", onClick = function()
                    if page > 1 then page = page - 1; showPage() end
                end },
                UI.Button{ text = "Next", onClick = function()
                    if page < #pages then page = page + 1; showPage() end
                end },
                UI.Button{ text = "Refresh", tooltip = "Read the skills again", onClick = M.refresh },
                UI.Button{ text = "Save file", tooltip = "Write " .. SotaLore.files.skills .. " (every field, for checking)", onClick = Skills.export },
            } },
        },
    }
end

-- Opens the window with fresh skills, or closes it.
function M.toggle()
    if win:IsShown() then
        win:Hide()
    else
        M.refresh()
        win:Show()
    end
end
