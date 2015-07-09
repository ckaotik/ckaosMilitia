local addonName, addon, _ = ...
_G[addonName] = addon

-- GLOBALS: _G, C_Garrison, C_Timer, GameTooltip, GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonRecruitSelectFrame, GarrisonLandingPage, GarrisonLandingPageReport, ITEM_QUALITY_COLORS, LE_ITEM_QUALITY_COMMON
-- GLOBALS: GarrisonFollowerList_UpdateFollowers, GarrisonThreatCountersFrame, GarrisonFollowerTooltip, GarrisonFollowerTooltip_Show, GarrisonBuildingFrame, FloatingGarrisonMissionTooltip
-- GLOBALS: CreateFrame, IsAddOnLoaded, RGBTableToColorCode, HybridScrollFrame_GetOffset, GetItemInfo, BreakUpLargeNumbers, HandleModifiedItemClick, GetCurrencyInfo
-- GLOBALS: GarrisonLandingPageMinimapButton, GarrisonFollowerButton_SetCounterButton, GarrisonLandingPageReportList_FormatXPNumbers
-- GLOBALS: pairs, ipairs, wipe, table, strsplit, tostring, strjoin, strrep, next, hooksecurefunc, tContains, select, rawget, setmetatable

local tinsert, tremove, tsort = table.insert, table.remove, table.sort
local floor = math.floor
local emptyTable = {}
local threatList = C_Garrison.GetAllEncounterThreats(LE_FOLLOWER_TYPE_GARRISON_6_0)
local shipyardThreatList = C_Garrison.GetAllEncounterThreats(LE_FOLLOWER_TYPE_SHIPYARD_6_2)
local THREATS = {}
for _, threat in pairs(threatList) do THREATS[threat.id] = threat end
for _, threat in pairs(shipyardThreatList) do THREATS[threat.id] = threat end

addon.frame = CreateFrame('Frame')
addon.frame:SetScript('OnEvent', function(self, event, ...)
	if addon[event] then addon[event](addon, event, ...) end
end)
addon.frame:RegisterEvent('ADDON_LOADED')

addon.defaults = {
	showExtraMissionInfo = true,
	showMissionThreats = true,
	showRewardCounts = true,
	desaturateUnavailable = true,
	showFollowerReturnTime = true,
	showRequiredResources = true,
	setMissionFrameMovable = true,
	showFollowerAbilityOptions = true,
	showMinimapBuildings = true,
	doubleClickToAddFollower = true,
	replaceAbilityWithThreat = true,
	missionCompleteFollowerTooltips = true,
	showMissionPageThreats = true,
	excludeWorkingFromTotals = false,
	showLowLevelCounters = false,
	showListCounters = false,
	showTTRewardInfo = true,
}

-- map threat counters to follower specIDs (.classSpec values)
local specs = {}
for index = 1, GetNumClasses() do
	local _, class, classID = GetClassInfo(index)
	specs[classID] = {}
	specs[class]   = specs[classID]
end
specs.DEATHKNIGHT.blood, specs.DEATHKNIGHT.frost, specs.DEATHKNIGHT.unholy = 2, 3, 4
specs.DRUID.balance, specs.DRUID.feral, specs.DRUID.guardian, specs.DRUID.restoration = 5, 7, 8, 9
specs.HUNTER.beastmaster, specs.HUNTER.marksman, specs.HUNTER.survival = 10, 12, 13
specs.MAGE.arcane, specs.MAGE.fire, specs.MAGE.frost = 14, 15, 16
specs.MONK.brewmaster, specs.MONK.mistweaver, specs.MONK.windwalker = 17, 18, 19
specs.PALADIN.holy, specs.PALADIN.protection, specs.PALADIN.retribution = 20, 21, 22
specs.PRIEST.discipline, specs.PRIEST.holy, specs.PRIEST.shadow = 23, 24, 25
specs.ROGUE.assassination, specs.ROGUE.combat, specs.ROGUE.subtelty = 26, 27, 28
specs.SHAMAN.elemental, specs.SHAMAN.enhancement, specs.SHAMAN.restoration = 29, 30, 31
specs.WARLOCK.affliction, specs.WARLOCK.demonology, specs.WARLOCK.destruction = 32, 33, 34
specs.WARRIOR.arms, specs.WARRIOR.fury, specs.WARRIOR.protection = 35, 37, 38

local abilitySpecs = {
	[1] = { -- wild aggression
		specs.DEATHKNIGHT.frost, specs.DEATHKNIGHT.unholy, specs.DEATHKNIGHT.blood, specs.DRUID.guardian, specs.DRUID.feral, specs.HUNTER.beastmaster, specs.MONK.brewmaster, specs.MONK.windwalker, specs.PALADIN.protection, specs.WARRIOR.arms, specs.WARRIOR.protection
	},
	[2] = { -- massive strike
		specs.DRUID.feral, specs.DRUID.guardian, specs.DEATHKNIGHT.blood, specs.DEATHKNIGHT.unholy, specs.HUNTER.survival, specs.PALADIN.retribution, specs.PALADIN.protection, specs.MAGE.frost, specs.MONK.brewmaster, specs.ROGUE.assassination, specs.ROGUE.subtelty, specs.WARLOCK.destruction, specs.WARRIOR.protection, specs.WARRIOR.fury
	},
	[3] = { -- group damage
		specs.SHAMAN.restoration, specs.MONK.mistweaver, specs.WARLOCK.destruction, specs.PALADIN.holy, specs.PRIEST.holy, specs.PRIEST.discipline, specs.DRUID.restoration
	},
	[4] = { -- magic debuff
		specs.DEATHKNIGHT.frost, specs.DRUID.restoration, specs.MONK.mistweaver, specs.PALADIN.holy, specs.PALADIN.protection, specs.PRIEST.holy, specs.PRIEST.discipline, specs.PRIEST.shadow, specs.SHAMAN.restoration, specs.WARLOCK.affliction
	},
	[6] = { -- danger zones
		specs.DRUID.feral, specs.DRUID.guardian, specs.DRUID.balance, specs.HUNTER.survival, specs.HUNTER.marksman, specs.HUNTER.beastmaster, specs.MAGE.arcane, specs.MAGE.fire, specs.MONK.windwalker, specs.MONK.brewmaster, specs.MONK.mistweaver, specs.PRIEST.holy, specs.PRIEST.discipline, specs.PRIEST.shadow, specs.ROGUE.assassination, specs.ROGUE.subtelty, specs.ROGUE.combat, specs.SHAMAN.enhancement, specs.WARRIOR.arms, specs.WARRIOR.fury, specs.WARRIOR.protection
	},
	[7]  = { -- minion swarms
		specs.DEATHKNIGHT.frost, specs.DEATHKNIGHT.blood, specs.DEATHKNIGHT.unholy, specs.DRUID.balance, specs.DRUID.restoration, specs.HUNTER.survival, specs.HUNTER.marksman, specs.HUNTER.beastmaster, specs.MAGE.frost, specs.MAGE.fire, specs.PALADIN.retribution, specs.PRIEST.holy, specs.PRIEST.shadow, specs.ROGUE.combat, specs.ROGUE.subtelty, specs.SHAMAN.restoration, specs.SHAMAN.elemental, specs.SHAMAN.enhancement, specs.WARLOCK.affliction, specs.WARLOCK.demonology, specs.WARRIOR.arms, specs.WARRIOR.fury, specs.WARRIOR.protection
	},
	[8] = { -- powerful spell
		specs.DEATHKNIGHT.frost, specs.DEATHKNIGHT.blood, specs.DEATHKNIGHT.unholy, specs.HUNTER.marksman, specs.MAGE.frost, specs.MAGE.fire, specs.MAGE.arcane, specs.MONK.mistweaver, specs.MONK.windwalker, specs.PALADIN.retribution, specs.PALADIN.holy, specs.PALADIN.protection, specs.ROGUE.assassination, specs.ROGUE.subtelty, specs.ROGUE.combat, specs.SHAMAN.elemental, specs.SHAMAN.restoration, specs.WARLOCK.affliction, specs.WARLOCK.demonology, specs.WARLOCK.destruction, specs.WARRIOR.arms, specs.WARRIOR.fury, specs.WARRIOR.protection
	},
	[9] = { -- deadly minions
		specs.DRUID.restoration, specs.DRUID.guardian, specs.DRUID.balance, specs.HUNTER.survival, specs.HUNTER.marksman, specs.HUNTER.beastmaster, specs.MAGE.frost, specs.MAGE.fire, specs.MAGE.arcane, specs.MONK.brewmaster, specs.MONK.windwalker, specs.PALADIN.retribution, specs.PALADIN.holy, specs.PALADIN.protection, specs.PRIEST.discipline, specs.PRIEST.shadow, specs.ROGUE.assassination, specs.ROGUE.subtelty, specs.ROGUE.combat, specs.SHAMAN.elemental, specs.SHAMAN.enhancement, specs.WARLOCK.affliction, specs.WARLOCK.destruction
	},
	[10]  = { -- timed battle, multiples: druid, mage, warlock
		specs.DEATHKNIGHT.frost, specs.DEATHKNIGHT.blood, specs.DEATHKNIGHT.unholy, specs.DRUID.restoration, specs.DRUID.guardian, specs.DRUID.balance, specs.DRUID.feral, specs.HUNTER.survival, specs.HUNTER.marksman, specs.HUNTER.beastmaster, specs.MAGE.frost, specs.MAGE.fire, specs.MAGE.arcane, specs.MONK.windwalker, specs.MONK.mistweaver, specs.PALADIN.retribution, specs.PALADIN.holy, specs.PRIEST.holy, specs.PRIEST.discipline, specs.PRIEST.shadow, specs.ROGUE.assassination, specs.ROGUE.combat, specs.SHAMAN.restoration, specs.SHAMAN.elemental, specs.SHAMAN.enhancement, specs.WARLOCK.affliction, specs.WARLOCK.demonology, specs.WARLOCK.destruction, specs.WARRIOR.arms, specs.WARRIOR.fury
	},
}

