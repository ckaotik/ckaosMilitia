local addonName, addon, _ = ...
local panel

local function OnClick(self)
	addon.db[self.setting] = not addon.db[self.setting]
	if self.setting == 'showTabs' then
		addon.GARRISON_FOLLOWER_LIST_UPDATE()
	end
end

local function OnValueChanged(self, value)
	addon.db[self.setting] = value
end

local function OnEnter(self)
	if not self.setting or not addon.L[self.setting..'Desc'] then return end
	GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
	GameTooltip:AddLine(addon.L[self.setting] or self.setting, 1, 1, 1)
	GameTooltip:AddLine(addon.L[self.setting..'Desc'], nil, nil, nil, true)
	GameTooltip:Show()
end

local function OpenConfiguration(self, args)
	if not self.label then
		-- initial load
		local label = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
		label:SetPoint('TOPLEFT', 10, -15)
		label:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 10, -45)
		label:SetJustifyH('LEFT')
		label:SetJustifyV('TOP')
		label:SetText(addonName)
		self.label = label
	end

	local prevCheckbox = nil
	if not self.controls then self.controls = {} end
	for setting, default in pairs(addon.defaults) do
		if type(default) == 'boolean' then
			if not self.controls[setting] then
				local checkbox = CreateFrame('CheckButton', '$parent'..setting:gsub("^%l", string.upper), self, 'OptionsCheckButtonTemplate')
				checkbox:SetHitRectInsets(0, -150, 0, 0)
				checkbox:SetScript('OnClick', OnClick)
				checkbox:SetScript('OnEnter', OnEnter)
				checkbox:SetScript('OnLeave', GameTooltip_Hide)
				checkbox.text = _G[checkbox:GetName()..'Text']
				checkbox.setting = setting

				if prevCheckbox then
					checkbox:SetPoint('TOPLEFT', prevCheckbox, 'BOTTOMLEFT', 0, -2)
				else
					checkbox:SetPoint('TOPLEFT', self, 'TOPLEFT', 10, -40)
				end
				self.controls[setting] = checkbox
				prevCheckbox = checkbox
			end

			local control = self.controls[setting]
			control:SetChecked(addon.db[setting])
			control.text:SetText(addon.L[setting] or setting)
		end
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
