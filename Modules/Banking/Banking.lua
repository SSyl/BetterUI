local _

local BANKING_ROW_TEMPLATE = "BUI_GenericEntry_Template"

local LIST_WITHDRAW = 1
local LIST_DEPOSIT  = 2
local lastUsedBank = 0
local currentUsedBank = 0
local lastActionName

local function GetCategoryTypeFromWeaponType(bagId, slotIndex)
    local weaponType = GetItemWeaponType(bagId, slotIndex)
    if weaponType == WEAPONTYPE_AXE or weaponType == WEAPONTYPE_HAMMER or weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_DAGGER then
        return GAMEPAD_WEAPON_CATEGORY_ONE_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_TWO_HANDED_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_AXE or weaponType == WEAPONTYPE_TWO_HANDED_HAMMER then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_LIGHTNING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF
    elseif weaponType == WEAPONTYPE_HEALING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF
    elseif weaponType == WEAPONTYPE_BOW then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
    elseif weaponType ~= WEAPONTYPE_NONE then
        return GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED
    end
end

local function IsTwoHandedWeaponCategory(categoryType)
    return (categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE or
            categoryType == GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW)
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.equipType == EQUIP_TYPE_INVALID then
        return GetString("SI_ITEMTYPE", itemData.itemType)
    end
    local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
    if categoryType ==  GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
        local weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
        return GetString("SI_WEAPONTYPE", weaponType)
    elseif categoryType then
        return GetString("SI_GAMEPADWEAPONCATEGORY", categoryType)
    end
    local armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
    local itemLink = GetItemLink(itemData.bagId,itemData.slotIndex)
    if armorType ~= ARMORTYPE_NONE then
        return GetString("SI_ARMORTYPE", armorType).." "..GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))
    end
    local fullDesc = GetString("SI_ITEMTYPE", itemData.itemType)
	
	-- Stops types like "Poison" displaying "Poison" twice
	if( fullDesc ~= GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))) then
		fullDesc = fullDesc.." "..GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))
	end
	
	return fullDesc
end

local function GetMarketPrice(itemLink, stackCount)
	if(stackCount == nil) then stackCount = 1 end
	
	if (BUI.Settings.Modules["Tooltips"].mmIntegration and MasterMerchant ~= nil) then
		local mmData = MasterMerchant:itemStats(itemLink, false)
		if (mmData.avgPrice ~= nil) then
			return mmData.avgPrice*stackCount
		end
	end
	return 0
end

local function SetupListing(control, data)
    local itemQualityColour = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)
    local fullItemName = itemQualityColour:Colorize(data.name)..(data.stackCount > 1 and " ("..data.stackCount..")" or "")

    local itemLink = GetItemLink(dS.bagId, dS.slotIndex)
    local currentItemType = GetItemLinkItemType(itemLink) --GetItemType(bagId, slotIndex) 
    if(BUI.Settings.Modules["CIM"].attributeIcons) then
        local dS = data
        local bagId = dS.bagId
        local slotIndex = dS.slotIndex
		local isLocked = dS.isPlayerLocked
        local isBoPTradeable = dS.isBoPTradeable
        local labelTxt = ""
	
		if isLocked then labelTxt = labelTxt.. "|t24:24:"..ZO_GAMEPAD_LOCKED_ICON_32.."|t" end
        if isBoPTradeable then labelTxt = labelTxt.."|t24:24:"..ZO_TRADE_BOP_ICON.."|t" end
        fullItemName = labelTxt .. fullItemName
		
        local setItem, _, _, _, _ = GetItemLinkSetInfo(itemLink, false)
        local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemLink)
	
	
		local isUnbound = not IsItemBound(bagId, slotIndex) and not data.stolen and data.quality ~= ITEM_QUALITY_TRASH
	
		if isUnbound and BUI.Settings.Modules["Banking"].showIconUnboundItem then fullItemName = fullItemName.." |t16:16:/esoui/art/guild/gamepad/gp_ownership_icon_guildtrader.dds|t" end
        if(hasEnchantment and BUI.Settings.Modules["Banking"].showIconEnchantment) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
        if(setItem and BUI.Settings.Modules["Banking"].showIconSetGear) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
		   
		if currentItemType == ITEMTYPE_RECIPE and not IsItemLinkRecipeKnown(itemLink) then fullItemName = fullItemName.." |t16:16:/esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_provisioning.dds|t" end
		if BUI.Settings.Modules["Banking"].showIconGamePadBuddyStatusIcon then fullItemName = fullItemName .. BUI.Helper.GamePadBuddy.GetItemStatusIndicator(bagId, slotIndex)  end
		if BUI.Settings.Modules["Banking"].showIconIakoniGearChanger then fullItemName = fullItemName .. BUI.Helper.IokaniGearChanger.GetGearSet(bagId, slotIndex, "Banking")  end
		if BUI.Settings.Modules["Banking"].showIconAlphaGear then fullItemName = fullItemName .. BUI.Helper.AlphaGear.GetGearSet(bagId, slotIndex, "Banking")  end
         
    end
    control:GetNamedChild("ItemType"):SetText(string.upper(data.itemCategoryName))
    if currentItemType == ITEMTYPE_RECIPE then
        control:GetNamedChild("Stat"):SetText(IsItemLinkRecipeKnown(itemLink) and GetString(SI_BUI_INV_RECIPE_KNOWN) or GetString(SI_BUI_INV_RECIPE_UNKNOWN))
    elseif IsItemLinkBook(itemLink) then
        control:GetNamedChild("Stat"):SetText(IsItemLinkBookKnown(itemLink) and GetString(SI_BUI_INV_RECIPE_KNOWN) or GetString(SI_BUI_INV_RECIPE_UNKNOWN))
    else
        control:GetNamedChild("Stat"):SetText((data.statValue == 0) and "-" or data.statValue)
    end
    control:GetNamedChild("Icon"):ClearIcons()
    control:GetNamedChild("Label"):SetText(fullItemName)
    control:GetNamedChild("Icon"):AddIcon(data.iconFile)
    control:GetNamedChild("Icon"):SetHidden(false)
    if not data.meetsUsageRequirement then control:GetNamedChild("Icon"):SetColor(1,0,0,1) else control:GetNamedChild("Icon"):SetColor(1,1,1,1) end
	
	if(BUI.Settings.Modules["Inventory"].showMarketPrice) then
		local marketPrice = GetMarketPrice(GetItemLink(data.bagId,data.slotIndex), data.stackCount)
		if(marketPrice ~= 0) then
			control:GetNamedChild("Value"):SetColor(1,0.75,0,1)
			control:GetNamedChild("Value"):SetText(ZO_CurrencyControl_FormatCurrency(math.floor(marketPrice), USE_SHORT_CURRENCY_FORMAT))
		else
			control:GetNamedChild("Value"):SetColor(1,1,1,1)
			control:GetNamedChild("Value"):SetText(data.stackSellPrice)
		end
	else
		control:GetNamedChild("Value"):SetColor(1,1,1,1)
		control:GetNamedChild("Value"):SetText(ZO_CurrencyControl_FormatCurrency(data.stackSellPrice, USE_SHORT_CURRENCY_FORMAT))
	end
