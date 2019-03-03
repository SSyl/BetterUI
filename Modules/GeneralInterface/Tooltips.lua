local _

function BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG)

    -- Get bag size
    local bagSize = GetBagSize(BAG)
 
    -- Var to hold item matches
    local itemMatches = 0
 
    -- Iterate through BAG
    for i = 0, bagSize do

        -- Get current item
        local currentItem = GetItemLink(BAG, i)
 
        -- Check if current item is researchable
        if(CanItemLinkBeTraitResearched(currentItem)) then
 
            -- Check if current item trait equals item's trait we're checking
            if (GetItemLinkTraitInfo(currentItem) == GetItemLinkTraitInfo(itemLink)) then
                itemMatches = itemMatches + 1
            end
        end
    end
 
    -- return number of matches
    return itemMatches;
end

local function AddInventoryPostInfo(tooltip, itemLink)
	if itemLink then --and itemLink ~= tooltip.lastItemLink then
		--tooltip.lastItemLink = itemLink
        if TamrielTradeCentre ~= nil and BUI.Settings.Modules["Tooltips"].ttcIntegration then
            local priceInfo = TamrielTradeCentrePrice:GetPriceInfo(itemLink)
            if(priceInfo == nil) then
                tooltip:AddLine(string.format("|c0066ff[BUI]|r  TTC " .. GetString(TTC_PRICE_NOLISTINGDATA)), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
            else
                if(priceInfo.SuggestedPrice ~= nil) then
                    tooltip:AddLine(string.format("|c0066ff[BUI]|r  TTC " .. GetString(TTC_PRICE_SUGGESTEDXTOY), 
                        TamrielTradeCentre:FormatNumber(priceInfo.SuggestedPrice, 0), TamrielTradeCentre:FormatNumber(priceInfo.SuggestedPrice * 1.25, 0)), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
                else
                    tooltip:AddLine(string.format("|c0066ff[BUI]|r  TTC Suggested : NONE "), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
                end
                tooltip:AddLine(string.format(GetString(TTC_PRICE_AGGREGATEPRICESXYZ), TamrielTradeCentre:FormatNumber(priceInfo.Avg), 
                TamrielTradeCentre:FormatNumber(priceInfo.Min), TamrielTradeCentre:FormatNumber(priceInfo.Max)), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }) 
            end
            --     tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r <<1>>",priceInfo), { fontSize = 28, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
        end

		if MasterMerchant ~= nil and BUI.Settings.Modules["Tooltips"].mmIntegration then
			local tipLine, avePrice, graphInfo = MasterMerchant:itemPriceTip(itemLink, false, clickable)
			if(tipLine ~= nil) then
				tooltip:AddLine(string.format("|c0066ff[BUI]|r  " .. tipLine), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			else
				tooltip:AddLine(string.format("|c0066ff[BUI]|r  MM price (0 sales, 0 days): UNKNOWN"), { fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			end
		end
	end
end

local function AddInventoryPreInfo(tooltip, itemLink)

    if itemLink and BUI.Settings.Modules["Tooltips"].showStyleTrait then
        local traitString
        if(CanItemLinkBeTraitResearched(itemLink))  then
            -- Find owned items that can be researchable
            if(BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_BACKPACK) > 0) then
                traitString = "|c00FF00Researchable|r - |cFF9900Found in Inventory|r"
            elseif(BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_BANK) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_SUBSCRIBER_BANK) > 0) then
                traitString = "|c00FF00Researchable|r - |cFF9900Found in Bank|r"
            elseif(BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_ONE) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_TWO) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_THREE) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_FOUR) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_FIVE) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_SIX) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_SEVEN) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_EIGHT) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_NINE) + BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_HOUSE_BANK_TEN) > 0) then
                traitString = "|c00FF00Researchable|r - |cFF9900Found in House Bank|r"
            elseif(BUI.Tooltips.GetNumberOfMatchingItems(itemLink, BAG_WORN) > 0) then
                traitString = "|c00FF00Researchable|r - |cFF9900Found Equipped|r"
            else
                traitString = "|c00FF00Researchable|r"
            end
        else
            return
        end    

        local style = GetItemLinkItemStyle(itemLink)
        local itemStyle = string.upper(GetString("SI_ITEMSTYLE", style))                    

        tooltip:AddLine(zo_strformat("<<1>> Trait: <<2>>", itemStyle, traitString), { fontSize = 28, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))

        if(itemStyle ~= ("NONE")) then
            tooltip:AddLine(zo_strformat("<<1>>", itemStyle), { fontSize = 28, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))
        end
    else
        return
    end
