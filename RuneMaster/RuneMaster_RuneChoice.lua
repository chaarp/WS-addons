-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
local RuneMaster = Apollo.GetAddon("RuneMaster")

runefloor = function(nRuneLevel)
	local tRuneLevels = RuneMaster.ktRuneLevels--CraftingLib.GetRunecraftingLevels()
	local nMaxLevel = 0
	for _,nPossLevel in pairs(tRuneLevels) do
		if nPossLevel <= nRuneLevel then
			nMaxLevel = nPossLevel
		end
	end
	return nMaxLevel
end

function RuneMaster:RuneChoice_Init()
	local wndRuneChoice = self.wndRuneChoice
	if not wndRuneChoice then
		self.wndRuneChoice = Apollo.LoadForm(self.xmlDoc, "RuneChoice", nil, self)
		self.wndRuneChoice:FindChild("Header"):SetRadioSel("RunesetType", self.settings.filters.settype or 1)
		self:RuneContent_Init()
		self:FusionContent_Init()
	end
end

function RuneMaster:RuneContent_Init()
	local wndRuneChoice = self.wndRuneChoice:FindChild("RuneContent")
	
	--Stats
	local wndAllStat = Apollo.LoadForm(self.xmlDoc, "RuneChoice_StatEntry", wndRuneChoice:FindChild("StatFilter"), self)
	wndAllStat:FindChild("Name"):SetText("ALL") --TODO: Locale
	wndAllStat:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_ChallengeLog")
	wndAllStat:FindChild("Icon"):SetAnchorOffsets(0,0,30,0)---2,-2,32,2)
	wndAllStat:SetData(999)
	wndAllStat:SetCheck(self.settings.filters.stats[999])
	
	for eStat,tStat in pairs(self.ktRuneStats) do
		local wndFilterStat = Apollo.LoadForm(self.xmlDoc, "RuneChoice_StatEntry", wndRuneChoice:FindChild("StatFilter"), self)
		local strStat = string.gsub(Item.GetPropertyName(eStat)," Rating","") --TODO: Figure out how to handle this better.
		strStat = string.gsub(strStat," Rate","")
		wndFilterStat:FindChild("Name"):SetText(strStat)--tStat.strLocale)
		wndFilterStat:FindChild("Icon"):SetSprite(tStat.strSprite)
		wndFilterStat:SetData(eStat)
		wndFilterStat:SetCheck(self.settings.filters.stats[eStat])
	end
	wndRuneChoice:FindChild("StatFilter"):ArrangeChildrenVert()
	
	local tLevels = CraftingLib.GetRunecraftingLevels()--self.ktRuneLevels--
	for _,nLevel in pairs(tLevels) do
		local wndLevel = Apollo.LoadForm(self.xmlDoc, "RuneChoice_iLvl", wndRuneChoice:FindChild("iLvl"), self)
		if self.settings.showlevelnames then
			local nWidth = Apollo.GetTextWidth("CRB_Header9", self.ktRuneLevelNames[nLevel])
			wndLevel:SetAnchorOffsets(0,1,nWidth+20,-2)
			wndLevel:SetText(self.ktRuneLevelNames[nLevel])
		else
			wndLevel:SetText(nLevel)
		end
		wndLevel:SetData(nLevel)
	end
	wndRuneChoice:FindChild("iLvl"):ArrangeChildrenHorz()
	wndRuneChoice:FindChild("MaxLvl"):SetData("Max")
end

function RuneMaster:FusionContent_Init()
	local wndRuneChoice = self.wndRuneChoice:FindChild("FusionContent")
	
	local tLevels = CraftingLib.GetRunecraftingLevels()--self.ktRuneLevels--
	for _,nLevel in pairs(tLevels) do
		local wndLevel = Apollo.LoadForm(self.xmlDoc, "RuneChoice_iLvl", wndRuneChoice:FindChild("iLvl"), self)
		wndLevel:SetText(nLevel)
		wndLevel:SetData(nLevel)
	end
	wndRuneChoice:FindChild("iLvl"):ArrangeChildrenHorz()
	wndRuneChoice:FindChild("MaxLvl"):SetData("Max")
end