end

local function SetupLabelListing(control, data)
    control:GetNamedChild("Label"):SetText(data.label)
    if BUI.Settings.Modules["CIM"].biggerSkin then
        control:GetNamedChild("Label"):SetFont("ZoFontGamepad36")
    end
end

BUI.Banking.Class = BUI.Interface.Window:Subclass()

function BUI.Banking.Class:New(...)
	return BUI.Interface.Window.New(self, ...)
end

function BUI.Banking.Class:CurrentUsedBank()
    if(IsHouseBankBag(GetBankingBag()) == false) then
        currentUsedBank = BAG_BANK
    elseif (IsHouseBankBag(GetBankingBag()) == true) then
        currentUsedBank = GetBankingBag()
    else
        currentUsedBank = BAG_BANK
    end
end

function BUI.Banking.Class:LastUsedBank()
   if(IsHouseBankBag(GetBankingBag()) == false) then
        lastUsedBank = BAG_BANK
    elseif (IsHouseBankBag(GetBankingBag()) == true) then
        lastUsedBank = GetBankingBag()
    else
        lastUsedBank = BAG_BANK
    end
end

function BUI.Banking.Class:RefreshFooter()

    if(currentUsedBank == BAG_BANK) then
            --d(IsHouseBankBag())
            --IsBankOpen()
        self.footer.footer:GetNamedChild("DepositButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_all.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))))
        self.footer.footer:GetNamedChild("WithdrawButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/icons/mapkey/mapkey_bank.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BANK) + GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK), GetBagUseableSize(BAG_BANK) + GetBagUseableSize(BAG_SUBSCRIBER_BANK))))
    else
        self.footer.footer:GetNamedChild("DepositButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_all.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))))
        self.footer.footer:GetNamedChild("WithdrawButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/icons/mapkey/mapkey_bank.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(currentUsedBank), GetBagUseableSize(currentUsedBank))))
    end

    if((self.currentMode == LIST_WITHDRAW) and (currentUsedBank == BAG_BANK)) then
        self.footerFragment.control:GetNamedChild("Data1Value"):SetText(BUI.DisplayNumber(GetBankedCurrencyAmount(CURT_MONEY)))
        self.footerFragment.control:GetNamedChild("Data2Value"):SetText(BUI.DisplayNumber(GetBankedCurrencyAmount(CURT_TELVAR_STONES)))
    else
        self.footerFragment.control:GetNamedChild("Data1Value"):SetText(BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_MONEY)))
        self.footerFragment.control:GetNamedChild("Data2Value"):SetText(BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_TELVAR_STONES)))
    end
end

