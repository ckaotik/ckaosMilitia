# 6.2v4
- Fixed incorrect mission threat counter information when threats were encountered multiple times
- Fixed shipyard bonus effect areas not showing on non-English locales
- Fixed error when double clicking on follower list when not currently building a party.

# 6.2v3
- Fixed lua error when follower list was too short
- Fixed ship mission return times only showing up on landing page
- Replaced ability icons on followers displayed on landing page with their countered mechanics
- Display armor and weapon levels on followers displayed on landing page
- Unified rendering and logic of threat buttons added to mission lists. When desaturateUnavailable is disabled, checkmarks will be shown similar to the default UI. When fading unavailable counters, additional icons indicating mission or work status will be displayed.

# 6.2v2
- Completely removed threat counter tabs. Instead we're now always using Blizzard style threat counter buttons.
- Updated "show low level counters" code for 6.2
- New: Shipyard: Display threat icons on missions
- New: Shipyard: Recognize "show mission page threats" setting
- New: Shipyard: Display cost and duration on shipyard missions. (must enable showRequiredResources setting)
- New: Shipyard: Show return time instead of "on a mission" on ship follower list
- New: Shipyard: Added mission expiry information to shipyard mission tooltips
- Fixed: Error when assigning follower workers to buildings.
- Fixed: Incorrect tooltips on shipyard counters in follower list.
- Fixed: Follower item level is disregarded for threat counters.
- Fixed: Remove follower data when ship gets destroyed.

# 6.2v1
- Updated for patch 6.2
- Rewrote animation skipping code. Hold down shift to skip mission complete animations but keep displaying rewards
- Fixed issue detecting available counters when low level missions report high req. ilevels
- Extended double-click-to-toggle behaviour to ships
- Extended mission complete tooltips to ships.
- Mission list: Do not append resource cost when mission costs no resources.
- Extended mission tooltips, including reward icons, follower level & quality
- Fixed grayed out followers, threats and counts when loading together with Blizzard_GarrisonUI

# 6.1v2
- New: expiry time to every mission's tooltip (not just rare missions)
- New: mission expiry in tooltips on landing page
- Fixed: follower counters were displayed when assigning followers to building slots
- Fixed: delay initialization to work with addons that force load the garrison UI

# 6.1v1
## General
- added ingame configuration
- added configuration for battle animation duration
- allow moving the garrison report frame
- added building information to garrison minimap button
- added learnable abilities in several places
- replace ability icons with their countered threat in tooltips, follower list and recruiter frame
- added a setting to always display ability counters even when not building a mission group
- low level follower's counters may now also be displayed in lists when building a mission group

## Threat Counter Tabs
- allow clicking tabs to filter the follower list for this ability
- added setting to (not) count working followers in tab totals
- show placeholders for counter tabs we have no followers for
- integrate with Blizzard's threat counter buttons
- attach to GarrisonRecruitSelectFrame frame (shown after selecting recruiter ability/trait)

## Mission Complete Dialog
- show follower tooltip on mission complete dialog
- added SHIFT linking followers on mission complete dialog
- displaying success chance on mission complete

## Mission List
- replace level with ilevel for max level missions
  This solves space issues for level 100 rare missions that have an item level requirement
- color resources red when insufficient

## Bugs
- fixed threat tab counts not updating right away when mission was failed
- fixed title being moved too far up when opening + closing mission page
- do not show reward quantity for items with common quality (I see you, Legion Chili!)

# 6.0v8
- Fixed required item level to help on a mission
- Fixed unavailable followers being "added" to missions via double click.
- Fixed flickering of counter tabs.

# 6.0v7
- Changed: Tab tooltips also display follower name in gray when follower is inactive
- New: Double click a follower to add to the current mission
- New: Allow mission frame to be moved

# 6.0v6
- Fixed: Threat icons stayed grayed out when followers were assigned but the mission then closed
- Fixed: Dancer trait not registering as counter to Danger Zone
- Fixed: Inactive followers are considered in tab counts even though they're not available
- New: Added option to show required resources

# 6.0v5
- Fixed: lua error that had already been fixed in 6.0v2

# 6.0v4
- Fixed: lua error when not all threats have countering followers

# 6.0v3
- New: Desaturate threats that cannot be countered with your available followers.
- New: Display follower mission return times in tooltip.
- Fixed: No longer displays "1" count.

# 6.0v2
- fixed lua error when item data is not yet available

# 6.0v1
- First release