local function FollowerAbilityOptions(self, followerID)
	local isRecruit = not self.AbilitiesFrame
	local options = not isRecruit and _G[addonName..'FollowerAbilityOptions'] or self.abilityOptions
	if (not isRecruit and not self.followerID) or not addon.db.showFollowerAbilityOptions then
		if options then options:SetText('') end
		return
	end

	-- unowned followers use generic *ByID(followerID) while owned use *(garrFollowerID)
	local spec = C_Garrison.GetFollowerClassSpecByID(followerID) or C_Garrison.GetFollowerClassSpec(followerID)
	local canLearn = ''
	for threatID, specIDs in pairs(abilitySpecs) do
		if tContains(specIDs, spec) then
			canLearn = canLearn .. (canLearn ~= '' and ' ' or '')
				.. '|T' .. THREATS[threatID].icon .. (isRecruit and ':18:18:0:-2' or ':16:16:0:2') .. '|t'
		end
	end
	if canLearn == '' then
		if options then options:SetText('') end
		return
	end

	if not options then
		local optionsName = not isRecruit and addonName..'FollowerAbilityOptions' or '$parentAbilityOptions'
		options = self:CreateFontString(optionsName, nil, 'GameFontHighlight')
		options:SetJustifyH('LEFT')
		options:SetJustifyV('TOP')
		if isRecruit then
			self.abilityOptions = options
		end
	end
	if isRecruit then
		options:SetPoint('TOPLEFT', self.Traits, 'BOTTOMLEFT', 0, -2)
		options:SetText('Learnable counters' .. '|n' .. canLearn)
	else
		options:SetParent(self)
		options:SetPoint('TOPLEFT', self.ClassSpec, 'TOPRIGHT', 0, 0)
		options:SetText(' – ' .. canLearn)
	end
end

local function ShowFollowerAbilityOptions()
	addon.UpdateThreatCounters(GarrisonRecruitSelectFrame)
	for i, follower in ipairs(C_Garrison.GetAvailableRecruits()) do
		local frame = GarrisonRecruitSelectFrame.FollowerSelection['Recruit'..i]
		FollowerAbilityOptions(frame, follower.followerID)
		if addon.db.replaceAbilityWithThreat then
			for k, abilityFrame in ipairs(frame.Abilities.Entries) do
				if not abilityFrame:IsShown() then break end
				local _, _, icon = C_Garrison.GetFollowerAbilityCounterMechanicInfo(abilityFrame.abilityID)
				abilityFrame.Icon:SetTexture(icon)
			end
		end
	end
end

local propertyOrder = {'GetFollowerItemLevelAverage', 'GetFollowerLevel', 'GetFollowerQuality', 'GetFollowerName'}
local function SortFollowers(followerA, followerB)
	for _, property in ipairs(propertyOrder) do
		local propertyA, propertyB = C_Garrison[property](followerA), C_Garrison[property](followerB)
		if propertyA ~= propertyB then
			return propertyA < propertyB
		end
	end
end

local function SortBuildingsBySize(a, b)
	local aSort, bSort = a.uiTab <= 2 and a.uiTab or -1, b.uiTab <= 2 and b.uiTab or -1
	if aSort ~= bSort then
		return aSort > bSort
	else
		return a.buildingID < b.buildingID
	end
end

local counters = {}
local maxNumAbilities, maxNumTraits = 2, 3
local function GetFollowerCounters(followerID)
	if not followerID then return false end
	wipe(counters)
	local hasCounters = false
	for i = 1, maxNumAbilities + maxNumTraits do
		local abilityID
		-- handle both garrFollowerID (hex) and followerID (decimal)
		if i <= maxNumAbilities then
			abilityID = C_Garrison.GetFollowerAbilityAtIndexByID(followerID, i)
				or C_Garrison.GetFollowerAbilityAtIndex(followerID, i)
		else
			abilityID = C_Garrison.GetFollowerTraitAtIndexByID(followerID, i - maxNumAbilities)
				or C_Garrison.GetFollowerTraitAtIndex(followerID, i - maxNumAbilities)
		end
		local threatID = (abilityID and abilityID ~= 0) and C_Garrison.GetFollowerAbilityCounterMechanicInfo(abilityID) or nil
		if threatID then
			if THREATS[threatID] then
				hasCounters = true
				counters[threatID] = (counters[threatID] or 0) + 1
			end
		end
	end
	return hasCounters and counters or false
end

