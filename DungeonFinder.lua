-- namespace
local _, ns = ...;
-- imports
local AddonMessage = ns.AddonMessage
local Group = ns.Group
local Player = ns.Player
local ScrollList = ns.ScrollList
local utils = ns.utils
local utilsUI = ns.utilsUI

local DUNGEON_LIST = ns.DUNGEON_LIST

-- constants
local ROLE_TANK = "TANK"
local ROLE_HEALER = "HEALER"
local ROLE_DAMAGER = "DAMAGER"

local CLASS_WARRIOR = "WARRIOR"
local CLASS_PALADIN = "PALADIN"
local CLASS_HUNTER = "HUNTER"
local CLASS_ROGUE = "ROGUE"
local CLASS_PRIEST = "PRIEST"
local CLASS_DEATH_KNIGHT = "DEATHKNIGHT"
local CLASS_SHAMAN = "SHAMAN"
local CLASS_MAGE = "MAGE"
local CLASS_WARLOCK = "WARLOCK"
local CLASS_MONK = "MONK"
local CLASS_DRUID = "DRUID"
local CLASS_DEMON_HUNTER = "DEMONHUNTER"

-- communication
local ADDON_CHANNEL = "DungeonFinder"
local EVENT_LFM = "DF_LFM"
local EVENT_LFG = "DF_LFG"
local EVENT_CANCEL = "DF_CANCEL"

local refeshLFGFields
local refreshLFMFields

local function LFMBroadcast()
    ns.DB.lfm = true
    ns.DB.applicants = {}
    local msg = ns.DB.group:encode()
    local channelId = GetChannelName(ADDON_CHANNEL);
    AddonMessage.Send(EVENT_LFM, msg, "CHANNEL", channelId)
    PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
end

local function LFGBroadcast()
    ns.DB.lfg = true
    ns.DB.dungeonGroups = {}
    local msg = ns.DB.player:encode()
    local channelId = GetChannelName(ADDON_CHANNEL);
    AddonMessage.Send(EVENT_LFG, msg, "CHANNEL", channelId)
    PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
end

local function LFGCancel()
    ns.DB.lfg = false
    ns.DB.dungeonGroups = {}
    local msg = UnitGUID("player")..";LFG"
    local channelId = GetChannelName(ADDON_CHANNEL);
    AddonMessage.Send(EVENT_CANCEL, msg, "CHANNEL", channelId)
    PlaySound(SOUNDKIT.LFG_DENIED)
end

local function LFMCancel()
    ns.DB.lfm = false
    ns.DB.applicants = {}
    local msg = UnitGUID("player")..";LFM"
    local channelId = GetChannelName(ADDON_CHANNEL);
    AddonMessage.Send(EVENT_CANCEL, msg, "CHANNEL", channelId)
    PlaySound(SOUNDKIT.LFG_DENIED)
end

local function respondWithLFG(sender)
    if (ns.DB.lfg) then
        local msg = ns.DB.player:encode()
        AddonMessage.Send(EVENT_LFG, msg, "WHISPER", sender)
    end
end

local function respondWithLFM(sender)
    if (ns.DB.lfm) then
        local msg = ns.DB.group:encode()
        AddonMessage.Send(EVENT_LFM, msg, "WHISPER", sender)
    end
end

local function checkGUID(guid, sender)
    if (guid) then
        local locClass, engClass, locRace, engRace, gender,
            name, server = GetPlayerInfoByGUID(guid)
        sender = strsplit("-", sender, 2)
        return name == sender
    end
end

