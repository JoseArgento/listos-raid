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
	ns.db = db
end

function ns.Me()
	return UnitName("player")
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
