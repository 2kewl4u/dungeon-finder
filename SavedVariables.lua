-- namespace
local _, ns = ...;
-- imports
local Player = ns.Player
local Group = ns.Group

-- saved variables
ns.DB = {
    lfg, lfm,
    player = Player.current(),
    group = Group.new(),
    dungeonGroups = {},
    applicants = {}
}

ns.loadSavedVariables = function()
    if (DungeonFinderDB) then
        -- assign the DB so that the variables are modified directly
        ns.DB = DungeonFinderDB
        -- restore object methods
        ns.DB.player = Player.of(ns.DB.player)
        ns.DB.group = Group.of(ns.DB.group)
        for guid, group in pairs(ns.DB.dungeonGroups) do
            ns.DB.dungeonGroups[guid] = Group.of(group)
        end
        for guid, player in pairs(ns.DB.applicants) do
            ns.DB.applicants[guid] = Player.of(player)
        end
    else
        -- initialize the DB if it was not present
        DungeonFinderDB = ns.DB
    end
end