-- TODO add/remove register for channel on demand
local function receiveAddonMessage(prefix, message, type, sender)
    -- verify that the message of the sender contains the player as guid
    local guid, rest = strsplit(";", message, 2)
    if (not checkGUID(guid, sender)) then
        print("invalid message")
        return -- invalid message
    end

    if (prefix == EVENT_LFM and ns.DB.lfg) then
        local group = Group.decode(message)
        if (group) then
            -- filter the message if we actually need it
            if (group:needsPlayer(ns.DB.player)) then
                ns.DB.dungeonGroups[group.guid] = group
                refeshLFGFields()

                if (type == "CHANNEL") then
                    respondWithLFG(sender)
                end
            end
        end
    elseif (prefix == EVENT_LFG) then
        local player = Player.decode(message)
        if (player) then
            -- filter the players according to our group selection
            if (ns.DB.group:needsPlayer(player)) then
                ns.DB.applicants[player.guid] = player
                refreshLFMFields()

                if (type == "CHANNEL") then
                    respondWithLFM(sender)
                end
            end
        end
    elseif (prefix == EVENT_CANCEL) then
        if (rest == "LFM") then
            ns.DB.dungeonGroups[guid] = nil
            refeshLFGFields()
        elseif (rest == "LFG") then
            ns.DB.applicants[guid] = nil
            refreshLFMFields()
        end
    end
end

-- UI
local WINDOW_WIDTH = 350
local WINDOW_HEIGHT = 450

local UIFrame = CreateFrame("Frame", "DungeonFinderIU", UIParent, "UIPanelDialogTemplate")
UIFrame:SetAttribute("UIPanelLayout-defined", true)
UIFrame:SetAttribute("UIPanelLayout-enabled", true)
UIFrame:SetAttribute("UIPanelLayout-area", "left")
UIFrame:SetAttribute("UIPanelLayout-pushable", 5)
UIFrame:SetAttribute("UIPanelLayout-width", WINDOW_WIDTH)
UIFrame:SetAttribute("UIPanelLayout-whileDead", true)
UIFrame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
UIFrame:SetPoint("CENTER")
UIFrame.Title:SetText("Dungeon Finder")
HideUIPanel(UIFrame)

-- create tabs
local tabs = utilsUI.createTabs(UIFrame, { "LFG", "LFM" })
local lfgTabFrame = tabs[1].contentFrame
local lfgDungeonFrame
local lfgGroupFrame
lfgTabFrame:SetScript("OnShow", function()
    if (ns.DB.lfg) then
        lfgDungeonFrame:Hide()
        lfgGroupFrame:Show()
    else
        lfgDungeonFrame:Show()
        lfgGroupFrame:Hide()
    end
end)

--
-- THE LFG DUNGEON FRAME
--
lfgDungeonFrame = CreateFrame("Frame", nil, lfgTabFrame)
lfgDungeonFrame:SetAllPoints()

local roleInset = CreateFrame("Frame", nil, lfgDungeonFrame, "InsetFrameTemplate")
roleInset:SetPoint("TOPLEFT", lfgDungeonFrame, "TOPLEFT", 0, 0)
roleInset:SetPoint("BOTTOMRIGHT", lfgDungeonFrame, "TOPRIGHT", 0, -75)

local tankRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
tankRoleButton:SetPoint("TOPLEFT", lfgDungeonFrame, "TOPLEFT", 60, -15)
tankRoleButton.role = ROLE_TANK
--tankRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_TANK))
tankRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_TANK));
tankRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_TANK, tankRoleButton.checkButton:GetChecked())
end)
tankRoleButton:SetScript("OnShow", function()
    tankRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_TANK))
end)

local healerRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
healerRoleButton:SetPoint("LEFT", tankRoleButton, "RIGHT", 45, 0)
healerRoleButton.role = ROLE_HEALER
--healerRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_HEALER))
healerRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_HEALER));
healerRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_HEALER, healerRoleButton.checkButton:GetChecked())
end)
healerRoleButton:SetScript("OnShow", function()
    healerRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_HEALER))
end)

local damagerRoleButton = CreateFrame("Button", nil, roleInset, "DungeonFinderRoleButtonTemplate")
damagerRoleButton:SetPoint("LEFT", healerRoleButton, "RIGHT", 45, 0)
damagerRoleButton.role = ROLE_DAMAGER
--damagerRoleButton.background:SetTexCoord(GetBackgroundTexCoordsForRole(ROLE_DAMAGER))
damagerRoleButton:GetNormalTexture():SetTexCoord(GetTexCoordsForRole(ROLE_DAMAGER));
damagerRoleButton.checkButton:SetScript("OnClick", function()
    ns.DB.player:setRole(ROLE_DAMAGER, damagerRoleButton.checkButton:GetChecked())
end)
damagerRoleButton:SetScript("OnShow", function()
    damagerRoleButton.checkButton:SetChecked(ns.DB.player:hasRole(ROLE_DAMAGER))
end)

