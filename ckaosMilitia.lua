local addonName, addon, _ = ...
_G[addonName] = addon

-- GLOBALS: _G, C_Garrison, C_Timer, GameTooltip, GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonRecruitSelectFrame, GarrisonLandingPage, ITEM_QUALITY_COLORS
-- GLOBALS: CreateFrame, IsAddOnLoaded, RGBTableToColorCode, HybridScrollFrame_GetOffset, GetItemInfo, BreakUpLargeNumbers, HandleModifiedItemClick, GetCurrencyInfo
-- GLOBALS: GarrisonMissionComplete_FindAnimIndexFor, GarrisonMissionComplete_AnimRewards, GarrisonLandingPageMinimapButton, GarrisonMissionPageFollowerFrame_OnEnter, GarrisonMissionPageFollowerFrame_OnLeave, GarrisonFollowerButton_SetCounterButton, GarrisonMissionPage_AddFollower, GarrisonMissionPage_UpdateParty
-- GLOBALS: pairs, ipairs, wipe, table, strsplit, tostring, strjoin, strrep, next, hooksecurefunc

local tinsert, tsort = table.insert, table.sort
local emptyTable = {}

-- issue: open mission, close mission, title will not be aligned properly
-- issue: UI blames excessive memory usage on us, also we supposedly taint
-- issue: mission fails, follower tab counts are not updated

addon.frame = CreateFrame('Frame')
addon.frame:SetScript('OnEvent', function(self, event, ...)
	if addon[event] then addon[event](addon, event, ...) end
end)
addon.frame:RegisterEvent('ADDON_LOADED')

addon.defaults = {
	skipBattleAnimation = true,
	showExtraMissionInfo = true,
	showMissionThreats = true,
	showRewardCounts = true,
	desaturateUnavailable = true,
	showFollowerReturnTime = true,
	showRequiredResources = true,
	setMissionFrameMovable = true,
	showOnMissionCounters = true,
	showMinimapBuildings = true,
	doubleClickToAddFollower = true,
	replaceAbilityWithThreat = true,
	missionCompleteFollowerTooltips = true,
	showTabs = true,
}

-- these numbers match the ingame .classSpec values
local _, bdk, fdk, udk, bdruid, _, fdruid, gdruid, rdruid, bhunter, _, mhunter, shunter, amage, firemage, fmage, bmonk, mmonk, wmonk, hpala, ppala, rpala, dpriest, hpriest, spriest, arogue, crogue, srogue, eleshaman, enhshaman, rshaman, alock, demolock, dlock, awarri, _, fwarri, pwarri = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38
local abilityClasses = {
	[1] = { -- wild aggression
		fdk, udk, bdk, gdruid, fdruid, bhunter, bmonk, wmonk, ppala, awarri, pwarri,
	},
	[2] = { -- massive strike
		fdruid, gdruid, bdk, udk, shunter, rpala, ppala, fmage, bmonk, arogue, srogue, dlock, pwarri, fwarri,
	},
	[3] = { -- group damage
		rshaman, mmonk, dlock, hpala, hpriest, dpriest, rdruid,
	},
	[4] = { -- magic debuff
		fdk, rdruid, mmonk, hpala, ppala, hpriest, dpriest, spriest, rshaman, alock,
	},
	[6] = { -- danger zones
		fdruid, gdruid, bdruid, shunter, mhunter, bhunter, amage, firemage, wmonk, bmonk, mmonk, hpriest, dpriest, spriest, arogue, srogue, crogue, enhshaman, awarri, fwarri, pwarri,
	},
	[7]  = { -- minion swarms
		fdk, bdk, udk, bdruid, rdruid, shunter, mhunter, bhunter, fmage, firemage, rpala, hpriest, spriest, crogue, srogue, rshaman, eleshaman, enhshaman, alock, demolock, awarri, fwarri, pwarri,
	},
	[8] = { -- powerful spell
		fdk, bdk, udk, mhunter, fmage, firemage, amage, mmonk, wmonk, rpala, hpala, ppala, arogue, srogue, crogue, eleshaman, rshaman, alock, demolock, dlock, awarri, fwarri, pwarri,
	},
	[9] = { -- deadly minions
		rdruid, gdruid, bdruid, shunter, mhunter, bhunter, fmage, firemage, amage, bmonk, wmonk, rpala, hpala, ppala, dpriest, spriest, arogue, srogue, crogue, eleshaman, enhshaman, alock, dlock,
	},
	[10]  = { -- timed battle, multiples: druid, mage, warlock
		fdk, bdk, udk, rdruid, gdruid, bdruid, fdruid, shunter, mhunter, bhunter, fmage, firemage, amage, wmonk, mmonk, rpala, hpala, hpriest, dpriest, spriest, arogue, crogue, rshaman, eleshaman, enhshaman, alock, demolock, dlock, awarri, fwarri,
	},
}
--[[
-- local bdk, fdk, udk, bdruid, fdruid, gdruid, rdruid, bhunter, mhunter, shunter, amage, firemage, fmage, bmonk, mmonk, wmonk, hpala, ppala, rpala, dpriest, hpriest, spriest, arogue, crogue, srogue, rshaman, eleshaman, enhshaman, alock, demolock, dlock, awarri, fwarri, pwarri = 250, 251, 252, 102, 103, 104, 105, 253, 254, 255, 62, 63, 64, 268, 270, 269, 65, 66, 70, 256, 257, 258, 259, 260, 261, 264, 262, 263, 265, 266, 267, 71, 72, 73
for threatID, specs in pairs(abilityClasses) do
	for i, specID in pairs(specs) do
		-- translate spec ids into localized spec names
		specs[i] = select(2, GetSpecializationInfoByID(specID))
	end
end --]]
-- TODO: supply this info somewhere

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

