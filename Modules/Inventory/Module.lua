local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local GENERAL_COLOR_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1
local GENERAL_COLOR_GREY = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_2
local GENERAL_COLOR_OFF_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3
local GENERAL_COLOR_RED = GAMEPAD_TOOLTIP_COLOR_FAILED

local changed = false

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Inventory Improvement Settings")

	local optionsTable = {
		{
			type = "checkbox",
			name = "Enable \"Junk\" feature",
			tooltip = "Allows items to be marked as \"junk\" to de-clutter the inventory and allow deletion of protected items",
			getFunc = function() return BETTERUI.Settings.Modules["Inventory"].enableJunk end,
			setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].enableJunk = value
				changed = true
				end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Enable \"Stolen\" inventory category",
			tooltip = "Displays items marked as \"stolen\" as their own tab category",
			getFunc = function() return BETTERUI.Settings.Modules["Inventory"].enableStolen end,
			setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].enableStolen = value
				changed = true
				end,
			width = "full",
			requiresReload = true,
		},
        {
            type = "checkbox",
            name = "Enable category wrapping",
            tooltip = "Enables quick access to \"Quickslots\" when you press LB when selecting \"All\"",
            getFunc = function() return BETTERUI.Settings.Modules["Inventory"].enableWrapping end,
            setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].enableWrapping = value end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Use triggers to move to next item type",
            tooltip = "Rather than skip a certain number of items every trigger press (default global behaviour), this will move to the next item type",
            getFunc = function() return BETTERUI.Settings.Modules["Inventory"].useTriggersForSkip end,
            setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].useTriggersForSkip = value end,
            width = "full",
        },
		{
            type = "checkbox",
            name = "Display character attributes when switching tooltip",
            tooltip = "Show the character attributes on the switching tooltip rather than seeing the current equipped item",
            getFunc = function() return BETTERUI.Settings.Modules["Inventory"].displayCharAttributes end,
            setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].displayCharAttributes = value end,
            width = "full",
        },
        {
            type = "checkbox",
            name = "Replace \"Value\" with the market's price",
            tooltip = "Replaces the item \"Value\" with either Master Merchant's price or TTC's market price",
            getFunc = function() return BETTERUI.Settings.Modules["Inventory"].showMarketPrice end,
            setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].showMarketPrice = value end,
            width = "full",
        },
		{
			type = "checkbox",
			name = "Short Currency Format",
			tooltip = "Automatically formats the value column to shorten large numbers and to display the currency with commas",
			getFunc = function() return BETTERUI.Settings.Modules["Inventory"].useShortFormat end,
			setFunc = function(value) BETTERUI.Settings.Modules["Inventory"].useShortFormat = value
				changed = true
				end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Bind on Equip Protection",
			tooltip = "Show a dialog before equipping Bind on Equip items",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].bindOnEquipProtection end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].bindOnEquipProtection = value
				changed = true
				end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Unbound Items",
			tooltip = "Show an icon after unbound items",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconUnboundItem end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconUnboundItem = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Enchantment",
			tooltip = "Show an icon after enchanted item",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconEnchantment end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconEnchantment = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Set Gear",
			tooltip = "Show an icon after set gears",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconSetGear end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconSetGear = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Iakoni's Gear Changer",
			tooltip = "Show the first set number in Iakoni's settings",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconIakoniGearChanger end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconIakoniGearChanger = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Show all sets instead",
			tooltip = "Show all sets if in multiple Iakoni's settings",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconIakoniGearChangerAllSets end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconIakoniGearChangerAllSets = value
				changed = true end,
			width = "full",
			requiresReload = true,
			disabled = function() return not BETTERUI.Settings.Modules["Inventory"].showIconIakoniGearChanger end,  
		},		
		{
			type = "checkbox",
			name = "Item Icon - GamePadBuddy's Status Indicator",
			tooltip = "Show an icon to indicate gear's researchable/known/duplicated/researching/ornate/intricate status",
			getFunc = function () return BETTERUI.Settings.Modules["Inventory"].showIconGamePadBuddyStatusIcon end,
			setFunc = function (value) BETTERUI.Settings.Modules["Inventory"].showIconGamePadBuddyStatusIcon = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "button",	
			name = "Reload UI",
			func = function() ReloadUI() end,
		},	         	 	
	}
	LAM:RegisterAddonPanel("BETTERUI_"..mId, panelData)
	LAM:RegisterOptionControls("BETTERUI_"..mId, optionsTable)
end

function BETTERUI.Inventory.InitModule(m_options)
    m_options["enableWrapping"] = true
    m_options["showMarketPrice"] = false
    m_options["useTriggersForSkip"] = false
    m_options["enableJunk"] = true
    m_options["enableStolen"] = true
	m_options["displayCharAttributes"] = true
	m_options["useShortFormat"] = true
	m_options["bindOnEquipProtection"] = true
	m_options["showIconEnchantment"] = true
	m_options["showIconSetGear"] = true
	m_options["showIconUnboundItem"] = true
	m_options["showIconIakoniGearChanger"] = true
	m_options["showIconIakoniGearChangerAllSets"] = false
	m_options["showIconGamePadBuddyStatusIcon"] = true

    return m_options
end


-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Finally, the Setup() function which replaces the inventory system with a duplicate that I've heavily modified. Duplication is necessary as I don't
--    have access to the beginning :New() method of ZO_GamepadInventory. Will mess quite a few addons up, but will make GAMEPAD_INVENTORY a reference at the end
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