function RuneMaster:ToggleRuneSelection(tRune)
	if not self.wndRuneChoice then --TODO: Reanalyze this for memory usage and feasibility
		self:RuneChoice_Init()
	else
		if self.wndRuneChoice:IsShown() then --TODO: This conflicts with CloseOnExternalClick; remedy.
			self.wndRuneChoice:Show(false)
			self.wndRuneChoice:FindChild("Runes"):DestroyChildren()
			self.wndRuneChoice:FindChild("SetFilter"):DestroyChildren()		
		else
			self.wndRuneChoice:Show(true)
			self.wndRuneChoice:ToFront()
			self.wndRuneChoice:SetData(tRune)
			local nHeight,nWidth = self.wndRuneChoice:GetHeight(), self.wndRuneChoice:GetWidth()
			local tMouse = Apollo.GetMouse()
			local nLeft, nTop = tMouse.x+5, tMouse.y+5
			local tScreen = {}
			tScreen.x,tScreen.y = Apollo.GetScreenSize()
			if nLeft+nWidth > tScreen.x then
				nLeft = tScreen.x-nWidth
			end
			if nTop+nHeight > tScreen.y then
				nTop = tScreen.y-nHeight
			end
			self.wndRuneChoice:Move(nLeft,nTop,nWidth,nHeight)
				
			self.wndRuneChoice:FindChild("Container:CurrentRune:Icon"):SetSprite(self.ktElementData[tRune.eElement].strSprite)
			self.wndRuneChoice:FindChild("Container:CurrentRune:Icon"):SetBGColor("ff"..self.ktElementData[tRune.eElement].strColor)

			self:PopulateRunesetType(self.wndRuneChoice:FindChild("Header"):GetRadioSel("RunesetType"))
		end
	end
end

function RuneMaster:OnRunesetTypeChoice( wndHandler, wndControl, eMouseButton )
	local nRunesetType = wndHandler:GetParent():GetRadioSel("RunesetType")
	--local tRune = wndHandler:GetData()
	
	self:PopulateRunesetType(nRunesetType)
end