local threats, threatMissionID = {}, nil
local function GetMissionThreats(missionID)
	if not missionID then return false end
	if missionID == threatMissionID then return threats end
	wipe(threats)

	local hasThreats = false
	local enemies = select(8, C_Garrison.GetMissionInfo(missionID))
	for i, enemy in ipairs(enemies or emptyTable) do
		for threatID, info in pairs(enemy.mechanics) do
			hasThreats = true
			threats[threatID] = (threats[threatID] or 0) + 1
		end
	end
	threatMissionID = missionID
	return hasThreats and threats or false
end

local abilities = {}
local function ScanFollowerAbilities(followerID, removeData)
	for threatID, followers in pairs(abilities) do
		for i, follower in pairs(followers) do
			if follower == followerID then
				tremove(followers, i)
				break
			end
		end
	end
	if removeData then return end
	for threatID in pairs(GetFollowerCounters(followerID) or emptyTable) do
		if not abilities[threatID] then
			abilities[threatID] = {}
		end
		if not tContains(abilities[threatID], followerID) then
			tinsert(abilities[threatID], followerID)
		end
	end
end

local function GetFollowerLevelText(followerID)
	local level   = C_Garrison.GetFollowerLevel(followerID)
	local iLevel  = C_Garrison.GetFollowerItemLevelAverage(followerID)
	local quality = C_Garrison.GetFollowerQuality(followerID)

	local qualityColor = RGBTableToColorCode(_G.ITEM_QUALITY_COLORS[quality])
	local displayLevel
	if level < 100 then
		-- display invisible zero to keep padding intact
		displayLevel = '|c000000000|r'..qualityColor..level..'|r '
	else
		displayLevel = qualityColor .. iLevel .. '|r '
	end
	return displayLevel
end

local function MissionOnEnter(self, button)
	local info = self.info
	if not self.info and GarrisonLandingPageReport:IsShown() and GarrisonLandingPageReport.selectedTab == GarrisonLandingPageReport.Available then
		info = (GarrisonLandingPageReport.List.AvailableItems or emptyTable)[self.id]
	end
	if not info or info.isRare or info.inProgress then
		return
	end

	-- display mission expiry
	GameTooltip:AddLine(_G.GARRISON_MISSION_AVAILABILITY)
	GameTooltip:AddLine(info.offerTimeRemaining, 1, 1, 1)
	GameTooltip:Show()
end

local function ThreatOnEnter(self)
	local followers = self.id and abilities[self.id]
	if not followers or #followers < 1 then return end

	if self.description then
		GameTooltip:AddLine(self.description, 255, 255, 255, true)
		GameTooltip:AddLine(' ')
	end

	tsort(followers, SortFollowers)
	for _, followerID in pairs(followers) do
		local name   = C_Garrison.GetFollowerName(followerID)
		local status = C_Garrison.GetFollowerStatus(followerID) or ''
		local displayLevel = GetFollowerLevelText(followerID)

		local color = _G.YELLOW_FONT_COLOR
		if status == _G.GARRISON_FOLLOWER_INACTIVE then
			color = _G.GRAY_FONT_COLOR
			name  = _G.GRAY_FONT_COLOR_CODE .. name .. '|r'
		elseif status == _G.GARRISON_FOLLOWER_ON_MISSION then
			color = _G.RED_FONT_COLOR
			if addon.db.showFollowerReturnTime then
				status = C_Garrison.GetFollowerMissionTimeLeft(followerID)
			end
		end
		GameTooltip:AddDoubleLine(displayLevel..name, status, nil, nil, nil, color.r, color.g, color.b)
	end
	GameTooltip:Show()
end

local function GetNumFollowersForMechanic(threatID)
	local followers = abilities[threatID]
	if not followers then
		return 0, 0
	end

	local numAvailable, numFollowers = #followers, #followers
	for _, followerID in pairs(followers) do
		local status = C_Garrison.GetFollowerStatus(followerID)
		if status and status ~= _G.GARRISON_FOLLOWER_IN_PARTY then
			numAvailable = numAvailable - 1
			if status == _G.GARRISON_FOLLOWER_INACTIVE or (addon.db.excludeWorkingFromTotals and status == _G.GARRISON_FOLLOWER_WORKING) then
				-- don't count inactive followers in tab count
				numFollowers = numFollowers - 1
			end
		end
	end
	return numFollowers, numAvailable
end

local function UpdateThreatCounterButtons(self)
	for index, button in pairs(self.ThreatsList) do
		local numFollowers, numAvailable = GetNumFollowersForMechanic(button.id)
		if numAvailable ~= numFollowers then
			button.Count:SetFormattedText('%d/%d', numAvailable, numFollowers)
		end
		button.Icon:SetDesaturated(numFollowers < 1 and addon.db.desaturateUnavailable)
	end
end

local function UpdateThreatCounters(self)
	-- TODO: this is awkward
	if addon.db.showMissionPageThreats
		and (GarrisonMissionFrame:IsShown() or GarrisonLandingPage.FollowerList:IsShown()) then
		UpdateThreatCounterButtons(GarrisonThreatCountersFrame)
	end
end
addon.UpdateThreatCounters = UpdateThreatCounters

