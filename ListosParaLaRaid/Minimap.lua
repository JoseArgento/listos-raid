local ADDON, ns = ...
local L = ns.L

-- The round button on the minimap's edge (Pergamino.MinimapButton): a click opens or closes the page. Its angle
-- lives in settings.minimapAngle; settings.minimap = false hides it (/listos minimapa off). The button is
-- registered in the family's hub: with settings.minimapMerged the lib shows one button for every addon that
-- shares it (/listos minimapa juntar on|off). Clicks go through the guard, so an error is kept, not thrown.

local button

function ns.MinimapButton()
	if button then
		return button
	end
	local s = ns.db.settings
	button = Pergamino.MinimapButton(ADDON .. "MinimapButton", {
		icon = "Interface\\AddOns\\" .. ADDON .. "\\Media\\icon",
		angle = s.minimapAngle,
		shown = s.minimap ~= false,
		onClick = function()
			ns.UI.Toggle()
		end,
		onMove = function(angle)
			s.minimapAngle = angle
		end,
		tooltip = function(tip)
			tip:SetText(L.TITLE)
			tip:AddLine(L.MINIMAP_TIP, 1, 1, 1, true)
		end,
		guard = ns.guard,
		hub = { addon = L.TITLE, label = L.TITLE, order = 5 },
	})
	if s.minimapMerged ~= nil then
		Pergamino.MinimapHub.SetMerged(s.minimapMerged)
	end
	return button
end

-- /listos minimapa juntar on|off: one button for the whole family (the lib keeps it for every addon)
function ns.SetMinimapMerged(merged)
	ns.db.settings.minimapMerged = merged and true or false
	Pergamino.MinimapHub.SetMerged(merged)
	ns.Print(merged and L.MINIMAP_MERGED_ON or L.MINIMAP_MERGED_OFF)
end

-- /listos minimapa on|off (without a word: switch it)
function ns.SetMinimapShown(shown)
	ns.db.settings.minimap = shown and true or false
	ns.MinimapButton():SetShown(shown)
	ns.Print(shown and L.MINIMAP_ON or L.MINIMAP_OFF)
end