function RuneMaster:PopulateRunesetType(nRunesetType)
	local wndRuneChoice = self.wndRuneChoice
	if wndRuneChoice:FindChild("Header"):GetRadioSel("RunesetType") ~= nRunesetType then
		wndRuneChoice:FindChild("Header"):SetRadioSel("RunesetType", nRunesetType)
	end	
	
	wndRuneChoice:FindChild("SetFilter"):DestroyChildren()	
	
	--[[--"ALL"
	local wndAllSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
	wndAllSet:FindChild("Name"):SetText("ALL") --TODO: Locale
	wndAllSet:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_ChallengeLog")
	wndAllSet:FindChild("Icon"):SetAnchorOffsets(0,0,30,0)---2,-2,32,2)
	wndAllSet:SetData(999)--]]
	
	--Sets chosen
	if nRunesetType == 4 then --Fusion Runes
		wndRuneChoice:FindChild("FusionContent"):Show(true)
		wndRuneChoice:FindChild("RuneContent"):Show(false)
		local wndFilterSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
		wndFilterSet:FindChild("Name"):SetText("Fusion") --TODO: Locale
		wndFilterSet:SetCheck(true)
		wndFilterSet:SetData("Fusion")
	else
		wndRuneChoice:FindChild("RuneContent"):Show(true)
		wndRuneChoice:FindChild("FusionContent"):Show(false)
		if nRunesetType == 1 then --Your Sets
			local tYourSets = {}
			local bYourSets = false
			for _,tSet in pairs(Item.GetSetBonuses()) do
				bYourSets = true
				if not tYourSets[tSet.nSetId] then
					tYourSets[tSet.nSetId] = true
				end
			end
			
			if bYourSets then
				for nSetId,_ in pairs(tYourSets) do
					local tSet = self.ktSets[nSetId]
					local wndFilterSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
					wndFilterSet:FindChild("Name"):SetText(tSet.strName) --TODO: Locale
					if tSet.eClass then
						wndFilterSet:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows16_UI_CRB_Class"..GameLib.GetClassName(tSet.eClass))
						wndFilterSet:FindChild("Icon"):SetAnchorOffsets(7,7,23,-7)
					end
					--self:HelperBuildItemTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId)) --TODO: Deprecate.
					self:HelperBuildRunesetTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId):GetDetailedInfo().tPrimary.tRuneSet)
					wndFilterSet:SetData(nSetId)
				end
			else
				self:PopulateRunesetType(2) --If no 'your sets' available, default to Class Sets.
			end
		elseif nRunesetType == 2 then --Class Sets
			for nSetId,tSet in pairs(self.ktSets) do
				if tSet.eClass == self.ePlayerClass then--This populates sets that are class sets. Change to... TODO: PVP, PVE, BOTH, CLASS distinctions from RuneMiner
					local wndFilterSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
					wndFilterSet:FindChild("Name"):SetText(tSet.strName) --TODO: Locale
					wndFilterSet:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows16_UI_CRB_Class"..GameLib.GetClassName(tSet.eClass))
					wndFilterSet:FindChild("Icon"):SetAnchorOffsets(7,7,23,-7)
					--self:HelperBuildItemTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId)) --TODO: Deprecate.
					self:HelperBuildRunesetTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId):GetDetailedInfo().tPrimary.tRuneSet)
					wndFilterSet:SetData(nSetId)
				end
			end
		elseif nRunesetType == 3 then --Rune Sets
			for nSetId,tSet in pairs(self.ktSets) do
				if not tSet.eClass then --This populates sets that aren't class sets. Change to... TODO: PVP, PVE, BOTH, CLASS distinctions from RuneMiner
					local wndFilterSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
					wndFilterSet:FindChild("Name"):SetText(tSet.strName) --TODO: Locale
					--self:HelperBuildItemTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId)) --TODO: Deprecate.
					--self:HelperBuildRunesetTooltip(wndFilterSet, Item.GetDataFromId(tSet.nExampleId):GetDetailedInfo().tPrimary.tRuneSet)
					wndFilterSet:SetData(nSetId)
				end
			end
		elseif nRunesetType == 5 then --Basic Runes
			local wndFilterSet = Apollo.LoadForm(self.xmlDoc, "RuneChoice_SetEntry", wndRuneChoice:FindChild("SetFilter"), self)
			wndFilterSet:FindChild("Name"):SetText("Basic") --TODO: Locale
			wndFilterSet:SetCheck(true)
			wndFilterSet:SetData("Basic")
		end
	end
	
	wndRuneChoice:FindChild("SetFilter"):ArrangeChildrenVert()
	
	for _,wnd in pairs(wndRuneChoice:FindChild("SetFilter"):GetChildren()) do
		local nSetId = wnd:GetData()
		if self.settings.filters.sets == nSetId then --if self.settings.filters.sets[nSetId] then
			wnd:SetCheck(true)
		end
	end
	if nRunesetType ~= 4 then --Not fusion runes.
		self:UpdatePossibleRunes()
	else
		self:UpdateFusionRunes()
	end
end

function RuneMaster:OnStatEntryToggle(wndHandler, wndControl, eMouseButton)
	local bChecked = wndHandler:IsChecked()
	local eStat = wndHandler:GetData()
	
	if eStat == 999 then
		for _,wnd in pairs(wndHandler:GetParent():GetChildren()) do
			if wnd ~= wndHandler then
				local eStat = wnd:GetData()
				wnd:SetCheck(bChecked)
				self.settings.filters.stats[eStat] = bChecked or nil
			end
		end
	else
		if not bChecked then
			for _,wnd in pairs(wndHandler:GetParent():GetChildren()) do
				local eStat = wnd:GetData()
				if eStat == 999 then
					wnd:SetCheck(bChecked)
					self.settings.filters.stats[eStat] = bChecked or nil
					break
				end
			end
		end
	end
	
	self.settings.filters.stats[eStat] = bChecked or nil
	
	self:UpdatePossibleRunes()
end

function RuneMaster:OnSetEntryToggle(wndHandler, wndControl, eMouseButton)
	local bChecked = wndHandler:IsChecked()
	local eSet = wndHandler:GetData()
	
	--[[if eSet == 999 then
		for _,wnd in pairs(wndHandler:GetParent():GetChildren()) do
			if wnd ~= wndHandler then
				local eSet = wnd:GetData()
				wnd:SetCheck(bChecked)
				self.settings.filters.sets[eSet] = bChecked or nil
			end
		end
	else
		if not bChecked then
			for _,wnd in pairs(wndHandler:GetParent():GetChildren()) do
				local eSet = wnd:GetData()
				if eSet == 999 then
					wnd:SetCheck(bChecked)
					self.settings.filters.sets[eSet] = bChecked or nil
					break
				end
			end
		end
	end
	
	self.settings.filters.sets[eSet] = bChecked or nil--]]
	
	RuneMaster.settings.filters.sets = eSet
	
	self:UpdatePossibleRunes()
