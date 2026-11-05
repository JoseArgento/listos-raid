local _, ns = ...

local L = {
	TITLE = "Ready for the raid",
	COUNTDOWN = "Raids open on December 9: %d days to go",
	COUNTDOWN_TODAY = "Raids open today!",
	COUNTDOWN_OPEN = "Raids are open.",
	YOU = "You",
	LEVEL = "Level %d",
	AMULET = "Drakefire Amulet",
	AMULET_YES = "in your bags",
	AMULET_NO = "missing",
	STEP = "Attunement: step %d of %d",
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
	HELP = "/listos opens the panel. /listos copiar gives you the guild list as text.",
	COMPARTMENT = "Click to see who is ready.",
}

local es = {
	TITLE = "Listos para la raid",
	COUNTDOWN = "Las raids abren el 9 de diciembre: faltan %d días",
	COUNTDOWN_TODAY = "¡Las raids abren hoy!",
	COUNTDOWN_OPEN = "Las raids ya están abiertas.",
	YOU = "Vos",
	LEVEL = "Nivel %d",
	AMULET = "Amuleto de Fuego Dracónico",
	AMULET_YES = "en tus bolsas",
	AMULET_NO = "te falta",
	STEP = "Sintonización: paso %d de %d",
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
	HELP = "/listos abre el panel. /listos copiar te da la lista de la guild como texto.",
	COMPARTMENT = "Clic para ver quién está listo.",
}

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
	for k, v in pairs(es) do
		L[k] = v
	end
end
ns.L = L
