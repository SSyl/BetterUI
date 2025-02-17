local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local changed = false
local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Banking Improvement Settings")

	local optionsTable = {
		{
			type = "checkbox",
			name = "Item Icon - Unbound Items",
			tooltip = "Show an icon after unbound items.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconUnboundItem end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconUnboundItem = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Enchantment",
			tooltip = "Show an icon after enchanted item.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconEnchantment end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconEnchantment = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Set Gear",
			tooltip = "Show an icon after set gears.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconSetGear end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconSetGear = value
				changed = true end,
			width = "full",
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Iakoni's Gear Changer",
			tooltip = "Show the first set number in Iakoni's settings.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChanger end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChanger = value
				changed = true end,
			width = "full",
			disabled = function() return BETTERUI.Settings.Modules["Banking"].showIconAlphaGear end,
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Item Icon - Alpha Gear",
			tooltip = "Show the first set number in Alpha Gear.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconAlphaGear end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconAlphaGear = value
				changed = true end,
			width = "full",
			disabled = function() return BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChanger end,
			requiresReload = true,
		},
		{
			type = "checkbox",
			name = "Show all sets instead",
			tooltip = "Show all sets if in multiple settings.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChangerAllSets end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChangerAllSets = value
				changed = true end,
			width = "full",
			requiresReload = true,
			disabled = function() return not BETTERUI.Settings.Modules["Banking"].showIconIakoniGearChanger and not BETTERUI.Settings.Modules["Banking"].showIconAlphaGear end,  
		},		
		{
			type = "checkbox",
			name = "Item Icon - GamePadBuddy's Status Indicator",
			tooltip = "Show an icon to indicate gear's researchable/known/duplicated/researching/ornate/intricate status.",
			getFunc = function () return BETTERUI.Settings.Modules["Banking"].showIconGamePadBuddyStatusIcon end,
			setFunc = function (value) BETTERUI.Settings.Modules["Banking"].showIconGamePadBuddyStatusIcon = value
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

function BETTERUI.Banking.InitModule(m_options)
	m_options["showIconEnchantment"] = true
	m_options["showIconSetGear"] = true
	m_options["showIconUnboundItem"] = true
	m_options["showIconIakoniGearChanger"] = true
	m_options["showIconIakoniGearChangerAllSets"] = true
	m_options["showIconAlphaGear"] = true
	m_options["showIconGamePadBuddyStatusIcon"] = true
	return m_options
end

function BETTERUI.Banking.Setup()

	Init("Bank", "Banking")

	BETTERUI.Banking.Init()

end