function BUI.Banking.Class:RefreshList()
    lastActionName = nil
    --d("tt refresh bank list")
    self.list:OnUpdate()
    self.list:Clear()
    self:CurrentUsedBank()

    -- We have to add 2 rows to the list, one for Withdraw/Deposit GOLD and one for Withdraw/Deposit TEL-VAR
    local wdString = self.currentMode == LIST_WITHDRAW and GetString(SI_BUI_BANKING_WITHDRAW) or GetString(SI_BUI_BANKING_DEPOSIT)
    wdString = zo_strformat("<<Z:1>>", wdString)
    if(currentUsedBank == BAG_BANK) then
        self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFF"..wdString.." " .. GetString(SI_BUI_CURRENCY_GOLD) ..  "|r", currencyType = CURT_MONEY})
        self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFF"..wdString.." " .. GetString(SI_BUI_CURRENCY_TEL_VAR) ..  "|r", currencyType = CURT_TELVAR_STONES})
        self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFF"..wdString.." " .. GetString(SI_BUI_CURRENCY_ALLIANCE_POINT) ..  "|r", currencyType = CURT_ALLIANCE_POINTS})
        self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFF"..wdString.." " .. GetString(SI_BUI_CURRENCY_WRIT_VOUCHER) ..  "|r", currencyType = CURT_WRIT_VOUCHERS})
    else
        if(self.currentMode == LIST_WITHDRAW) then
            if(GetNumBagUsedSlots(currentUsedBank) == 0) then
                self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFFHOUSE BANK IS EMPTY!|r"})
            else
                self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFFHOUSE BANK|r"})
            end
        else
            if(GetNumBagUsedSlots(BAG_BACKPACK) == 0) then
                self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFFPLAYER BAG IS EMPTY!|r"})
            else
                self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFFFFFPLAYER BAG|r"})
            end
        end        
    end
    --fix subscriber bank bag issue
    checking_bags = {}
    local slotType
    if(self.currentMode == LIST_WITHDRAW) then
        if(currentUsedBank == BAG_BANK) then
          checking_bags[1] = BAG_BANK
          checking_bags[2] = BAG_SUBSCRIBER_BANK
          slotType = SLOT_TYPE_BANK_ITEM
        else
            checking_bags[1] = currentUsedBank
            slotType = SLOT_TYPE_BANK_ITEM
        end
    else 
        checking_bags[1] = BAG_BACKPACK
        slotType = SLOT_TYPE_GAMEPAD_INVENTORY_ITEM
    end
    
    local function IsNotStolenItem(itemData)
        local isNotStolen = not itemData.stolen
        return isNotStolen
    end

    --excludes stolen items
    local filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(IsNotStolenItem, unpack(checking_bags))
    --d("tt bank refreshed items: " .. #filteredDataTable)
    local tempDataTable = {}
    for i = 1, #filteredDataTable  do
        local itemData = filteredDataTable[i]
        --use custom categories
        local customCategory, matched, catName, catPriority = BUI.Helper.AutoCategory:GetCustomCategory(itemData)
        if customCategory and not matched then
            itemData.bestItemTypeName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
            itemData.bestItemCategoryName = AC_UNGROUPED_NAME
            itemData.sortPriorityName = string.format("%03d%s", 999 , catName) 
        else
            if customCategory then
                itemData.bestItemTypeName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
                itemData.bestItemCategoryName = catName
                itemData.sortPriorityName = string.format("%03d%s", 100 - catPriority , catName) 
            else
                itemData.bestItemTypeName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
                itemData.bestItemCategoryName = itemData.bestItemTypeName
                itemData.sortPriorityName = itemData.bestItemCategoryName
            end
        end
        local slotIndex = GetItemCurrentActionBarSlot(itemData.bagId, itemData.slotIndex)
        itemData.isEquippedInCurrentCategory = slotIndex and true or nil

        table.insert(tempDataTable, itemData)
        ZO_InventorySlot_SetType(itemData, slotType)
    end
    filteredDataTable = tempDataTable
    
    table.sort(filteredDataTable, BUI_GamepadInventory_DefaultItemSortComparator)

    local currentBestCategoryName = nil

    for i, itemData in ipairs(filteredDataTable) do
        local nextItemData = filteredDataTable[i + 1]

        local data = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        data.InitializeInventoryVisualData = BUI.Inventory.Class.InitializeInventoryVisualData
        data:InitializeInventoryVisualData(itemData)

        local remaining, duration
  
        remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)
      
        if remaining > 0 and duration > 0 then
            data:SetCooldown(remaining, duration)
        end

        data.bestItemCategoryName = itemData.bestItemCategoryName
        data.bestGamepadItemCategoryName = itemData.bestItemCategoryName
        data.isEquippedInCurrentCategory = itemData.isEquippedInCurrentCategory
        data.isEquippedInAnotherCategory = itemData.isEquippedInAnotherCategory
        data.isJunk = itemData.isJunk

        if (not data.isJunk and not showJunkCategory) or (data.isJunk and showJunkCategory) or not BUI.Settings.Modules["Inventory"].enableJunk then
         
            if data.bestGamepadItemCategoryName ~= currentBestCategoryName then
                currentBestCategoryName = data.bestGamepadItemCategoryName
                data:SetHeader(currentBestCategoryName)
                if((AutoCategory) and ((GetNumBagUsedSlots(currentUsedBank) ~= 0) or (GetNumBagUsedSlots(BAG_BACKPACK) ~= 0))) then
                    self.list:AddEntryWithHeader("BUI_GamepadItemSubEntryTemplate", data)
                else
                    self.list:AddEntry("BUI_GamepadItemSubEntryTemplate", data)
                end
            else
                self.list:AddEntry("BUI_GamepadItemSubEntryTemplate", data)
            end
        end
    end

    self.list:Commit()
    self:ReturnToSaved()
    self:UpdateActions()
    self:RefreshFooter()
end

function BUI.Banking.Class:RefreshCurrencyTooltip()
	if SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() and self:GetList().selectedData.label ~= nil then 
        GAMEPAD_TOOLTIPS:LayoutBankCurrencies(GAMEPAD_LEFT_TOOLTIP, ZO_BANKABLE_CURRENCIES)
	end
