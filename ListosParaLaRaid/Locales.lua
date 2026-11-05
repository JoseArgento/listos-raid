local _, ns = ...

-- English is the fallback and the whole Spanish set is complete. ns.L is one table that gets refilled when
-- the language changes (settings.lang: "auto" follows the client, or "es" / "en"), so every file's
-- `local L = ns.L` keeps working; static texts on screen are redrawn by the "lang" topic.
local en = {
	BINDING_TOGGLE = "Open / close",
	TITLE = "Ready for the raid",
	COUNTDOWN = "Raids open on December 9: %d days to go",
	COUNTDOWN_1 = "Raids open on December 9: tomorrow",
	COUNTDOWN_TODAY = "Raids open today!",
	COUNTDOWN_OPEN = "Raids are open.",
	YOU = "You",
	LEVEL = "Level %d",
	AMULET = "Drakefire Amulet",
	AMULET_YES = "in your bags",
	AMULET_NO = "missing",
	STEP = "Attunement: step %d of %d",
	LEVELS_TO_GO = "%d levels to go. The attunement starts at level %d.",
	LEVELS_TO_GO_1 = "1 level to go. The attunement starts at level %d.",
	FIRE = "Fire resistance: %d",
	FIRE_HINT = "Fire resistance: %d (aim for about %d, a common target; there is no official number yet)",
	READY_FOR = "Ready for: %s",
	NOT_YET = "Not ready for any raid yet.",
	RAID_barrow = "The Barrow Deeps",
	RAID_hyjal = "Hyjal Summit",
	RAID_onyxia = "Onyxia's Lair",
	GUILD = "Your guild",
	GUILD_COUNT = "Ready: %d for Onyxia, %d at level 60",
	NOBODY = "Nobody else has the addon yet. Tell your guild!",
	NO_GUILD = "You are not in a guild: only your own status.",
	TRIAL = "Trial accounts cannot send addon messages: you see your guild, they do not see you.",
	ROW = "%s  ·  %d  ·  %s  ·  %s",
	ROW_AMULET = "amulet",
	ROW_STEP = "step %d/%d",
	ROW_FIRE = "fire %d",
	COPY = "Copy list",
	COPY_PROMPT = "Copy with Ctrl+C (name, level, amulet, attunement step, fire resistance):",
	TAG_READY = "ready for Onyxia",
	HELP = "/listos opens the page. /listos copiar gives you the guild list as text. /listos idioma es|en|auto picks the language. /listos minimapa on|off shows or hides the minimap button.",
	LANG_SET = "Language: %s.",
	LANG_AUTO = "the client's",
	COMPARTMENT = "Click to see who is ready.",
	MINIMAP_TIP = "Click: who is ready. Drag to move it around the minimap. /listos minimapa off hides it.",
	MINIMAP_ON = "Minimap button on.",
	MINIMAP_OFF = "Minimap button off (/listos minimapa on brings it back).",
}

local es = {
	BINDING_TOGGLE = "Abrir / cerrar",
	TITLE = "Listos para la raid",
	COUNTDOWN = "Las raids abren el 9 de diciembre: faltan %d días",
	COUNTDOWN_1 = "Las raids abren el 9 de diciembre: es mañana",
	COUNTDOWN_TODAY = "¡Las raids abren hoy!",
	COUNTDOWN_OPEN = "Las raids ya están abiertas.",
	YOU = "Vos",
	LEVEL = "Nivel %d",
	AMULET = "Amuleto de Fuego Dracónico",
	AMULET_YES = "en tus bolsas",
	AMULET_NO = "te falta",
	STEP = "Sintonización: paso %d de %d",
	LEVELS_TO_GO = "Te faltan %d niveles. La sintonización arranca en el nivel %d.",
	LEVELS_TO_GO_1 = "Te falta 1 nivel. La sintonización arranca en el nivel %d.",
	FIRE = "Resistencia al fuego: %d",
	FIRE_HINT = "Resistencia al fuego: %d (apuntá a unos %d, un objetivo común; todavía no hay número oficial)",
	READY_FOR = "Listo para: %s",
	NOT_YET = "Todavía no estás listo para ninguna raid.",
	RAID_barrow = "The Barrow Deeps",
	RAID_hyjal = "Cima Hyjal",
	RAID_onyxia = "Guarida de Onyxia",
	GUILD = "Tu guild",
	GUILD_COUNT = "Listos: %d para Onyxia, %d en nivel 60",
	NOBODY = "Nadie más tiene el addon todavía. ¡Pasáselo a la guild!",
	NO_GUILD = "No estás en una guild: solo tu estado.",
	TRIAL = "Las cuentas de prueba no pueden mandar mensajes de addon: ves a tu guild, pero ellos no te ven.",
	ROW = "%s  ·  %d  ·  %s  ·  %s",
	ROW_AMULET = "amuleto",
	ROW_STEP = "paso %d/%d",
	ROW_FIRE = "fuego %d",
	COPY = "Copiar lista",
	COPY_PROMPT = "Copiá con Ctrl+C (nombre, nivel, amuleto, paso de la sintonización, resistencia al fuego):",
	TAG_READY = "lista para Onyxia",
	HELP = "/listos abre la página. /listos copiar te da la lista de la guild como texto. /listos idioma es|en|auto elige el idioma. /listos minimapa on|off muestra o esconde el botón del minimapa.",
	LANG_SET = "Idioma: %s.",
	LANG_AUTO = "el del cliente",
	COMPARTMENT = "Clic para ver quién está listo.",
	MINIMAP_TIP = "Clic: quién está listo. Arrastralo para moverlo alrededor del minimapa. /listos minimapa off lo esconde.",
	MINIMAP_ON = "Botón del minimapa encendido.",
	MINIMAP_OFF = "Botón del minimapa apagado (/listos minimapa on lo devuelve).",
}

local L = {}
ns.L = L
ns.LANGS = { auto = true, es = true, en = true }

-- Fill L for a language: "es", "en", or "auto" (the client's: Spanish on esES/esMX, English otherwise).
function ns.SetLanguage(mode)
	mode = ns.LANGS[mode] and mode or "auto"
	local locale = GetLocale()
	local spanish = mode == "es" or (mode == "auto" and (locale == "esES" or locale == "esMX"))
	for k in pairs(L) do
		L[k] = nil
	end
	for k, v in pairs(en) do
		L[k] = v
	end
	if spanish then
		for k, v in pairs(es) do
			L[k] = v
		end
	end
	ns.lang = mode
	if ns.Fire then -- Core.lua loads after this file; the first fill has nobody listening yet
		ns.Fire("lang", mode)
	end
end

ns.SetLanguage("auto")
