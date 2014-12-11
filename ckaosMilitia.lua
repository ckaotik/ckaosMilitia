local addonName, addon, _ = ...
addon = CreateFrame('Frame')

--  Use this section to enable/disable specific features
-- --------------------------------------------------------
local skipBattleAnimation    = true
local showExtraMissionInfo   = true
local showRewardCounts       = true
local desaturateUnavailable  = true
local showFollowerReturnTime = true
local showRequiredResources  = true
local setMissionFrameMovable = true
local showOnMissionCounters  = true
local notifyLevelQualityChange = true
local doubleClickToAddFollower = true
local showLandingPageBuildingInfo = true
-- --------------------------------------------------------
-- DO NOT TOUCH ANYTHING BELOW THIS POINT!

-- GLOBALS: _G, C_Garrison, C_Timer, GameTooltip, GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonRecruitSelectFrame, GarrisonLandingPage, ITEM_QUALITY_COLORS
-- GLOBALS: CreateFrame, IsAddOnLoaded, RGBTableToColorCode, HybridScrollFrame_GetOffset, GetItemInfo, BreakUpLargeNumbers, HandleModifiedItemClick
-- GLOBALS: GarrisonMissionComplete_FindAnimIndexFor, GarrisonMissionComplete_AnimRewards
-- GLOBALS: pairs, ipairs, wipe, table, strsplit, tostring, strjoin, strrep
local tinsert, tsort = table.insert, table.sort
local emptyTable = {}

local propertyOrder = {'iLevel', 'level', 'quality', 'name'}
local function SortFollowers(a, b)
	local dataA, dataB = C_Garrison.GetFollowerInfo(a), C_Garrison.GetFollowerInfo(b)
	for _, property in ipairs(propertyOrder) do
		if dataA[property] ~= dataB[property] then
			return dataA[property] < dataB[property]
		end
	end
end

local mechanics, traits = {}, {}
local abilities = {
	ability = {},
	trait = {},
}
local function ScanFollowerAbilities()
	wipe(abilities.ability)
	wipe(abilities.trait)
	for index, follower in pairs(C_Garrison.GetFollowers()) do
		if follower.isCollected then
			for abilityIndex, ability in pairs(C_Garrison.GetFollowerAbilities(follower.followerID)) do
				local dataTable, key
				-- 232: dancer counters danger zones
				if ability.isTrait and ability.id ~= 232 then
					key = ability.id
					dataTable = abilities.trait
					-- store trait info
					traits[ability.id] = traits[ability.id] or {
						icon = ability.icon,
						name = ability.name,
						description = ability.description,
					}
				else
					local mechanicID, mechanicInfo = next(ability.counters)
					key = mechanicID
					dataTable = abilities.ability
					-- store reference to info table
					mechanics[mechanicID] = mechanicInfo
				end

				if not dataTable[key] then dataTable[key] = {} end
				tinsert(dataTable[key], follower.followerID)
				tsort(dataTable[key], SortFollowers)
			end
		end
	end
	return abilities
end

local function GetMissionTimeLeft(followerID)
	for index, mission in ipairs(GarrisonMissionFrame.MissionTab.MissionList.inProgressMissions) do
		for _, missionFollowerID in ipairs(mission.followers) do
			if missionFollowerID == followerID then
				return mission.timeLeft
			end
		end
	end
end

--[[ local counteredMechanics = {}
local function GetCounteredMechanics(followerID)
	wipe(counteredMechanics)
	for index = 1, #C_Garrison.GetFollowerAbilities(followerID) do
		local abilityID = C_Garrison.GetFollowerAbilityAtIndex(followerID, index)
		if abilityID ~= 0 then
			local id, name, icon = C_Garrison.GetFollowerAbilityCounterMechanicInfo(abilityID)
			counteredMechanics[id] = icon
		end
	end
	return counteredMechanics
end --]]

