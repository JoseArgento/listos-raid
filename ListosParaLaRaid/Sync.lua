local _, ns = ...

-- Telling the guild how ready you are, through addon messages on the GUILD channel. Plain text:
--   S|1|<level>|<amulet 0/1>|<steps done>|<steps>|<fire>    my status
--   Q|1                                                    "send me yours"
-- Only numbers travel, and only numbers in sensible ranges are kept. Nothing received is run.

ns.PREFIX = "ListosRaid1"

local MAX_SENDERS = 1000
local WINDOW, PER_WINDOW = 10, 5
local SUCCESS = Enum.SendAddonMessageResult and Enum.SendAddonMessageResult.Success or 0
local RETRY = {}
if Enum.SendAddonMessageResult then
	for _, k in ipairs({ "AddonMessageThrottle", "ChannelThrottle", "AddOnMessageLockdown", "GeneralError" }) do
		if Enum.SendAddonMessageResult[k] then
			RETRY[Enum.SendAddonMessageResult[k]] = true
		end
	end
end

function ns.IsTrial()
	return (IsTrialAccount and IsTrialAccount()) or (IsVeteranTrialAccount and IsVeteranTrialAccount()) or false
end

function ns.CanSend()
	return ns.GuildKey() ~= nil and not ns.IsTrial()
end

local retryPending = false
local function send(text)
	if not ns.CanSend() then
		return false
	end
	local function later()
		if not retryPending then
			retryPending = true
			C_Timer.After(15, function()
				retryPending = false
				send(text)
			end)
		end
	end
	if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
		later()
		return false
	end
	local result = C_ChatInfo.SendAddonMessage(ns.PREFIX, text, "GUILD")
	if result ~= nil and result ~= SUCCESS then
		if RETRY[result] then
			later()
		end
		return false
	end
	return true
end

local lastSent
function ns.ShareNow(force)
	local s = ns.MyStatus()
	local text = table.concat({ "S", 1, s.lv, s.am and 1 or 0, s.st, s.of, s.fr }, "|")
	if text == lastSent and not force then
		return false -- nothing changed
	end
	lastSent = text
	return send(text)
end

local sharePending = false
function ns.ShareSoon()
	if sharePending or not ns.CanSend() then
		return
	end
	sharePending = true
	C_Timer.After(3, function()
		sharePending = false
		ns.ShareNow()
	end)
end

function ns.AskGuild()
	return send("Q|1")
end

function ns.Guild()
	local key = ns.GuildKey()
	if not key then
		return {}
	end
	ns.db.guilds[key] = ns.db.guilds[key] or {}
	return ns.db.guilds[key]
end

local rate = {}
local function allowed(sender)
	local now = time()
	local r = rate[sender]
	if not r or now - r.t >= WINDOW then
		r = { t = now, n = 0 }
		rate[sender] = r
	end
	r.n = r.n + 1
	return r.n <= PER_WINDOW
end

local lastReply, replyPending = 0, false

function ns.OnAddonMessage(prefix, text, channel, sender)
	if prefix ~= ns.PREFIX or channel ~= "GUILD" then
		return
	end
	if issecretvalue(text) or issecretvalue(sender) or type(text) ~= "string" or type(sender) ~= "string" then
		return
	end
	if #text > 40 or #sender > 64 then
		return
	end
	sender = Ambiguate(sender, "none")
	if sender == ns.Me() or not allowed(sender) then
		return
	end
	if text == "Q|1" then
		if not replyPending and time() - lastReply >= 20 then
			replyPending = true
			C_Timer.After(2 + math.random() * 6, function()
				replyPending = false
				lastReply = time()
				ns.ShareNow(true)
			end)
		end
		return
	end
	local lv, am, st, of, fr = text:match("^S|1|(%d+)|([01])|(%d+)|(%d+)|(%d+)$")
	lv, st, of, fr = tonumber(lv), tonumber(st), tonumber(of), tonumber(fr)
	if not lv or lv < 1 or lv > 100 or of > 40 or st > of or fr > 1000 then
		return
	end
	local guild = ns.Guild()
	if not guild[sender] then
		local n = 0
		for _ in pairs(guild) do
			n = n + 1
		end
		if n >= MAX_SENDERS then
			return
		end
	end
	guild[sender] = { lv = lv, am = am == "1", st = st, of = of, fr = fr, t = time() }
	ns.Fire("guild")
end