-- add extra info to mission list for easier overview
local followerSlotIcon = '|TInterface\\FriendsFrame\\UI-Toast-FriendOnlineIcon:0:0:0:0:32:32:4:26:4:26|t'
local function UpdateMissionList()
	GarrisonMissionFrame.FollowerList.SearchBox:SetText('')
	-- GarrisonFollowerList_UpdateFollowers(GarrisonMissionFrame.FollowerList)

	if not addon.db.showExtraMissionInfo then return end
	local self     = GarrisonMissionFrame.MissionTab.MissionList
	local active   = self.showInProgress
	local missions = active and self.inProgressMissions or self.availableMissions
	local _, numRessources = GetCurrencyInfo(824)

	local offset  = HybridScrollFrame_GetOffset(self.listScroll)
	local buttons = self.listScroll.buttons
	for i = 1, #buttons do
		local button = buttons[i]
		local mission = missions[i + offset]
		if not mission or not button:IsShown() then break end

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
		button.followers:SetText(strrep(followerSlotIcon, mission.numFollowers))

		-- show item level instead of max level
		if mission.level == _G.GARRISON_FOLLOWER_MAX_LEVEL and mission.iLevel > 0 then
			button.Level:SetText(mission.iLevel)
			button.Level:SetPoint('CENTER', button, 'TOPLEFT', 40, -36)
			button.ItemLevel:Hide()
		end

		-- show resource cost
		if not active and addon.db.showRequiredResources and (mission.cost or 0) > 0 then
			local duration = mission.duration
			if mission.durationSeconds >= _G.GARRISON_LONG_MISSION_TIME then
				duration = _G.GARRISON_LONG_MISSION_TIME_FORMAT:format(mission.duration)
			end
			button.Summary:SetDrawLayer('OVERLAY') -- fix our icon layer
			button.Summary:SetFormattedText('(%2$s, %3$s%1$s|r |TInterface\\Icons\\inv_garrison_resource:0:0:0:0|t)',
				mission.cost or 0, duration, (mission.cost or 0) > numRessources and _G.RED_FONT_COLOR_CODE or '')
		end

		-- show required abilities
		local _, _, _, _, _, _, _, enemies = C_Garrison.GetMissionInfo(mission.missionID)
		local  levelReq  = mission.level - 2
		local iLevelReq  = (levelReq == _G.GARRISON_FOLLOWER_MAX_LEVEL and mission.iLevel or 0) - 14
		local numThreats = 0

		for j = 1, #enemies do
			if not addon.db.showMissionThreats then break end
			button.Threats = button.Threats or {}

			for mechanicID, mechanic in pairs(enemies[j].mechanics) do
				numThreats = numThreats + 1
				local threatFrame = button.Threats[numThreats]
				if not threatFrame then
					button.Threats[numThreats] = CreateFrame('Frame', nil, button, 'GarrisonAbilityCounterTemplate') -- GarrisonAbilityCounterWithCheckTemplate
					threatFrame = button.Threats[numThreats]
					if numThreats == 1 then
						threatFrame:SetPoint('TOPLEFT', button.Title, 'BOTTOMLEFT', 0, -2)
					else
						threatFrame:SetPoint('LEFT', button.Threats[numThreats-1], 'RIGHT', 8, 0)
					end
					threatFrame.Border:SetAtlas('GarrMission_EncounterAbilityBorder')
				end
				threatFrame.id = mechanicID
				threatFrame.info = mechanic
				threatFrame.Icon:SetTexture(mechanic.icon)
				threatFrame:Show()

				-- also see GarrisonMissionButton_CheckTooltipThreat
				if not active and addon.db.desaturateUnavailable then
					local numCounters = 0
					for _, followerID in ipairs(abilities[mechanicID] or emptyTable) do
						if C_Garrison.GetFollowerLevel(followerID) >= levelReq
							and C_Garrison.GetFollowerItemLevelAverage(followerID) >= iLevelReq
							and not C_Garrison.GetFollowerStatus(followerID) then
							-- must have high level, high gear and be available
							numCounters = numCounters + 1
						end
					end
					-- might have used up followers for previous counters
					for prevThreatIndex = 1, numThreats - 1 do
						if button.Threats[prevThreatIndex].id == mechanicID then
							numCounters = numCounters - 1
						end
					end
					threatFrame.Icon:SetDesaturated(numCounters < 1)
					threatFrame.Icon:SetAlpha(numCounters < 1 and 0.5 or 1)
				else
					threatFrame.Icon:SetDesaturated(false)
					threatFrame.Icon:SetAlpha(1)
				end
			end
		end
		-- hide unused threat icons
		for k = numThreats + 1, #(button.Threats or emptyTable) do
			button.Threats[k]:Hide()
		end
		-- move title text
		if numThreats > 0 then
			local anchorFrom, relativeTo, anchorTo, xOffset, yOffset = button.Title:GetPoint()
			if yOffset == 0 then
				button.Title:SetPoint(anchorFrom, relativeTo, anchorTo, xOffset, yOffset + 10)
			end
		end
	end
end

local function UpdateShipyardMissionList()
	local self = GarrisonShipyardFrame.MissionTab.MissionList
	local missions = self.missions
	for i, mission in pairs(self.missions) do
		local missionFrame = self.missionFrames[i]
		local index = 0
		if addon.db.showExtraMissionInfo and mission.canStart and not mission.inProgress then
			-- local _, durationSeconds, _, successChance, partyBuffs, environmentCounter, extraXP, currencyMultipliers, goldMultiplier = C_Garrison.GetPartyMissionInfo(missionID)
			local _, _, _, _, _, _, _, enemies = C_Garrison.GetMissionInfo(mission.missionID)

			if addon.db.showMissionThreats then
				local counterableThreats = GarrisonMission_DetermineCounterableThreats(mission.missionID, mission.followerTypeID)
				missionFrame.Threats = missionFrame.Threats or {}

				for j = 1, #enemies do
					for mechanicID, mechanic in pairs(enemies[j].mechanics) do
						index = index + 1
						local threatFrame = missionFrame.Threats[index]
						if not threatFrame then
							missionFrame.Threats[index] = CreateFrame('Frame', nil, missionFrame, 'GarrisonAbilityCounterWithCheckTemplate')
							missionFrame.Threats[index]:SetPoint('LEFT', missionFrame.Threats[index - 1], 'RIGHT', 4, 0)
							threatFrame = missionFrame.Threats[index]
						end
						-- update threat counters
						if mission.followerTypeID == LE_FOLLOWER_TYPE_SHIPYARD_6_2
							and mechanic.factor <= GARRISON_HIGH_THREAT_VALUE then
							threatFrame.Border:SetAtlas('GarrMission_WeakEncounterAbilityBorder')
						else
							threatFrame.Border:SetAtlas('GarrMission_EncounterAbilityBorder')
						end
						-- GarrisonMission_DetermineCounterableThreats + GarrisonMissionButton_CheckTooltipThreat
						GarrisonMissionButton_CheckTooltipThreat(threatFrame, mission.missionID, mechanicID, counterableThreats)
						threatFrame.TimeLeft:Hide()
						threatFrame.Icon:SetTexture(mechanic.icon)
						threatFrame:Show()
					end
				end
				if index > 0 then
					missionFrame.Threats[1]:ClearAllPoints()
					missionFrame.Threats[1]:SetPoint('TOP', missionFrame, 'BOTTOM', 10-4 -index*20/2, 10)
				end
			end
			if addon.db.showRequiredResources then
				-- TODO
			end
			if addon.db.showFollowerReturnTime then
				-- TODO
			end
		end
		-- hide unused threat icons
		for k = index + 1, #(missionFrame.Threats or emptyTable) do
			missionFrame.Threats[k]:Hide()
		end
	end
end

local function OnRewardClick(self, btn, up)
	HandleModifiedItemClick(self.link)
end

-- show reward counts
local function UpdateMissionRewards(self, rewards, numRewards)
	if not addon.db.showRewardCounts or numRewards < 1 then return end
	local index = 1
	for id, reward in pairs(rewards) do
		local button = self.Rewards[index]
		if not button:GetScript('OnMouseDown') then
			-- allow shift-click to post rewards to chat
			button:SetScript('OnMouseDown', OnRewardClick)
		end
		button.link = nil
		if reward.itemID and reward.quantity == 1 then
			-- show item level
			local info
			local _, link, quality, iLevel = GetItemInfo(reward.itemID)
			if iLevel and iLevel > 1 and quality > LE_ITEM_QUALITY_COMMON then
				info = ITEM_QUALITY_COLORS[quality or _G.LE_ITEM_QUALITY_COMMON].hex .. iLevel .. '|r'
			end
			button.link = link

			if info and info ~= 1 then
				button.Quantity:Show()
				button.Quantity:SetText(info)
			end
		end
		index = index + 1
	end
end

