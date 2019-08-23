-- namespace
local _, ns = ...;
-- imports
local utils = ns.utils

local Group = {
    guid,
    name,
    dungeon,
    -- a set of roles that are searched for the group
    roles,
    -- a set of classes that are searched for the group
    classes,
    created,
    comment,
    leader,
    -- map role - count NYI
    members
}
Group.__index = Group
ns.Group = Group

function Group.of(groupInfo)
    return setmetatable(groupInfo, Group)
end

function Group.new(name, dungeon, roles, classes, created, comment, leader, members)
    local self = setmetatable({}, Group)
    self.guid = UnitGUID("player")
    self.name = name or ""
    self.dungeon = dungeon or ""
    self.roles = roles or {}
    self.classes = classes or {}
    self.created = created or time()
    self.comment = comment or ""
    self.leader = leader or UnitName("player")
    self.members = members or {}
    return self
end

function Group:needsPlayer(player)
    local group = self
    -- check that the player has the correct role
    local hasRole = false
    for role in pairs(group.roles) do
        if (player.roles[role]) then
            hasRole = true
            break;
        end
    end
    if (not hasRole) then return false end
    
    -- check that the player has the correct class
    if (not group.classes[player.class]) then return false end
    
    -- check that the player is looking for the dungeon
    if (not player.dungeons[group.dungeon]) then return false end
    
    return true
end

function Group:encode()
    local group = self
    local roles = utils.toCSV(group.roles, function(k,v) return k end)
    local classes = utils.toCSV(group.classes, function(k,v) return k end)

    local list = {
        group.guid,
        group.name,
        group.dungeon,
        roles,
        classes,
        tostring(group.created),
        group.comment,
        group.leader
    }
    return utils.toCSV(list, function(k, v) return v end, ";")
end

function Group.decode(encoded)
    if (encoded) then

        local list = utils.fromCSV(encoded, function(list, element)
            table.insert(list, element)
        end, ";")
        
        local guid = list[1]
        local name = list[2]
        local dungeon = list[3]
        local roles = list[4]
        local classes = list[5]
        local created = tonumber(list[6])
        local comment = list[7]
        local leader = list[8]
        
        -- decode the roles and classes
        roles = utils.fromCSV(roles, function(list, element)
            list[element] = true
        end)
        classes = utils.fromCSV(classes, function(list, element)
            list[element] = true
        end)
        
        local group = Group.new(name, dungeon, roles, classes, created, comment, leader)
        group.guid = guid
        return group
    end
end