local dungeonInset = CreateFrame("Frame", nil, lfgDungeonFrame, "InsetFrameTemplate")
dungeonInset:SetPoint("TOPLEFT", roleInset, "BOTTOMLEFT", 0, 0)
dungeonInset:SetPoint("BOTTOMRIGHT", lfgDungeonFrame, "BOTTOMRIGHT", 0, 33)

local categoryFilters = {}
local dungeonScrollList = ScrollList.new("DungeonFinderDungeonScrollList", dungeonInset, 18, "LFRFrameDungeonChoiceTemplate")
dungeonScrollList:SetPoint("TOPLEFT", dungeonInset, "TOPLEFT", 0, -6)
dungeonScrollList:SetPoint("BOTTOMRIGHT", dungeonInset, "BOTTOMRIGHT", -26, 6)
dungeonScrollList:SetWidth(300)
dungeonScrollList:SetButtonHeight(16)
dungeonScrollList:SetContentProvider(function() return DUNGEON_LIST end)
dungeonScrollList:SetLabelProvider(function(index, dungeon, button)
    local playerLevel = UnitLevel("player")

    button.dungeon = dungeon
    button.instanceName:SetText(dungeon.name)
    button.level:SetPoint("RIGHT", button, "RIGHT", 0, 0)
    if (dungeon.category) then
        -- a dungeon or raid
        button.expandOrCollapseButton:Hide()
        button.isCollapsed = false
        button.instanceName:SetFontObject("GameFontNormalLeft");

        -- check the required level of the player
        if (playerLevel < dungeon.requiredLevel) then
            button.lockedIndicator:Show()
            --            button:SetScript("OnEnter", function()
            --                GameTooltip:ClearLines()
            --                GameTooltip:SetOwner(button, "ANCHOR_CURSOR")
            --                GameTooltip:AddLine("Requires Level "..dungeon.requiredLevel..".")
            --                GameTooltip:Show()
            --            end)
            --            button:SetScript("OnLeave", function()
            --                GameTooltip:Hide()
            --            end)
            button.enableButton:Disable()
            button.enableButton:Hide()
        else
            button.lockedIndicator:Hide()
            button.enableButton:Enable()
            button.enableButton:Show()
        end

        -- set checked status
        button.enableButton:SetChecked(ns.DB.player:isLookingForDungeon(dungeon))
        button.enableButton:SetScript("OnClick", function()
            if (dungeon.category) then
                ns.DB.player:setLookingForDungeon(dungeon, button.enableButton:GetChecked())
            end
        end)

        -- the level range
        button.level:Show()
        local levelText
        if (dungeon.minimumLevel == dungeon.maximumLevel) then
            levelText = tostring(dungeon.minimumLevel)
        else
            levelText = dungeon.minimumLevel.." - "..dungeon.maximumLevel
        end
        button.level:SetText("("..levelText..")")
        button.instanceName:SetPoint("RIGHT", button.level, "LEFT", -10, 0)

        -- the color for the level range
        local levelCompare
        if (playerLevel < dungeon.minimumLevel) then
            levelCompare = dungeon.minimumLevel
        elseif (playerLevel > dungeon.maximumLevel) then
            levelCompare = dungeon.maximumLevel
        else
            levelCompare = playerLevel
        end
        local difficultyColor = GetQuestDifficultyColor(levelCompare)
        button.level:SetFontObject(difficultyColor.font)

    else
        -- simply a category
        button.instanceName:SetFontObject("GameFontHighlightLeft");
        button.level:Hide()
        button.instanceName:SetPoint("RIGHT", button, "RIGHT", 0, 0)
        button.lockedIndicator:Hide()
        button.enableButton:Enable()
        button.enableButton:Show()
        
        -- enable expand / collapse
        button.expandOrCollapseButton:Show()
        button.expandOrCollapseButton:SetScript("OnClick", function()
            local state = categoryFilters[dungeon.name]
            if (state) then
                categoryFilters[dungeon.name] = nil
            else
                categoryFilters[dungeon.name] = true
            end
            dungeonScrollList:Update()
        end)
        if (categoryFilters[dungeon.name]) then
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-UP")
        else
            button.expandOrCollapseButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        end
    end
    button.enableButton:SetPoint("LEFT", button.expandOrCollapseButton, "RIGHT", 6, 0)
    button.heroicIcon:Hide()
end)
dungeonScrollList:SetFilter(function(index, dungeon)
    if (not dungeon.category or not categoryFilters[dungeon.category]) then
        return true
    end
end)
dungeonScrollList:Update()

