local ADDON, ns = ...
local L = ns.L

-- Saved data (ListosParaLaRaidDB): guilds[guild-realm][Name] = { lv, am, st, of, fr, t } as they arrived.

local listeners = {}
function ns.On(topic, fn)
	listeners[topic] = listeners[topic] or {}
	table.insert(listeners[topic], fn)
end
function ns.Fire(topic, ...)
	for _, fn in ipairs(listeners[topic] or {}) do
		fn(...)
	end
end

function ns.InitDB()
	if type(ListosParaLaRaidDB) ~= "table" then
		ListosParaLaRaidDB = {}
	end
	local db = ListosParaLaRaidDB
	db.version = 1
	db.guilds = type(db.guilds) == "table" and db.guilds or {}
	db.settings = type(db.settings) == "table" and db.settings or {}
	ns.db = db
	if db.settings.lang and db.settings.lang ~= ns.lang then
		ns.SetLanguage(db.settings.lang)
	end
	-- the addon's own errors, kept here and shown with /listos errores (Pergamino.Guard)
	db.errors = type(db.errors) == "table" and db.errors or {}
	ns.guard = Pergamino.Guard(ADDON, db, {
		slash = "/listos",
		chat = function()
			ns.Print(L.ERR_NOTICE)
		end,
		L = { title = L.ERR_TITLE, empty = L.ERR_EMPTY, clear = L.ERR_CLEAR, copy = L.ERR_COPY },
	})
end

-- "auto", "es" or "en": saved, applied at once, and the page redraws its texts.
function ns.ChooseLanguage(mode)
	mode = ns.LANGS[mode] and mode or "auto"
	ns.db.settings.lang = mode
	ns.SetLanguage(mode)
	ns.Print(L.LANG_SET:format(mode == "auto" and L.LANG_AUTO or mode))
end

function ns.Me()
	-- one value: UnitName also returns the realm, which would spill into table.insert and the like
	return (UnitName("player"))
end

function ns.GuildKey()
	if not IsInGuild() then
		return nil
	end
	local guild, _, _, realm = GetGuildInfo("player")
	if not guild or issecretvalue(guild) or guild == "" then
		return nil
	end
	return guild .. "-" .. (realm or GetNormalizedRealmName() or "")
end

local function plainNumber(v)
	if type(v) ~= "number" or issecretvalue(v) then
		return nil
	end
	return v
end

-- How far along this character is: { lv, am (amulet: true/false), st (steps done), of (steps in the chain), fr (fire) }.
function ns.MyStatus()
	local faction = UnitFactionGroup("player")
	local chain = ns.CHAIN[faction] or {}
	local done = 0
	for _, quest in ipairs(chain) do
		if C_QuestLog.IsQuestFlaggedCompleted(quest) then
			done = done + 1
		end
	end
	local amulet = (plainNumber(C_Item.GetItemCount(ns.AMULET, true)) or 0) > 0
	if amulet then
		done = #chain -- with the amulet in hand every step is behind you
	end
	local _, _, fire = UnitResistance("player", Enum.Damageclass and Enum.Damageclass.Fire or 2)
	return {
		lv = plainNumber(UnitLevel("player")) or 0,
		am = amulet,
		st = done,
		of = #chain,
		fr = plainNumber(fire) or 0,
	}
end

-- Which raids a status lets you into.
function ns.ReadyFor(s)
	local out = {}
	for _, raid in ipairs(ns.RAIDS) do
		if s.lv >= ns.LEVEL and (not raid.attune or s.am) then
			out[#out + 1] = raid.key
		end
	end
	return out
end

-- Whole days until the raids open, by your computer's calendar; 0 on the day, negative after.
function ns.DaysLeft()
	local open = time({ year = ns.OPEN.year, month = ns.OPEN.month, day = ns.OPEN.day, hour = 0 })
	local t = date("*t", time())
	local today = time({ year = t.year, month = t.month, day = t.day, hour = 0 })
	return math.floor((open - today) / 86400 + 0.5)
end

function ns.Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffd100" .. L.TITLE .. ":|r " .. msg)
end

ns.ADDON = ADDON