end

function BUI.InventoryHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		AddInventoryPreInfo(self, linkFunc(...))
		origMethod(self, ...)
		AddInventoryPostInfo(self, linkFunc(...))
	end
end

function BUI.ReturnItemLink(itemLink)
	return itemLink
end

function BUI.Tooltips.RefreshControls(self)
 	if(self.hidden) then
        self.dirty = true
    else
        if(self.hasTarget) then
            if self.nameLabel then
                local name

                if IsInGamepadPreferredMode()  then
                	if BUI.Settings.Modules["Tooltips"].showAccountName then
                    	name = zo_strformat("|c<<1>><<2>>|r|c<<3>><<4>>|r",BUI.RGBToHex(BUI.Settings.Modules["Tooltips"].showCharacterColor),ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag)),BUI.RGBToHex(BUI.Settings.Modules["Tooltips"].showAccountColor),GetUnitDisplayName(self.unitTag))
                    else
                    	name = ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag))
                    end
                else
                    name = GetUnitName(self.unitTag)
                end
                self.nameLabel:SetText(name)
            end
            self:UpdateUnitReaction()
            self:UpdateLevel()
            self:UpdateCaption()

            local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
            self.healthBar:Update(POWERTYPE_HEALTH, health, maxHealth, FORCE_INIT)
			if (self.healthBar and self.healthBar.BUI_labelRef) then
				self.healthBar.BUI_labelRef:SetHidden(not IsUnitOnline(self.unitTag))
			end

            for i = 1, NUM_POWER_POOLS do
                local powerType, cur, max = GetUnitPowerInfo(self.unitTag, i)
                self:UpdatePowerBar(i, powerType, cur, max, FORCE_INIT)
            end
            self:UpdateStatus(IsUnitDead(self.unitTag), IsUnitOnline(self.unitTag))
            self:UpdateRank()
            self:UpdateDifficulty()
            self:DoAlphaUpdate(IsUnitInGroupSupportRange(self.unitTag), IsUnitOnline(self.unitTag), IsUnitGroupLeader(unitTag))
        end
	end
end

function BUI.Tooltips.UpdateHealthbar(self, barType, cur, max, forceInit)
    local barCur = cur
    local barMax = max
    if(#self.barControls == 2) then
        barCur = cur / 2
        barMax = max / 2
    end
    for i = 1, #self.barControls do
        ZO_StatusBar_SmoothTransition(self.barControls[i], barCur, barMax, forceInit)
    end
    local updateBarType = false
    local updateValue = cur ~= self.currentValue or self.maxValue ~= max
    self.currentValue = cur
    self.maxValue = max
    if(barType ~= self.barType) then
        updateBarType = true
        self.barType = barType
        self.barTypeName = GetString("SI_COMBATMECHANICTYPE", self.barType)
    end
    self:UpdateText(updateBarType, updateValue)
end

function BUI.Tooltips.UpdateGroupAnchorFrames(self)
    for unitTag, unitFrame in pairs(self.groupFrames) do
	    if(unitFrame.healthBar.BUI_labelRef == nil) then
		    unitFrame.healthBar.BUI_labelRef =  BUI.WindowManager:CreateControl(unitFrame.frame:GetName().."HealthLabel", unitFrame.frame, CT_LABEL)
		    unitFrame.healthBar.BUI_labelRef:SetFont("ZoFontGamepad20")
		    unitFrame.healthBar.BUI_labelRef:SetText("100 (100%)")
		    unitFrame.healthBar.BUI_labelRef:SetColor(1, 1, 1, 1)
		    unitFrame.healthBar.BUI_labelRef:SetAnchor(CENTER, unitFrame.frame, TOP, 5,53)
		    unitFrame.healthBar.BUI_labelRef:SetHidden(true)

            unitFrame.frame:GetNamedChild("Background2"):SetAnchor(6, unitFrame.frame, 6, -6, 42 )

		    unitFrame.frame:SetHeight(30)
		    unitFrame.frame:GetNamedChild("Background1"):SetHeight(24)
		    unitFrame.healthBar.barControls[1]:SetHeight(20)

		    unitFrame.RefreshControls = BUI.Tooltips.RefreshControls
		    unitFrame.healthBar.Update = BUI.Tooltips.UpdateHealthbar

		   	unitFrame.RefreshControls(unitFrame)
		end
    end

    return true
end