local findGroupButton = CreateFrame("Button", nil, lfgDungeonFrame, "GameMenuButtonTemplate")
findGroupButton:SetPoint("BOTTOM", lfgDungeonFrame, "BOTTOM", 0, 6)
findGroupButton:SetSize(155, 20)
findGroupButton:SetText("Find Group")
findGroupButton:SetNormalFontObject("GameFontNormal")
findGroupButton:SetScript("OnClick", function()
    if (ns.DB.player:isLFGReady()) then
        LFGBroadcast()
        lfgDungeonFrame:Hide()
        lfgGroupFrame:Show()
    else
        PlaySound(SOUNDKIT.LFG_DENIED)
    end
end)


--
-- THE LFG GROUP FRAME
--
lfgGroupFrame = CreateFrame("Frame", nil, lfgTabFrame)
lfgGroupFrame:SetAllPoints()
if (not ns.DB.lfg) then
    lfgGroupFrame:Hide() -- only show the first frame
end

local lfgGroupLabel = lfgGroupFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfgGroupLabel:SetPoint("TOPLEFT", lfgGroupFrame, "TOPLEFT", 12, -15)
lfgGroupLabel:SetText("Dungeon Groups")
lfgGroupLabel:SetTextColor(1, 0.82, 0)

local lfgRefreshButton = CreateFrame("Button", nil, lfgGroupFrame, "DungeonFinderRefreshButtonTemplate")
lfgRefreshButton:SetSize(32, 32)
lfgRefreshButton:SetPoint("TOPRIGHT", lfgGroupFrame, "TOPRIGHT", -6, -6)
lfgRefreshButton:SetScript("OnClick", function()
    LFGBroadcast()
    refeshLFGFields()
end)

--local refreshButtonTexture = lfgRefreshButton:CreateTexture(nil, "ARTWORK")
--refreshButtonTexture:SetSize(16, 16)
--refreshButtonTexture:SetPoint("CENTER", lfgRefreshButton, "CENTER", -1, 0)
--refreshButtonTexture:SetTexture("Interface\\Buttons\\UI-RefreshButton")

local lfgGroupSearchBox = CreateFrame("EditBox", nil, lfgGroupFrame, "SearchBoxTemplate")
lfgGroupSearchBox:SetPoint("TOP", lfgGroupLabel, "BOTTOM", 0, -12)
lfgGroupSearchBox:SetPoint("LEFT", lfgGroupFrame, "LEFT", 12, 0)
lfgGroupSearchBox:SetPoint("RIGHT", lfgGroupFrame, "RIGHT", -12, 0)
lfgGroupSearchBox:SetPoint("BOTTOM", lfgGroupLabel, "BOTTOM", 0, -30)

local lfgGroupInset = CreateFrame("Frame", nil, lfgGroupFrame, "InsetFrameTemplate")
lfgGroupInset:SetPoint("TOP", lfgGroupSearchBox, "BOTTOM", 0, -12)
lfgGroupInset:SetPoint("LEFT", lfgGroupFrame, "LEFT", 0, 0)
lfgGroupInset:SetPoint("RIGHT", lfgGroupFrame, "RIGHT", 0, 0)
lfgGroupInset:SetPoint("BOTTOM", lfgGroupFrame, "BOTTOM", 0, 33)

