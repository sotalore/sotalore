-- skills_ui.lua: the "SotaLore Skills" window: the player's skills as text to copy into the website.
--
-- Everything this window says is for a player who only copies and pastes: what the add-on is for (and that it
-- is only useful with the SotaLore website), how to copy, and why there can be more than one page to copy (a text
-- box holds at most 1024 characters and an add-on cannot reach the clipboard, so a long code is split up). How the
-- code is built is the site's business and is not explained here.
--
-- The player clicks the text box, presses Ctrl+A then Ctrl+C, and pastes on the site; Next and Previous move
-- between the pages. The site takes all the pages in one box, in any order.
--
-- Used by: main.lua (the /slskills command, the key binding, and ShroudOnSkillsChanged).

local UI = Shroud.UI
local Skills = SotaLoreSkills.Skills

local M = {}
SotaLoreSkills.SkillsUI = M

local SITE = "www.sotalore.com"

local win, summaryLabel, pagesLabel, pageLabel, codeBox
local pages = {}
local page = 1

-- A label that wraps onto more lines instead of running off the edge of the window.
local function para(text, class)
    return UI.Label{ text = text, class = class, style = { whiteSpace = "wrap" } }
end

local function showPage()
    if not win then return end
    codeBox:SetText(pages[page] or "")
    if #pages > 1 then
        pageLabel:SetText("Page " .. page .. " of " .. #pages)
        pagesLabel:SetText("The add-on can't copy all of your skills in one go, so they come in " .. #pages
            .. " pages. Copy each page in turn (Next shows the next one) and paste them all into the same box on the site.")
    elseif #pages == 1 then
        pageLabel:SetText("")
        pagesLabel:SetText("All of your skills fit in one page: copy it and paste it on the site.")
    else
        pageLabel:SetText("")
        pagesLabel:SetText("")
    end
end

-- Reads the skills again and fills the window. With keepPage it stays on the page being copied (as far as
-- that page still exists), so a level going up mid-copy does not throw the player back to page 1.
function M.refresh(keepPage)
    if not win then return end
    local info = Skills.read()
    if not info then
        summaryLabel:SetText("Your skills aren't loaded yet. Press Refresh in a moment.")
        pages = {}
        page = 1
        showPage()
        return
    end
    pages = Skills.pages(info)
    if keepPage == true then
        page = math.max(1, math.min(page, #pages))
    else
        page = 1
    end
    summaryLabel:SetText(info.count .. " skills for " .. info.character .. ".")
    showPage()
end

function M.build()
    pages, page = {}, 1
    summaryLabel = UI.Label{ text = "", class = "heading" }
    pagesLabel = para("", "dim")
    pageLabel = UI.Label{ text = "" }
    codeBox = UI.TextField{ text = "", maxLength = 1024 }
    win = UI.Window{
        id = "sotaloreskills",
        title = "SotaLore Skills",
        width = 400, height = 380,
        x = 400, y = 120,
        escCloses = true,
        children = {
            para("Copy your skill levels into the SotaLore website, " .. SITE .. ", to plan your skills there. "
                .. "This add-on is only useful if you use that site.", "dim"),
            summaryLabel,
            para("On " .. SITE .. ", open your avatar's skills page and choose Import from game. Then here: click the "
                .. "box below, press Ctrl+A, then Ctrl+C, and paste it into the box on the site."),
            pagesLabel,
            codeBox,
            pageLabel,
            UI.Row{ children = {
                UI.Button{ text = "Previous", onClick = function()
                    if page > 1 then page = page - 1; showPage() end
                end },
                UI.Button{ text = "Next", onClick = function()
                    if page < #pages then page = page + 1; showPage() end
                end },
                UI.Button{ text = "Refresh", tooltip = "Read your skills again", onClick = function() M.refresh(false) end },
            } },
        },
    }
end

-- Opens the window with fresh skills, or closes it.
function M.toggle()
    if win:IsShown() then
        win:Hide()
    else
        M.refresh(false)
        win:Show()
    end
end

-- Keeps the window up to date while it is open (from ShroudOnSkillsChanged, which can fire before the window
-- exists).
function M.refreshIfShown()
    if win and win:IsShown() then M.refresh(true) end
end