end


function RuneMaster:RuneChoice_OnLevelToggle( wndHandler, wndControl, eMouseButton )
	self.settings.filters.level = wndHandler:GetData()
	local nRunesetType = self.wndRuneChoice:FindChild("Header"):GetRadioSel("RunesetType")
	if nRunesetType == 4 then
		self:UpdateFusionRunes()
	else
		self:UpdatePossibleRunes()	
	end
end

function RuneMaster:DrawPossibleRune(nRuneId, eStat, wndParent)
	local itemRune = Item.GetDataFromId(nRuneId)
	local tDetailedInfo = itemRune:GetDetailedInfo().tPrimary
	local tRuneSet = tDetailedInfo.tRuneSet
	local fValue = 0
	
	if tDetailedInfo.arBudgetBasedProperties then --TODO: Maybe make a constant somehow? Use item level and stat as a base? i.e. self.ktStatValues[nLevel][eStat] = nValue; This seems to work, though.
		fValue = tDetailedInfo.arBudgetBasedProperties[1].nValue
	elseif tDetailedInfo.arInnateProperties then
		fValue = tDetailedInfo.arInnateProperties[1].nValue
	end
	local wndRune = Apollo.LoadForm(self.xmlDoc, "RuneChoice_Rune", wndParent, self)
	wndRune:FindChild("Icon"):SetSprite(itemRune:GetIcon())
	
	local strStat = eStat ~= 0 and Item.GetPropertyName(eStat) or tDetailedInfo.arSpells[1].strName
	wndRune:FindChild("Stat"):SetText(string.sub(strStat,1,5):upper())
	
	local tElements = tDetailedInfo.arRuneTypes
	if #tElements == 1 then
		wndRune:FindChild("Icon:Reroll"):Show(tElements[1] ~= self.wndRuneChoice:GetData().eElement)
	else
		--TODO: Multi-element runes (mist, lava, etc.) if ever implemented.
	end
	self:HelperBuildItemTooltip(wndRune, itemRune)

	if tRuneSet then
		local strSet = tRuneSet.strName
		wndRune:FindChild("Set"):SetText(string.sub(strSet,1,5):upper())
		wndRune:FindChild("Icon:Power"):SetText(tRuneSet.nPower)
		--wndRune:FindChild("Icon:Power"):SetTextColor("ItemQuality_"..ktItemQualityColors[itemRune:GetItemQuality()])
		wndRune:FindChild("Icon:Power"):SetTooltip(String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSetText"), tRuneSet.nPower, strSet))
		--wndRune:FindChild("Icon:Quality"):SetSprite("BK3:UI_BK3_ItemQuality"..ktItemQualityData[itemRune:GetItemQuality()].strSprite)
	else
		wndRune:FindChild("Set"):SetText(string.sub("Basic",1,5):upper())
		wndRune:FindChild("Icon:Power"):SetText("")
		--wndRune:FindChild("Icon:Power"):SetTextColor("ItemQuality_"..ktItemQualityColors[itemRune:GetItemQuality()])
	end
	wndRune:FindChild("Value"):SetText(fValue > 0 and math.floor(fValue) or "")
	wndRune:FindChild("Icon:Level"):SetText(tDetailedInfo.nItemLevel)
	wndRune:SetData(nRuneId)
end

function RuneMaster:DrawFusionRune(nRuneId, eStat, wndParent)
	local itemRune = Item.GetDataFromId(nRuneId)
	local tDetailedInfo = itemRune:GetDetailedInfo().tPrimary
	local tSpell = tDetailedInfo.arSpells[1] --TODO: Multiple spells?
	local fValue = 0
	
	local wndRune = Apollo.LoadForm(self.xmlDoc, "RuneChoice_Fusion", wndParent, self)
	wndRune:FindChild("Icon"):SetSprite(itemRune:GetIcon())
	wndRune:FindChild("Level"):SetText(tDetailedInfo.nItemLevel)
		
	self:HelperBuildFusionTooltip(wndRune, tDetailedInfo)

	if tSpell then
		wndRune:FindChild("Name"):SetText(tSpell.strName)
		wndRune:FindChild("Description"):SetText(tSpell.strFlavor)
	else
		wndRune:FindChild("Name"):SetText("SPELLNAMEERR")
		wndRune:FindChild("Description"):SetText("DESCRIPTIONERR")
	end
	wndRune:SetData(nRuneId)
end

function RuneMaster:UpdatePossibleRunes()
	local wndRuneChoice = self.wndRuneChoice:FindChild("RuneContent")
	local luaItem = self.wndRuneChoice:GetData().luaItem
	local nCurrRuneId = self.wndRuneChoice:GetData().nRuneId
	local nItemLevel = luaItem.item:GetPowerLevel()
	local nMaxLevel = nil
	if not self.settings.filters.level then
		self.settings.filters.level = runefloor(nItemLevel)
	end
	wndRuneChoice:FindChild("Runes"):DestroyChildren()

	local tSets = wndRuneChoice:FindChild("SetFilter"):GetChildren()
	local tStats = {}
	for _,wndStat in pairs(wndRuneChoice:FindChild("StatFilter"):GetChildren()) do
		if wndStat:IsChecked() then
			local eStat = wndStat:GetData()
			tStats[eStat] = true
		end
	end
	
	 tSetLevels = {}
	local nFilterLevel = self.settings.filters.level
	for idx=1,#tSets do--for idx=2,#tSets do
		local wndSet = tSets[idx]
		if wndSet:IsChecked() then
			local vSet = wndSet:GetData()
			for nLevel,_ in pairs(self.ktRuneElements[vSet]) do
				tSetLevels[nLevel] = true
				if not nMaxLevel then
					nMaxLevel = nLevel
				else
					nMaxLevel = nMaxLevel < nLevel and nLevel or nMaxLevel
				end				
			end
			if not tSetLevels[self.settings.filters.level] then --Triggers "Max" to max level, since the string is not in the level (integer) table.
				--Debug("Setting to max: ",nMaxLevel)
				nFilterLevel = nItemLevel >= nMaxLevel and nMaxLevel or 0
			end
			if self.ktRuneElements[vSet][nFilterLevel] then 	
				for nRuneId,eStat in pairs(self.ktRuneElements[vSet][nFilterLevel]) do
					if not self.tUniqueRunes[nRuneId] and not luaItem.tItemUniqueRunes[nRuneId] and nCurrRuneId ~= nRuneId then
						if tStats[eStat] then
							self:DrawPossibleRune(nRuneId, eStat, wndRuneChoice:FindChild("Runes"))
						end
					else
						--Print("Found duplicate for",nRuneId)
					end
				end
			else
				--[[local strLevels = ""
				for nLevel,_ in pairs(self.ktRuneElements[vSet]) do
					if strLevels ~= "" then
						strLevels = strLevels..","
					end
					strLevels = strLevels..nLevel
				end-]]
			end
		end
	end
	
	local tLevelWnds = wndRuneChoice:FindChild("iLvl"):GetChildren()
	for _,wndLevel in pairs(tLevelWnds) do
		local nLevel = wndLevel:GetData()
		local nRequiredLevel = self.ktRuneRequiredLevels[nLevel]
		local bEnabled = true
		if not tSetLevels[nLevel] then
			bEnabled = false
		end
		if nRequiredLevel and nItemLevel < nRequiredLevel then
			bEnabled = false
			wndLevel:SetDisabledTextColor("ffff4444")
		else
			wndLevel:SetDisabledTextColor("UI_BtnTextGoldListDisabled")
		end
		wndLevel:Enable(bEnabled)
		if nLevel == nFilterLevel then
			wndLevel:SetCheck(true)
		else
			wndLevel:SetCheck(false)
		end
	end

	wndRuneChoice:FindChild("Runes"):ArrangeChildrenTiles()
end

function RuneMaster:UpdateFusionRunes()
	local wndRuneChoice = self.wndRuneChoice:FindChild("FusionContent")
	local luaItem = self.wndRuneChoice:GetData().luaItem
	local nCurrRuneId = self.wndRuneChoice:GetData().nRuneId
	local eItemSlot = luaItem.item:GetSlot()
	local nItemLevel = luaItem.item:GetPowerLevel()
	local nMaxLevel = nil
	if not self.settings.filters.level then
		self.settings.filters.level = runefloor(nItemLevel)
	end
	wndRuneChoice:FindChild("Runes"):DestroyChildren()
	
	local tSetLevels = {}
	local nFilterLevel = self.settings.filters.level
	for nLevel,_ in pairs(self.ktRuneElements.Fusion) do
		tSetLevels[nLevel] = true
		if not nMaxLevel then
			nMaxLevel = nLevel
		else
			nMaxLevel = nMaxLevel < nLevel and nLevel or nMaxLevel
		end				
	end
	if not tSetLevels[self.settings.filters.level] then --Triggers "Max" to max level, since the string is not in the level (integer) table.
		--Debug("Setting to max: ",nMaxLevel)
		nFilterLevel = nItemLevel >= nMaxLevel and nMaxLevel or 0
	end
	if self.ktRuneElements.Fusion[nFilterLevel] then
		for nRuneId,eStat in pairs(self.ktRuneElements.Fusion[nFilterLevel]) do
			if not self.tUniqueRunes[nRuneId] and not luaItem.tItemUniqueRunes[nRuneId] and nCurrRuneId ~= nRuneId then
				local tDetailedInfo = Item.GetDataFromId(nRuneId):GetDetailedInfo().tPrimary
				if tDetailedInfo.arAllowedSlots then
					local bShow = false
					for _,tSlot in pairs(tDetailedInfo.arAllowedSlots) do
						if tSlot.eEquippedId == eItemSlot then
							bShow = true
							break
						end
					end
					if bShow then
						self:DrawFusionRune(nRuneId, 0, wndRuneChoice:FindChild("Runes"))
					end
				else
					self:DrawFusionRune(nRuneId, 0, wndRuneChoice:FindChild("Runes"))
				end
			else
				--Print("Found duplicate for",nRuneId)
			end
		end
	else
		--[[local strLevels = ""
		for nLevel,_ in pairs(self.ktRuneElements[vSet]) do
			if strLevels ~= "" then
				strLevels = strLevels..","
			end
			strLevels = strLevels..nLevel
		end-]]
	end
	
	local tLevelWnds = wndRuneChoice:FindChild("iLvl"):GetChildren()
	for _,wndLevel in pairs(tLevelWnds) do
		local nLevel = wndLevel:GetData()
		local nRequiredLevel = self.ktRuneRequiredLevels[nLevel]
		local bEnabled = true
		if not tSetLevels[nLevel] then
			bEnabled = false
		end
		if nRequiredLevel and nItemLevel < nRequiredLevel then
			bEnabled = false
			wndLevel:SetDisabledTextColor("ffff4444")
		else
			wndLevel:SetDisabledTextColor("UI_BtnTextGoldListDisabled")
		end
		wndLevel:Enable(bEnabled)
		if nLevel == nFilterLevel then
			wndLevel:SetCheck(true)
		end
	end

	wndRuneChoice:FindChild("Runes"):ArrangeChildrenTiles()
end

function RuneMaster:RuneChoice_OnResetFiltersBtn(wndHandler, wndControl, eMouseButton)
	
end

function RuneMaster:OnRuneChoice(wndHandler, wndControl, eMouseButton)
	local tRuneSlotData = self.wndRuneChoice:GetData()
	local luaItem = tRuneSlotData.luaItem
	local nSlot = tRuneSlotData.nSlot
	local nRuneChoiceId = wndHandler:GetData()
	if not self.tRunePlans[luaItem.nItemId] then
		self.tRunePlans[luaItem.nItemId] = {}
	end
	local nOldRuneId = self.tRunePlans[luaItem.nItemId][nSlot]
	if nOldRuneId then
		if self.tUniqueRunes[nOldRuneId] then
			self.tUniqueRunes[nOldRuneId] = nil
		end
		if luaItem.tItemUniqueRunes[nOldRuneId] then
			luaItem.tItemUniqueRunes[nOldRuneId] = nil
		end
	end
	self.tRunePlans[luaItem.nItemId][nSlot] = nRuneChoiceId
	self.wndRuneChoice:Close()
	luaItem:UpdateWindow()
	
	self:StatReview_UpdateStatReview()
end