local groupScrollList = ScrollList.new("DungeonFinderGroupScrollList", lfgGroupInset, 8, "DungeonFinderGroupButtonTemplate")
groupScrollList:SetPoint("TOPLEFT", lfgGroupInset, "TOPLEFT", 6, -6)
groupScrollList:SetPoint("BOTTOMRIGHT", lfgGroupInset, "BOTTOMRIGHT", -26, 6)
groupScrollList:SetWidth(300)
groupScrollList:SetButtonHeight(36)
groupScrollList:SetContentProvider(function()
    return ns.DB.dungeonGroups
end)
groupScrollList:SetLabelProvider(function(guid, group, button)
    button.DataDisplay.RoleCount.TankCount:SetText("?")
    button.DataDisplay.RoleCount.HealerCount:SetText("?")
    button.DataDisplay.RoleCount.DamagerCount:SetText("?")
    button.Name:SetText(group.name or "")
    button.ActivityName:SetText(group.dungeon or "")

    -- add script to whisper the leader
    button:SetScript("OnClick", function()
        ChatFrame_SendTell(group.leader)
    end)
end)

local cancelFindGroupButton = CreateFrame("Button", nil, lfgGroupFrame, "GameMenuButtonTemplate")
cancelFindGroupButton:SetPoint("BOTTOM", lfgGroupFrame, "BOTTOM", 0, 6)
cancelFindGroupButton:SetSize(155, 20)
cancelFindGroupButton:SetText("Cancel")
cancelFindGroupButton:SetNormalFontObject("GameFontNormal")
cancelFindGroupButton:SetScript("OnClick", function()
    lfgDungeonFrame:Show()
    lfgGroupFrame:Hide()
    -- send cancel group message
    LFGCancel()
end)

--{"groupfinder-icon-role-large-dps", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.6591796875, 0.6875, 0.1123046875, 0.140625, false, false},
--{"groupfinder-icon-role-large-heal", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.6455078125, 0.673828125, 0.0751953125, 0.103515625, false, false},
--{"groupfinder-icon-role-large-tank", [[Interface\LFGFrame\GroupFinder.BLP]], 29, 29, 0.62890625, 0.6572265625, 0.1123046875, 0.140625, false, false},

local lfmTabFrame = tabs[2].contentFrame
local lfmCreateFrame
local lfmInviteFrame
lfmTabFrame:SetScript("OnShow", function()
    if (ns.DB.lfm) then
        lfmCreateFrame:Hide()
        lfmInviteFrame:Show()
    else
        lfmCreateFrame:Show()
        lfmInviteFrame:Hide()
    end
end)

--
-- THE LFM CREATE GROUP FRAME
--
lfmCreateFrame = CreateFrame("Frame", nil, lfmTabFrame)
lfmCreateFrame:SetAllPoints()

local lfmGroupLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfmGroupLabel:SetPoint("TOPLEFT", lfmCreateFrame, "TOPLEFT", 12, -15)
lfmGroupLabel:SetText("Create Group")
lfmGroupLabel:SetTextColor(1, 0.82, 0)

local lfmCreateGroupInset = CreateFrame("Frame", nil, lfmCreateFrame, "InsetFrameTemplate")
lfmCreateGroupInset:SetPoint("TOP", lfmGroupLabel, "BOTTOM", 0, -12)
lfmCreateGroupInset:SetPoint("LEFT", lfmCreateFrame, "LEFT", 0, 0)
lfmCreateGroupInset:SetPoint("RIGHT", lfmCreateFrame, "RIGHT", 0, 0)
lfmCreateGroupInset:SetPoint("BOTTOM", lfmCreateFrame, "BOTTOM", 0, 33)

local lfmDungeonLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmDungeonLabel:SetPoint("TOPLEFT", lfmCreateGroupInset, "TOPLEFT", 12, -12)
lfmDungeonLabel:SetFontObject("GameFontNormalLEFT")
lfmDungeonLabel:SetText("Dungeon")