-- note: this will only work once Blizzard_GarrisonUI (and therefore this addon) is loaded
local function ShowMinimapBuildings(self, motion)
	if not addon.db.showMinimapBuildings then return end
	local buildings = C_Garrison.GetBuildings()
	tsort(buildings, SortBuildingsBySize)

	for i, building in ipairs(buildings) do
		if i == 1 then GameTooltip:AddLine(' ') end
		local _, name, _, icon, _, rank, _, resources, gold, buildTime, needsPlan, _, _, upgrades, canUpgrade, isMaxLevel, _, _, _, _, isBeingBuilt, _, _, _, canCompleteBuild = C_Garrison.GetOwnedBuildingInfo(building.plotID)
		-- currencyID, currencyQty, and goldQty from above are the cost of the building's current level, which we do not display. What we do display is the cost of the next level.
		-- _, _, _, _, _, currencyID, currencyQty, goldQty = C_Garrison.GetBuildingUpgradeInfo(id)

		local infoText = _G.GARRISON_BUILDING_LEVEL_TOOLTIP_TEXT:format(rank)
		if canCompleteBuild then
			infoText = _G.GREEN_FONT_COLOR_CODE .. infoText .. '|r'
		elseif isBeingBuilt then
			infoText = '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t' .. infoText
		elseif isMaxLevel or rank == _G.GARRISON_MAX_BUILDING_LEVEL then
			infoText = _G.GRAY_FONT_COLOR_CODE .. infoText .. '|r'
		elseif canUpgrade and not needsPlan then
			infoText = '|TInterface\\petbattles\\battlebar-abilitybadge-strong-small:0|t' .. infoText
		end

		GameTooltip:AddDoubleLine('|T'..icon..':0|t '..name, infoText)
	end
	GameTooltip:Show()
end

local function MissionCompleteFollowerOnClick(self, btn, up)
	local followerLink = C_Garrison.GetFollowerLink(self.followerID)
	HandleModifiedItemClick(followerLink)
end

local dummyFollowerInfo = {followerID = 0, garrFollowerID = 0}
local function MissionCompleteFollowerOnEnter(self)
	if not addon.db.missionCompleteFollowerTooltips then return end
	local frame = self:GetParent():GetParent():GetParent():GetParent()

	local followerID = self.followerID
	local link = C_Garrison.GetFollowerLink(followerID)
	if not link then return end
	local garrFollowerID = link:match('garrfollower:(%d+)') * 1
	local followerType = C_Garrison.GetFollowerTypeByID(garrFollowerID)

	local tooltip, xpWidth = GarrisonFollowerTooltip, nil
	if followerType == LE_FOLLOWER_TYPE_SHIPYARD_6_2 then
		tooltip, xpWidth = GarrisonShipyardFollowerTooltip, 231
	end
	tooltip:ClearAllPoints()
	tooltip:SetPoint('TOPLEFT', self, 'BOTTOMRIGHT')
	GarrisonFollowerTooltip_Show(garrFollowerID,
		C_Garrison.IsFollowerCollected(garrFollowerID),
		C_Garrison.GetFollowerQuality(followerID),
		C_Garrison.GetFollowerLevel(followerID),
		C_Garrison.GetFollowerXP(followerID),
		C_Garrison.GetFollowerLevelXP(followerID),
		C_Garrison.GetFollowerItemLevelAverage(followerID),
		C_Garrison.GetFollowerAbilityAtIndex(followerID, 1),
		C_Garrison.GetFollowerAbilityAtIndex(followerID, 2),
		C_Garrison.GetFollowerAbilityAtIndex(followerID, 3),
		C_Garrison.GetFollowerAbilityAtIndex(followerID, 4),
		C_Garrison.GetFollowerTraitAtIndex(followerID, 1),
		C_Garrison.GetFollowerTraitAtIndex(followerID, 2),
		C_Garrison.GetFollowerTraitAtIndex(followerID, 3),
		C_Garrison.GetFollowerTraitAtIndex(followerID, 4),
		true, -- no ability description
		false, -- under bias
		tooltip,
		xpWidth
	)
end

local function MissionCompleteFollowerOnLeave(self)
	local frame = self:GetParent():GetParent():GetParent():GetParent()
	local tooltipFunc = frame.MissionTab.MissionPage.Follower1:GetScript('OnLeave')
	tooltipFunc(self)
end

local function TooltipReplaceAbilityWithThreat(tooltipFrame, data)
	if not addon.db.replaceAbilityWithThreat or not data.noAbilityDescriptions then return end
	for index, frame in pairs(tooltipFrame.Abilities) do
		if frame:IsShown() then
			local _, _, icon = C_Garrison.GetFollowerAbilityCounterMechanicInfo(data['ability'..index])
			frame.Icon:SetTexture(icon)
		end
	end
end

local function FollowerListReplaceAbilityWithThreat(self, index, ability)
	-- TODO: this does not yet work on landing page
	if addon.db.replaceAbilityWithThreat and not ability.isTrait then
		local _, _, icon = C_Garrison.GetFollowerAbilityCounterMechanicInfo(ability.id)
		self.Abilities[index].Icon:SetTexture(icon)
	end
end

local function GetRewardText(reward)
	local rewardTitle, count, icon = reward.title, reward.quantity, reward.icon
	local quality = reward.quality and reward.quality + 1 or nil

	if reward.itemID then
		rewardTitle, _, quality, _, _, _, _, _, _, icon = GetItemInfo(reward.itemID)
		icon = icon or reward.icon or '' -- item data might not be available
	elseif reward.currencyID == 0 then
		count = BreakUpLargeNumbers(floor(reward.quantity / _G.COPPER_PER_GOLD))
	elseif reward.followerXP then
		count = GarrisonLandingPageReportList_FormatXPNumbers(reward.followerXP)
	else
		count = BreakUpLargeNumbers(reward.quantity)
	end

	if quality then
		rewardTitle = _G.ITEM_QUALITY_COLORS[quality].hex .. rewardTitle .. _G.FONT_COLOR_CODE_CLOSE
	end
	if count and count ~= 1 then
		return ('|T%1$s:0|t %2$s (%3$s)'):format(icon, rewardTitle, count)
	else
		return ('|T%1$s:0|t %2$s'):format(icon or '', rewardTitle or '')
	end
end
local function UpdateMissionTooltip(missionID)
	if not addon.db.showTTRewardInfo then return end
	local missionRewards
	for id, reward in pairs(C_Garrison.GetMissionRewardInfo(missionID)) do
		missionRewards = (missionRewards and missionRewards..'\n' or '') .. GetRewardText(reward)
	end
	FloatingGarrisonMissionTooltip.Rewards:SetText(missionRewards, 1, 1, 1)
	FloatingGarrisonMissionTooltip:SetHeight(70 + FloatingGarrisonMissionTooltip.Rewards:GetHeight())
end

local function UpdateInProgressMissionTooltip(missionInfo, showRewards)
	if not showRewards or not addon.db.showTTRewardInfo then return end
	local lineNum
	for i = 1, GameTooltip:NumLines() do
		if _G['GameTooltipTextLeft'..i]:GetText() == _G.REWARDS then
			-- found rewards header
			lineNum = i; break
		end
	end
	for id, reward in pairs(missionInfo.rewards) do
		lineNum = lineNum + 1
		_G['GameTooltipTextLeft'..lineNum]:SetText(GetRewardText(reward))
	end

	for i = lineNum, GameTooltip:NumLines() do
		if _G['GameTooltipTextLeft'..i]:GetText() == _G.GARRISON_FOLLOWERS then
			-- found followers header
			lineNum = i; break
		end
	end
	-- color follower by quality
	for _, followerID in ipairs(missionInfo.followers or emptyTable) do
		lineNum = lineNum + 1
		-- local color = _G.ITEM_QUALITY_COLORS[C_Garrison.GetFollowerQuality(followerID)]
		-- _G['GameTooltipTextLeft'..lineNum]:SetTextColor(color.r, color.g, color.b)
		local displayLevel = GetFollowerLevelText(followerID)
		local name = C_Garrison.GetFollowerName(followerID)
		_G['GameTooltipTextLeft'..lineNum]:SetText(displayLevel .. name)
	end

	-- update tooltip dimensions
	GameTooltip:Show()
