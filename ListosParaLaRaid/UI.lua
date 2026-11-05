local ADDON, ns = ...
local L = ns.L

-- The panel: the countdown, your own status, and the guild's, ready players first.

local UI = {}
ns.UI = UI
local ROWS = 16
local GREEN, RED, GREY = "|cff40c040", "|cffff5050", "|cff9d9d9d"

-- Everything the panel says, as plain lines (the tests read them; the panel draws them).
function UI.Lines()
	local out = {}
	local days = ns.DaysLeft()
	out.countdown = days > 0 and L.COUNTDOWN:format(days) or (days == 0 and L.COUNTDOWN_TODAY or L.COUNTDOWN_OPEN)
	local s = ns.MyStatus()
	local mine = {
		L.LEVEL:format(s.lv),
		L.AMULET .. ": " .. (s.am and (GREEN .. L.AMULET_YES .. "|r") or (RED .. L.AMULET_NO .. "|r")),
	}
	-- below the attunement's level the steps and the fire resistance would only nag: say what comes first
	if s.lv < ns.CHAIN_LEVEL then
		mine[#mine + 1] = L.LEVELS_TO_GO:format(ns.LEVEL - s.lv, ns.CHAIN_LEVEL)
	else
		if not s.am and s.of > 0 then
			mine[#mine + 1] = L.STEP:format(s.st, s.of)
		end
		mine[#mine + 1] = s.fr >= ns.FIRE_GOAL and L.FIRE:format(s.fr) or L.FIRE_HINT:format(s.fr, ns.FIRE_GOAL)
		local ready = {}
		for _, key in ipairs(ns.ReadyFor(s)) do
			ready[#ready + 1] = L["RAID_" .. key]
		end
		mine[#mine + 1] = #ready > 0 and L.READY_FOR:format(table.concat(ready, ", ")) or L.NOT_YET
	end
	out.mine = mine

	local list = {}
	for name, st in pairs(ns.Guild()) do
		list[#list + 1] = { name = name, s = st }
	end
	local onyxia, sixty = 0, 0
	for _, e in ipairs(list) do
		if e.s.lv >= ns.LEVEL then
			sixty = sixty + 1
			if e.s.am then
				onyxia = onyxia + 1
			end
		end
	end
	table.sort(list, function(a, b)
		local ra, rb = (a.s.am and 2 or 0) + (a.s.lv >= ns.LEVEL and 1 or 0), (b.s.am and 2 or 0) + (b.s.lv >= ns.LEVEL and 1 or 0)
		if ra ~= rb then
			return ra > rb
		end
		if a.s.lv ~= b.s.lv then
			return a.s.lv > b.s.lv
		end
		return a.name < b.name
	end)
	out.count = L.GUILD_COUNT:format(onyxia, sixty)
	out.guild = {}
	for _, e in ipairs(list) do
		local st = e.s
		local attune = st.am and (GREEN .. L.ROW_AMULET .. "|r") or (GREY .. L.ROW_STEP:format(st.st, st.of) .. "|r")
		out.guild[#out.guild + 1] = L.ROW:format(e.name, st.lv, attune, L.ROW_FIRE:format(st.fr))
	end
	if not ns.GuildKey() then
		out.note = L.NO_GUILD
	elseif ns.IsTrial() then
		out.note = L.TRIAL
	elseif #list == 0 then
		out.note = L.NOBODY
	end
	return out
end

-- The guild as text, to paste in a spreadsheet or in RaidCalendar's notes.
function UI.ListText()
	local lines = { "name,level,amulet,step,steps,fire" }
	local names = {}
	for name in pairs(ns.Guild()) do
		names[#names + 1] = name
	end
	table.sort(names)
	local me = ns.MyStatus()
	table.insert(names, 1, ns.Me())
	for _, name in ipairs(names) do
		local s = name == ns.Me() and me or ns.Guild()[name]
		lines[#lines + 1] = table.concat({ name, s.lv, s.am and 1 or 0, s.st, s.of, s.fr }, ",")
	end
	return table.concat(lines, "\n")
end

StaticPopupDialogs.LISTOSPARALARAID_COPY = {
	text = "%s",
	button1 = OKAY,
	hasEditBox = 1,
	editBoxWidth = 320,
	OnShow = function(dialog, data)
		local edit = dialog:GetEditBox()
		edit:SetText(data or "")
		edit:HighlightText()
		edit:SetFocus()
	end,
	EditBoxOnEscapePressed = function(editBox)
		editBox:GetParent():Hide()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

function UI.Copy()
	StaticPopup_Show("LISTOSPARALARAID_COPY", L.COPY_PROMPT, nil, UI.ListText())
end

local function build()
	local FRAME = ADDON .. "Frame"
	local f = CreateFrame("Frame", FRAME, UIParent, "BasicFrameTemplateWithInset")
	f:SetSize(460, 470)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")
	f:SetToplevel(true)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:Hide()
	f.TitleText:SetText(L.TITLE)
	tinsert(UISpecialFrames, FRAME)
	UI.frame = f

	f.countdown = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.countdown:SetPoint("TOPLEFT", 16, -34)
	f.you = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.you:SetPoint("TOPLEFT", 16, -64)
	f.you:SetText(L.YOU)
	f.mine = {}
	for i = 1, 5 do
		local line = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		line:SetPoint("TOPLEFT", 24, -66 - i * 16)
		line:SetPoint("RIGHT", -16, 0)
		line:SetJustifyH("LEFT")
		f.mine[i] = line
	end
	f.guildHead = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.guildHead:SetPoint("TOPLEFT", 16, -176)
	f.guildHead:SetText(L.GUILD)
	f.count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	f.count:SetPoint("LEFT", f.guildHead, "RIGHT", 12, 0)
	f.rows = {}
	for i = 1, ROWS do
		local row = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		row:SetPoint("TOPLEFT", 24, -180 - i * 15)
		row:SetPoint("RIGHT", -16, 0)
		row:SetJustifyH("LEFT")
		f.rows[i] = row
	end
	f.note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	f.note:SetPoint("BOTTOMLEFT", 16, 44)
	f.note:SetPoint("RIGHT", -16, 0)
	f.note:SetJustifyH("LEFT")
	f.note:SetWordWrap(true)
	f.copy = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	f.copy:SetSize(140, 24)
	f.copy:SetPoint("BOTTOMRIGHT", -14, 12)
	f.copy:SetText(L.COPY)
	f.copy:SetScript("OnClick", UI.Copy)
	f:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		UI.Refresh()
	end)
	f:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)
	return f
end

function UI.Refresh()
	local f = UI.frame
	if not f or not f:IsShown() then
		return
	end
	local lines = UI.Lines()
	f.countdown:SetText(lines.countdown)
	for i, fs in ipairs(f.mine) do
		fs:SetText(lines.mine[i] or "")
	end
	f.count:SetText(lines.count)
	for i, fs in ipairs(f.rows) do
		fs:SetText(lines.guild[i] or "")
	end
	f.note:SetText(lines.note or "")
end

function UI.Toggle()
	local f = UI.frame or build()
	f:SetShown(not f:IsShown())
end

ns.On("guild", UI.Refresh)
ns.On("status", UI.Refresh)
