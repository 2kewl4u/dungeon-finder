-- namespace
local _, ns = ...;

-- constants
local CATEGORY_DUNGEON = "Dungeons"
local CATEGORY_RAID = "Raids"

local DUNGEONS = {
    {
        name = "Ragefire Chasm",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 10,
        minimumLevel = 13,
        maximumLevel = 18
    },
    {
        name = "Wailing Caverns",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 10,
        minimumLevel = 15,
        maximumLevel = 25
    },
    {
        name = "The Deadmines",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 10,
        minimumLevel = 18,
        maximumLevel = 23
    },
    {
        name = "Shadowfang Keep",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 14,
        minimumLevel = 22,
        maximumLevel = 30
    },
    {
        name = "Blackfathom Deeps",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 15,
        minimumLevel = 20,
        maximumLevel = 30
    },
    {
        name = "The Stockade",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 15,
        minimumLevel = 22,
        maximumLevel = 30
    },
    {
        name = "Gnomeregan",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 19,
        minimumLevel = 24,
        maximumLevel = 34
    },
    {
        name = "Razorfen Kraul",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 25,
        minimumLevel = 30,
        maximumLevel = 40
    },
    {
        name = "Scarlet Monastery - Graveyard",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 21,
        minimumLevel = 26,
        maximumLevel = 36
    },
    {
        name = "Scarlet Monastery - Library",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 21,
        minimumLevel = 29,
        maximumLevel = 39
    },
    {
        name = "Scarlet Monastery - Armory",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 21,
        minimumLevel = 32,
        maximumLevel = 42
    },
    {
        name = "Scarlet Monastery - Cathedral",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 21,
        minimumLevel = 35,
        maximumLevel = 45
    },
    {
        name = "Uldaman",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 30,
        minimumLevel = 35,
        maximumLevel = 45
    },
    {
        name = "Razorfen Downs",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 35,
        minimumLevel = 40,
        maximumLevel = 50
    },
    {
        name = "Zul'Farrak",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 39,
        minimumLevel = 44,
        maximumLevel = 54
    },
    {
        name = "Maraudon",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 30,
        minimumLevel = 46,
        maximumLevel = 55
    },
    {
        name = "Temple of Atal'Hakkar",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 45,
        minimumLevel = 55,
        maximumLevel = 60
    },
    {
        name = "Blackrock Depths",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 48,
        minimumLevel = 52,
        maximumLevel = 60
    },
    {
        name = "Lower Blackrock Spire",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 48,
        minimumLevel = 55,
        maximumLevel = 60
    },
    {
        name = "Upper Blackrock Spire",
        category = CATEGORY_DUNGEON,
        maxPlayers = 10,
        requiredLevel = 48,
        minimumLevel = 55,
        maximumLevel = 60
    },
    {
        name = "Dire Maul",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 48,
        minimumLevel = 55,
        maximumLevel = 60
    },
    {
        name = "Scholomance",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 48,
        minimumLevel = 58,
        maximumLevel = 60
    },
    {
        name = "Stratholme",
        category = CATEGORY_DUNGEON,
        maxPlayers = 5,
        requiredLevel = 48,
        minimumLevel = 58,
        maximumLevel = 60
    }
}
ns.DUNGEONS = DUNGEONS

local RAIDS = {
    {
        name = "Zul'Gurub",
        category = CATEGORY_RAID,
        maxPlayers = 20,
        requiredLevel = 60,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Onyxia's Lair",
        category = CATEGORY_RAID,
        maxPlayers = 40,
        requiredLevel = 50,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Molten Core",
        category = CATEGORY_RAID,
        maxPlayers = 40,
        requiredLevel = 58,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Blackwing Lair",
        category = CATEGORY_RAID,
        maxPlayers = 40,
        requiredLevel = 60,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Ruins of Ahn'Qiraj",
        category = CATEGORY_RAID,
        maxPlayers = 20,
        requiredLevel = 60,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Temple of Ahn'Qiraj",
        category = CATEGORY_RAID,
        maxPlayers = 40,
        requiredLevel = 60,
        minimumLevel = 60,
        maximumLevel = 60
    },
    {
        name = "Naxxramas",
        category = CATEGORY_RAID,
        maxPlayers = 40,
        requiredLevel = 60,
        minimumLevel = 60,
        maximumLevel = 60
    }
}
ns.RAIDS = RAIDS

local DUNGEON_LIST = {}
local DUNGEON_SET = {}
table.insert(DUNGEON_LIST, { name = CATEGORY_DUNGEON })
for i, dungeon in ipairs(DUNGEONS) do
    table.insert(DUNGEON_LIST, dungeon)
    DUNGEON_SET[dungeon.name] = dungeon
end
table.insert(DUNGEON_LIST, { name = CATEGORY_RAID })
for i, raid in ipairs(RAIDS) do
    table.insert(DUNGEON_LIST, raid)
    DUNGEON_SET[raid.name] = raid
end
ns.DUNGEON_LIST = DUNGEON_LIST
ns.DUNGEON_SET = DUNGEON_SET