local lfmSelectDungeonDropDown = CreateFrame("Frame", nil, lfmCreateGroupInset, "UIDropDownMenuTemplate")
lfmSelectDungeonDropDown:SetPoint("TOP", lfmDungeonLabel, "BOTTOM", 0, -6)
lfmSelectDungeonDropDown:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 0, 0)
lfmSelectDungeonDropDown:SetPoint("RIGHT", lfmCreateGroupInset, "RIGHT", -12, 0)
UIDropDownMenu_SetWidth(lfmSelectDungeonDropDown, 284) -- Use in place :SetWidth
UIDropDownMenu_Initialize(lfmSelectDungeonDropDown, function(self, level, menuList)
    for index, dungeon in ipairs(DUNGEON_LIST) do
        if (dungeon.category) then
            local menuItem = UIDropDownMenu_CreateInfo()
            menuItem.text = dungeon.name
            menuItem.func = function()
                lfmSelectDungeonDropDown.value = dungeon.name
                UIDropDownMenu_SetText(lfmSelectDungeonDropDown, dungeon.name)
            end
            UIDropDownMenu_AddButton(menuItem)
        end
    end
end)

local lfmNameLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmNameLabel:SetPoint("TOP", lfmSelectDungeonDropDown, "BOTTOM", 0, -6)
lfmNameLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmNameLabel:SetHeight(20)
lfmNameLabel:SetFontObject("GameFontNormalLEFT")
lfmNameLabel:SetText("Name")

local lfmNameEditBox = CreateFrame("Editbox", nil, lfmCreateGroupInset, "InputBoxInstructionsTemplate")
lfmNameEditBox:SetPoint("TOPLEFT", lfmNameLabel, "BOTTOMLEFT", 12, 0)
lfmNameEditBox:SetSize(292, 25)
lfmNameEditBox:SetAutoFocus(false)
lfmNameEditBox:ClearFocus()

local lfmCommentLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmCommentLabel:SetPoint("TOP", lfmNameEditBox, "BOTTOM", 0, -6)
lfmCommentLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmCommentLabel:SetHeight(20)
lfmCommentLabel:SetFontObject("GameFontNormalLEFT")
lfmCommentLabel:SetText("Comment")

local lfmCommentEditBox = CreateFrame("Editbox", nil, lfmCreateGroupInset, "InputBoxInstructionsTemplate")
lfmCommentEditBox:SetPoint("TOPLEFT", lfmCommentLabel, "BOTTOMLEFT", 12, 0)
lfmCommentEditBox:SetSize(292, 25)
lfmCommentEditBox:SetAutoFocus(false)
lfmCommentEditBox:ClearFocus()

local lfmRoleLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmRoleLabel:SetPoint("TOP", lfmCommentEditBox, "BOTTOM", 0, -6)
lfmRoleLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmRoleLabel:SetHeight(20)
lfmRoleLabel:SetFontObject("GameFontNormalLEFT")
lfmRoleLabel:SetText("Roles")

local lfmRolesFrame = CreateFrame("Frame", nil, lfmCreateGroupInset, "DungeonFinderRoleSelectionFrameTemplate")
lfmRolesFrame:SetPoint("CENTER", lfmCreateGroupInset, "CENTER", 0, 0)
lfmRolesFrame:SetPoint("TOP", lfmCommentEditBox, "BOTTOM", 0, -18)

local lfmClassLabel = lfmCreateFrame:CreateFontString(nil, "ARTWORK")
lfmClassLabel:SetPoint("TOP", lfmRolesFrame, "BOTTOM", 0, -6)
lfmClassLabel:SetPoint("LEFT", lfmCreateGroupInset, "LEFT", 12, 0)
lfmClassLabel:SetHeight(20)
lfmClassLabel:SetFontObject("GameFontNormalLEFT")
lfmClassLabel:SetText("Classes")

local lfmClassesFrame = CreateFrame("Frame", nil, lfmCreateFrame, "DungeonFinderClassFrameTemplate")
lfmClassesFrame:SetPoint("CENTER", lfmCreateGroupInset, "CENTER", 0, 0)
lfmClassesFrame:SetPoint("TOP", lfmRolesFrame, "BOTTOM", 0, -28)