end

local function OnItemSelectedChange(self, list, selectedData)
    -- Check if we are on the "Deposit/withdraw" gold/telvar row

	if not SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() then
		return
	end
    if(currentUsedBank == BAG_BANK) then
        if(selectedData.label ~= nil) then
            -- Yes! We are, so add the "withdraw/deposit gold/telvar" keybinds here
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.withdrawDepositKeybinds)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.currencyKeybinds)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currencyKeybinds)

            --GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    		self:RefreshCurrencyTooltip()
        else
            -- We are not, add the "withdraw/deposit" keybinds here
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencyKeybinds)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.withdrawDepositKeybinds)

            GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)
        end
    else
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencyKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.withdrawDepositKeybinds)
        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)
        self:RefreshCurrencyTooltip()
    end
	self:UpdateActions()
end


local function SetupItemList(list)
    list:AddDataTemplate("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    list:AddDataTemplateWithHeader("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality, "ZO_GamepadMenuEntryHeaderTemplate")
end

function BUI.Banking.Class:Initialize(tlw_name, scene_name)
	BUI.Interface.Window.Initialize(self, tlw_name, scene_name)

	self:InitializeKeybind()
    self:InitializeList()
    self.itemActions = BUI.Inventory.SlotActions:New(KEYBIND_STRIP_ALIGN_LEFT)
	self.itemActions:SetUseKeybindStrip(false) 
    self:InitializeActionsDialog()
	
	local function CallbackSplitStackFinished()
		--refresh list
		if SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() then
			--d("tt bank split")
			SHARED_INVENTORY:PerformFullUpdateOnBagCache(currentUsedBank)
            self:RefreshList()
			self:ReturnToSaved()
		end
	end
	CALLBACK_MANAGER:RegisterCallback("BUI_EVENT_SPLIT_STACK_DIALOG_FINISHED", CallbackSplitStackFinished)
	
    self.list.maxOffset = 30
    self.list:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING * 0.75, GAMEPAD_HEADER_SELECTED_PADDING * 0.75)
	self.list:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING * 0.75)    

    -- Setup data templates of the lists
    --self:SetupList(BANKING_ROW_TEMPLATE, SetupListing)
	SetupItemList(self.list)
    self:AddTemplate("BUI_HeaderRow_Template",SetupLabelListing)

    self.currentMode = LIST_WITHDRAW
    self.lastPositions = { [LIST_WITHDRAW] = 1, [LIST_DEPOSIT] = 1 }

    self.selectedDataCallback = OnItemSelectedChange

    -- this is essentially a way to encapsulate a function which allows us to override "selectedDataCallback" but still keep some logic code
    local function SelectionChangedCallback(list, selectedData)
        local selectedControl = list:GetSelectedControl()
        if self.selectedDataCallback then
            self:selectedDataCallback(selectedControl, selectedData)
        end
        if selectedControl and selectedControl.bagId then
            SHARED_INVENTORY:ClearNewStatus(selectedControl.bagId, selectedControl.slotIndex)
            self:GetParametricList():RefreshList()
        end
    end

    -- these are event handlers which are specific to the banking interface. Handling the events this way encapsulates the banking interface
    -- these local functions are essentially just router functions to other functions within this class. it is done in this way to allow for
    -- us to access this classes' members (through "self")

    local function UpdateSingle_Handler(eventId, bagId, slotId, isNewItem, itemSound)
        self:UpdateSingleItem(bagId, slotId)
		self:RefreshList()
        self:selectedDataCallback(self.list:GetSelectedControl(), self.list:GetSelectedData())
	end

    local function UpdateCurrency_Handler()
        self:RefreshFooter()
		KEYBIND_STRIP:UpdateKeybindButtonGroup(self.coreKeybinds)
		self:RefreshCurrencyTooltip()
    end

    local function OnEffectivelyShown()
        self:CurrentUsedBank()
        if self.isDirty then
            self:RefreshList()
        elseif self.selectedDataCallback then
            self:selectedDataCallback(self.list:GetSelectedControl(), self.list:GetSelectedData())
        end
        self.list:Activate()
	
		if wykkydsToolbar then
			wykkydsToolbar:SetHidden(true)
		end

        self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, UpdateSingle_Handler)
        self:RefreshList()
    end

    local function OnEffectivelyHidden()
        self:LastUsedBank()
        self.list:Deactivate()
        self.selector:Deactivate()

        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
	
		if wykkydsToolbar then
			wykkydsToolbar:SetHidden(false)
		end

        self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
        self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	end

    local selectorContainer = self.control:GetNamedChild("Container"):GetNamedChild("InputContainer")
    self.selector = ZO_CurrencySelector_Gamepad:New(selectorContainer:GetNamedChild("Selector"))
	self.selector:SetClampValues(true)
	self.selectorCurrency = selectorContainer:GetNamedChild("CurrencyTexture")

    self.list:SetOnSelectedDataChangedCallback(SelectionChangedCallback)

    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    -- Always-running event listeners, these don't add much overhead
    self.control:RegisterForEvent(EVENT_CARRIED_CURRENCY_UPDATE, UpdateCurrency_Handler)
    self.control:RegisterForEvent(EVENT_BANKED_CURRENCY_UPDATE, UpdateCurrency_Handler)
end

