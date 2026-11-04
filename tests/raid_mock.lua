-- What Listos para la raid needs on top of wow_mock.lua and guild_mock.lua.
MOCK.faction = "Alliance"
MOCK.doneQuests = {}
MOCK.counts = {} -- itemID -> count (bags and bank)
MOCK.fireRes = 0
Enum.Damageclass = { Physical = 0, Holy = 1, Fire = 2, Nature = 3, Frost = 4, Shadow = 5, Arcane = 6 }
OKAY = "Okay"
function UnitFactionGroup(unit)
	return MOCK.faction, MOCK.faction
end
C_QuestLog.IsQuestFlaggedCompleted = function(id)
	return MOCK.doneQuests[id] == true
end
C_Item.GetItemCount = function(id, includeBank)
	assert(includeBank == true, "count the bank too")
	return MOCK.counts[id] or 0
end
function UnitResistance(unit, school)
	assert(school == Enum.Damageclass.Fire)
	return MOCK.fireRes, MOCK.fireRes, MOCK.fireRes, 0
end
