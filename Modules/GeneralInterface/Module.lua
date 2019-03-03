local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT = "inventory"
local ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT = "bank"
local ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT = "inventoryAndBank"

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "General Interface Improvement Settings")

	local optionsTable = {
		{
		type = "checkbox",
			name = "Display item style and trait knowledge",
			tooltip = "On items, displays the style of the item and whether the trait can be researched",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showStyleTrait end,
			setFunc = function(value) BUI.Settings.Modules["Tooltips"].showStyleTrait = value end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display the account name next to the character name?",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showAccountName end,
			setFunc = function(value)
						BUI.Settings.Modules["Tooltips"].showAccountName = value
						UNIT_FRAMES.firstDirtyGroupIndex = 1
					end,
			width = "full",
		},
		{
			type = "colorpicker",
			name = "Character name color",
			getFunc = function() return unpack(BUI.Settings.Modules["Tooltips"].showCharacterColor) end,
			setFunc = function(r,g,b,a) BUI.Settings.Modules["Tooltips"].showCharacterColor={r,g,b,a} end,
			width = "full",	--or "half" (optional)
		},
		{
			type = "colorpicker",
			name = "Account name color",
			getFunc = function() return unpack(BUI.Settings.Modules["Tooltips"].showAccountColor) end,
			setFunc = function(r,g,b,a) BUI.Settings.Modules["Tooltips"].showAccountColor={r,g,b,a} end,
			width = "full",	--or "half" (optional)
		},
		{
			type = "checkbox",
			name = "Display the health value (text) on the target?",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showHealthText end,
			setFunc = function(value)
						BUI.Settings.Modules["Tooltips"].showHealthText = value
						UNIT_FRAMES.firstDirtyGroupIndex = 1
						end,
			width = "full",
		},
		{
            type = "editbox",
            name = "Chat window history size",
            tooltip = "Alters how many lines to store in the chat buffer, default=200",
            getFunc = function() return BUI.Settings.Modules["Tooltips"].chatHistory end,
            setFunc = function(value) BUI.Settings.Modules["Tooltips"].chatHistory = tonumber(value)
            							if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.Settings.Modules["Tooltips"].chatHistory) end end,
            default=200,
            width = "full",
        },
		{
			type = "checkbox",
			name = "Remove the 'delete' dialog in the Mail inbox?",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].removeDeleteDialog end,
			setFunc = function(value)
						BUI.Settings.Modules["Tooltips"].removeDeleteDialog = value
					end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "MasterMerchant integration",
			tooltip = "Hooks MasterMerchant into the guild store and item tooltips",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].mmIntegration end,
			setFunc = function(value) BUI.Settings.Modules["Tooltips"].mmIntegration = value
					end,
			disabled = function() return MasterMerchant == nil end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Tamriel Trade Centre integration",
			tooltip = "Hooks TTC Price info into the guild store if MM is not presented",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].ttcIntegration end,
			setFunc = function(value) BUI.Settings.Modules["Tooltips"].ttcIntegration = value
					end,
			disabled = function() return TamrielTradeCentre == nil end,
			width = "full",
			requiresReload = true,
		},
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Tooltips.UpdateText(self, updateBarType, updateValue)
    if(self.showBarText == SHOW_BAR_TEXT or self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER) then
        local visible = GetVisibility(self)
        if(self.leftText and self.rightText) then
            self.leftText:SetHidden(not visible)
            self.rightText:SetHidden(not visible)
            if visible then
                if updateBarType then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARTYPE, self.barTypeName))
                end
                if updateValue then
                    self.rightText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            end
        elseif(self.leftText) then
            if visible then
                self.leftText:SetHidden(false)
                if updateValue then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            else
                self.leftText:SetHidden(true)
            end
        end
    end

    if BUI.Settings.Modules["Tooltips"].showHealthText and self.BUI_labelRef ~= nil then
        self.BUI_labelRef:SetText(BUI.DisplayNumber(self.currentValue).." ("..string.format("%.0f",100*self.currentValue/self.maxValue).."%)")
    	self.BUI_labelRef:SetHidden(false)
    else
    end

end

function BUI.Tooltips.InitModule(m_options)
    m_options["chatHistory"] = 200
    m_options["showStyleTrait"] = true
    m_options["showHealthText"] = true
    m_options["showAccountName"] = true
    m_options["showCharacterColor"] = {1, 0.95, 0.5, 1}
	m_options["showAccountColor"] = {1, 1, 1, 1}
	m_options["removeDeleteDialog"] = false
	m_options["mmIntegration"] = true
	m_options["ttcIntegration"] = true
    return m_options
end

function BUI.Tooltips.Setup()

	Init("General", "General Interface")

	if BUI.Settings.Modules["Tooltips"].removeDeleteDialog then
		BUI.PostHook(ZO_MailInbox_Gamepad, 'InitializeKeybindDescriptors', function(self)
			self.mainKeybindDescriptor[3]["callback"] = function() self:Delete() end
		end)
	end

	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	ZO_PreHook(UNIT_FRAMES,"UpdateGroupAnchorFrames", BUI.Tooltips.UpdateGroupAnchorFrames)
	UNIT_FRAMES.staticFrames.reticleover.RefreshControls = BUI.Tooltips.RefreshControls

	if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.Settings.Modules["Tooltips"].chatHistory) end
end