local mechanics, abilities = {}, {}
local function ScanFollowerAbilities(followerID, data)
	-- Note: this churns the client's memory ...
	-- should probably use local abilityID = C_Garrison.GetFollower(Ability|Trait)AtIndex(followerID, i)
	-- local followerAbilities = data.abilities
	local followerAbilities = C_Garrison.GetFollowerAbilities(followerID)
	for abilityIndex, ability in pairs(followerAbilities) do
		-- 232: dancer counters danger zones
		if not ability.isTrait or ability.id == 232 then
			local mechanicID, mechanicInfo = next(ability.counters)
			if not abilities[mechanicID] then abilities[mechanicID] = {} end
			if not tContains(abilities[mechanicID], followerID) then
				tinsert(abilities[mechanicID], followerID)
			end
			if not mechanics[mechanicID] then
				-- store reference to info table
				mechanics[mechanicID] = mechanicInfo
			end
		end
	end
end
local function ScanAllFollowerAbilities(followerList)
	for abilityID, followers in pairs(abilities) do
		wipe(followers)
	end
	-- if possible, reuse existing list
	for index, info in pairs(followerList or C_Garrison.GetFollowers()) do
		if info.isCollected then
			ScanFollowerAbilities(info.followerID, info)
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

local function ThreatOnEnter(self)
	local followers = self.threatID and abilities[self.threatID]
	if not followers then return end

	if self.description then
		GameTooltip:AddLine(self.description, 255, 255, 255, true)
		GameTooltip:AddLine(' ')
	end

	tsort(followers, SortFollowers)
	for _, followerID in pairs(followers) do
		local level   = C_Garrison.GetFollowerLevel(followerID)
		local iLevel  = C_Garrison.GetFollowerItemLevelAverage(followerID)
		local quality = C_Garrison.GetFollowerQuality(followerID)
		local status  = C_Garrison.GetFollowerStatus(followerID) or ''
		local name    = C_Garrison.GetFollowerName(followerID)

		local qualityColor = RGBTableToColorCode(_G.ITEM_QUALITY_COLORS[quality])
		local displayLevel
		if level < 100 then
			-- display invisible zero to keep padding intact
			displayLevel = '|c000000000|r'..qualityColor..level..'|r '
		else
			displayLevel = qualityColor .. iLevel .. '|r '
		end
		local color = _G.YELLOW_FONT_COLOR
		if status == _G.GARRISON_FOLLOWER_INACTIVE then
			color = _G.GRAY_FONT_COLOR
			name  = _G.GRAY_FONT_COLOR_CODE .. name .. '|r'
		elseif status == _G.GARRISON_FOLLOWER_ON_MISSION then
			color = _G.RED_FONT_COLOR
			if addon.db.showFollowerReturnTime then
				-- follower will return from her mission
				status = GetMissionTimeLeft(followerID)
			end
		end
		GameTooltip:AddDoubleLine(displayLevel..name, status, nil, nil, nil, color.r, color.g, color.b)
	end
	GameTooltip:Show()
end

local function ThreatOnClick(self, btn, up)
	self:SetChecked(false)
	local list = self:GetParent().FollowerList
	if not list or not list:IsShown() or not list.SearchBox then return end
	local mechanic = mechanics[self.threatID]
	local text = btn == 'RightButton' and '' or mechanic.name
	list.SearchBox:SetText(text)
	GarrisonFollowerList_UpdateFollowers(list)