-- Calling this function will add keybinds to the strip, likely using the primary key
-- The primary key will conflict with the category keybind descriptor if added
function BUI.Banking.Class:RefreshItemActions()
    local targetData = self:GetList().selectedData
    --self:SetSelectedInventoryData(targetData) instead:
    self.itemActions:SetInventorySlot(targetData)
end


function BUI.Banking.Class:ActionsDialogSetup(dialog)
	dialog.entryList:SetOnSelectedDataChangedCallback(  function(list, selectedData)
		self.itemActions:SetSelectedAction(selectedData and selectedData.action)
	end)

    local parametricList = dialog.info.parametricList
    ZO_ClearNumericallyIndexedTable(parametricList)

    self:RefreshItemActions()

    --self:RefreshItemActions()
    local actions = self.itemActions:GetSlotActions()
    local numActions = actions:GetNumSlotActions()

    for i = 1, numActions do
        local action = actions:GetSlotAction(i)
        local actionName = actions:GetRawActionName(action)

        local entryData = ZO_GamepadEntryData:New(actionName)
        entryData:SetIconTintOnSelection(true)
        entryData.action = action
        entryData.setup = ZO_SharedGamepadEntry_OnSetup

        local listItem =
        {
            template = "ZO_GamepadItemEntryTemplate",
            entryData = entryData,
        }
		
		--if actionName ~= "Use" and actionName ~= "Equip" and i ~= 1 then
        table.insert(parametricList, listItem)
		--end
    end

    dialog:setupFunc()
end

function BUI.Banking.Class:InitializeActionsDialog()
	local function ActionDialogSetup(dialog)
		if SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() then
	
			--d("tt bank action setup")
			dialog.entryList:SetOnSelectedDataChangedCallback(  function(list, selectedData)
			self.itemActions:SetSelectedAction(selectedData and selectedData.action)
			end)

			local parametricList = dialog.info.parametricList
			ZO_ClearNumericallyIndexedTable(parametricList)

			self:RefreshItemActions()

			local actions = self.itemActions:GetSlotActions()
			local numActions = actions:GetNumSlotActions()

			for i = 1, numActions do
				local action = actions:GetSlotAction(i)
				local actionName = actions:GetRawActionName(action)

				local entryData = ZO_GamepadEntryData:New(actionName)
				entryData:SetIconTintOnSelection(true)
				entryData.action = action
				entryData.setup = ZO_SharedGamepadEntry_OnSetup

				local listItem =
				{
					template = "ZO_GamepadItemEntryTemplate",
					entryData = entryData,
				}
				
                lastActionName = actionName
				--if actionName ~= "Use" and actionName ~= "Equip" and i ~= 1 then
				table.insert(parametricList, listItem)
			end

			dialog:setupFunc()
		end
	end

	local function ActionDialogFinish() 
		if SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() then
			--d("tt bank action finish")
			-- make sure to wipe out the keybinds added by actions
			self:AddKeybinds()
			--restore the selected inventory item
		
			self:RefreshItemActions()
			
			--refresh so keybinds react to newly selected item
			--self:RefreshActiveKeybinds()

			self:RefreshList()
			--if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
			--	self:RefreshCategoryList()
			--end
		end
	end
	local function ActionDialogButtonConfirm(dialog)
		if SCENE_MANAGER.scenes['gamepad_banking']:IsShowing() then
			--d(ZO_InventorySlotActions:GetRawActionName(self.itemActions.selectedAction))
            if (lastActionName ~= nil) then
    			if ((ZO_InventorySlotActions:GetRawActionName(self.itemActions.selectedAction) == GetString(SI_ITEM_ACTION_LINK_TO_CHAT)) and (ZO_InventorySlotActions:GetRawActionName(self.itemActions.selectedAction) ~= nil)) then
    				--Also perform bag stack!
    				--StackBag(BAG_BACKPACK)
    				--link in chat
    				local targetData = self:GetList().selectedData
    				local itemLink
    				local bag, slot = ZO_Inventory_GetBagAndIndex(targetData)
    				if bag and slot then
    					itemLink = GetItemLink(bag, slot)
    				end
    				if itemLink then
    					ZO_LinkHandler_InsertLink(zo_strformat("[<<2>>]", SI_TOOLTIP_ITEM_NAME, itemLink))
    				end
    			else
    				self.itemActions:DoSelectedAction()
    			end
            else
                return
            end
            lastActionName = nil
		end
	end
	CALLBACK_MANAGER:RegisterCallback("BUI_EVENT_ACTION_DIALOG_SETUP", ActionDialogSetup)
	CALLBACK_MANAGER:RegisterCallback("BUI_EVENT_ACTION_DIALOG_FINISH", ActionDialogFinish)
	CALLBACK_MANAGER:RegisterCallback("BUI_EVENT_ACTION_DIALOG_BUTTON_CONFIRM", ActionDialogButtonConfirm)
end


-- Thanks to Ayantir for the following method to quickly return the next free slotIndex!
local tinyBagCache = {
    [BAG_BACKPACK] = {},
    [currentUsedBank] = {},
}