end

local function UpdateInProgressShipyardMissionTooltip(missionInfo, inProgress)
	local tooltipFrame = GarrisonShipyardMapMissionTooltip

	-- color followers by quality
	for i, followerID in ipairs(missionInfo.followers or emptyTable) do
		local quality = C_Garrison.GetFollowerQuality(followerID)
		local color = _G.ITEM_QUALITY_COLORS[quality]
		tooltipFrame.Ships[i]:SetTextColor(color.r, color.g, color.b)
	end
end

local function FollowerOnDoubleClick(self, btn)
	if not addon.db.doubleClickToAddFollower then return end
	local frame = self:GetParent():GetParent():GetParent():GetParent()
	if not frame or not frame.MissionTab or not frame.MissionTab.MissionPage then return end

	-- trigger second click handling
	self:GetScript('OnClick')(self, btn)

	local status = C_Garrison.GetFollowerStatus(self.info.followerID)
	if status == _G.GARRISON_FOLLOWER_IN_PARTY then
		-- remove from party
		for index, follower in pairs(frame.MissionTab.MissionPage.Followers) do
			if follower.info and follower.info.followerID == self.info.followerID then
				frame:RemoveFollowerFromMission(follower, true)
				break
			end
		end
	elseif not status then
		-- add to party
		for index, follower in pairs(frame.MissionTab.MissionPage.Followers) do
			if not follower.info then
				frame:AssignFollowerToMission(follower, self.info)
				break
			end
		end
	end
end

local function UpdateFollowerCounters(frame, button, follower, showCounters, lastUpdate)
	if (not showCounters and not addon.db.showListCounters)
		or (showCounters and not addon.db.showLowLevelCounters)
		or not button.Counters or not button.Counters[1] or not button.Counters[1].Icon then
		-- only display on listings and/or low levels on mission grouping
		return
	end
	if showCounters and frame.followerCounters
		and frame.followerCounters[follower.followerID] then
		-- already displaying counters for this follower
		return
	end

	local missionID
	if frame.MissionTab and frame.MissionTab.MissionPage.missionInfo then
		missionID = frame.MissionTab.MissionPage.missionInfo.missionID
	end
	local threats  = showCounters and GetMissionThreats(missionID)
	local counters = GetFollowerCounters(follower.followerID)
	local numShown = 0
	for threatID in pairs(counters or emptyTable) do
		if numShown >= 4 then break end
		if not threats or threats[threatID] then
			numShown = numShown + 1
			GarrisonFollowerButton_SetCounterButton(button, follower.followerID, numShown, THREATS[threatID], nil, follower.followerTypeID)
			button.Counters[numShown].info.showCounters = false
		end
	end

	-- we might have added abilities, when there were only traits before
	local traits = showCounters and frame.followerTraits
		and frame.followerTraits[follower.followerID]
	for i = 1, traits and #traits or 0 do
		if numShown >= 4 then break end
		numShown = numShown + 1
		GarrisonFollowerButton_SetCounterButton(button, follower.followerID, numShown, traits[i], nil, follower.followerTypeID)
	end
	button.Counters[1]:SetPoint('TOPRIGHT', -8, numShown <= 2 and -16 or -4)
end

local function CheckPseudoCounter(enemies, counterID)
	local isThreat = false
	for i = 1, #enemies do
		local enemyFrame = enemies[i]
		for mechanicIndex = 1, #enemyFrame.Mechanics do
			isThreat = isThreat or counterID == enemyFrame.Mechanics[mechanicIndex].mechanicID
			if counterID == enemyFrame.Mechanics[mechanicIndex].mechanicID then
				isThreat = true
				if not enemyFrame.Mechanics[mechanicIndex].hasCounter then
					enemyFrame.Mechanics[mechanicIndex].hasCounter = true
					return isThreat
				end
			end
		end
	end
	return isThreat
end

local function MissionUpdateCounters(followers, enemies, missionID)
	if not addon.db.showLowLevelCounters then return end
	for index = 1, #followers do
		local followerFrame, info = followers[index], followers[index].info
		local counterIndex = 1
		if info and C_Garrison.GetFollowerBiasForMission(missionID, info.followerID) == -1 then
			for i = 1, maxNumAbilities + maxNumTraits do
				local abilityID = i <= maxNumAbilities
					and C_Garrison.GetFollowerAbilityAtIndex(info.followerID, i)
					or  C_Garrison.GetFollowerTraitAtIndex(info.followerID, i - maxNumAbilities)
				local threatID = abilityID ~= 0 and C_Garrison.GetFollowerAbilityCounterMechanicInfo(abilityID)
				if threatID and CheckPseudoCounter(enemies, threatID) then
					local button = followerFrame.Counters[counterIndex]
					if not button then
						button = CreateFrame('Frame', nil, followerFrame, 'GarrisonMissionAbilityLargeCounterTemplate')
						button:SetPoint('LEFT', followerFrame.Counters[counterIndex-1], 'RIGHT', 16, 0)
						followerFrame.Counters[counterIndex] = button
					end
					counterIndex = counterIndex + 1
					button.info = THREATS[threatID]
					button.Icon:SetTexture(THREATS[threatID].icon)
					button:Show()
				end
			end
		end
	end

	-- update checkmarks
	for i = 1, #enemies do
		local enemyFrame = enemies[i]
		for mechanicIndex = 1, #enemyFrame.Mechanics do
			local mechanicFrame = enemyFrame.Mechanics[mechanicIndex]
			if mechanicFrame.hasCounter and not mechanicFrame.Check:IsShown() then
				mechanicFrame.Check:SetAlpha(1)
				mechanicFrame.Check:Show()
				-- FIXME: this also plays for pre-existing pseudo counters
				mechanicFrame.Anim:Play()
			end
		end
	end
end

local function MissionCompleteSuccessChance(self)
	local frame = self.MissionComplete
	local chance = C_Garrison.GetRewardChance(frame.currentMission.missionID)
	if not chance then
		-- API forgets about failed missions, parse chance text
		chance = tonumber(frame.ChanceFrame.ChanceText:GetText():match('(%d+)%%') or '')
	end
	if chance and chance < 100 then
		local resultText
		if frame.currentMission.succeeded then
			resultText = _G.GARRISON_MISSION_SUCCESS
			frame.ChanceFrame.ResultText:SetTextColor(0.1, 1, 0.1)
		else
			resultText = _G.GARRISON_MISSION_FAILED
			frame.ChanceFrame.ResultText:SetTextColor(1, 0.1, 0.1)
		end
		frame.ChanceFrame.ResultText:SetFormattedText('%1$s (%2$d%%)', resultText, chance)
	end
end