local createGroupButton = CreateFrame("Button", nil, lfmCreateFrame, "GameMenuButtonTemplate")
createGroupButton:SetPoint("BOTTOM", lfmCreateFrame, "BOTTOM", 0, 6)
createGroupButton:SetSize(155, 20)
createGroupButton:SetText("Create Group")
createGroupButton:SetNormalFontObject("GameFontNormal")
createGroupButton:SetScript("OnClick", function()
    -- check that all necessary fields are set
    local dungeonName = lfmSelectDungeonDropDown.value
    local groupName = lfmNameEditBox:GetText()
    local roles = {}
    for _, button in pairs(lfmRolesFrame.roleButtons) do
        if (button.checkButton:GetChecked()) then
            roles[button:GetAttribute("role")] = true
        end
    end
    local classes = {}
    for _, button in pairs(lfmClassesFrame.classButtons) do
        if (button.checkButton:GetChecked()) then
            classes[button:GetAttribute("class")] = true
        end
    end
    local comment = lfmCommentEditBox:GetText()

    if (groupName and strlen(groupName) > 0
        and dungeonName and strlen(dungeonName) > 0
        and utils.tblsize(roles) > 0
        and utils.tblsize(classes) > 0) then
        ns.DB.group = Group.new(groupName, dungeonName,
            roles, classes, nil, comment, nil, nil)
        -- send group info
        LFMBroadcast()
        lfmCreateFrame:Hide()
        lfmInviteFrame:Show()
    else
        PlaySound(SOUNDKIT.LFG_DENIED)
    end
end)

--
-- THE LFM INVITE MEMBERS FRAME
--
lfmInviteFrame = CreateFrame("Frame", nil, lfmTabFrame)
lfmInviteFrame:SetAllPoints()
lfmInviteFrame:Hide()

local lfmDungeonNameLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK", "MailFont_Large")
lfmDungeonNameLabel:SetPoint("TOPLEFT", lfmInviteFrame, "TOPLEFT", 12, -15)
lfmDungeonNameLabel:SetText("Dungeon Name")
lfmDungeonNameLabel:SetTextColor(1, 0.82, 0)

local lfmGroupNameLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK")
lfmGroupNameLabel:SetPoint("TOPLEFT", lfmDungeonNameLabel, "BOTTOMLEFT", 0, -6)
lfmGroupNameLabel:SetFontObject("GameFontHighlightLEFT")
lfmGroupNameLabel:SetText("Group Name")

local lfmGroupCommentLabel = lfmInviteFrame:CreateFontString(nil, "ARTWORK")
lfmGroupCommentLabel:SetPoint("TOPLEFT", lfmGroupNameLabel, "BOTTOMLEFT", 0, -6)
lfmGroupCommentLabel:SetFontObject("GameFontDisableSmallLEFT")
lfmGroupCommentLabel:SetText("Comment")

local lfmRefreshButton = CreateFrame("Button", nil, lfmInviteFrame, "DungeonFinderRefreshButtonTemplate")
lfmRefreshButton:SetSize(32, 32)
lfmRefreshButton:SetPoint("TOPRIGHT", lfmInviteFrame, "TOPRIGHT", -6, -6)
lfmRefreshButton:SetScript("OnClick", function()
    LFMBroadcast()
    refreshLFMFields()
end)

-- TODO show member count
--local lfmGroupMemberCountFrame = CreateFrame("Frame", nil, lfmInviteFrame, "DungeonFinderGroupDataDisplayTemplate")
--lfmGroupMemberCountFrame:SetPoint("TOPRIGHT", lfmRefreshButton, "BOTTOMRIGHT", 0, -6)

local lfmInviteInset = CreateFrame("Frame", nil, lfmInviteFrame, "InsetFrameTemplate")
lfmInviteInset:SetPoint("TOP", lfmGroupCommentLabel, "BOTTOM", 0, -12)
lfmInviteInset:SetPoint("LEFT", lfmInviteFrame, "LEFT", 0, 0)
lfmInviteInset:SetPoint("RIGHT", lfmInviteFrame, "RIGHT", 0, 0)
lfmInviteInset:SetPoint("BOTTOM", lfmInviteFrame, "BOTTOM", 0, 33)