-- Thanks Merlight & circonian, FindFirstEmptySlotInBag don't refresh in realtime.
local function FindEmptySlotInBag(bagId)
    if false then
        for slotIndex = 0, (GetBagSize(bagId) - 1) do
            if not SHARED_INVENTORY.bagCache[bagId][slotIndex] and not tinyBagCache[bagId][slotIndex] then
                tinyBagCache[bagId][slotIndex] = true
                return slotIndex
            end
        end
        return nil
    else
        return FindFirstEmptySlotInBag(bagId)
    end
end

local function FindEmptySlotInBank()
    if(IsHouseBankBag(GetBankingBag()) == false) then
        local emptySlotIndex = FindEmptySlotInBag(BAG_BANK)
        if(emptySlotIndex ~= nil) then
            return BAG_BANK, emptySlotIndex
        end

        emptySlotIndex = FindEmptySlotInBag(BAG_SUBSCRIBER_BANK)
        if(emptySlotIndex ~= nil) then
            return BAG_SUBSCRIBER_BANK, emptySlotIndex
        end
    else
        emptySlotIndex = FindEmptySlotInBag(currentUsedBank)
        if(emptySlotIndex ~= nil) then
            return currentUsedBank, emptySlotIndex
        end
    end
	return nil
end

function BUI.Banking.Class:ActivateSpinner()
    self.spinner:SetHidden(false)
    self.spinner:Activate()
    if(self:GetList() ~= nil) then
        self:GetList():Deactivate()

        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
    end
end

function BUI.Banking.Class:DeactivateSpinner()
    self.spinner:SetValue(1)
    self.spinner:SetHidden(true)
    self.spinner:Deactivate()
    if(self:GetList() ~= nil) then
        self:GetList():Activate()
        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
    end
end


function BUI.Banking.Class:MoveItem(list, quantity)
	local movingItemBag, index = ZO_Inventory_GetBagAndIndex(list:GetSelectedData())
    local stackCount = GetSlotStackSize(movingItemBag, index)
	local inSpinner = false
	if quantity ~= nil then
		--in spinner
		inSpinner = true
	else 
		--not in spinner
		if(stackCount > 1) then
			-- display the spinner
			self:UpdateSpinnerConfirmation(true, self.list)
			self:SetSpinnerValue(list:GetSelectedData().stackCount, list:GetSelectedData().stackCount)
			return
		else
		--since stackcount = 1
		quantity = 1
		end
	end
	 
	-- We're in the spinner! Confirm the move here :)
	local fromBag = movingItemBag
	local toBag, emptySlotIndex
	if self.currentMode == LIST_WITHDRAW then
		--we are withdrawing item from bank/subscriber bank bag
		toBag = BAG_BACKPACK
		emptySlotIndex = FindEmptySlotInBag(toBag)
	else
		--we are depositing item to bank/subscriber bank bag
		toBag, emptySlotIndex = FindEmptySlotInBank()
	end
	if emptySlotIndex ~= nil then
		--good to move
		CallSecureProtected("RequestMoveItem", fromBag, index, toBag, emptySlotIndex, quantity)
		if inSpinner then
			self:UpdateSpinnerConfirmation(false, self.list)
		end
    else
        local errorStringId = (toBag == BAG_BACKPACK) and SI_INVENTORY_ERROR_INVENTORY_FULL or SI_INVENTORY_ERROR_BANK_FULL
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
	end
end

function BUI.Banking.Class:CancelWithdrawDeposit(list)
    if self.confirmationMode then
        self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, list)
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

function BUI.Banking.Class:DisplaySelector(currencyType)
    local currency_max

    if(self.currentMode == LIST_DEPOSIT) then
        currency_max = GetCarriedCurrencyAmount(currencyType)
    else
        currency_max = GetBankedCurrencyAmount(currencyType)
    end

    -- Does the player actually have anything that can be transferred?
    if(currency_max ~= 0) then
        self.selector:SetMaxValue(currency_max)
        self.selector:SetClampValues(0, currency_max)
        self.selector.control:GetParent():SetHidden(false)
	
		local CURRENCY_TYPE_TO_TEXTURE =
		{
			[CURT_MONEY] = "EsoUI/Art/currency/gamepad/gp_gold.dds",
			[CURT_TELVAR_STONES] = "EsoUI/Art/currency/gamepad/gp_telvar.dds",
			[CURT_ALLIANCE_POINTS] = "esoui/art/currency/gamepad/gp_alliancepoints.dds",
			[CURT_WRIT_VOUCHERS] = "EsoUI/Art/currency/gamepad/gp_writvoucher.dds",
		}
	
		self.selectorCurrency:SetTexture(CURRENCY_TYPE_TO_TEXTURE[currencyType])
	
        self.selector:Activate()
        self.list:Deactivate()

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencyKeybinds)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.coreKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currencySelectorKeybinds)
    else
        -- No, display an alert
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, "Not enough funds available for transfer.")
    end
end

function BUI.Banking.Class:HideSelector()
    self.selector.control:GetParent():SetHidden(true)
    self.selector:Deactivate()
    self.list:Activate()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencySelectorKeybinds)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currencyKeybinds)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
end

