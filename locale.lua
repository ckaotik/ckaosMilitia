local addonName, addon, _ = ...

addon.L = {
	showMinimapBuildings         = 'Show buildings in minimap tooltip',
	showMinimapBuildingsDesc     = 'Check to display active buildings in the Garrison minimap tooltip',
	skipBattleAnimation          = 'Skip battle animation',
	skipBattleAnimationDesc      = 'Check to skip the battle animation that is played before being able to collect mission rewards.',
	setMissionFrameMovable       = 'Move MissionFrame',
	setMissionFrameMovableDesc   = 'Check to allow the mission frame to be moved.|n' .. _G.RED_FONT_COLOR_CODE..'This requires a reload.',
	doubleClickToAddFollower     = 'Double-click to add followers',
	doubleClickToAddFollowerDesc = 'Check to add followers to the current mission when double-clicking them in the follower list.',
	notifyLevelQualityChange     = 'Print follower changes',
	notifyLevelQualityChangeDesc = 'Check to print a message to chat whenever a follower gains a level or improves in quality.',

	-- mission list
	showExtraMissionInfo         = 'Show extra mission information',
	showExtraMissionInfoDesc     = 'Check to make adjustments to the mission list, including number of followers, threat icons and reward texts.|n' .. _G.RED_FONT_COLOR_CODE..'Unchecking this disables all mission list features.',
	showRewardCounts             = 'Show reward counts',
	showRewardCountsDesc         = 'Check to display the item level or items or amount of gold/experience on mission reward buttons.',
	showMissionThreats           = 'Show threat icons',
	showMissionThreatsDesc       = 'Check to display mission threats as icons below the mission title.',
	desaturateUnavailable        = 'Fade uncountered threats',
	desaturateUnavailableDesc    = 'Check to fade out threats that cannot be countered with your followers.',
	showRequiredResources        = 'Show required resources',
	showRequiredResourcesDesc    = 'Check to add the amount of resources required for each mission after its duration.',
	showOnMissionCounters        = 'Show counters when on mission',
	showOnMissionCountersDesc    = 'Check to display counters for followers that are currently on a mission.',
	showFollowerReturnTime       = 'Show return time',
	showFollowerReturnTimeDesc   = 'Check to display follower return times in threat counter tab tooltips.',
}
