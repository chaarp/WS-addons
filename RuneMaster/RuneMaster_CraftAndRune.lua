-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------

local RuneMaster = Apollo.GetAddon("RuneMaster")

local tCraftAndRuneHandlers = {
	{"ItemModified", "CraftAndRune_OnItemModified"},
	{"ChannelUpdate_Crafting", "CraftAndRune_OnChannelUpdate_Crafting"}
}

function RuneMaster:CraftAndRune_Init()
	self.wndMain:FindChild("CraftAndRune"):FindChild("Schematics"):DestroyChildren()
	self:AttachEventHandlers(tCraftAndRuneHandlers)
	self:CraftAndRune_LoadSchematics()
	self.wndMain:FindChild("CraftAndRune"):FindChild("CraftAndRuneAll"):Enable(false) --TODO: Remove when implemented.
end

function RuneMaster:OnRuneAllBtn( wndHandler, wndControl, eMouseButton )
	if not self.settings.disclaimer then
		self:OpenDisclaimer()
	else
		self:CraftAndRune_StartItemQueue()
	end
end

function RuneMaster:OnCraftAndRuneBtn(wndHandler, wndControl, eMouseButton)
	self:CraftAndRune_Init()
end

function RuneMaster:OpenDisclaimer()
	local wndDisclaimer = self.wndMain:FindChild("AutoRuneDisclaimer")
	wndDisclaimer:Show(true)
	wndDisclaimer:FindChild("btnAccept"):Enable(false)
	wndDisclaimer:FindChild("btnAcceptForever"):SetCheck(false)
	wndDisclaimer:FindChild("EditBox"):SetText("")
	wndDisclaimer:FindChild("Name"):SetText(GameLib.GetPlayerUnit():GetName())
	
	--Disable window behind.
	for _,wnd in pairs(self.wndMain:FindChild("CraftAndRune"):GetChildren()) do --TODO: Possibly move if needed elsewhere.
		if wnd ~= wndDisclaimer then
			wnd:Enable(false) --TODO: Make the boolean value an argument if above is done.
		end
	end
end

function RuneMaster:OnDisclaimerEditChange( wndHandler, wndControl, strText )
	local wndDisclaimer = self.wndMain:FindChild("AutoRuneDisclaimer")
	local strPlayerName = wndDisclaimer:FindChild("Name"):GetText()
	local bEnable = string.lower(strText) == string.lower(strPlayerName)
	wndDisclaimer:FindChild("btnAccept"):Enable(bEnable)
end

function RuneMaster:OnDisclaimerCancel( wndHandler, wndControl, eMouseButton )
	local wndDisclaimer = self.wndMain:FindChild("AutoRuneDisclaimer")
	wndDisclaimer:Close()
	
	--Enable window behind.
	for _,wnd in pairs(self.wndMain:FindChild("CraftAndRune"):GetChildren()) do --TODO: Possibly move if needed elsewhere.
		if wnd ~= wndDisclaimer then
			wnd:Enable(true) --TODO: Make the boolean value an argument if above is done.
		end
	end
end

function RuneMaster:OnDisclaimerAccept( wndHandler, wndControl, eMouseButton )
	local wndDisclaimer = self.wndMain:FindChild("AutoRuneDisclaimer")
	self.settings.disclaimer = wndDisclaimer:FindChild("btnAcceptForever"):IsChecked()
	self:CraftAndRune_StartItemQueue()
	wndDisclaimer:Close()
	
	--Enable window behind.
	for _,wnd in pairs(self.wndMain:FindChild("CraftAndRune"):GetChildren()) do --TODO: Possibly move if needed elsewhere.
		if wnd ~= wndDisclaimer then
			wnd:Enable(true) --TODO: Make the boolean value an argument if above is done.
		end
	end
end