function BUI.Banking.Class:CreateListTriggerKeybindDescriptors(list)
    local leftTrigger = {
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        callback = function()
            local list = self.list
            if not list:IsEmpty() then
                list:SetSelectedIndex(list.selectedIndex-tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
            end
        end
    }
    local rightTrigger = {
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        callback = function()
			local list = self.list
            if not list:IsEmpty() then
                list:SetSelectedIndex(list.selectedIndex+tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
            end
        end,
    }
    return leftTrigger, rightTrigger
end

function BUI.Banking.Class:UpdateActions()
    local targetData = self:GetList().selectedData
    -- since SetInventorySlot also adds/removes keybinds, the order which we call these 2 functions is important
    -- based on whether we are looking at an item or a faux-item
    if ZO_GamepadBanking.IsEntryDataCurrencyRelated(targetData) then
		--d("tt currency")
        self.itemActions:SetInventorySlot(nil)
    else
		--d("tt targetData, slotType:" .. targetData.slotType)
        self.itemActions:SetInventorySlot(targetData)
    end
end

function BUI.Banking.Class:AddKeybinds()
	KEYBIND_STRIP:RemoveAllKeyButtonGroups()
	KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
	KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
	self:UpdateActions()
end

function BUI.Banking.Class:RemoveKeybinds()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.withdrawDepositKeybinds)
    KEYBIND_STRIP:RemoveKeybindButton(self.coreKeybinds)
end

function BUI.Banking.Class:ShowActions()
    self:RemoveKeybinds()

    local function OnActionsFinishedCallback()
        self:AddKeybinds()
    end

    local dialogData = 
    {
        targetData = self:GetList().selectedData,
        finishedCallback = OnActionsFinishedCallback,
        itemActions = self.itemActions,
    }

    ZO_Dialogs_ShowPlatformDialog(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG, dialogData)
end

function BUI.Banking.Class:InitializeKeybind()
	if not BUI.Settings.Modules["Banking"].m_enabled then
		return
	end
	
	self.coreKeybinds = {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
		        {
		            name = GetString(SI_BUI_BANKING_TOGGLE_LIST),
		            keybind = "UI_SHORTCUT_SECONDARY",
		            callback = function()
		                self:ToggleList(self.currentMode == LIST_DEPOSIT)
		            end,
		            visible = function()
		                return true
		            end,
		            enabled = true,
		        },
               {
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            name = function()
                local cost = GetNextBankUpgradePrice()
                if GetCarriedCurrencyAmount(CURT_MONEY) >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_CurrencyControl_FormatCurrency(cost), ZO_GAMEPAD_GOLD_ICON_FORMAT_24)
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)), ZO_GAMEPAD_GOLD_ICON_FORMAT_24)
            end,
            visible = function()
                return IsBankUpgradeAvailable()
            end,
            enabled = function()
                return GetCarriedCurrencyAmount(CURT_MONEY) >= GetNextBankUpgradePrice()
            end,
            callback = function()
                if GetNextBankUpgradePrice() > GetCarriedCurrencyAmount(CURT_MONEY) then
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_BUY_BANK_SPACE_CANNOT_AFFORD))
                else
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
                    DisplayBankUpgrade()
                end
            end
        },
{
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil or self:GetList().selectedData ~= nil
            end,

            callback = function()
				self:SaveListPosition()
                self:ShowActions()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()				
                if(self.currentMode == LIST_WITHDRAW) then
                    if(currentUsedBank == BAG_BANK) then
                        StackBag(BAG_BANK)
                        StackBag(BAG_SUBSCRIBER_BANK)
                    else
                        StackBag(currentUsedBank)
                    end
                else
                    StackBag(BAG_BACKPACK)
                end
            end,
        },
	}
    self.withdrawDepositKeybinds = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
                {
                    name = function() return (self.currentMode == LIST_WITHDRAW) and GetString(SI_BUI_BANKING_WITHDRAW) or GetString(SI_BUI_BANKING_DEPOSIT) end,
                    keybind = "UI_SHORTCUT_PRIMARY",
                    callback = function()
                        self:SaveListPosition()
                        self:MoveItem(self.list)
                    end,
                    visible = function()
                        return true
                    end,
                    enabled = true,
                },
    }

    self.currencySelectorKeybinds =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_BUI_CONFIRM_AMOUNT),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return true
            end,
            callback = function()
                local amount = self.selector:GetValue()
				local currencyType = self:GetList().selectedData.currencyType
                if(self.currentMode == LIST_WITHDRAW) then
                    WithdrawCurrencyFromBank(currencyType, amount)
                else
                    DepositCurrencyIntoBank(currencyType, amount)
                end
                self:HideSelector()
                self:RefreshFooter()
				KEYBIND_STRIP:UpdateKeybindButtonGroup(self.coreKeybinds)

            end,
        }
    }

    self.currencyKeybinds = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
                {
                    name = function() return self:GetList().selectedData.label end,
                    keybind = "UI_SHORTCUT_PRIMARY",
                    callback = function()
                        self:SaveListPosition()
                        self:DisplaySelector(self:GetList().selectedData.currencyType)
                    end,
                    visible = function()
                        return true
                    end,
                    enabled = true,
                },
    }


	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.coreKeybinds, GAME_NAVIGATION_TYPE_BUTTON) -- "Back"
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.currencySelectorKeybinds, GAME_NAVIGATION_TYPE_BUTTON, function() self:HideSelector() end)

	self.triggerSpinnerBinds = {}
	local leftTrigger, rightTrigger = self:CreateListTriggerKeybindDescriptors(self.list)
    table.insert(self.coreKeybinds, leftTrigger)
    table.insert(self.coreKeybinds, rightTrigger)


	self.spinnerKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_BUI_CONFIRM),
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
            	self:SaveListPosition()
		        self:MoveItem(self.list, self.spinner:GetValue())
            end,
            visible = function()
                return true
            end,
            enabled = true,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.spinnerKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function()
                                                        local list = self.list
                                                        self:CancelWithdrawDeposit(list)
                                                        KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
                                                    end)