local function ShowAbilityTooltip(self)
	local followers = self.threatID and abilities.ability[self.threatID]
	if not followers then return end

	if self.description then
		GameTooltip:AddLine(self.description, 255, 255, 255, true)
		GameTooltip:AddLine(' ')
	end

	for _, followerID in pairs(followers) do
		local data = C_Garrison.GetFollowerInfo(followerID)
		local qualityColor = RGBTableToColorCode(_G.ITEM_QUALITY_COLORS[data.quality])
		local displayLevel
		if data.level < 100 then
			-- display invisible zero to keep padding intact
			displayLevel = '|c000000000|r'..qualityColor..data.level..'|r '
		else
			displayLevel = qualityColor .. data.iLevel .. '|r '
		end
		local status, name = data.status or '', data.name
		local color  = _G.YELLOW_FONT_COLOR
		if status == _G.GARRISON_FOLLOWER_INACTIVE then
			color = _G.GRAY_FONT_COLOR
			name  = _G.GRAY_FONT_COLOR_CODE .. name .. '|r'
		elseif status == _G.GARRISON_FOLLOWER_ON_MISSION then
			color = _G.RED_FONT_COLOR
		end
		if showFollowerReturnTime and status == _G.GARRISON_FOLLOWER_ON_MISSION then
			-- follower will return from her mission
			status = GetMissionTimeLeft(followerID)
		end
		GameTooltip:AddDoubleLine(displayLevel..name, status, nil, nil, nil, color.r, color.g, color.b)
	end
	GameTooltip:Show()
end

local function GetTab(frame, index)
	local tab = addon[index]
	if not tab then
		tab = CreateFrame('CheckButton', nil, nil, 'SpellBookSkillLineTabTemplate', index)
		tab:HookScript('OnEnter', ShowAbilityTooltip)
		tab:RegisterForClicks() -- disable clicking
		tab:Show()
		local count = tab:CreateFontString(nil, nil, 'NumberFontNormalSmall')
		      count:SetAllPoints()
		      count:SetJustifyH('RIGHT')
		      count:SetJustifyV('BOTTOM')
		tab.count = count
		addon[index] = tab
	end

	tab:SetParent(frame)
	tab:ClearAllPoints()
	tab:SetPoint('TOPLEFT', frame, 'TOPRIGHT', frame == GarrisonLandingPage and -10 or 0, 16 - 44*index)
	return tab
end

local function UpdateFollowerTabs(frame)
	-- don't update for invisible frames
	if not frame or not frame:IsShown() then return end

	ScanFollowerAbilities()
	local index = 1
	for threatID, followers in pairs(abilities.ability) do
		local numAvailable, numFollowers = #followers, #followers
		for _, followerID in pairs(followers) do
			local data = C_Garrison.GetFollowerInfo(followerID)
			if data.status and data.status ~= _G.GARRISON_FOLLOWER_IN_PARTY then
				numAvailable = numAvailable - 1
				if data.status == _G.GARRISON_FOLLOWER_INACTIVE then
					-- don't count inactive followers in tab count
					numFollowers = numFollowers - 1
				end
			end
		end

		local tab = GetTab(frame, index)
		tab.threatID = threatID
		local threatInfo = mechanics[threatID]
		tab:SetNormalTexture(threatInfo.icon)
		tab.tooltip = ('|T%1$s:0|t %2$s'):format(threatInfo.icon, threatInfo.name)
		tab.description = threatInfo.description
		tab.count:SetText(numAvailable ~= numFollowers and ('%d/%d'):format(numAvailable, numFollowers) or numFollowers)
		index = index + 1
	end
end

-- allow to immediately click the reward chest
local function SkipBattleAnimation(self, missionID, canComplete, success)
	self.Stage.EncountersFrame.FadeOut:Play()
	self.animIndex = GarrisonMissionComplete_FindAnimIndexFor(GarrisonMissionComplete_AnimRewards) - 1
	self.animTimeLeft = 0
end

