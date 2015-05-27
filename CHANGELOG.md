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
