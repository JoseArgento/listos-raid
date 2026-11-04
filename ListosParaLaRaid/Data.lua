local _, ns = ...

-- What the raids of December 9 ask for. Sources: Blizzard's announcement and the launch guides (4/11/2026):
-- The Barrow Deeps (10 players), Hyjal Summit (20) and Onyxia's Lair (40), all level 60. Only Onyxia has an
-- attunement: the Drakefire Amulet in your bags, per character in Forever (no "Chipped" amulet for sale).
-- ⏳ The quest IDs are Classic's, as the guides list them for Forever; if Forever changed some, that step
-- simply never shows as done, and the amulet still says you are ready.

ns.OPEN = { year = 2026, month = 12, day = 9 } -- ⏳ the hour depends on the region's weekly reset
ns.LEVEL = 60
ns.AMULET = 16309 -- Drakefire Amulet
ns.FIRE_GOAL = 100 -- a common target for Onyxia's breath (guides: "build fire resistance"); only a hint

ns.RAIDS = {
	{ key = "barrow", size = 10, attune = false },
	{ key = "hyjal", size = 20, attune = false },
	{ key = "onyxia", size = 40, attune = true },
}

-- Onyxia's attunement, step by step (conquestcapped.com, "WoW Forever Onyxia attunement", 2026).
ns.CHAIN = {
	Alliance = { 4182, 4183, 4184, 4185, 4186, 4223, 4224, 4241, 4242, 4264, 4282, 4322, 6402, 6403, 6501, 6502 },
	Horde = { 4903, 4941, 4974, 6566, 6567, 6568, 6569, 6570, 6582, 6583, 6584, 6585, 6601, 6602 },
}