-- add extra info to mission list for easier overview
local function UpdateMissionList()
	local self     = GarrisonMissionFrame.MissionTab.MissionList
	local active   = self.showInProgress
	local missions = active and self.inProgressMissions or self.availableMissions
	local _, numRessources = GetCurrencyInfo(824)

	local offset  = HybridScrollFrame_GetOffset(self.listScroll)
	local buttons = self.listScroll.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		local mission = missions[i + offset]
		if button:IsShown() then
			if not button.threats then button.threats = {} end
			if active then
				-- show success chance
				local success = C_Garrison.GetRewardChance(mission.missionID)
				if not button.successChance then
					button.successChance = button:CreateFontString(nil, nil, 'GameFontHighlightLarge')
					button.successChance:SetAllPoints(button.MissionType)
				end
				button.successChance:SetText(success..'%')
				button.successChance:Show()
			elseif button.successChance then
				button.successChance:Hide()
			end

			-- show number of followers
			if not button.followers then
				button.followers = button:CreateFontString(nil, nil, 'GameFontNormal')
				button.followers:SetPoint('CENTER', button, 'TOPLEFT', 40, -16)
			end
			local icon = '|TInterface\\FriendsFrame\\UI-Toast-FriendOnlineIcon:0:0:0:0:32:32:4:26:4:26|t'
			button.followers:SetText(strrep(icon, mission.numFollowers))

			-- show required abilities
			local _, _, env, envDesc, envIcon, _, _, enemies = C_Garrison.GetMissionInfo(mission.missionID)
			local numThreats = 1
			for j = 1, #enemies do
				for threatID, threat in pairs(enemies[j].mechanics) do
					local threatButton = button.threats[numThreats]
					if not threatButton then
						threatButton = CreateFrame('Frame', nil, button, 'GarrisonMissionMechanicTemplate', numThreats)
						if numThreats == 1 then
							threatButton:SetPoint('TOPLEFT', button.Title, 'BOTTOMLEFT', 0, -2)
						else
							threatButton:SetPoint('LEFT', button.threats[numThreats-1], 'RIGHT', 8, 0)
						end
						button.threats[numThreats] = threatButton
					end
					threatButton.threatID = threatID
					threatButton.info = threat
					threatButton.Icon:SetTexture(threat.icon)
					threatButton:Show()

					-- desaturate threats we cannot counter
					if not active and desaturateUnavailable then
						local numCounters = 0
						for _, followerID in ipairs(abilities.ability[threatID] or emptyTable) do
							if C_Garrison.GetFollowerLevel(followerID) + 2 >= mission.level
								and C_Garrison.GetFollowerItemLevelAverage(followerID) + 14 >= mission.iLevel
								and not C_Garrison.GetFollowerStatus(followerID) then
								-- must have high level, high gear and be available
								numCounters = numCounters + 1
							end
						end
						-- might have used up followers for previous counters
						for prevThreatIndex = 1, numThreats - 1 do
							if button.threats[prevThreatIndex].threatID == threatID then
								numCounters = numCounters - 1
							end
						end
						threatButton.Icon:SetDesaturated(numCounters < 1)
						threatButton.Icon:SetAlpha(numCounters < 1 and 0.5 or 1)
					else
						threatButton.Icon:SetDesaturated(false)
						threatButton.Icon:SetAlpha(1)
					end

					numThreats = numThreats + 1
				end
			end
			-- move title text
			if numThreats > 1 then
				local anchorFrom, relativeTo, anchorTo, xOffset, yOffset = button.Title:GetPoint()
				button.Title:SetPoint(anchorFrom, relativeTo, anchorTo, xOffset, yOffset + 10)
			end

			if showRequiredResources and not active then
				local duration = mission.duration
				-- TODO: add more steps to colorize by duration
				if mission.durationSeconds >= _G.GARRISON_LONG_MISSION_TIME then
					duration = _G.GARRISON_LONG_MISSION_TIME_FORMAT:format(mission.duration)
				end
				button.Summary:SetDrawLayer('OVERLAY') -- fix our icon layer
				button.Summary:SetFormattedText('(%2$s, %3$s%1$s|r |TInterface\\Icons\\inv_garrison_resource:0:0:0:0|t)',
					mission.cost or 0, duration, (mission.cost or 0) > numRessources and _G.RED_FONT_COLOR_CODE or '')
			end

			-- hide unused threat buttons
			while button.threats[numThreats] do
				button.threats[numThreats]:Hide()
				numThreats = numThreats + 1
			end
		end
	end
