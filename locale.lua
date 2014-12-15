local addonName, addon, _ = ...

addon.L = {
	showTabs                     = 'Show threat tabs',
	showTabsDesc                 = 'Display counterable threats as tabs that attach to several garrison frames.',
	showMinimapBuildings         = 'Show buildings in minimap tooltip',
	showMinimapBuildingsDesc     = 'Display active buildings in the Garrison minimap tooltip',
	skipBattleAnimation          = 'Skip battle animation',
	skipBattleAnimationDesc      = 'Skip the battle animation that is played before being able to collect mission rewards.',
	setMissionFrameMovable       = 'Move MissionFrame',
	setMissionFrameMovableDesc   = 'Allow the mission frame to be moved.|n' .. _G.RED_FONT_COLOR_CODE..'This requires a reload.',
	doubleClickToAddFollower     = 'Double-click to add followers',
	doubleClickToAddFollowerDesc = 'Add followers to the current mission by double-clicking them in the follower list.',
	replaceAbilityWithThreat     = 'Replace tooltip icons',
	replaceAbilityWithThreatDesc = 'Replace follower tooltip ability icons with their respective counters',
	missionCompleteFollowerTooltips = 'Mission complete tooltips',
	missionCompleteFollowerTooltipsDesc = 'Enable follower tooltips in mission complete scene.',

	-- mission list
	showExtraMissionInfo         = 'Show extra mission information',
	showExtraMissionInfoDesc     = 'Make adjustments to the mission list, including number of followers, threat icons and reward texts.|n' .. _G.RED_FONT_COLOR_CODE..'Unchecking this disables all mission list features.',
	showRewardCounts             = 'Show reward counts',
	showRewardCountsDesc         = 'Display the item level or amount of gold/experience on mission reward buttons.',
	showMissionThreats           = 'Show threat icons',
	showMissionThreatsDesc       = 'Display mission threats as icons below the mission title.',
	desaturateUnavailable        = 'Fade uncountered threats',
	desaturateUnavailableDesc    = 'Fade out threats that cannot be countered with your followers.',
	showRequiredResources        = 'Show required resources',
	showRequiredResourcesDesc    = 'Append the amount of required resources to mission duration texts.',
	showOnMissionCounters        = 'Show counters when on mission',
	showOnMissionCountersDesc    = 'Display counters for followers that are currently on a mission.',
	showFollowerReturnTime       = 'Show return time',
	showFollowerReturnTimeDesc   = 'Display follower return times in threat counter tab tooltips.',
}