local function MissionCompleteSkipAnimations(self, key)
	-- other key options: (L|R)ALT, ENTER, ESCAPE, ...
	if key == 'LSHIFT' or key == 'RSHIFT' then
		self:SetPropagateKeyboardInput(false)
		local animIndex = self.animIndex
		if animIndex and not self.skipAnimations then
			local followersInAnimIndex = self:FindAnimIndexFor(self.AnimFollowersIn)
			if animIndex < followersInAnimIndex then
				-- play sounds if we haven't yet
				local playSound = animIndex < self:FindAnimIndexFor(GarrisonMissionComplete.AnimRewards)
				-- hide encounters
				self.Stage.EncountersFrame.FadeOut:Stop()
				self.Stage.EncountersFrame:Hide()
				-- rewards bg
				self.BonusRewards.Saturated:Show()
				self.BonusRewards.Saturated:SetAlpha(1)
				-- success or failure text
				self.ChanceFrame.SuccessChanceInAnim:Stop()
				self.ChanceFrame.ResultAnim:Stop()
				self.ChanceFrame.ChanceText:SetAlpha(0)
				self.ChanceFrame.ChanceGlow:SetAlpha(0)
				self.ChanceFrame.SuccessGlow:SetAlpha(0)
				self.ChanceFrame.Banner:SetAlpha(1)
				self.ChanceFrame.Banner:SetWidth(GARRISON_MISSION_COMPLETE_BANNER_WIDTH)
				self.ChanceFrame.ResultText:SetAlpha(1)

				if playSound then
					if self.currentMission.succeeded then
						PlaySound('UI_Garrison_CommandTable_MissionSuccess_Stinger')
					else
						PlaySound('UI_Garrison_Mission_Complete_MissionFail_Stinger')
					end
				end
				self:BeginAnims(self:FindAnimIndexFor(self.AnimRewards) - 1)
			end
		end
	end
end

-- --------------------------------------------------------
--  Event handlers
-- --------------------------------------------------------
function addon:GARRISON_MISSION_NPC_OPENED()
	-- note: this is also triggered on successful mission completion
	UpdateThreatCounters(GarrisonMissionFrame)
end
function addon:GARRISON_SHIPYARD_NPC_OPENED()
	-- UpdateThreatCounters(GarrisonShipyardFrame)
end
function addon:GARRISON_RECRUITMENT_NPC_OPENED()
	UpdateThreatCounters(GarrisonRecruiterFrame)
	UpdateThreatCounters(GarrisonRecruitSelectFrame)
end
function addon:GARRISON_SHOW_LANDING_PAGE()
	UpdateThreatCounters(GarrisonLandingPage)
end
function addon:GARRISON_FOLLOWER_LIST_UPDATE()
	-- always show counter buttons
	GarrisonThreatCountersFrame:Show()
	-- TODO: we could probably pick more suitable events/hooks for these actions
	-- this tracks: => work, => mission, => inactive, and probably more
	UpdateThreatCounters()
end

function addon:GARRISON_FOLLOWER_UPGRADED(event, followerID)
	ScanFollowerAbilities(followerID)
	UpdateThreatCounters()
end

function addon:GARRISON_MISSION_COMPLETE_RESPONSE(event, missionID, canComplete, success, followers)
	if success or not followers or #followers < 1 then return end
	for index, follower in pairs(followers) do
		if follower.state == 2 then
			-- ship was destroyed
			ScanFollowerAbilities(follower.followerID, true)
		end
	end
end

function addon:GARRISON_FOLLOWER_XP_CHANGED(event, followerID, xpGain, oldXP, oldLevel, oldQuality)
	local _, _, level, quality, currXP, maxXP = C_Garrison.GetFollowerMissionCompleteInfo(followerID)
	if quality > oldQuality and quality == _G.LE_ITEM_QUALITY_EPIC then
		-- new ability at epic quality
		ScanFollowerAbilities(followerID)
	end
end

function addon:GARRISON_FOLLOWER_ADDED(event, followerID, name, class, displayID, level, quality, isUpgraded, texPrefix, followerType)
	ScanFollowerAbilities(followerID)
end

function addon:GARRISON_UPGRADEABLE_RESULT(event)
	-- this is the actual initialization
	for index, info in pairs(C_Garrison.GetFollowers()) do
		if info.isCollected then
			ScanFollowerAbilities(info.followerID)
		end
	end
	addon.GARRISON_FOLLOWER_LIST_UPDATE()

	self.frame:UnregisterEvent(event)
end

