local ADDON, ns = ...
local L = ns.L

-- Anything that can change how ready you are: a level, a quest, the amulet arriving, gear (resistance).
local function changed()
	ns.Fire("status")
	ns.ShareSoon()
end

local handlers = {
	PLAYER_LEVEL_UP = changed,
	QUEST_TURNED_IN = changed,
	BAG_UPDATE_DELAYED = changed,
	UNIT_RESISTANCES = function(unit)
		if unit == "player" then
			changed()
		end
	end,
	PLAYER_EQUIPMENT_CHANGED = changed,
	CHAT_MSG_ADDON = function(prefix, text, channel, sender)
		ns.OnAddonMessage(prefix, text, channel, sender)
	end,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		if ... == ADDON then
			ns.InitDB()
			frame:UnregisterEvent("ADDON_LOADED")
		end
	elseif event == "PLAYER_LOGIN" then
		C_ChatInfo.RegisterAddonMessagePrefix(ns.PREFIX)
		for e in pairs(handlers) do
			frame:RegisterEvent(e)
		end
		ns.MinimapButton()
		-- a moment after login, when the guild and the quest log are there
		C_Timer.After(8, function()
			if ns.CanSend() then
				ns.AskGuild()
				ns.ShareNow(true)
			end
		end)
	elseif handlers[event] then
		handlers[event](...)
	end
end)

SLASH_LISTOSPARALARAID1 = "/listos"
SlashCmdList.LISTOSPARALARAID = function(msg)
	msg = strtrim((msg or ""):lower())
	local verb, arg = msg:match("^(%S+)%s*(.*)$")
	if msg == "copiar" or msg == "copy" then
		ns.UI.Copy()
	elseif verb == "idioma" or verb == "lang" then
		ns.ChooseLanguage(arg)
	elseif verb == "minimapa" or verb == "minimap" then
		if arg == "on" or arg == "off" then
			ns.SetMinimapShown(arg == "on")
		else
			ns.SetMinimapShown(ns.db.settings.minimap == false)
		end
	elseif msg == "help" or msg == "ayuda" then
		ns.Print(L.HELP)
	else
		ns.UI.Toggle()
	end
end

function ListosParaLaRaid_OnAddonCompartmentClick()
	ns.UI.Toggle()
end
function ListosParaLaRaid_OnAddonCompartmentEnter(_, button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(L.TITLE)
	GameTooltip:AddLine(L.COMPARTMENT, 1, 1, 1)
	GameTooltip:Show()
end
function ListosParaLaRaid_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

-- Key binding (Bindings.xml) and its names in the key bindings panel.
_G["ListosParaLaRaid_Toggle"] = function()
	ns.UI.Toggle()
end
_G["BINDING_HEADER_LISTOSPARALARAID"] = "Listos para la raid"
_G["BINDING_NAME_LISTOSPARALARAID_TOGGLE"] = L.BINDING_TOGGLE