end

local function GetPrettyAmount(value)
	-- mini money formatter: only handles values > 0
	value = tostring(value)
	local gold, silver, copper = value:sub(1, -5), value:sub(-4, -3), value:sub(-2, -1)
	      gold, silver, copper = (gold or 0)*1, (silver or 0)*1, (copper or 0)*1
	local stringFormat = strjoin('',
		gold > 0 and '%1$s' or '', gold > 0 and '|cffffd700g|r' or '',
		silver > 0 and '%2$02d' or '', silver > 0 and '|cffc7c7cfs|r' or '',
		copper > 0 and '%3$02d' or '', copper > 0 and '|cffeda55fc|r' or '')
	return (stringFormat):format(gold, silver, copper)
end

local function OnRewardClick(self, btn, up)
	HandleModifiedItemClick(self.link)
end

-- show reward counts
local function UpdateMissionRewards(self, rewards, numRewards)
	if numRewards <= 0 then return end
	local index = 1
	for id, reward in pairs(rewards) do
		local button = self.Rewards[index]
		local quantity = reward.quantity or reward.followerXP
		if not reward.itemID then
			if reward.currencyID == 0 then
				-- gold coin reward
				quantity = GetPrettyAmount(quantity)
			else
				-- garrison resources/apexis shards/followerXP/playerXP
				quantity = BreakUpLargeNumbers(quantity)
			end
		elseif reward.quantity == 1 then
			-- show item level
			local _, link, quality, iLevel = GetItemInfo(reward.itemID)
			if iLevel and iLevel > 1 then
				quantity = ITEM_QUALITY_COLORS[quality or _G.LE_ITEM_QUALITY_COMMON].hex .. iLevel .. '|r'
			end
		end
		if quantity and quantity ~= 1 then
			button.Quantity:Show()
			button.Quantity:SetText(quantity)
		end
		index = index + 1
	end
end

addon:SetScript('OnEvent', function(self, event, ...)
	if self[event] then self[event](self, event, ...) end
end)

addon:RegisterEvent('GARRISON_MISSION_NPC_OPENED')
function addon:GARRISON_MISSION_NPC_OPENED()
	UpdateFollowerTabs(GarrisonMissionFrame)
end
addon:RegisterEvent('GARRISON_RECRUITMENT_NPC_OPENED')
function addon:GARRISON_RECRUITMENT_NPC_OPENED()
	UpdateFollowerTabs(GarrisonRecruiterFrame)
	UpdateFollowerTabs(GarrisonRecruitSelectFrame)
end
addon:RegisterEvent('GARRISON_SHOW_LANDING_PAGE')
function addon:GARRISON_SHOW_LANDING_PAGE()
	UpdateFollowerTabs(GarrisonLandingPage)
end
addon:RegisterEvent('GARRISON_FOLLOWER_LIST_UPDATE')
function addon:GARRISON_FOLLOWER_LIST_UPDATE()
	for _, frame in pairs({GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage, GarrisonRecruitSelectFrame}) do
		UpdateFollowerTabs(frame)
	end
end

