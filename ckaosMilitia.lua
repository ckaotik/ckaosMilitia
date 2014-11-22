local addonName, addon, _ = ...
addon = CreateFrame('Frame')

local skipBattleAnimation = true

-- GLOBALS: _G, C_Garrison, C_Timer, GameTooltip, GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage
-- GLOBALS: CreateFrame, IsAddOnLoaded, RGBTableToColorCode
-- GLOBALS: pairs, ipairs, wipe, table, strsplit
local tinsert, tsort = table.insert, table.sort

local propertyOrder = {'iLevel', 'level', 'name'}
local function SortFollowers(a, b)
	local dataA, dataB = C_Garrison.GetFollowerInfo(a), C_Garrison.GetFollowerInfo(b)
	for _, property in ipairs(propertyOrder) do
		if dataA[property] ~= dataB[property] then
			return dataA[property] < dataB[property]
		end
	end
end

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
				local dataTable = abilities[ability.isTrait and 'trait' or 'ability']
				for _, threat in pairs(ability.counters) do
					local threatLabel = ('%s|%s|%s'):format(threat.icon, threat.name, threat.description)
					if not dataTable[threatLabel] then dataTable[threatLabel] = {} end
					tinsert(dataTable[threatLabel], follower.followerID)
					tsort(dataTable[threatLabel], SortFollowers)
				end
			end
		end
	end
	return abilities
end

local function ShowAbilityTooltip(self, motion)
	local threat = self.threat
	local followers = threat and abilities.ability[threat]
	if not followers then return end

	if self.description then
		GameTooltip:AddLine(self.description, 255, 255, 255, true)
		GameTooltip:AddLine(' ')
	end

	for _, followerID in pairs(followers) do
		local data = C_Garrison.GetFollowerInfo(followerID)
		local displayLevel = data.iLevel
		if data.level < 100 then
			-- display invisible zero to keep padding intact
			displayLevel = '|c000000000|r'..data.level
		end
		local text  = ('%1$s%2$s|r %3$s'):format(RGBTableToColorCode(_G.ITEM_QUALITY_COLORS[data.quality]), displayLevel, data.name)
		local statusColor = data.status == _G.GARRISON_FOLLOWER_ON_MISSION and _G.RED_FONT_COLOR or _G.YELLOW_FONT_COLOR
		GameTooltip:AddDoubleLine(text, data.status or '', nil, nil, nil, statusColor.r, statusColor.g, statusColor.b)
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
	ScanFollowerAbilities()
	local index = 1
	for threat, followers in pairs(abilities.ability) do
		local icon, name, description = strsplit('|', threat)
		local followersList = '' -- table.concat(followers, '|n')
		local numAvailable, numFollowers = #followers, #followers
		for _, followerID in pairs(followers) do
			local data = C_Garrison.GetFollowerInfo(followerID)
			if data.status and data.status ~= _G.GARRISON_FOLLOWER_IN_PARTY then
				numAvailable = numAvailable - 1
			end
		end

		local tab = GetTab(frame, index)
		tab.threat = threat
		tab:SetNormalTexture(icon)
		tab.tooltip = ('|T%1$s:0|t %2$s'):format(icon, name)
		tab.description = description
		tab.count:SetText(numAvailable ~= numFollowers
			and ('%d/%d'):format(numAvailable, numFollowers)
			or numFollowers)
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
end
addon:RegisterEvent('GARRISON_SHOW_LANDING_PAGE')
function addon:GARRISON_SHOW_LANDING_PAGE()
	UpdateFollowerTabs(GarrisonLandingPage)
end
addon:RegisterEvent('GARRISON_FOLLOWER_LIST_UPDATE')
function addon:GARRISON_FOLLOWER_LIST_UPDATE()
	for _, frame in pairs({GarrisonMissionFrame, GarrisonRecruiterFrame, GarrisonLandingPage}) do
		if frame:IsShown() then
			UpdateFollowerTabs(frame)
		end
	end
end

-- initialize on the currently shown frame
C_Timer.After(0.1, addon.GARRISON_FOLLOWER_LIST_UPDATE)

if skipBattleAnimation then
	-- allow to immediately click the reward chest
	hooksecurefunc('GarrisonMissionComplete_OnMissionCompleteResponse', function(self, missionID, canComplete, success)
		self.Stage.EncountersFrame.FadeOut:Play()
		self.animIndex = GarrisonMissionComplete_FindAnimIndexFor(GarrisonMissionComplete_AnimRewards) - 1
		self.animTimeLeft = 0
	end)
end
