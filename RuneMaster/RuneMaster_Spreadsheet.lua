-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
local RuneMaster = Apollo.GetAddon("RuneMaster")
local ItemSlot = RuneMaster.ItemSlot

local tItemQualityToSprite = {
	[Item.CodeEnumItemQuality.Inferior] = "Grey",
	[Item.CodeEnumItemQuality.Average] = "White",
	[Item.CodeEnumItemQuality.Good] = "Green",
	[Item.CodeEnumItemQuality.Excellent] = "Blue",
	[Item.CodeEnumItemQuality.Superb] = "Purple",
	[Item.CodeEnumItemQuality.Legendary] = "Orange",
	[Item.CodeEnumItemQuality.Artifact] = "Magenta"
}

local tItemSlots = {
	GameLib.CodeEnumEquippedItems.WeaponPrimary,
	--GameLib.CodeEnumEquippedItems.Shields,
	GameLib.CodeEnumEquippedItems.Head,
	GameLib.CodeEnumEquippedItems.Shoulder,
	GameLib.CodeEnumEquippedItems.Chest,
	GameLib.CodeEnumEquippedItems.Hands,
	GameLib.CodeEnumEquippedItems.Legs,
	GameLib.CodeEnumEquippedItems.Feet,
	--GameLib.CodeEnumEquippedItems.WeaponAttachment,
	--GameLib.CodeEnumEquippedItems.System,
	--GameLib.CodeEnumEquippedItems.Gadget,
	--GameLib.CodeEnumEquippedItems.Implant
}

function RuneMaster:LoadItems()
	self.tItemSlots = {}
	local unitPlayer = GameLib.GetPlayerUnit()
	local tEquipped = unitPlayer:GetEquippedItems()
	self.ePlayerClass = unitPlayer:GetClassId()
	
	for _,nSlot in pairs(tItemSlots) do
		local luaItemSlot = ItemSlot:new(nSlot)
		local itemFound = nil
		for _,item in pairs(tEquipped) do
			if item:GetSlot() == nSlot then
				itemFound = item
				break
			end
		end
		luaItemSlot:SetItem(itemFound)
		self.tItemSlots[nSlot] = luaItemSlot
	end
	
	self:StatReview_UpdateStatReview()
end

local tSpreadsheetHandlers = {
	{"ItemModified", "Spreadsheet_OnItemModified"}
}

function RuneMaster:OnPlanBtn( wndHandler, wndControl, eMouseButton )
	self:Spreadsheet_InitNewSs()
end

function RuneMaster:Spreadsheet_InitNewSs()
	self.wndMain:FindChild("Plan"):FindChild("Items"):DestroyChildren()
	self.tUniqueRunes = {}
	self:LoadItems()
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", "Spreadsheet_OnPlayerEquippedItemChanged", self)
	self:AttachEventHandlers(tSpreadsheetHandlers)
	
	self.wndMain:FindChild("ResetBtn"):Enable(false)
	
	self.wndMain:FindChild("Plan"):FindChild("Items"):ArrangeChildrenTiles()
end

function RuneMaster:Spreadsheet_CheckItemHeights(nFoundSets)
	local nMaxSets = 0
	for _,luaItem in pairs(self.tItemSlots) do
		nMaxSets = luaItem.nFoundSets > nMaxSets and luaItem.nFoundSets or nMaxSets
	end
	if nMaxSets <= 3 then
		nMaxSets = 0
	else
		nMaxSets = nMaxSets - 3
	end
	local nHeight = 160+nMaxSets*15
	for _,luaItem in pairs(self.tItemSlots) do
		luaItem.wndItem:SetAnchorOffsets(0,0,320,160+nMaxSets*15)
	end
	self.wndMain:FindChild("Plan"):FindChild("Items"):ArrangeChildrenTiles()
end

function RuneMaster:Spreadsheet_OnItemModified(itemModified)
	if itemModified:CanEquip() then
		if self.wndMain and self.tItemSlots then
			local nItemId = itemModified:GetItemId()
			local nArmorSlot = itemModified:GetSlot()

			if self.tItemSlots[nArmorSlot].nItemId == nItemId then
				self.tItemSlots[nArmorSlot]:SetItem(itemModified) --Update with new item info.
				self.tItemSlots[nArmorSlot]:UpdateWindow()
			end
		end
	end
end

function RuneMaster:Spreadsheet_OnPlayerEquippedItemChanged(nArmorSlot, itemNew, itemOld)
	if self.wndMain then
		if self.tItemSlots[nArmorSlot] then
			self.tItemSlots[nArmorSlot]:SetItem(itemNew)
			self.tItemSlots[nArmorSlot]:UpdateWindow()
		end
	end
end

function RuneMaster:Spreadsheet_OnAddSlotBtn( wndHandler, wndControl )
	
end


local nResetSecs = 3
local nResetTimer = 0
function RuneMaster:Spreadsheet_OnResetMouseEnter( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end
	
	self.timerReset = ApolloTimer.Create(0.05, true, "Spreadsheet_OnResetBarTimer", self)
end

function RuneMaster:Spreadsheet_OnResetMouseExit( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end
	
	self.wndMain:FindChild("Reset"):FindChild("ResetBtn"):Enable(false)
	self.wndMain:FindChild("Reset"):FindChild("ResetBar"):SetBGColor("77fff9900")
	self.wndMain:FindChild("Reset"):FindChild("ResetBar"):SetAnchorOffsets(0, 0, 0, 0)
	nResetTimer = 0
	if self.timerReset then
		self.timerReset:Stop()
	end
end

function RuneMaster:Spreadsheet_OnResetBarTimer()
	nResetTimer = nResetTimer + 0.05
	local nRight = (nResetTimer/nResetSecs)*245
	self.wndMain:FindChild("Reset"):FindChild("ResetBar"):SetAnchorOffsets(0, 0, nRight, 0)
	if nResetTimer >= nResetSecs then
		self.wndMain:FindChild("Reset"):FindChild("ResetBtn"):Enable(true)
		self.wndMain:FindChild("Reset"):FindChild("ResetBar"):SetBGColor("77ff0000")
		nResetTimer = 0
		if self.timerReset then
			self.timerReset:Stop()
		end
	end
end

function RuneMaster:Spreadsheet_OnResetAll()
	for eArmorSlot,luaArmor in pairs(self.tItemSlots) do
		self.tRunePlans[luaArmor.nItemId] = nil
		luaArmor:UpdateWindow()
	end
end