local tCraftQueue = {}
local nCraftQueue = 0
local bCraftQueue = false
function RuneMaster:CraftAndRune_LoadSchematics() --TODO: Total materials count for shopping list.
	local tRuneCounts = {}
	tCraftQueue = {}
	nCraftQueue = 0
	
	local tEquipped = {}
	for _,item in pairs(CraftingLib.GetItemsWithRuneSlots(true,false)) do --Equipped,Bags
		tEquipped[item:GetItemId()] = true
	end
	
	for nItemId,tRunes in pairs(self.tRunePlans) do
		if tEquipped[nItemId] then
			for nSlot,nRuneId in pairs(tRunes) do
				if not tRuneCounts[nRuneId] then
					tRuneCounts[nRuneId] = 1
				else
					tRuneCounts[nRuneId] = tRuneCounts[nRuneId] + 1
				end
			end
		end
	end
	
	for nRuneId,nCount in pairs(tRuneCounts) do
		local wndRuneSchematic = Apollo.LoadForm(self.xmlDoc, "Craft_Rune", self.wndMain:FindChild("CraftAndRune"):FindChild("Schematics"), self)
		local itemRune = Item.GetDataFromId(nRuneId)
		local nBagCount = itemRune:GetBackpackCount()
		wndRuneSchematic:FindChild("Icon"):SetSprite(itemRune:GetIcon())
		wndRuneSchematic:FindChild("Icon"):FindChild("Quality"):SetSprite("BK3:UI_BK3_ItemQuality"..self.ktItemQualityData[itemRune:GetItemQuality()].strSprite)
		wndRuneSchematic:FindChild("Name"):SetText(itemRune:GetName())
		wndRuneSchematic:FindChild("CraftAmount"):SetText(string.format("%s/%s",nBagCount,nCount))
		if self.ktSchematics[nRuneId] then
			local tSchematicInfo = CraftingLib.GetSchematicInfo(self.ktSchematics[nRuneId])
			tSchematicInfo.nCount = nCount
			wndRuneSchematic:SetData(tSchematicInfo)
			--[[{
			  arMaterials = { {
				  itemMaterial = <userdata 1>,
				  nNeeded = 2,
				  nOwned = 495
				}, {
				  itemMaterial = <userdata 2>,
				  nNeeded = 1,
				  nOwned = 0
				} },
			  bIsAutoCraft = false,
			  bIsAutoLearn = true,
			  bIsKnown = true,
			  bIsOneUse = false,
			  bIsUniversal = false,
			  eTier = 1,
			  eTradeskillId = 22,
			  itemOutput = <userdata 3>,
			  monMaxCraftingCost = <userdata 4>,
			  nCraftXp = 0,
			  nCreateCount = 1,
			  nFailXp = 0,
			  nLearnXp = 0,
			  nParentSchematicId = 0,
			  nSchematicId = 3529,
			  strName = "Lesser Logic Rune: CriMit"
			}--]]
			

			wndRuneSchematic:FindChild("Cost"):SetAmount(tSchematicInfo.monMaxCraftingCost)
			for _,tMaterial in pairs(tSchematicInfo.arMaterials) do
				local itemMaterial = tMaterial.itemMaterial
				local wndMaterial = Apollo.LoadForm(self.xmlDoc, "Craft_Material", wndRuneSchematic:FindChild("Materials"), self)
				wndMaterial:FindChild("Icon"):SetSprite(itemMaterial:GetIcon())
				wndMaterial:FindChild("Amount"):SetText(string.format("%s / %s",tMaterial.nOwned,tMaterial.nNeeded*nCount))
				if tMaterial.nOwned < tMaterial.nNeeded*nCount then
					wndMaterial:FindChild("Icon"):SetBGColor("FFFF0000")
				end
				self:HelperBuildItemTooltip(wndMaterial, itemMaterial)
				
				--[[tMaterial.itemMaterial
				tMaterial.nNeeded
				tMaterial.nOwned--]]
			end
			wndRuneSchematic:FindChild("Materials"):ArrangeChildrenHorz()
			
			
			while nBagCount < nCount do
				table.insert(tCraftQueue, tSchematicInfo)
				nBagCount = nBagCount + 1
			end
		else
			wndRuneSchematic:FindChild("Materials"):SetText("No Known Schematic")
			wndRuneSchematic:FindChild("Craft"):Show(false)
		end
	end
	self.wndMain:FindChild("CraftAndRune"):FindChild("Schematics"):ArrangeChildrenVert()
