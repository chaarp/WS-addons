-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
local RuneMaster = Apollo.GetAddon("RuneMaster")
local ItemSlot = {}
function ItemSlot:new(nArmorSlot, item)
	local o = {}
	o.nArmorSlot = nArmorSlot
	o.itemEquipped = item
	
	setmetatable(o, self)
	self.__index = self
	o:Init()
	
	return o
end

function ItemSlot:Init()
	self.wndItem = Apollo.LoadForm(RuneMaster.xmlDoc, "ItemSlot_ItemEntry", RuneMaster.wndMain:FindChild("Spreadsheet"):FindChild("Items"), self)
	self.nFoundSets = 0
end


function ItemSlot:SetItem(item)
	self.item = item
	self.tItemUniqueRunes = {}
	self.nItemId = item and item:GetItemId() or 0
	self:UpdateWindow()
end

function ItemSlot:UpdateWindow()
	if self.item and RuneMaster.wndMain then
		--Cleanup
		self.wndItem:FindChild("Runes"):DestroyChildren()
		self.wndItem:FindChild("RuneSets"):DestroyChildren()
		self.wndItem:FindChild("FusionBonus"):DestroyChildren()
		
		--Item
		self.wndItem:FindChild("ItemIcon"):SetSprite(self.item:GetIcon())
		self.wndItem:FindChild("ItemIcon:Quality"):SetSprite("BK3:UI_BK3_ItemQuality"..RuneMaster.ktItemQualityData[self.item:GetItemQuality()].strSprite)
		RuneMaster:HelperBuildItemTooltip(self.wndItem:FindChild("ItemIcon"), self.item)
		
		--Runes/Runesets
		local tRuneInfo = self.item:GetRuneSlots() --Returns {} if no rune slots, so not useful in determining if runes or not.
		local tRunePlan = RuneMaster.tRunePlans[self.nItemId]
		local tFoundSets = {}
		local tStatReview = {sets={},stats={}}--{curr={sets={},stats={}},plan={sets={},stats={}}}
		
		if tRuneInfo.nMaximum then
			local bFoundFusion = false
						
			for nSlot=1,tRuneInfo.nMaximum do
				local wndRune = Apollo.LoadForm(RuneMaster.xmlDoc, "ItemSlot_RuneEntry", self.wndItem:FindChild("Runes"), self)
				wndRune:SetData(nSlot)
				if tRuneInfo.arRuneSlots then
					local tRuneSlot = tRuneInfo.arRuneSlots[nSlot] --Will be nil if locked/unadded.
					if tRuneSlot then --Slot is unlocked (added)
						tRuneSlot.nSlot = nSlot
						tRuneSlot.luaItem = self
						tRuneSlot.nRuneId = tRuneSlot.itemRune and tRuneSlot.itemRune:GetItemId() or 0
						local itemPlanRune = tRunePlan and Item.GetDataFromId(tRunePlan[nSlot]) or nil
						local itemCurrRune = tRuneSlot.itemRune
						
						--StatReview
						RuneMaster:StatReview_PopulateStatReview(tStatReview, itemCurrRune, itemPlanRune)
						
						local itemRune = itemPlanRune or itemCurrRune
						if itemRune then
							local tDetailedInfo = itemRune:GetDetailedInfo().tPrimary
							wndRune:FindChild("Icon"):SetSprite(itemRune:GetIcon()) --TODO: ktElementData[tRuneSlot.eElement]) to remove the class icons??
							
							local tRuneSet = tDetailedInfo.tRuneSet
							if tRuneSet then
								local nSetId = tRuneSet.nSetId
								if not tFoundSets[nSetId] then
									tFoundSets[nSetId] = tRuneSet
								else
									tFoundSets[nSetId].nPower = tFoundSets[nSetId].nPower + tRuneSet.nPower
								end
								if tDetailedInfo.tUnique then
									RuneMaster.tUniqueRunes[itemRune:GetItemId()] = true
								else
									self.tItemUniqueRunes[itemRune:GetItemId()] = true
								end
								
								wndRune:FindChild("Runeset"):SetText(string.sub(tRuneSet.strName,1,5):upper()) --TODO: LOCALE RuneMaster.ktSets[nSetId].strName
								
								local tStat = tDetailedInfo.arBudgetBasedProperties or tDetailedInfo.arInnateProperties
								if tStat then
									local strStat = tStat[1].strName --TODO: Runes with multiple stats. Also has tStat[1].arProperty. 
									wndRune:FindChild("Stat"):SetText(string.sub(strStat,1,6):upper())
								end
								
								wndRune:FindChild("Icon:Power"):Show(true)
								wndRune:FindChild("Icon:Power"):SetText(tRuneSet.nPower)
								local bReroll = tRuneSlot.eElement ~= Item.CodeEnumRuneType.Fusion and tRuneSlot.eElement ~= tDetailedInfo.arRuneTypes[1] --TODO: Possibly use for SlotQueue/RuneQueue
								wndRune:FindChild("Icon:Reroll"):Show(bReroll)
								--wndRune:FindChild("Icon:Power"):SetTextColor("ItemQuality_"..ktItemQualityData[itemRune:GetItemQuality()].strColor)
								wndRune:FindChild("Icon:Power"):SetTooltip(String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSetText"), tRuneSet.nPower, tRuneSet.strSet))
							else
								if tDetailedInfo.arSpells then
									if #tDetailedInfo.arSpells == 1 then
										local strSpell = tDetailedInfo.arSpells[1].strName
										wndRune:FindChild("Runeset"):SetText("FUSION")
										wndRune:FindChild("Stat"):SetText(string.sub(strSpell,1,5):upper())
										
										local wndFusion = Apollo.LoadForm(RuneMaster.xmlDoc, "ItemSlot_RunesetEntry", self.wndItem:FindChild("FusionBonus"), self)
										wndFusion:FindChild("Icon"):SetSprite("IconSprites:Icon_ItemMisc_Rune_Fusion")
										wndFusion:FindChild("Icon"):SetAnchorOffsets(0,0,15,0)
										wndFusion:FindChild("Name"):SetText(tDetailedInfo.arSpells[1].strName)
										RuneMaster:HelperBuildFusionTooltip(wndFusion, tDetailedInfo)
										
										if not bFoundFusion then
											bFoundFusion = true
										end
									else
										Print("[RuneMaster] ERR:IS01 - Multi-spell rune found. Report to Potato via Curse.")
									end
								else
									wndRune:FindChild("Runeset"):SetText("BASIC")
									local tStat = tDetailedInfo.arBudgetBasedProperties or tDetailedInfo.arInnateProperties
									if tStat then
										local strStat = tStat[1].strName --TODO: Runes with multiple stats. Also has tStat[1].arProperty. 
										wndRune:FindChild("Stat"):SetText(string.sub(strStat,1,6):upper())
									end
								end
							end
							wndRune:FindChild("Icon:Level"):SetText(tDetailedInfo.nItemLevel)
							wndRune:FindChild("Icon"):SetOpacity(itemPlanRune ~= nil and 1 or 0.5)
							wndRune:FindChild("Runeset"):SetTextColor(tRuneSlot.eElement == Item.CodeEnumRuneType.Fusion and "FFFF99FF" or "FFFFFFFF")
							wndRune:FindChild("Stat"):SetTextColor(tRuneSlot.eElement == Item.CodeEnumRuneType.Fusion and "FFFF99FF" or "FFFFFFFF")
							
							RuneMaster:HelperBuildItemTooltip(wndRune, itemRune)
						else
							wndRune:FindChild("Icon"):SetAnchorOffsets(-2,-2,2,47)
							wndRune:FindChild("Icon"):SetSprite(RuneMaster.ktElementData[tRuneSlot.eElement].strSprite)
							wndRune:FindChild("Icon"):SetBGColor("99"..RuneMaster.ktElementData[tRuneSlot.eElement].strColor)
							wndRune:FindChild("Icon:Level"):SetText("")
							wndRune:FindChild("Runeset"):SetText("EMPTY")
							wndRune:FindChild("Runeset"):SetTextColor("FFFFFF99")
							wndRune:FindChild("Empty"):Show(true)
						end
					else
						wndRune:FindChild("Icon"):SetSprite("CRB_ActionBarFrameSprites:sprActionBarFrame_Lock4")
						wndRune:FindChild("Runeset"):SetText("LOCKED")
						wndRune:FindChild("RuneButton"):Show(false)
						local wndAddSlot = Apollo.LoadForm(RuneMaster.xmlDoc, "ItemSlot_AddSlotBtn", wndRune, self)
						wndAddSlot:SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotAdd, self.item, nSlot)
					end
					
					wndRune:FindChild("RuneButton"):SetData(tRuneSlot)
				end
			end

			self.wndItem:FindChild("FusionBonus"):SetText(bFoundFusion and "" or "[No Fusion Bonus]")
			
			self.nFoundSets = 0
			for _,tSet in pairs(tFoundSets) do
				self.nFoundSets = self.nFoundSets + 1
				local eClass = RuneMaster.ktSets[tSet.nSetId].eClass
				local wndRuneset = Apollo.LoadForm(RuneMaster.xmlDoc, "ItemSlot_RunesetEntry", self.wndItem:FindChild("RuneSets"), self)
				wndRuneset:FindChild("Name"):SetText(string.format("%s (%s/%s)",tSet.strName,tSet.nPower,tSet.nMaxPower))
				if eClass then
					wndRuneset:FindChild("Icon"):SetAnchorOffsets(0,0,15,0)
					wndRuneset:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows16_UI_CRB_Class"..GameLib.GetClassName(eClass))
				else
					wndRuneset:FindChild("Icon"):SetAnchorOffsets(-6,-6,21,6)
					wndRuneset:FindChild("Icon"):SetSprite("IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_RuneCrafting")
				end
				RuneMaster:HelperBuildRunesetTooltip(wndRuneset, tSet)
			end
			
			self.wndItem:FindChild("RuneSets"):SetText(#self.wndItem:FindChild("RuneSets"):GetChildren()>0 and "" or "[No Rune Sets]")
			
			RuneMaster:Spreadsheet_CheckItemHeights(self.nFoundSets)

			self.wndItem:FindChild("RuneSets"):ArrangeChildrenVert(1)
			
			self.wndItem:FindChild("Runes"):ArrangeChildrenHorz(1)
		end
		
		RuneMaster:StatReview_UpdateArmorSlot(self.nArmorSlot, tStatReview)
	else
		self.wndItem:FindChild("ItemIcon"):SetSprite(RuneMaster.ktArmorSlotInfo[self.nArmorSlot].strSprite)
		self.wndItem:FindChild("RuneSets"):SetText("-")
		self.wndItem:FindChild("RuneSets"):DestroyChildren()
		self.wndItem:FindChild("FusionBonus"):SetText("-")
		self.wndItem:FindChild("FusionBonus"):DestroyChildren()
		self.wndItem:FindChild("Runes"):DestroyChildren()
		self.wndItem:FindChild("ItemIcon:Quality"):SetSprite("")
		self.wndItem:FindChild("ItemIcon"):SetTooltip("")
	end
end

---------------------------------------------------------------------------------------------------
-- RuneEntry Functions
---------------------------------------------------------------------------------------------------
function ItemSlot:OnRuneSlotSelect( wndHandler, wndControl, eMouseButton )
	local tRune = wndHandler:GetData()
	tRune.luaItem = self
	if eMouseButton == 0 then --Left Click
		RuneMaster:ToggleRuneSelection(tRune)
	else --Right Click
		if RuneMaster.tRunePlans[self.nItemId] and RuneMaster.tRunePlans[self.nItemId][tRune.nSlot] then
			local nRuneId = RuneMaster.tRunePlans[self.nItemId][tRune.nSlot]
			RuneMaster.tRunePlans[self.nItemId][tRune.nSlot] = nil
			local bEmpty = true
			for _,_ in pairs(RuneMaster.tRunePlans[self.nItemId]) do
				bEmpty = false
				break
			end
			if bEmpty then
				RuneMaster.tRunePlans[self.nItemId] = nil
			end
			RuneMaster.tUniqueRunes[nRuneId] = nil
			self.tItemUniqueRunes[nRuneId] = nil
			self:UpdateWindow()
			RuneMaster:StatReview_UpdateStatReview()
		end
	end
end

RuneMaster.ItemSlot = ItemSlot