local ADDON, ns = ...
local L = ns.L

-- The window: a single parchment page (Pergamino.Book, single mode). The countdown as the big line, your
-- own status in ink, the guild as a list with the ready ones first, and "Copiar lista" on a parchment card.

local UI = {}
ns.UI = UI
local P = Pergamino
-- inks for the inline colours (the texts are read by the tests, so they stay plain strings)
local GREEN, RED, GREY = "|cff1d6e10", "|cff8f2a1d", "|cff6c4e31"
local ROW_H = 22

-- Everything the page says, as plain lines (the tests read them; the page draws them).
function UI.Lines()
	local out = {}
	local days = ns.DaysLeft()
	out.countdown = days > 1 and L.COUNTDOWN:format(days) or days == 1 and L.COUNTDOWN_1 or (days == 0 and L.COUNTDOWN_TODAY or L.COUNTDOWN_OPEN)
	local s = ns.MyStatus()
	local mine = {
		L.LEVEL:format(s.lv),
		L.AMULET .. ": " .. (s.am and (GREEN .. L.AMULET_YES .. "|r") or (RED .. L.AMULET_NO .. "|r")),
	}
	-- below the attunement's level the steps and the fire resistance would only nag: say what comes first
	if s.lv < ns.CHAIN_LEVEL then
		local toGo = ns.LEVEL - s.lv
		mine[#mine + 1] = toGo == 1 and L.LEVELS_TO_GO_1:format(ns.CHAIN_LEVEL) or L.LEVELS_TO_GO:format(toGo, ns.CHAIN_LEVEL)
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
	local others = 0
	for name, st in pairs(ns.Guild()) do
		list[#list + 1] = { name = name, s = st }
		if name ~= ns.Me() then
			others = others + 1
		end
	end
	-- your own row is always there, guild or not (before the first sync the guild table has nobody)
	if #list == others then
		list[#list + 1] = { name = ns.Me(), s = s }
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
	out.rows = {}
	for _, e in ipairs(list) do
		local st = e.s
		local attune = st.am and (GREEN .. L.ROW_AMULET .. "|r") or (GREY .. L.ROW_STEP:format(st.st, st.of) .. "|r")
		out.guild[#out.guild + 1] = L.ROW:format(e.name, st.lv, attune, L.ROW_FIRE:format(st.fr))
		out.rows[#out.rows + 1] = {
			name = e.name,
			lv = st.lv,
			am = st.am,
			st = st.st,
			of = st.of,
			fr = st.fr,
			ready = st.am and st.lv >= ns.LEVEL,
			sixty = st.lv >= ns.LEVEL,
		}
	end
	if not ns.GuildKey() then
		out.note = L.NO_GUILD
	elseif ns.IsTrial() then
		out.note = L.TRIAL
	elseif others == 0 then
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

-- "Copiar lista": a parchment card with the text selected, ready for Ctrl+C.
local function copyCard()
	if UI.card then
		return UI.card
	end
	local card = P.Card(ADDON .. "CopyCard", 440, 220, L.COPY)
	local hint = P.Label(card.body, L.COPY_PROMPT, "small")
	hint:SetPoint("TOPLEFT")
	hint:SetPoint("TOPRIGHT")
	hint:SetWordWrap(true)
	local area = P.TextArea(card.body)
	area:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -8)
	area:SetPoint("BOTTOMRIGHT")
	card.area = area
	UI.card = card
	return card
end

function UI.Copy()
	local card = copyCard()
	card.area.box:SetText(UI.ListText())
	card:Show()
	local edit = card.area.box.GetEditBox and card.area.box:GetEditBox()
	if edit then
		if edit.HighlightText then
			edit:HighlightText()
		end
		if edit.SetFocus then
			edit:SetFocus()
		end
	end
end

-- a guild row: name · level · amulet or step · fire, and a gold tag when ready for Onyxia
local function initRow(row, item)
	if not row.name then
		row.name = P.Label(row, "", "strong")
		row.name:SetPoint("LEFT", 6, 0)
		row.name:SetWidth(120)
		row.name:SetWordWrap(false)
		row.level = P.Label(row, "", "body", "CENTER")
		row.level:SetPoint("LEFT", row.name, "RIGHT", 4, 0)
		row.level:SetWidth(28)
		row.attune = P.Label(row, "", "small")
		row.attune:SetPoint("LEFT", row.level, "RIGHT", 6, 0)
		row.attune:SetWidth(90)
		row.attune:SetWordWrap(false)
		row.fire = P.Label(row, "", "small", "RIGHT")
		row.fire:SetPoint("RIGHT", -6, 0)
		row.fire:SetWidth(56)
		row.tag = P.Tag(row, L.TAG_READY, "pinned")
		row.tag:SetPoint("RIGHT", row.fire, "LEFT", -6, 0)
	end
	row.name:SetText(item.name)
	row.level:SetText(tostring(item.lv))
	row.attune:SetText(item.am and (GREEN .. L.ROW_AMULET .. "|r") or (GREY .. L.ROW_STEP:format(item.st, item.of) .. "|r"))
	row.fire:SetText(L.ROW_FIRE:format(item.fr))
	row.tag:Set(L.TAG_READY, "pinned")
	row.tag:SetShown(item.ready)
end

local function build()
	local f = P.Book(ADDON .. "Frame", { title = L.TITLE, single = true, width = 480, height = 540 })
	-- clicking the page brings the whole of it over any other book that is open
	f:SetToplevel(true)
	UI.frame = f
	local page = f.left

	f.countdown = P.Label(page, "", "big")
	f.countdown:SetPoint("TOPLEFT")
	f.countdown:SetPoint("TOPRIGHT")
	f.countdown:SetWordWrap(true)

	local rule = P.Rule(page)
	rule:SetPoint("TOPLEFT", f.countdown, "BOTTOMLEFT", 0, -10)
	rule:SetPoint("TOPRIGHT", f.countdown, "BOTTOMRIGHT", 0, -10)

	f.you = P.Label(page, L.YOU, "heading")
	f.you:SetPoint("TOPLEFT", rule, "BOTTOMLEFT", 0, -12)
	f.mine = {}
	local prev = f.you
	for i = 1, 5 do
		local ln = P.Label(page, "", "body")
		ln:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", i == 1 and 8 or 0, -4)
		ln:SetPoint("RIGHT", page, "RIGHT", 0, 0)
		ln:SetWordWrap(true)
		f.mine[i] = ln
		prev = ln
	end
	f.guildHead = P.Label(page, L.GUILD, "heading")
	f.guildHead:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", -8, -16)
	f.count = P.Label(page, "", "small")
	f.count:SetPoint("LEFT", f.guildHead, "RIGHT", 10, 0)
	f.count:SetPoint("RIGHT", page, "RIGHT", 0, 0)
	f.count:SetWordWrap(false)

	f.copy = P.Button(page, L.COPY, 140, UI.Copy)
	f.copy:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)

	f.note = P.Label(page, "", "muted")
	f.note:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 4)
	f.note:SetPoint("RIGHT", f.copy, "LEFT", -10, 0)
	f.note:SetWordWrap(true)

	local holder = P.Panel(page)
	holder:SetPoint("TOPLEFT", f.guildHead, "BOTTOMLEFT", 0, -6)
	holder:SetPoint("RIGHT", page, "RIGHT", -14, 0)
	holder:SetPoint("BOTTOM", f.copy, "TOP", 0, 12)
	f.list = P.List(holder, ROW_H, initRow)
	f.list.box:SetPoint("TOPLEFT", 2, -2)
	f.list.box:SetPoint("BOTTOMRIGHT", -2, 2)

	f:SetScript("OnShow", function()
		if PlaySound and SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_OPEN then
			PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
		end
		UI.Refresh()
	end)
	return f
end

-- The static texts, again: the language can change after the page was built.
function UI.ApplyTexts()
	local f = UI.frame
	if not f then
		return
	end
	f:SetTitle(L.TITLE)
	f.you:SetText(L.YOU)
	f.guildHead:SetText(L.GUILD)
	f.copy:SetText(L.COPY)
	if UI.card then
		UI.card.title:SetText(L.COPY)
	end
	UI.Refresh()
end

function UI.Refresh()
	local f = UI.frame
	if not f or not f:IsShown() then
		return
	end
	local lines = UI.Lines()
	f.countdown:SetText(lines.countdown)
	local last = f.you
	for i, fs in ipairs(f.mine) do
		local text = lines.mine[i]
		fs:SetText(text or "")
		fs:SetShown(text ~= nil)
		if text then
			last = fs
		end
	end
	-- the guild block hangs from the last line that has text, so the page has no gap when there are fewer
	f.guildHead:ClearAllPoints()
	f.guildHead:SetPoint("TOPLEFT", last, "BOTTOMLEFT", last == f.you and 0 or -8, -16)
	f.count:SetText(lines.count)
	f.list:SetData(lines.rows, true)
	f.note:SetText(lines.note or "")
end

function UI.Toggle()
	local f = UI.frame or build()
	f:SetShown(not f:IsShown())
end

ns.On("guild", UI.Refresh)
ns.On("status", UI.Refresh)
ns.On("lang", UI.ApplyTexts)