end

function RuneMaster:UpdateNeededList()
	local tShoppingList = {}
	self.wndMain:FindChild("CraftAndRune"):FindChild("ShoppingList"):DestroyChildren()
	
	for _,wndRuneSchematic in pairs(self.wndMain:FindChild("CraftAndRune"):FindChild("Schematics"):GetChildren()) do
		local tSchematicInfo = wndRuneSchematic:GetData()
		local itemRune = tSchematicInfo.itemOutput
		local nBagCount = itemRune:GetBackpackCount()
		wndRuneSchematic:FindChild("CraftAmount"):SetText(string.format("%s/%s",nBagCount,tSchematicInfo.nCount))
		for _,tMaterial in pairs(tSchematicInfo.arMaterials) do
			local itemMaterial = tMaterial.itemMaterial
			local wndMaterial = Apollo.LoadForm(self.xmlDoc, "Craft_Material", wndRuneSchematic:FindChild("Materials"), self)
			wndMaterial:FindChild("Icon"):SetSprite(itemMaterial:GetIcon())
			wndMaterial:FindChild("Icon"):SetText(string.format("%s/%s",tMaterial.nOwned,tMaterial.nNeeded*tSchematicInfo.nCount))
			
			local nNeeded = tMaterial.nNeeded*tSchematicInfo.nCount-tMaterial.nOwned
			if nNeeded > 0 then
				wndMaterial:FindChild("Icon"):SetBGColor("FFFF0000")
				--local nMaterialId = tMaterial.itemMaterial:GetItemId()
				--tShoppingList[nMaterialId] = tShoppingList[nMaterialId] or {}
				--tShoppingList[nMaterialId] = tShoppingList[nMaterialId] + nNeeded
			end
			self:HelperBuildItemTooltip(wndMaterial, itemMaterial)
			
			--[[tMaterial.itemMaterial
			tMaterial.nNeeded
			tMaterial.nOwned--]]
		end
	end
	
	--[[for nItemId,nNeeded in pairs(tShoppingList) do
		local itemMaterial = Item.GetDataFromId(nItemId)
		local wndMaterial = Apollo.LoadForm(self.xmlDoc, "Craft_ShoppingList", self.wndMain:FindChild("CraftAndRune"):FindChild("ShoppingList"), self)
		
		wndMaterial:FindChild("wndMatIcon"):SetSprite(itemMaterial:GetIcon())
		wndMaterial:FindChild("wndNumber"):SetText(nNeeded.." x")
		wndMaterial:FindChild("wndItemName"):SetText(itemMaterial:GetName())
	end--]]
end

function RuneMaster:CraftAndRune_OnSchematicCraftBtn(wndHandler, wndControl, eMouseButton)
	local Runecrafting = Apollo.GetAddon("Runecrafting")
	if not Runecrafting.wndMain then
		if CraftingLib.IsAtEngravingStation() then
			Sound.Play(Sound.PlayUICraftingFailure)
			Print("[RuneMaster] Runecrafting window not open!")
			return
		else
			Sound.Play(Sound.PlayUICraftingFailure)
			Print("[RuneMaster] You are not near an engraving station!")
			return
		end
	end
	
	local tSchematicInfo = wndHandler:GetParent():GetData()
	if tSchematicInfo then --If the next craft queue exists.
		for _,tMaterial in pairs(tSchematicInfo.arMaterials) do
			if tMaterial.nOwned < tMaterial.nNeeded then
				Print(string.format("[RuneMaster] You do not have the materials needed for %s.",tSchematicInfo.strName)) --TODO: GUI
				return
			end
		end
		CraftingLib.CraftItem(tSchematicInfo.nSchematicId)
	else
		self:CraftAndRune_CraftComplete()
	end	
end

function RuneMaster:OnCraftAllBtn(wndHandler, wndControl, eMouseButton)
	self:CraftAndRune_StartCraftQueue()
end