local lfmMemberScrollList = ScrollList.new("DungeonFinderApplicantScrollList", lfmInviteInset, 8, "DungeonFinderApplicantButtonTemplate")
lfmMemberScrollList:SetPoint("TOPLEFT", lfmInviteInset, "TOPLEFT", 6, -6)
lfmMemberScrollList:SetPoint("BOTTOMRIGHT", lfmInviteInset, "BOTTOMRIGHT", -26, 6)
lfmMemberScrollList:SetWidth(300)
lfmMemberScrollList:SetButtonHeight(36)
lfmMemberScrollList:SetContentProvider(function()
    return ns.DB.applicants
end)
lfmMemberScrollList:SetLabelProvider(function(guid, player, button)
    button.PlayerName:SetText(player.name)
    button.ClassName:SetText(player.class)
    button.Level:SetText(tostring(player.level))

    -- adjust role buttons
    for i, role in ipairs({ ROLE_DAMAGER, ROLE_HEALER, ROLE_TANK }) do
        local roleIcon = button.roleIcons[i]
        if (player.roles[role]) then
            roleIcon:Show()
        else
            roleIcon:Hide()
        end
    end

    -- add script to whisper the player
    button:SetScript("OnClick", function()
        ChatFrame_SendTell(player.name)
    end)
    button.InviteButton:SetScript("OnClick", function()
        InviteUnit(player.name)
    end)
    button.DeclineButton:SetScript("OnClick", function()
        -- remove the player from the list
        ns.DB.applicants[player.guid] = nil
        refreshLFMFields()
    end)
end)
lfmMemberScrollList:Update()

local cancelCreateGroupButton = CreateFrame("Button", nil, lfmInviteFrame, "GameMenuButtonTemplate")
cancelCreateGroupButton:SetPoint("BOTTOM", lfmInviteFrame, "BOTTOM", 0, 6)
cancelCreateGroupButton:SetSize(155, 20)
cancelCreateGroupButton:SetText("Cancel")
cancelCreateGroupButton:SetNormalFontObject("GameFontNormal")
cancelCreateGroupButton:SetScript("OnClick", function()
    lfmCreateFrame:Show()
    lfmInviteFrame:Hide()
    PlaySound(SOUNDKIT.LFG_DENIED)
    -- send cancel group message
    LFMCancel()
end)
-- update the dungeon info in the label frames
lfmInviteFrame:SetScript("OnShow", function()
    lfmDungeonNameLabel:SetText(ns.DB.group.dungeon)
    lfmGroupNameLabel:SetText(ns.DB.group.name)
    lfmGroupCommentLabel:SetText(ns.DB.group.comment)
end)

refeshLFGFields = function()
    groupScrollList:Update()
end

refreshLFMFields = function()
    lfmMemberScrollList:Update()
end
-- TODO add notifications

--lfmCreateFrame:Hide()
--lfmInviteFrame:Show()

SLASH_DungeonFinder1 = "/lfg"
SLASH_DungeonFinder2 = "/lfm"
SLASH_DungeonFinder3 = "/dungeonfinder"
SlashCmdList["DungeonFinder"] = function(s)
    if (not UnitAffectingCombat("player")) then
        JoinChannelByName(ADDON_CHANNEL)
        if (UIFrame:IsShown()) then
            HideUIPanel(UIFrame)
        else
            ShowUIPanel(UIFrame)
        end
    end
end


local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("VARIABLES_LOADED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("RAID_TARGET_UPDATE")
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_LFM)
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_LFG)
C_ChatInfo.RegisterAddonMessagePrefix(EVENT_CANCEL)
eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
    if (event == "VARIABLES_LOADED") then
        ns.loadSavedVariables()
    elseif (event == "CHAT_MSG_ADDON") then
                print("received addon message from "..arg4)
                print(arg2)
        if (arg1 == EVENT_LFM or arg1 == EVENT_LFG or arg1 == EVENT_CANCEL) then
            AddonMessage.Receive(arg1, arg2, arg3, arg4, receiveAddonMessage)
        end
    elseif (event == "RAID_TARGET_UPDATE") then
        -- when joining a group, cancel the LFG
        if (IsInGroup() and ns.DB.lfg) then
            LFGCancel()
            lfgDungeonFrame:Show()
            lfgGroupFrame:Hide()
        end
    end
end)

print("Addon loaded... DungeonFinder "..GetAddOnMetadata("DungeonFinder", "Version"))