end

function BUI.Banking.Class:SaveListPosition()
    -- Able to return to the current position again!
    self.lastPositions[self.currentMode] = self.list.selectedIndex
end

function BUI.Banking.Class:ReturnToSaved()
    self:CurrentUsedBank()
    local lastPosition = self.lastPositions[self.currentMode]
    if(self.currentMode == LIST_WITHDRAW) then
        if(lastUsedBank ~= currentUsedBank) then
            self.list:SetSelectedIndexWithoutAnimation(1, true, false)
            self:SaveListPosition()
            self.currentMode = LIST_DEPOSIT
            self.list:SetSelectedIndexWithoutAnimation(1, true, false)
            self:SaveListPosition()
			self.currentMode = LIST_WITHDRAW
            self:LastUsedBank()
            self:RefreshList()
        else
            self.list:SetSelectedIndexWithoutAnimation(lastPosition, true, false)
        end
    else
        if(lastUsedBank ~= currentUsedBank) then
            self.list:SetSelectedIndexWithoutAnimation(1, true, false)
            self:SaveListPosition()
            self:LastUsedBank()
            self.currentMode = LIST_WITHDRAW
            self:ToggleList(self.currentMode == LIST_WITHDRAW)
        else
            self.list:SetSelectedIndexWithoutAnimation(lastPosition, true, false)
        end
    end
end

-- Go through and get the item which has been passed to us through the event
function BUI.Banking.Class:UpdateSingleItem(bagId, slotIndex)
    if GetSlotStackSize(bagId, slotIndex) > 0 then
        self:RefreshList()
        return
    else 
        self:RefreshList()
    end
    
    for index = 1, #self.list.dataList do
        if self.list.dataList[index].bagId == bagId and self.list.dataList[index].slotIndex == slotIndex then
            self:RemoveItemStack(index)
            break
        end
    end
end

-- This is the final function for the Event "EVENT_INVENTORY_SINGLE_SLOT_UPDATE".
function BUI.Banking.Class:RemoveItemStack(itemIndex)

    if(itemIndex >= #self.list.dataList) then
      self.list:MovePrevious()
    end
    table.remove(self.list.dataList,itemIndex)
    table.remove(self.list.templateList,itemIndex)
    table.remove(self.list.prePadding,itemIndex)
    table.remove(self.list.postPadding,itemIndex)
    table.remove(self.list.preSelectedOffsetAdditionalPadding,itemIndex)
    table.remove(self.list.postSelectedOffsetAdditionalPadding,itemIndex)
    table.remove(self.list.selectedCenterOffset,itemIndex)

    self:RefreshList()
end

function BUI.Banking.Class:ToggleList(toWithdraw)
	self:SaveListPosition()

	self.currentMode = toWithdraw and LIST_WITHDRAW or LIST_DEPOSIT
	local footer = self.footer:GetNamedChild("Footer")
	if(self.currentMode == LIST_WITHDRAW) then
		footer:GetNamedChild("SelectBg"):SetTextureRotation(0)

		footer:GetNamedChild("DepositButtonLabel"):SetColor(0.26,0.26,0.26,1)
		footer:GetNamedChild("WithdrawButtonLabel"):SetColor(1,1,1,1)
	else
		footer:GetNamedChild("SelectBg"):SetTextureRotation(3.1415)

		footer:GetNamedChild("DepositButtonLabel"):SetColor(1,1,1,1)
		footer:GetNamedChild("WithdrawButtonLabel"):SetColor(0.26,0.26,0.26,1)
	end
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.coreKeybinds)
	--KEYBIND_STRIP:UpdateKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
	self:RefreshList()
end

function BUI.Banking.Init()
    BUI.Banking.Window = BUI.Banking.Class:New("BUI_TestWindow", BUI_TEST_SCENE)
    BUI.Banking.Window:SetTitle("|c0066FFBanking Enhanced|r")


    -- Set the column headings up, maybe put them into a table?
    BUI.Banking.Window:AddColumn(GetString(SI_BUI_BANKING_COLUMN_NAME),87)
    BUI.Banking.Window:AddColumn(GetString(SI_BUI_BANKING_COLUMN_TYPE),637)
    BUI.Banking.Window:AddColumn(GetString(SI_BUI_BANKING_COLUMN_TRAIT),897)
    BUI.Banking.Window:AddColumn(GetString(SI_BUI_BANKING_COLUMN_STAT),1067)
    BUI.Banking.Window:AddColumn(GetString(SI_BUI_BANKING_COLUMN_VALUE),1187)

    BUI.Banking.Window:RefreshList()

    SCENE_MANAGER.scenes['gamepad_banking'] = SCENE_MANAGER.scenes['BUI_BANKING']
	
	if ((not USE_SHORT_CURRENCY_FORMAT ~= nil) and BUI.Settings.Modules["Inventory"].useShortFormat ~= nil) then
		USE_SHORT_CURRENCY_FORMAT = BUI.Settings.Modules["Inventory"].useShortFormat
	end
    --tw = BUI.Banking.Window --dev mode
end