function RuneMaster:CraftAndRune_OnChannelUpdate_Crafting(eType, tEventArgs)
	--[[tEventArgs = {
		itemNew = Item,
		nCount = n
	}]]--
	if self.wndMain and self.wndMain:IsVisible() and bCraftQueue then
		local itemNew = tEventArgs.itemNew
		if eType == GameLib.ChannelUpdateCraftingType.Item and itemNew then
			self:UpdateNeededList()
			if #tCraftQueue > 0 then
				self:NextCraftQueue()
			else
				Print("[RuneMaster] ERR: NO CRAFT QUEUE")
			end
		end
	end
end

local unitPlayer = {}
local nTotalInventory = 0
function RuneMaster:CraftAndRune_StartCraftQueue() --TODO: Reconfigure this to match the other 2 queues.
	Print("[RuneMaster] Auto-crafting started.")
	bCraftQueue = true
	unitPlayer = GameLib.GetPlayerUnit()
	nTotalInventory = GameLib.GetTotalInventorySlots() or 0
	--TODO: Move below to a function and return a boolean to continue.
	local Runecrafting = Apollo.GetAddon("Runecrafting")
	if not Runecrafting.wndMain then
		if CraftingLib.IsAtEngravingStation() then
			Sound.Play(Sound.PlayUICraftingFailure)
			Print("[RuneMaster] Runecrafting window not open!")
			return
		else
			Sound.Play(Sound.PlayUICraftingFailure)
			Print("[RuneMaster] You are not near an engraving station!")
			return
		end
	end

	if #tCraftQueue > 0 then
		local nOccupiedInventory = #unitPlayer:GetInventoryItems() or 0
		local nAvailableInventory = nTotalInventory - nOccupiedInventory
		
		if nAvailableInventory >= #tCraftQueue then
			self:NextCraftQueue()
		else
			Print(string.format("[RuneMaster] Inventory full. You have %s of %s slots needed (need %s more).", nAvailableInventory, #tCraftQueue, #tCraftQueue-nAvailableInventory)) --TODO: GUI; Addon detection of inventory freeing. Use to toggle button "enabled"
			self:CraftAndRune_CraftFailed()
			return
		end
	else
		Print("[RuneMaster] Have all runes, skipping Auto-crafting.") --TODO: Make the button not available until craft queue exists.
		--self:CraftAndRune_CraftFailed()
		return
	end
end

function RuneMaster:NextCraftQueue()
	nCraftQueue = nCraftQueue + 1
	local tSchematicInfo = tCraftQueue[nCraftQueue]
	if tSchematicInfo then --If the next craft queue exists.
		for _,tMaterial in pairs(tSchematicInfo.arMaterials) do
			if tMaterial.nOwned < tMaterial.nNeeded then
				Print(string.format("[RuneMaster] You do not have the materials needed for %s.",tSchematicInfo.strName)) --TODO: GUI
				self:CraftAndRune_CraftFailed()
				return
			end
		end
		CraftingLib.CraftItem(tSchematicInfo.nSchematicId)
	else
		self:CraftAndRune_CraftComplete()
	end
end

function RuneMaster:CraftAndRune_CraftComplete()
	--TODO: Put in update for runes needed list here.
	--self:CraftAndRune_Update
	bCraftQueue = false
	Print("[RuneMaster] Auto-crafting completed.") --TODO: GUI
end

function RuneMaster:CraftAndRune_CraftFailed()
	bCraftQueue = false
	Print("[RuneMaster] Auto-crafting stopped.")
end


















local tItemMap = {}
local tItemQueue = {}
local nItemQueue = 0

--Per item variables, but used globally in functions other than CAR_NIQ
local tRemoveQueue = {}
local bRemoveQueue = false
local nRemoveQueue = 0
local tRerollQueue = {}
local bRerollQueue = false
local nRerollQueue = 0
local bFinalizeItem = false

local tFinalPlan = {}
local tNeededElements = {}
local tFusionSlots = {}

function RuneMaster:CraftAndRune_StartItemQueue()
	tItemQueue = {}
	nItemQueue = 0
	
	for nArmorSlot,luaItem in pairs(self.tItemSlots) do
		if self.tRunePlans[luaItem.nItemId] then
			tItemMap[luaItem.nItemId] = luaItem.item
		end
	end
	
	for nItemId,tPlan in pairs(self.tRunePlans) do
		if tItemMap[nItemId] then
			for _,_ in pairs(tPlan) do --TODO: Ghetto. Take out empty self.tRunePlans. Possibly not needed after self-clearing self.tRunePlans
				table.insert(tItemQueue,nItemId)
				break
			end
		end
	end
	
	if #tItemQueue > 0 then
		self:CraftAndRune_NextItemQueue()
	else
		self:CraftAndRune_FinishItemQueue()
	end
end

--Per Item Slot Queue
function RuneMaster:CraftAndRune_NextItemQueue()
	nItemQueue = nItemQueue + 1
	
	local nItemId = tItemQueue[nItemQueue]
	if nItemId ~= nil then
		local tPlanElements = {}
		local tItemElements = {}
		
		-------------------------------------		
		tRemoveQueue = {}
		bRemoveQueue = false
		tRerollQueue = {}
		bRerollQueue = false
		bFinalizeItem = false
		
		tFinalPlan = {}
		tNeededElements = {}
		tFusionSlots = {}
		tFusionRunes = {}
		-------------------------------------
		
		local item = tItemMap[nItemId]
		local tItemRuneSlots = item:GetRuneSlots().arRuneSlots

		for nSlot,tRune in pairs(tItemRuneSlots) do
			local nRunePlanId = self.tRunePlans[nItemId][nSlot]
			if nRunePlanId then --Has a rune planned.
				local itemRunePlan = Item.GetDataFromId(nRunePlanId)
				local tRunePlanInfo = itemRunePlan:GetDetailedInfo().tPrimary
				local ePlanElement = #tRunePlanInfo.arRuneTypes == 1 and tRunePlanInfo.arRuneTypes[1] or Item.CodeEnumRuneType.Fusion --TODO: This is where steam/lava/multi-runes will be handled. Currently defaults to Fusion.
				
				if tRune.eElement == Item.CodeEnumRuneType.Fusion then
					tFusionSlots[nSlot] = false
				end
				if not tItemElements[tRune.eElement] then
					tItemElements[tRune.eElement] = {}
				end
				table.insert(tItemElements[tRune.eElement], nSlot)
				
				if not tPlanElements[ePlanElement] then
					tPlanElements[ePlanElement] = {}
				end
				table.insert(tPlanElements[ePlanElement], nRunePlanId)
				
				if tRune.itemRune then
					table.insert(tRemoveQueue, nSlot)
				end
			else
				tFinalPlan[nSlot] = tRune.itemRune and tRune.itemRune:GetItemId() or 0
			end
		end

		for eElement,tRunes in pairs(tPlanElements) do
			if eElement ~= Item.CodeEnumRuneType.Fusion then
				for idx, nRunePlanId in pairs(tRunes) do
					if tItemElements[eElement] and tItemElements[eElement][idx] then
						tFinalPlan[tItemElements[eElement][idx]] = nRunePlanId					
					else
						if not tNeededElements[eElement] then
							tNeededElements[eElement] = {}
						end
						table.insert(tNeededElements[eElement], nRunePlanId)
					end
				end
			else
				for idx, nRunePlanId in pairs(tRunes) do
					table.insert(tFusionRunes, nRunePlanId)
				end
			end
		end
		
		local nMaxSlots = #tItemRuneSlots
		for idx=1,nMaxSlots do
			if not tFinalPlan[idx] then
				--If it's a fusion slot, and it's not already planned
				if tFusionSlots[idx] ~= nil and not tFusionSlots[idx] then
					for eElement,tRunes in pairs(tNeededElements) do
						if #tRunes > 0 then
							tFinalPlan[idx] = tRunes[1]
							table.remove(tNeededElements[eElement], 1)
							tFusionSlots[idx] = true
							break
						end
					end
				else
					if #tFusionRunes > 0 then
						tFinalPlan[idx] = tFusionRunes[1]
						table.remove(tFusionRunes,1)
					else
						table.insert(tRerollQueue,idx)
					end
				end
			end
		end

		if #tRemoveQueue > 0 then
			self:CraftAndRune_StartRemoveQueue()
		elseif #tRerollQueue > 0 then
			self:CraftAndRune_StartRerollQueue()
		else
			self:CraftAndRune_FinalizeCurrentItemQueue()
		end
	else
		self:CraftAndRune_FinishItemQueue()
	end
end

function RuneMaster:CraftAndRune_FinalizeCurrentItemQueue()
	bRemoveQueue = false
	bRerollQueue = false
	bFinalizeItem = true
	
	CraftingLib.InstallRuneIntoSlot(tItemMap[tItemQueue[nItemQueue]], tFinalPlan)
	self.tRunePlans[tItemQueue[nItemQueue]] = nil --TODO: This clears plan even if they don't slot properly. Put in a double check via CAR_OIM
end

function RuneMaster:CraftAndRune_FinishItemQueue()
	Print("[RuneMaster] ItemQueue Complete")
end

function RuneMaster:CraftAndRune_StartRemoveQueue()
	bRemoveQueue = true
	bRerollQueue = false
	bFinalizeItem = false
	nRemoveQueue = 1
	
	self:CraftAndRune_NextRemoveQueue()
end

function RuneMaster:CraftAndRune_NextRemoveQueue()
	self:RemoveQuery(tRemoveQueue[nRemoveQueue])
end

function RuneMaster:CraftAndRune_FinishRemoveQueue()
	bRemoveQueue = false
	
	if #tRerollQueue > 0 then
		self:CraftAndRune_StartRerollQueue()
	end
end

function RuneMaster:RemoveQuery(nSlot)
	local wndRemove = self:CraftAndRune_AutoRuneWindowShow("Remove")
	
	local item = tItemMap[tItemQueue[nItemQueue]]
	local itemRemoveRune = item:GetRuneSlots().arRuneSlots[nSlot].itemRune
	
	wndRemove:FindChild("RuneName"):SetText(itemRemoveRune:GetName())
	wndRemove:FindChild("RemoveBtn"):FindChild("RuneIcon"):SetSprite(itemRemoveRune:GetIcon())
	wndRemove:FindChild("PlatinumBtn"):FindChild("RuneIcon"):SetSprite(itemRemoveRune:GetIcon())
	wndRemove:FindChild("ServiceBtn"):FindChild("RuneIcon"):SetSprite(itemRemoveRune:GetIcon())
	
	wndRemove:FindChild("RemoveBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotClear, item, nSlot, false, false) --false,false = bSave,bServicetkns
	wndRemove:FindChild("PlatinumBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotClear, item, nSlot, true, false)
	wndRemove:FindChild("ServiceBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotClear, item, nSlot, true, true)
end

function RuneMaster:CraftAndRune_StartRerollQueue()
	bRemoveQueue = false
	bRerollQueue = true
	bFinalizeItem = false
	nRerollQueue = 1
	
	self:CraftAndRune_NextRerollQueue()
end

function RuneMaster:CraftAndRune_NextRerollQueue()
	self:RerollQuery(tRerollQueue[nRerollQueue])
end

function RuneMaster:CraftAndRune_FinishRerollQueue()
	bRerollQueue = false
	
	self:CraftAndRune_FinalizeCurrentItemQueue()
	--self:CraftAndRune_NextItemQueue()
end

function RuneMaster:RerollQuery(nSlot)
	local wndReroll = self:CraftAndRune_AutoRuneWindowShow("Reroll")
	
	local item = tItemMap[tItemQueue[nItemQueue]]
	--TODO: New UI for multiple element rerolls. Circle? This shows that it's just going to one. That's not correct. Misleading.
	--wndReroll:FindChild("ElementChange"):SetText(self.ktElementData[item:GetRuneSlots().arRuneSlots[nSlot].eElement].strName.." -> "..self.ktElementData[eFirstElement].strName)	

	--TODO: Temporary slot UI.
	wndReroll:FindChild("ElementChange"):DestroyChildren()
	for key,val in pairs(item:GetRuneSlots().arRuneSlots) do
		local wndRune = Apollo.LoadForm(self.xmlDoc, "CraftAndRune_TempRune", wndReroll:FindChild("ElementChange"), self)
		wndRune:FindChild("RuneIcon"):SetSprite(val.itemRune and val.itemRune:GetIcon() or self.ktElementData[val.eElement].strSprite)
		wndRune:FindChild("Border"):Show(key==nSlot)
	end
	wndReroll:FindChild("ElementChange"):ArrangeChildrenHorz(1)
	
	--Random Button
	wndReroll:FindChild("RandomBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotReroll, item, nSlot)
	
	--Match Button
	--Find the first match in the needed rune table.
	local eFirstElement = 0
	for eElement,tRunes in pairs(tNeededElements) do
		if #tRunes > 0 then
			eFirstElement = eElement
			break
		else
			Print("[RuneMaster] ERR:CAR01 - No match found. Report to Potato via Curse.")
		end
	end
	if eFirstElement > 0 then
		wndReroll:FindChild("MatchBtn"):FindChild("ElementIcon"):SetSprite(self.ktElementData[eFirstElement].strSprite)
		wndReroll:FindChild("MatchBtn"):FindChild("ElementIcon"):SetBGColor("FF"..self.ktElementData[eFirstElement].strColor)
		wndReroll:FindChild("MatchBtn"):FindChild("ElementName"):SetText(self.ktElementData[eFirstElement].strName.." Slot")
		
		wndReroll:FindChild("MatchBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.RuneSlotReroll, item, nSlot, eFirstElement)
	else
		Print("ERR WITH NO FIRST ELEMENT")
	end
end
function RuneMaster:CraftAndRune_OnItemModified(itemMod)
	local nItemId = itemMod:GetItemId()
	if tItemMap[nItemId] and nItemId == tItemQueue[nItemQueue] then --If the item is in the queue and is the current itemqueue item.
		tItemMap[nItemId] = itemMod
		
		if bRemoveQueue then
			nRemoveQueue = nRemoveQueue + 1
			if tRemoveQueue[nRemoveQueue] then
				self:CraftAndRune_NextRemoveQueue()
			else
				self:CraftAndRune_FinishRemoveQueue()
			end
		elseif bRerollQueue then
			local tItemRunes = itemMod:GetRuneSlots().arRuneSlots
			local nSlot = tRerollQueue[nRerollQueue]
			local eSlotElement = tItemRunes[nSlot].eElement
			if tNeededElements[eSlotElement] then
				tFinalPlan[nSlot] = tNeededElements[eSlotElement][1]
				table.remove(tNeededElements[eSlotElement],1)
				if #tNeededElements[eSlotElement] < 1 then
					tNeededElements[eSlotElement] = nil
				end
				nRerollQueue = nRerollQueue + 1
			else
				--Not a needed rune, reroll again (this is forced by the CAR_NRQ without incrementing nRerollQueue - TODO: Ghetto).
			end
			if tRerollQueue[nRerollQueue] then
				self:CraftAndRune_NextRerollQueue()
			else
				self:CraftAndRune_FinishRerollQueue()
			end
		elseif bFinalizeItem then
			--TODO: Put in a final check here before advancing.
			self:CraftAndRune_NextItemQueue()
		end
	end
end

function RuneMaster:CraftAndRune_OnRuneSlotRerolledBtn( wndHandler, wndControl )
	self:CraftAndRune_AutoRuneWindowShow("Loading")
end

function RuneMaster:CraftAndRune_OnRuneSlotClearedBtn( wndHandler, wndControl )
	self:CraftAndRune_AutoRuneWindowShow("Loading")
end

function RuneMaster:CraftAndRune_AutoRuneWindowShow(strWindow)
	local wndFound = nil
	
	for _,wnd in pairs(self.wndMain:FindChild("AutoRuneWindow"):GetChildren()) do
		if wnd:GetName() == strWindow then
			wnd:Show(true)
			wndFound = wnd
		else
			wnd:Show(false)
		end
	end
	
	return wndFound
end