if notifyLevelQualityChange then
	addon:RegisterEvent('GARRISON_FOLLOWER_XP_CHANGED')
	function addon:GARRISON_FOLLOWER_XP_CHANGED(event, followerID, xpGain, oldXP, oldLevel, oldQuality)
		-- local info = C_Garrison.GetFollowerInfo(followerID) -- .level, .iLevel, .quality
		local _, _, level, quality, currXP, maxXP = C_Garrison.GetFollowerMissionCompleteInfo(followerID)
		local name = C_Garrison.GetFollowerLink(followerID)

		local color = _G.ITEM_QUALITY_COLORS[oldQuality].hex
		if quality > oldQuality then
			local newSkills
			if quality == _G.LE_ITEM_QUALITY_EPIC then
				-- new ability at epic quality
				local abilityID = C_Garrison.GetFollowerAbilityAtIndex(followerID, 2)
				newSkills = C_Garrison.GetFollowerAbilityLink(abilityID)
			end
			-- new trait at rare & epic quality
			local traitID = C_Garrison.GetFollowerTraitAtIndex(followerID, quality)
			newSkills = (newSkills and newSkills..' and ' or '') .. C_Garrison.GetFollowerAbilityLink(traitID)

			print(('%1$s%2$s|r turned %4$s%3$s|r and learned %5$s'):format(color, name, _G['BATTLE_PET_BREED_QUALITY'..(quality+1)], _G.ITEM_QUALITY_COLORS[quality].hex, newSkills))
		elseif level > oldLevel then
			print(('%1$s%2$s|r turned %4$d!'):format(color, name, oldLevel, level))
		end
	end
end

if skipBattleAnimation then
	hooksecurefunc('GarrisonMissionComplete_OnMissionCompleteResponse', SkipBattleAnimation)
end
if showExtraMissionInfo then
	hooksecurefunc('GarrisonMissionList_Update', UpdateMissionList)
	hooksecurefunc(GarrisonMissionFrame.MissionTab.MissionList.listScroll, 'update', UpdateMissionList)
	GarrisonMissionFrame.MissionTab.MissionPage.CloseButton:HookScript('OnClick', UpdateMissionList)
end
if showRewardCounts then
	hooksecurefunc('GarrisonMissionButton_SetRewards', UpdateMissionRewards)