function BETTERUI.Inventory.Setup()
	Init("Inventory", "Inventory")

	GAMEPAD_INVENTORY = BETTERUI.Inventory.Class:New(BETTERUI_GamepadInventoryTopLevel) -- Bam! Initialise the custom inventory class so it's integrated neatly

	GAMEPAD_INVENTORY_FRAGMENT = ZO_SimpleSceneFragment:New(BETTERUI_GamepadInventoryTopLevel) -- **Replaces** the old inventory with a new one defined in "Templates/GamepadInventory.xml"
    GAMEPAD_INVENTORY_FRAGMENT:SetHideOnSceneHidden(true)

    -- Now update the changes throughout the interface...
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_INVENTORY_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_INVENTORY)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)


    -- Just some modification to the right tooltip to be cleaner
	ZO_GamepadTooltipTopLevelLeftTooltipContainer.tip.maxFadeGradientSize=10
	
	-- This code allows the player to scroll the tooltips with their mouse
	ZO_GamepadTooltipTopLevelLeftTooltipContainerTip:SetMouseEnabled(true)
	ZO_GamepadTooltipTopLevelLeftTooltipContainerTipScroll:SetMouseEnabled(true)
	ZO_GamepadTooltipTopLevelLeftTooltipContainerTip:SetHandler("OnMouseWheel", function(self, delta) 
		local newScrollValue
		
		if delta > 0 then
			newScrollValue = self.scrollValue - BETTERUI.Settings.Modules["CIM"].rhScrollSpeed
		else
			newScrollValue = self.scrollValue + BETTERUI.Settings.Modules["CIM"].rhScrollSpeed
		end
		
		self.scrollValue = newScrollValue
		self.scroll:SetVerticalScroll(newScrollValue)
	end)
	

	GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.fragment.control.container:SetAnchor(3,ZO_GamepadTooltipTopLevelLeftTooltip,3,40,-100,0)		


	inv = GAMEPAD_INVENTORY

	--ZO_TOOLTIP_STYLES["topSection"] = {
		--fontSize = "$(GP_27)",
		--height = DOES NOT EXIST

	if(BETTERUI.Settings.Modules["CIM"].tooltipSize == "Small") then
        ZO_TOOLTIP_STYLES["topSection"] = { -- Item Type (e.g. Ring, Neck, Crown Item)
            layoutPrimaryDirection = "up",
            layoutSecondaryDirection = "right",
            widthPercent = 100,
            childSpacing = 1,
            fontSize = 22,
            height = 64,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
		}
		ZO_TOOLTIP_STYLES["flavorText"] = {
			fontSize = 22,
		}
        ZO_TOOLTIP_STYLES["statValuePairStat"] = { --Level word
            fontSize = 22,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
        }
        ZO_TOOLTIP_STYLES["statValuePairValue"] = { --Level Number
            fontSize = 30,
            fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["title"] = {  --Item name
            fontSize = 32,
			customSpacing = 8,
			--widthPercent = 100,
            uppercase = true,
            fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["bodyDescription"] = { -- Actual item stats including set bonuses
            fontSize = 22,
        }
	elseif(BETTERUI.Settings.Modules["CIM"].tooltipSize == "Medium") then
        ZO_TOOLTIP_STYLES["topSection"] = { -- Item Type (e.g. Ring, Neck, Crown Item)
            layoutPrimaryDirection = "up",
            layoutSecondaryDirection = "right",
            widthPercent = 100,
            childSpacing = 1,
            fontSize = 25,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
		}
		ZO_TOOLTIP_STYLES["flavorText"] = {
			fontSize = 34,
		}
        ZO_TOOLTIP_STYLES["statValuePairStat"] = { --Level word
            fontSize = 27,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
		}
        ZO_TOOLTIP_STYLES["statValuePairValue"] = { --Level Number
            fontSize = 38,
            fontColorField = GENERAL_COLOR_WHITE,
		}
        ZO_TOOLTIP_STYLES["title"] = { --Item name
            fontSize = 34,
			customSpacing = 8,
			widthPercent = 100,
            uppercase = true,
			fontColorField = GENERAL_COLOR_WHITE,
		}
        ZO_TOOLTIP_STYLES["bodyDescription"] = { -- Actual item stats including set bonuses
            fontSize = 34,
        }
	elseif(BETTERUI.Settings.Modules["CIM"].tooltipSize == "Large") then
        ZO_TOOLTIP_STYLES["topSection"] = { -- Item Type (e.g. Ring, Neck, Crown Item)
            layoutPrimaryDirection = "up",
            layoutSecondaryDirection = "right",
            widthPercent = 100,
            childSpacing = 1,
            fontSize = 27,
            height = 64,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
        }
		ZO_TOOLTIP_STYLES["flavorText"] = {
			fontSize = 38,
		}
        ZO_TOOLTIP_STYLES["statValuePairStat"] = { --Level word
            fontSize = 27,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
        }
        ZO_TOOLTIP_STYLES["statValuePairValue"] = { --Level Number
            fontSize = 42,
            fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["title"] = { --Item name
            fontSize = 38,
			customSpacing = 8,
			widthPercent = 100,
            uppercase = true,
			fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["bodyDescription"] = { -- Actual item stats including set bonuses
            fontSize = 38,
        }
    end
	
	if not SaveEquip ~= nil or not SaveEquip then
	
		ZO_Dialogs_RegisterCustomDialog("CONFIRM_EQUIP_BOE", {
			gamepadInfo =
			{
				dialogType = GAMEPAD_DIALOGS.BASIC,
			},
			title =
			{
				text = SI_SAVE_EQUIP_CONFIRM_TITLE,
			},
			mainText =
			{
				text = SI_SAVE_EQUIP_CONFIRM_EQUIP_BOE,
			},
			buttons =
			{
				[1] =
				{
					text =      SI_SAVE_EQUIP_EQUIP,
					callback =  function(dialog)
						dialog.data.callback()
					end
				},
				
				[2] =
				{
					text =      SI_DIALOG_CANCEL,
				}
			}
		})
	end
end