-- --------------------------------------------------------
--  Setup
-- --------------------------------------------------------
function addon:ADDON_LOADED(event, arg1)
	if arg1 ~= addonName then return end
	if not _G[addonName..'DB'] then _G[addonName..'DB'] = {} end
	addon.db = _G[addonName..'DB']

	-- remove outdated settings
	for key, value in pairs(addon.db) do
		if addon.defaults[key] == nil then
			addon.db[key] = nil
		end
	end
	-- automatically add unregistered settings
	setmetatable(addon.db, {
		__index = function(db, key)
			db[key] = addon.defaults[key]
			return rawget(db, key)
		end,
	})

	-- register events
	addon.frame:RegisterEvent('GARRISON_MISSION_NPC_OPENED')
	addon.frame:RegisterEvent('GARRISON_SHIPYARD_NPC_OPENED')
	addon.frame:RegisterEvent('GARRISON_RECRUITMENT_NPC_OPENED')
	addon.frame:RegisterEvent('GARRISON_SHOW_LANDING_PAGE')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_XP_CHANGED')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_LIST_UPDATE')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_ADDED')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_UPGRADED')
	addon.frame:RegisterEvent('GARRISON_MISSION_COMPLETE_RESPONSE')

	-- setup hooks
	hooksecurefunc('GarrisonMissionPage_SetCounters', MissionUpdateCounters)
	hooksecurefunc('GarrisonMissionList_Update', UpdateMissionList)
	hooksecurefunc(GarrisonMissionFrame.MissionTab.MissionList.listScroll, 'update', UpdateMissionList)
	hooksecurefunc('GarrisonMissionButton_SetRewards', UpdateMissionRewards)
	hooksecurefunc('GarrisonFollowerButton_AddAbility', FollowerListReplaceAbilityWithThreat)
	hooksecurefunc('GarrisonFollowerTooltipTemplate_SetGarrisonFollower', TooltipReplaceAbilityWithThreat)
	hooksecurefunc('GarrisonFollowerTooltipTemplate_SetGarrisonFollower', TooltipReplaceAbilityWithThreat)
	hooksecurefunc('GarrisonRecruitSelectFrame_UpdateRecruits', ShowFollowerAbilityOptions)
	-- shipyard missions
	hooksecurefunc('GarrisonShipyardMap_UpdateMissions', UpdateShipyardMissionList)
	hooksecurefunc(GarrisonShipyardFrame, 'ClearParty', UpdateShipyardMissionList) -- CloseMission

	-- skip battle animations on finished missions
	hooksecurefunc(GarrisonMissionComplete, 'OnSkipKeyPressed', MissionCompleteSkipAnimations)
	-- show success chance on finished missions
	hooksecurefunc(GarrisonMission, 'MissionCompleteInitialize', MissionCompleteSuccessChance)

	-- show extra reward info in tooltips
	hooksecurefunc('FloatingGarrisonMission_Show', UpdateMissionTooltip)
	hooksecurefunc('GarrisonMissionButton_SetInProgressTooltip', UpdateInProgressMissionTooltip)
	hooksecurefunc('GarrisonShipyardMapMission_SetTooltip', UpdateInProgressShipyardMissionTooltip)
	hooksecurefunc('GarrisonFollowerButton_UpdateCounters', UpdateFollowerCounters)

	-- mission tooltips
	hooksecurefunc('GarrisonMissionButton_OnEnter', MissionOnEnter)
	for _, button in pairs(GarrisonMissionFrame.MissionTab.MissionList.listScroll.buttons) do
		button:HookScript('OnEnter', MissionOnEnter)
	end
	hooksecurefunc('GarrisonLandingPageReportMission_OnEnter', MissionOnEnter)
	for _, button in pairs(GarrisonLandingPageReport.List.listScroll.buttons) do
		button:HookScript('OnEnter', MissionOnEnter)
	end

	-- provide easier code access
	GarrisonMissionFrame.FollowerTab.ThreatCountersFrame = GarrisonThreatCountersFrame
	-- for some reason, none of GarrisonFollowerList's hooks works here
	local frames = {GarrisonMissionFrame, GarrisonShipyardFrame, GarrisonLandingPage}
	for _, frame in pairs(frames) do
		-- display learnable counters
		hooksecurefunc(frame.FollowerList, 'ShowFollower', function(self, followerID)
			FollowerAbilityOptions(self:GetParent().FollowerTab, followerID)
		end)

		if frame.MissionComplete then
			-- double click to add follower to mission
			for index, button in pairs(frame.FollowerList.listScroll.buttons) do
				button:HookScript('OnDoubleClick', FollowerOnDoubleClick)
			end
			-- enable follower tooltips & links on mission complete
			for index, button in pairs(frame.MissionComplete.Stage.FollowersFrame.Followers) do
				button:HookScript('OnMouseDown', MissionCompleteFollowerOnClick)
				button:SetScript('OnEnter', MissionCompleteFollowerOnEnter)
				button:SetScript('OnLeave', MissionCompleteFollowerOnLeave)
			end
			-- show success chance on finished missions
			hooksecurefunc(frame.MissionComplete.ChanceFrame.ResultAnim, 'Play', function(self)
				MissionCompleteSuccessChance(frame)
			end)
			-- add skip animations instructions
			local _, Title, Summary, info = frame.MissionTab.MissionList.CompleteDialog.BorderFrame.Model:GetRegions()
			if info and info:GetObjectType() == 'FontString' and info:GetText() == _G.GARRISON_SKIP_ANIMATION_LABEL then
				info:SetFormattedText(addon.L['skipAnimationInstructions'], _G.SHIFT_KEY, _G.KEY_SPACE)
			end
		end

		if frame.MissionTab and frame.MissionTab.MissionPage then
			-- show follower counter info on mission page
			if addon.db.showMissionPageThreats then
				local page = frame.MissionTab.MissionPage
				page:SetPoint('TOPRIGHT', '$parent', 'TOPRIGHT', -55, -34-30)
				page:SetHeight(550)

				page:HookScript('OnShow', function(self)
					frame.FollowerTab.NumFollowers:SetParent(frame.MissionTab)
					frame.FollowerTab.ThreatCountersFrame:SetParent(frame.MissionTab)
				end)
				page:HookScript('OnHide', function(self)
					frame.FollowerTab.NumFollowers:SetParent(frame.FollowerTab)
					frame.FollowerTab.ThreatCountersFrame:SetParent(frame.FollowerTab)
				end)
			end
		end
	end

	if addon.db.showMissionPageThreats then
		hooksecurefunc(GarrisonMission, 'UpdateMissionData', function(self, missionPage)
			if self:GetName() == 'GarrisonShipyardFrame' then
				local point, anchor, relativeTo, x, y = missionPage.Enemy1:GetPoint()
				missionPage.Enemy1:SetPoint(point, anchor, relativeTo, x, -83 + 20)
				local point, anchor, relativeTo, x, y = missionPage.Follower1:GetPoint()
				missionPage.Follower1:SetPoint(point, anchor, relativeTo, x, -206 + 20)
			else
				if not missionPage.BuffsFrame or not missionPage.BuffsFrame:IsShown() then return end
				local anchor, anchorTo, otherAnchor, x, y = missionPage.BuffsFrame:GetPoint()
				missionPage.BuffsFrame:SetPoint(anchor, anchorTo, otherAnchor, x, 198 - 18)
			end
		end)
	end

	-- show garrison buildings in minimap button tooltip
	local minimapButton = GarrisonLandingPageMinimapButton
	minimapButton:HookScript('OnEnter', ShowMinimapBuildings)
	if addon.db.showMinimapBuildings and GameTooltip:GetOwner() == minimapButton then
		-- update minimap icon tooltip if it's currently shown
		minimapButton:GetScript('OnEnter')(minimapButton)
	end

	if addon.db.setMissionFrameMovable then
		local frame = GarrisonMissionFrame
		      frame:SetMovable(true)
		frame:CreateTitleRegion():SetAllPoints(frame.TopBorder)
		GarrisonLandingPage:SetMovable(true)
		GarrisonLandingPage:CreateTitleRegion():SetAllPoints(GarrisonLandingPage)
	end

	-- add threat counters list to recruiter frames
	local frame = GarrisonRecruiterFrame
	frame.ThreatCountersFrame = CreateFrame('Frame', nil, frame, 'GarrisonThreatCountersFrameTemplate')
	frame.ThreatCountersFrame:SetPoint('TOPRIGHT', -42, -60)
	frame.ThreatCountersFrame:Show()
	for i, threatButton in pairs(frame.ThreatCountersFrame.ThreatsList) do
		if i >= 2 then
			local point, anchor, otherPoint, x, y = threatButton:GetPoint()
			threatButton:SetPoint(point, anchor, otherPoint, x+5, y)
		end
	end

	local frame = GarrisonRecruitSelectFrame
	frame.ThreatCountersFrame = CreateFrame('Frame', nil, frame, 'GarrisonThreatCountersFrameTemplate')
	frame.ThreatCountersFrame:SetPoint('TOPRIGHT', frame.FollowerSelection, 'TOPRIGHT', -12, 30)
	frame.ThreatCountersFrame:Show()
	frame.FollowerSelection.ChooseFollower:SetJustifyH('LEFT')

	-- extend Blizzard's threat counters list
	local frames = {
		GarrisonThreatCountersFrame,
		GarrisonRecruiterFrame.ThreatCountersFrame,
		GarrisonRecruitSelectFrame.ThreatCountersFrame,
		GarrisonShipyardFrame.FollowerTab.ThreatCountersFrame,
		GarrisonLandingPage.ShipFollowerTab.ThreatCountersFrame,
	}
	for _, frame in pairs(frames) do
		for index, button in ipairs(frame.ThreatsList) do
			button:HookScript('OnEnter', ThreatOnEnter)
		end
		frame:HookScript('OnShow', UpdateThreatCounterButtons)
	end

	-- Blizzard_GarrisonUI might have been forcably loaded
	addon:GARRISON_UPGRADEABLE_RESULT('GARRISON_UPGRADEABLE_RESULT')
	-- try again when more info is available
	addon.frame:RegisterEvent('GARRISON_UPGRADEABLE_RESULT')

	addon.frame:UnregisterEvent(event)
end