end
if showOnMissionCounters then
	-- note: this will still only show counters for followers that meet level/ilevel requirements
	hooksecurefunc('GarrisonFollowerButton_UpdateCounters', function(button, follower, showCounters)
		if follower.status ~= _G.GARRISON_FOLLOWER_ON_MISSION then return end
		local counters = GarrisonMissionFrame.followerCounters and GarrisonMissionFrame.followerCounters[follower.followerID]
		if not counters or #counters < 1 then return end
		for i = 1, #counters do
			if i > 4 then break end
			GarrisonFollowerButton_SetCounterButton(button, i, counters[i])
		end
		button.Counters[1]:SetPoint('TOPRIGHT', -8, #counters <= 2 and -16 or -4)
	end)
end
if doubleClickToAddFollower then
	for index, button in ipairs(GarrisonMissionFrame.FollowerList.listScroll.buttons) do
		button:HookScript('OnDoubleClick', function(self, btn)
			if GarrisonMissionFrame.selectedTab ~= 1 then return end
			-- collapse button
			self:GetScript('OnClick')(self, btn)

			-- add to mission
			local info = C_Garrison.GetFollowerInfo(self.id)
			if info.status == GARRISON_FOLLOWER_IN_PARTY then
				local missionID = GarrisonMissionFrame.MissionTab.MissionPage.missionInfo.missionID
				C_Garrison.RemoveFollowerFromMission(missionID, self.id)
			elseif not info.status then
				-- cannot add inactive/on mission/... followers
				GarrisonMissionPage_AddFollower(self.id)
			end
			GarrisonMissionPage_UpdateParty()
		end)
	end
end
if setMissionFrameMovable then
	local frame = GarrisonMissionFrame
	      frame:SetMovable(true)
	frame:CreateTitleRegion():SetAllPoints(frame.TopBorder)
end

if showLandingPageBuildingInfo then
	-- show garrison buildings & plans on landing page
	local function SortBySize(a, b)
		local aSort, bSort = a.uiTab <= 2 and a.uiTab or -1, b.uiTab <= 2 and b.uiTab or -1
		if aSort ~= bSort then
			return aSort > bSort
		else
			return a.buildingID < b.buildingID
		end
	end
	local plotEmpty = {
		[0] = _G.GARRISON_EMPTY_PLOT_SMALL,
		[1] = _G.GARRISON_EMPTY_PLOT_MEDIUM,
		[2] = _G.GARRISON_EMPTY_PLOT_LARGE,
	}
	local function OnBuildingEnter(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOP')
		local _, name, _, icon, description, rank, _, _, _, _, _, _, _, upgrades, canUpgrade, isMaxLevel, _, _, _, _, isBeingBuilt, _, _, _, canCompleteBuild = C_Garrison.GetOwnedBuildingInfo(self.plot or 0)
		if not name then
			GameTooltip:AddLine(plotEmpty[self.size] or _G.GARRISON_BUILDING_LOCKED)
		else
			GameTooltip:AddDoubleLine('|T'..icon..':0|t '..name, isMaxLevel and '' or _G.GARRISON_BUILDING_LEVEL_TOOLTIP_TEXT:format(rank))
			GameTooltip:AddLine(description, 255, 255, 255, true)

			if not isMaxLevel and not isBeingBuilt and not canCompleteBuild then
				local _, _, _, _, upgradedRank, currencyID, currencyAmount, goldAmount, buildTime, upgradedDescription = C_Garrison.GetBuildingUpgradeInfo(self.building or 0)
				local _, _, _, _, _, upgradeNeedsPlan = C_Garrison.GetBuildingTooltip(upgrades[rank+1])
				GameTooltip:AddLine('|n'.._G.GARRISON_BUILDING_LEVEL_UPGRADE:format(upgradedRank))
				GameTooltip:AddLine(upgradedDescription, 255, 255, 255, true)
				if upgradeNeedsPlan then
					GameTooltip:AddLine(_G.GARRISON_BUILDING_PLANS_REQUIRED, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
				end
				if currencyAmount then
					local costs = _G.COSTS_LABEL ..' '.. Garrison_GetTotalCostString(currencyAmount, goldAmount) ..'  '.. buildTime .. '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t'
					GameTooltip:AddLine(costs)
				end
			end
		end
		GameTooltip:Show()
	end
	local function UpdateBuildings()
		local buildings = GarrisonLandingPage.Report.Buildings
		local buildingData = C_Garrison.GetBuildings()
		table.sort(buildingData, SortBySize)

		for i, building in ipairs(buildingData) do
			local _, name, _, icon, description, rank = C_Garrison.GetOwnedBuildingInfo(building.plotID)
			buildings[i].building = building.buildingID
			buildings[i].plot = building.plotID
			buildings[i].size = building.uiTab
			if icon then
				buildings[i]:SetNormalTexture(icon)
			end
		end
	end
	GarrisonLandingPage:HookScript('OnShow', function(self)
		if self.Report:IsShown() then
			if not self.Report.Buildings then
				local numBuildings = 2+2+3+4 -- large + medium + small + utility
				self.Report.Buildings = CreateFrame('Frame', nil, self.Report)
				self.Report.Buildings:SetPoint('BOTTOMLEFT', 38, 40)
				self.Report.Buildings:SetSize(numBuildings*26, 26)

				for i = 1, numBuildings do
					local button = CreateFrame('Button', nil, self.Report.Buildings, nil, i)
					      button:SetSize(26, 26)
					      button:SetNormalTexture('Interface\\Icons\\inv_misc_questionmark')
					if i == 1 then
						button:SetPoint('BOTTOMLEFT', self.Report.Buildings, 'BOTTOMLEFT', 2, 0)
					else
						button:SetPoint('BOTTOMLEFT', self.Report.Buildings[i-1], 'BOTTOMRIGHT', 2, 0)
					end
					button:SetScript('OnEnter', OnBuildingEnter)
					button:SetScript('OnLeave', GameTooltip_Hide)
					self.Report.Buildings[i] = button
				end
			end
			UpdateBuildings()
			self.Report.Buildings:Show()
		elseif self.Report.Buildings then
			self.Report.Buildings:Hide()
		end
	end)
end

-- initialize on the currently shown frame
ScanFollowerAbilities()
C_Timer.After(0.1, addon.GARRISON_FOLLOWER_LIST_UPDATE)
