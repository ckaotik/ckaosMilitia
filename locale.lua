local addonName, addon, _ = ...

local L = {
	showMissionPageThreats       = 'Show threat buttons on mission page',
	showMissionPageThreatsDesc   = 'Display default Blizzard threat counter buttons on mission page.',
	excludeWorkingFromTotals     = 'Exclude working from tab count',
	excludeWorkingFromTotalsDesc = 'Check to not include working followers in tab total counts.',
	showLowLevelCounters         = 'Show low level counters',
	showLowLevelCountersDesc     = 'Display abilities that group followers below the mission level could provide.',
	showListCounters             = 'Show counters in lists',
	showListCountersDesc         = 'Display follower\'s abilities in all lists, including landing page and follower tab.',
	showMinimapBuildings         = 'Show buildings in minimap tooltip',
	showMinimapBuildingsDesc     = 'Display active buildings in the Garrison minimap tooltip',
	setMissionFrameMovable       = 'Move MissionFrame',
	setMissionFrameMovableDesc   = 'Allow the mission frame to be moved.|n' .. _G.RED_FONT_COLOR_CODE..'This requires a reload.',
	doubleClickToAddFollower     = 'Double-click to add followers',
	doubleClickToAddFollowerDesc = 'Add followers to the current mission by double-clicking them in the follower list.',
	replaceAbilityWithThreat     = 'Replace tooltip icons',
	replaceAbilityWithThreatDesc = 'Replace follower tooltip ability icons with their respective counters',
	showFollowerAbilityOptions   = 'Show learnable counters',
	showFollowerAbilityOptionsDesc = 'Adds icons for threat counters that can be learned by a follower\'s class.',
	missionCompleteFollowerTooltips = 'Mission complete tooltips',
	missionCompleteFollowerTooltipsDesc = 'Enable follower tooltips in mission complete scene.',
	showTTRewardInfo             = 'Show tooltip reward info',
	showTTRewardInfoDesc         = 'Display reward icons and amount texts in mission tooltip reward section.',

	-- mission list
	showExtraMissionInfo         = 'Show extra mission information',
	showExtraMissionInfoDesc     = 'Make adjustments to the mission list, including number of followers, threat icons and reward texts.|n' .. _G.RED_FONT_COLOR_CODE..'Unchecking this disables all mission list features.',
	showRewardCounts             = 'Show reward counts',
	showRewardCountsDesc         = 'Display the item level or amount of gold/experience on mission reward buttons.',
	showMissionThreats           = 'Show mission threat icons',
	showMissionThreatsDesc       = 'Display mission threats as icons below the mission title.',
	desaturateUnavailable        = 'Fade uncountered threats',
	desaturateUnavailableDesc    = 'Fade out threats that cannot be countered with your followers.',
	showRequiredResources        = 'Show required resources',
	showRequiredResourcesDesc    = 'Append the amount of required resources to mission duration texts.',
	showFollowerReturnTime       = 'Show return time',
	showFollowerReturnTimeDesc   = 'Display follower return times in threat counter list tooltips.',

	skipAnimationInstructions    = 'Use %s to skip combat animations|nor %s to skip all animations.',
}
addon.L = L

if GetLocale() == 'deDE' then
	L.skipAnimationInstructions = 'Verwende %s um Kämpfe zu überspringen|noder %s um alle Animationen zu überspringen.'
end