end

local function GetTab(index)
	local tab = addon[index]
	if not tab then
		tab = CreateFrame('CheckButton', nil, nil, 'SpellBookSkillLineTabTemplate', index)
		tab:HookScript('OnEnter', ThreatOnEnter)
		tab:SetScript('OnClick', ThreatOnClick)
		tab:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		tab:Show()
		local count = tab:CreateFontString(nil, nil, 'NumberFontNormalSmall')
		      count:SetAllPoints()
		      count:SetJustifyH('RIGHT')
		      count:SetJustifyV('BOTTOM')
		tab.count = count
		addon[index] = tab
	end
	return tab
end

local function UpdateFollowerTabs(frame)
	if not addon.db.showTabs then
		for index, tab in ipairs(addon) do
			tab:SetParent(nil)
			tab:Hide()
		end
	elseif not frame or not frame:IsShown() then
		-- don't update for invisible frames
		return
	end
	-- print('UpdateFollowerTabs', frame.FollowerList.followers and #frame.FollowerList.followers)

	local index = 1
	for threatID, followers in pairs(abilities) do
		local numAvailable, numFollowers = #followers, #followers
		for _, followerID in pairs(followers) do
			local status = C_Garrison.GetFollowerStatus(followerID)
			if status and status ~= _G.GARRISON_FOLLOWER_IN_PARTY then
				numAvailable = numAvailable - 1
				if status == _G.GARRISON_FOLLOWER_INACTIVE then
					-- don't count inactive followers in tab count
					numFollowers = numFollowers - 1
				end
			end
		end

		local threatInfo = mechanics[threatID]
		local tab = GetTab(index)
		if tab:GetParent() ~= frame then
			tab:SetParent(frame)
			tab:ClearAllPoints()
			tab:SetPoint('TOPLEFT', frame, 'TOPRIGHT', frame == GarrisonLandingPage and -10 or 0, 16 - 44*index)
		end
		tab:SetNormalTexture(threatInfo.icon)
		tab:Show()
		tab.count:SetText(numAvailable ~= numFollowers and ('%d/%d'):format(numAvailable, numFollowers) or numFollowers)
		tab.tooltip = ('|T%1$s:0|t %2$s'):format(threatInfo.icon, threatInfo.name)
		tab.description = threatInfo.description
		tab.threatID = threatID
		index = index + 1
	end
end

-- allow to immediately click the reward chest
local function SkipBattleAnimation(self, missionID, canComplete, success)
	if not addon.db.skipBattleAnimation then return end
	self.Stage.EncountersFrame.FadeOut:Play()
	self.animIndex = GarrisonMissionComplete_FindAnimIndexFor(GarrisonMissionComplete_AnimRewards) - 1
	self.animTimeLeft = 0
end

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
		if not button:IsShown() then break end

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
		button.followers:SetText(strrep(followerSlotIcon, mission.numFollowers))

		-- show required abilities
		local _, _, env, envDesc, envIcon, _, _, enemies = C_Garrison.GetMissionInfo(mission.missionID)
		local numThreats = 1
		for j = 1, #enemies do
			if not addon.db.showMissionThreats then break end
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
				if not active and addon.db.desaturateUnavailable then
					local numCounters = 0
					for _, followerID in ipairs(abilities[threatID] or emptyTable) do
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
		-- hide unused threat buttons
		while button.threats[numThreats] do
			button.threats[numThreats]:Hide()
			numThreats = numThreats + 1
		end

		if not active and addon.db.showRequiredResources then
			local duration = mission.duration
			-- TODO: add more steps to colorize by duration
			if mission.durationSeconds >= _G.GARRISON_LONG_MISSION_TIME then
				duration = _G.GARRISON_LONG_MISSION_TIME_FORMAT:format(mission.duration)
			end
			button.Summary:SetDrawLayer('OVERLAY') -- fix our icon layer
			button.Summary:SetFormattedText('(%2$s, %3$s%1$s|r |TInterface\\Icons\\inv_garrison_resource:0:0:0:0|t)',
				mission.cost or 0, duration, (mission.cost or 0) > numRessources and _G.RED_FONT_COLOR_CODE or '')
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
	if not addon.db.showRewardCounts or numRewards < 1 then return end
	local index = 1
	for id, reward in pairs(rewards) do
		local button = self.Rewards[index]
		if not button:GetScript('OnMouseDown') then
			-- allow shift-click to post rewards to chat
			button:SetScript('OnMouseDown', OnRewardClick)
		end
		button.link = nil
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
			button.link = link
		end
		if quantity and quantity ~= 1 then
			button.Quantity:Show()
			button.Quantity:SetText(quantity)
		end
		index = index + 1
	end
end

-- note: this will still only show counters for followers that meet level/ilevel requirements
local function ShowOnMissionCounters(button, follower, showCounters)
	if not addon.db.showOnMissionCounters then return end
	if follower.status ~= _G.GARRISON_FOLLOWER_ON_MISSION then return end
	local counters = GarrisonMissionFrame.followerCounters and GarrisonMissionFrame.followerCounters[follower.followerID]
	if not counters or #counters < 1 then return end
	for i = 1, #counters do
		if i > 4 then break end
		GarrisonFollowerButton_SetCounterButton(button, i, counters[i])
	end
	button.Counters[1]:SetPoint('TOPRIGHT', -8, #counters <= 2 and -16 or -4)
end

local function FollowerOnDoubleClick(self, btn)
	if not addon.db.doubleClickToAddFollower or GarrisonMissionFrame.selectedTab ~= 1 then return end
	-- trigger second click handling
	self:GetScript('OnClick')(self, btn)

	-- add to mission
	local status = C_Garrison.GetFollowerStatus(self.id)
	if status == _G.GARRISON_FOLLOWER_IN_PARTY then
		local missionID = GarrisonMissionFrame.MissionTab.MissionPage.missionInfo.missionID
		C_Garrison.RemoveFollowerFromMission(missionID, self.id)
	elseif not status then
		-- cannot add inactive/on mission/... followers
		GarrisonMissionPage_AddFollower(self.id)
	end
	GarrisonMissionPage_UpdateParty()
end

-- note: this will only work once Blizzard_GarrisonUI (and therefore this addon) is loaded
local function ShowMinimapBuildings(self, motion)
	if not addon.db.showMinimapBuildings then return end
	local buildings = C_Garrison.GetBuildings()
	tsort(buildings, SortBuildingsBySize)

	for i, building in ipairs(buildings) do
		if i == 1 then GameTooltip:AddLine(' ') end
		local _, name, _, icon, description, rank, _, _, _, _, _, _, _, upgrades, canUpgrade, isMaxLevel, _, _, _, _, isBeingBuilt, _, _, _, canCompleteBuild = C_Garrison.GetOwnedBuildingInfo(building.plotID)
		local bonusText, resources, gold, _, buildTime, needsPlan = C_Garrison.GetBuildingTooltip(upgrades and upgrades[rank+1] or 0)

		local infoText = _G.GARRISON_BUILDING_LEVEL_TOOLTIP_TEXT:format(rank)
		if canCompleteBuild then
			infoText = _G.GREEN_FONT_COLOR_CODE .. infoText .. '|r'
		elseif isBeingBuilt then
			infoText = '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t' .. infoText
		elseif rank == _G.GARRISON_MAX_BUILDING_LEVEL then
			infoText = _G.GRAY_FONT_COLOR_CODE .. infoText .. '|r'
		elseif not needsPlan then
			infoText = '|TInterface\\petbattles\\battlebar-abilitybadge-strong-small:0|t' .. infoText
		end

		GameTooltip:AddDoubleLine('|T'..icon..':0|t '..name, infoText)
	end
	GameTooltip:Show()
end

local function MissionCompleteFollowerOnEnter(self, ...)
	if not addon.db.missionCompleteFollowerTooltips then return end
	local followerID = GarrisonMissionFrame.MissionComplete.currentMission.followers[self:GetID()]
	self.info = C_Garrison.GetFollowerInfo(followerID)
	GarrisonMissionPageFollowerFrame_OnEnter(self, ...)
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
	if addon.db.replaceAbilityWithThreat and not ability.isTrait then
		local _, _, icon = C_Garrison.GetFollowerAbilityCounterMechanicInfo(ability.id)
		self.Abilities[index].Icon:SetTexture(icon)
	end
end

-- --------------------------------------------------------
--  Event handlers
-- --------------------------------------------------------
function addon:GARRISON_MISSION_NPC_OPENED()
	UpdateFollowerTabs(GarrisonMissionFrame)
end
function addon:GARRISON_RECRUITMENT_NPC_OPENED()
	UpdateFollowerTabs(GarrisonRecruiterFrame)
	UpdateFollowerTabs(GarrisonRecruitSelectFrame)
end
function addon:GARRISON_SHOW_LANDING_PAGE()
	UpdateFollowerTabs(GarrisonLandingPage)
end
-- follower returns from mission
-- function addon:GARRISON_MISSION_COMPLETE_RESPONSE(missionID, canComplete, isSuccess)
--	UpdateFollowerTabs(GarrisonMissionFrame)
-- end
local frames = {GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage, GarrisonRecruitSelectFrame}
function addon:GARRISON_FOLLOWER_LIST_UPDATE()
	-- TODO: we could probably pick more suitable events/hooks for these actions
	-- this tracks: => work, => mission, => inactive, and probably more
	for _, frame in pairs(frames) do
		UpdateFollowerTabs(frame)
	end
end

function addon:GARRISON_FOLLOWER_XP_CHANGED(event, followerID, xpGain, oldXP, oldLevel, oldQuality)
	local _, _, level, quality, currXP, maxXP = C_Garrison.GetFollowerMissionCompleteInfo(followerID)
	if quality > oldQuality and quality == _G.LE_ITEM_QUALITY_EPIC then
		-- new ability at epic quality
		ScanFollowerAbilities(followerID)
	end
end

function addon:GARRISON_FOLLOWER_ADDED(event, followerID, name, displayID, level, quality)
	ScanFollowerAbilities(followerID)
end

function addon:UNIT_SPELL_CAST_SUCCEEDED(event, unit, _, _, _, spellID)
	-- follower retraining certificate / hearthstone pro
	if unit == 'player' and (spellID == 174829 or spellID == 174254) then
		ScanAllFollowerAbilities()
	end
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
			return db[key]
		end,
	})

	-- register events
	addon.frame:RegisterEvent('GARRISON_MISSION_NPC_OPENED')
	addon.frame:RegisterEvent('GARRISON_RECRUITMENT_NPC_OPENED')
	addon.frame:RegisterEvent('GARRISON_SHOW_LANDING_PAGE')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_XP_CHANGED')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_LIST_UPDATE')
	addon.frame:RegisterEvent('GARRISON_FOLLOWER_ADDED')
	addon.frame:RegisterEvent('UNIT_SPELL_CAST_SUCCEEDED')

	-- setup hooks
	hooksecurefunc('GarrisonMissionComplete_OnMissionCompleteResponse', SkipBattleAnimation)
	hooksecurefunc('GarrisonMissionPage_ClearParty', UpdateMissionList)
	hooksecurefunc('GarrisonMissionList_Update', UpdateMissionList)
	hooksecurefunc(GarrisonMissionFrame.MissionTab.MissionList.listScroll, 'update', UpdateMissionList)
	hooksecurefunc('GarrisonMissionButton_SetRewards', UpdateMissionRewards)
	hooksecurefunc('GarrisonFollowerButton_UpdateCounters', ShowOnMissionCounters)
	hooksecurefunc('GarrisonFollowerTooltipTemplate_SetGarrisonFollower', TooltipReplaceAbilityWithThreat)
	hooksecurefunc('GarrisonFollowerButton_AddAbility', FollowerListReplaceAbilityWithThreat)
	hooksecurefunc('GarrisonRecruitSelectFrame_UpdateRecruits', function()
		UpdateFollowerTabs(GarrisonRecruitSelectFrame)
	end)

	-- show garrison buildings in minimap button tooltip
	local minimapButton = GarrisonLandingPageMinimapButton
	minimapButton:HookScript('OnEnter', ShowMinimapBuildings)
	if addon.db.showMinimapBuildings and GameTooltip:GetOwner() == minimapButton then
		-- update minimap icon tooltip if it's currently shown
		minimapButton:GetScript('OnEnter')(minimapButton)
	end

	-- double click to add follower to mission
	for index, button in ipairs(GarrisonMissionFrame.FollowerList.listScroll.buttons) do
		button:HookScript('OnDoubleClick', FollowerOnDoubleClick)
	end

	-- show follower tooltips in mission complete scene
	for index, frame in pairs(GarrisonMissionFrame.MissionComplete.Stage.FollowersFrame.Followers) do
		frame:SetID(index)
		-- these frames do not properly set their OnEnter/OnLeave scripts
		frame:SetScript('OnEnter', MissionCompleteFollowerOnEnter)
		frame:SetScript('OnLeave', GarrisonMissionPageFollowerFrame_OnLeave)
	end

	-- initialize on the currently shown frame
	ScanAllFollowerAbilities()
	C_Timer.After(0.05, addon.GARRISON_FOLLOWER_LIST_UPDATE) -- slight delay because ... reasons

	if addon.db.setMissionFrameMovable then
		local frame = GarrisonMissionFrame
		      frame:SetMovable(true)
		frame:CreateTitleRegion():SetAllPoints(frame.TopBorder)
	end

	addon.frame:UnregisterEvent(event)
end
