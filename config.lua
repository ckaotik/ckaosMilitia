local addonName, addon, _ = ...
local panel

local function OnClick(self)
	addon.db[self.setting] = not addon.db[self.setting]
	if self.setting == 'showTabs' then
		addon.GARRISON_FOLLOWER_LIST_UPDATE()
	end
end

local function OnEnter(self)
	if not self.setting or not addon.L[self.setting..'Desc'] then return end
	GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(addon.L[self.setting] or self.setting, 1, 1, 1)
	GameTooltip:AddLine(addon.L[self.setting..'Desc'], nil, nil, nil, true)
	GameTooltip:Show()
end

local function OpenConfiguration(self, args)
	local i = 1
	if not self[i] then
		-- initial load
		local label = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
		label:SetPoint('TOPLEFT', 10, -15)
		label:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 10, -45)
		label:SetJustifyH('LEFT')
		label:SetJustifyV('TOP')
		label:SetText(addonName)
	end

	for setting in pairs(addon.defaults) do
		if not self[i] then
			local button = CreateFrame('CheckButton', '$parentCheckButton'..i, self, 'OptionsCheckButtonTemplate', i)
			button:SetHitRectInsets(0, -150, 0, 0)
			button:SetScript('OnClick', OnClick)
			button:SetScript('OnEnter', OnEnter)
			button:SetScript('OnLeave', GameTooltip_Hide)
			button.text = _G[button:GetName()..'Text']

			if i == 1 then
				button:SetPoint('TOPLEFT', self, 'TOPLEFT', 10, -40)
			else
				button:SetPoint('TOPLEFT', self[i-1], 'BOTTOMLEFT', 0, -4)
			end
			self[i] = button
		end

		local checkbox = self[i]
		checkbox:SetChecked(addon.db[setting])
		checkbox.text:SetText(addon.L[setting] or setting)
		checkbox.setting = setting
		i = i + 1
	end

	if not self:IsVisible() then
		InterfaceOptionsFrame_OpenToCategory(addonName)
	end
end

panel = CreateFrame('Frame', addonName..'Config')
panel.name = addonName
panel:Hide()
panel:SetScript('OnShow', OpenConfiguration)
InterfaceOptions_AddCategory(panel)

-- use slash command to toggle config
_G['SLASH_'..addonName..'1'] = '/'..addonName
_G.SlashCmdList[addonName] = function(args) InterfaceOptionsFrame_OpenToCategory(addonName) end
