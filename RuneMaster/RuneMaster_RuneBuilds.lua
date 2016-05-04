-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
local RuneMaster = Apollo.GetAddon("RuneMaster")
local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage

local wndRuneBuilds = nil

--[[local floor,insert = math.floor, table.insert	
local function basen(n,b)
	n = floor(n)
	if not b or b == 10 then return tostring(n) end
	local digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	 t = {}
	local sign = ""
	if n < 0 then
		sign = "-"
	n = -n
	end
	repeat
		local d = (n % b) + 1
		n = floor(n / b)
		insert(t, 1, digits:sub(d,d))
	until n == 0
	return sign .. table.concat(t,"")
end
		
function RuneMaster:RuneBuild_PlanToBuild(eArmorSlot, tPlan, bFull)
	local strBuild=""
	for nSlot,nRuneId in pairs(tPlan) do
		strBuild = strBuild..nSlot..string.format("%05d", nRuneId)
	end

	return strBuild.."("..basen(strBuild,36)..")"
end--]]

local ktArmorSlots = {
	GameLib.CodeEnumEquippedItems.WeaponPrimary,
	GameLib.CodeEnumEquippedItems.Head,
	GameLib.CodeEnumEquippedItems.Shoulder,
	GameLib.CodeEnumEquippedItems.Chest,
	GameLib.CodeEnumEquippedItems.Hands,
	GameLib.CodeEnumEquippedItems.Legs,
	GameLib.CodeEnumEquippedItems.Feet
}

function RuneMaster:RuneBuilds_Init()
	wndRuneBuilds = self.wndMain:FindChild("RuneBuilds")
	
	wndRuneBuilds:FindChild("ExportBtn"):Enable(false)
	
	self:RuneBuilds_UpdateBuildList()
end

function RuneMaster:RuneBuilds_SwapWindow(strWindowTarget)
	for _,wnd in pairs(wndRuneBuilds:GetChildren()) do
		wnd:Show(wnd:GetName() == strWindowTarget)
	end
end

function RuneMaster:RuneBuilds_UpdateBuildList()
	local strCheckedBuild = ""
	for _,wndBuild in pairs(wndRuneBuilds:FindChild("BuildList:Builds"):GetChildren()) do
		if wndBuild:IsChecked() then
			strCheckedBuild = wndBuild:GetData()
		end
	end
	
	wndRuneBuilds:FindChild("BuildList:Builds"):DestroyChildren()
	
	for strBuildName,tBuild in pairs(self.tRuneBuilds) do
		local wndBuild = Apollo.LoadForm(self.xmlDoc, "RuneBuilds_BuildEntry", wndRuneBuilds:FindChild("BuildList:Builds"), self)
		wndBuild:SetData(strBuildName)
		wndBuild:FindChild("Name"):SetText(strBuildName)
		if strCheckedBuild == strBuildName then
			wndBuild:SetCheck(true)
			wndBuild:FindChild("LoadBuildBtn"):Show(true)
			wndBuild:FindChild("Name"):SetAnchorOffsets(42,0,-41,0)
		end
	end
	
	wndRuneBuilds:FindChild("BuildList:Builds"):ArrangeChildrenVert()
end

function RuneMaster:RuneBuilds_OnBuildEntryCheck( wndHandler, wndControl, eMouseButton )
	--wndHandler:FindChild("EditBuildBtn"):Show(true)
	wndHandler:FindChild("LoadBuildBtn"):Show(true)
	wndHandler:FindChild("Name"):SetAnchorOffsets(42,0,-41,0)
	
	local strBuildExport = self:RuneBuilds_ConvertBuildToText(wndHandler:GetData())
	wndRuneBuilds:FindChild("ExportBtn"):Enable(true)
	wndRuneBuilds:FindChild("ExportBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, strBuildExport)
end

function RuneMaster:RuneBuilds_ConvertBuildToText(strBuild)
	local tBuild = self.tRuneBuilds[strBuild]
	return strBuild..JSON.encode(tBuild)
end

function RuneMaster:RuneBuilds_OnBuildEntryUncheck( wndHandler, wndControl, eMouseButton )
	--wndHandler:FindChild("EditBuildBtn"):Show(false)
	wndHandler:FindChild("LoadBuildBtn"):Show(false)
	wndHandler:FindChild("Name"):SetAnchorOffsets(5,0,-41,0)
	wndRuneBuilds:FindChild("ExportBtn"):Enable(false)
	wndRuneBuilds:FindChild("ExportBtn"):SetActionData(nil)
end

function RuneMaster:RuneBuilds_OnBuildLoadBtn( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("RuneBuildLoadConfirm"):Show(true)
	self.wndMain:FindChild("RuneBuildLoadConfirm"):SetData(wndHandler:GetParent():GetData())
end

function RuneMaster:RuneBuilds_OnConfirmCancel( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("RuneBuildLoadConfirm"):Show(false)
end

function RuneMaster:RuneBuilds_OnConfirmAccept( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("RuneBuildLoadConfirm"):Show(false)
	
	local strSelectedBuild = self.wndMain:FindChild("RuneBuildLoadConfirm"):GetData()
	self.wndMain:FindChild("RuneBuildLoadConfirm"):SetData(nil)
	
	self.tRunePlans = {}
	 tRuneBuild = self.tRuneBuilds[strSelectedBuild]
	
	local unitPlayer = GameLib.GetPlayerUnit()
	local tEquipped = unitPlayer:GetEquippedItems()
	
	for eArmorSlot,tBuild in pairs(tRuneBuild) do
		local nItemId = nil
		for _,item in pairs(tEquipped) do
			if item:GetSlot() == eArmorSlot then
				nItemId = item:GetItemId()
				break
			end
		end
		for nSlot,nRuneId in pairs(tBuild) do
			if nRuneId then
				tBuild[nSlot] = nRuneId
			end
		end
		if nItemId then
			self.tRunePlans[nItemId] = tBuild
			self.tItemSlots[eArmorSlot]:UpdateWindow()
		end
	end	
end

function RuneMaster:RuneBuilds_OnBuildEditBtn( wndHandler, wndControl, eMouseButton )
	--[[wndRuneBuilds:FindChild("BuildList"):Show(false)
	wndRuneBuilds:FindChild("Edit"):Show(true)
	self.wndMain:FindChild("Spreadsheet"):Enable(false)
	
	local strBuildName = wndHandler:GetData()
	
	wndRuneBuilds:FindChild("Edit:Name"):SetText(strBuildName)
	wndRuneBuilds:FindChild("Edit:Name"):Enable(false)
	
	wndRuneBuilds:FindChild("FillEmpty"):SetCheck(false)
	wndRuneBuilds:FindChild("Edit:ArmorList"):DestroyChildren()
	
	for idx,eArmorSlot in pairs(ktArmorSlots) do
		local wndArmor = Apollo.LoadForm(self.xmlDoc, "RuneBuilds_ArmorEntry", wndRuneBuilds:FindChild("Edit:ArmorList"), self)
		wndArmor:SetText(self.ktArmorSlotInfo[eArmorSlot].strName)
		wndArmor:FindChild("Runes"):Show(false)
		wndArmor:SetData(eArmorSlot)
		
		local nArmorId = self.tItemSlots[eArmorSlot].nItemId
		local itemArmor = self.tItemSlots[eArmorSlot].item
		local tSlotInfo = itemArmor:GetRuneSlots()
		local nMaxSlots = nil
		if tSlotInfo then
			nMaxSlots = tSlotInfo.nMaximum or #tSlotInfo.arRuneSlots
		end
		
		local tRunePlan = self.tRunePlans[nArmorId]
		--if tRunePlan then
			for nSlot=1,nMaxSlots do
				local wndRune = Apollo.LoadForm(self.xmlDoc, "RuneBuilds_RuneEntry", wndArmor:FindChild("Runes"), self)
				if tRunePlan and tRunePlan[nSlot] then
					local nRuneId = tRunePlan[nSlot]
					wndRune:SetSprite(Item.GetDataFromId(nRuneId):GetIcon())
					wndRune:SetData({nRuneId=nRuneId,bPlan=true})
				else
					local nRuneId = 0
					if tSlotInfo and tSlotInfo.arRuneSlots and tSlotInfo.arRuneSlots[nSlot] and tSlotInfo.arRuneSlots[nSlot].itemRune then
						nRuneId = tSlotInfo.arRuneSlots[nSlot].itemRune:GetItemId()
					end
					wndRune:SetData({nRuneId=nRuneId,bPlan=false})
				end
			end
			wndArmor:FindChild("Runes"):ArrangeChildrenHorz(1)
		--end
	end
	wndRuneBuilds:FindChild("Edit:ArmorList"):ArrangeChildrenVert()
	
	wndRuneBuilds:FindChild("Save"):Enable(true)--]]
end

function RuneMaster:RuneBuilds_OnNewBuildBtn( wndHandler, wndControl, eMouseButton )
	self:RuneBuilds_SwapWindow("Edit")
	
	self.wndMain:FindChild("Spreadsheet"):Enable(false)
	
	wndRuneBuilds:FindChild("Edit:Name"):SetText("")
	--wndRuneBuilds:FindChild("Edit:Name"):Enable(true)
	wndRuneBuilds:FindChild("FillEmpty"):SetCheck(false)
	wndRuneBuilds:FindChild("Edit:ArmorList"):DestroyChildren()
	
	for idx,eArmorSlot in pairs(ktArmorSlots) do
		local wndArmor = Apollo.LoadForm(self.xmlDoc, "RuneBuilds_ArmorEntry", wndRuneBuilds:FindChild("Edit:ArmorList"), self)
		wndArmor:SetText(self.ktArmorSlotInfo[eArmorSlot].strName)
		wndArmor:FindChild("Runes"):Show(false)
		wndArmor:SetData(eArmorSlot)
		
		local nArmorId = self.tItemSlots[eArmorSlot].nItemId
		local itemArmor = self.tItemSlots[eArmorSlot].item
		local tSlotInfo = itemArmor:GetRuneSlots()
		local nMaxSlots = nil
		if tSlotInfo then
			nMaxSlots = tSlotInfo.nMaximum or #tSlotInfo.arRuneSlots
		end
		
		local tRunePlan = self.tRunePlans[nArmorId]
		--if tRunePlan then
			for nSlot=1,nMaxSlots do
				local wndRune = Apollo.LoadForm(self.xmlDoc, "RuneBuilds_RuneEntry", wndArmor:FindChild("Runes"), self)
				if tRunePlan and tRunePlan[nSlot] then
					local nRuneId = tRunePlan[nSlot]
					wndRune:SetSprite(Item.GetDataFromId(nRuneId):GetIcon())
					wndRune:SetData({nRuneId=nRuneId,bPlan=true})
				else
					local nRuneId = nil
					if tSlotInfo and tSlotInfo.arRuneSlots and tSlotInfo.arRuneSlots[nSlot] and tSlotInfo.arRuneSlots[nSlot].itemRune then
						nRuneId = tSlotInfo.arRuneSlots[nSlot].itemRune:GetItemId()
					end
					wndRune:SetData({nRuneId=nRuneId,bPlan=false})
				end
			end
			wndArmor:FindChild("Runes"):ArrangeChildrenHorz(1)
		--end
	end
	wndRuneBuilds:FindChild("Edit:ArmorList"):ArrangeChildrenVert()
	
	wndRuneBuilds:FindChild("Save"):Enable(false)
end

function RuneMaster:RuneBuilds_UpdateSaveBtn(bOverride)
	local bChecked, bName = false, false
	for _,wnd in pairs(wndRuneBuilds:FindChild("Edit:ArmorList"):GetChildren()) do
		if wnd:IsChecked() then
			bChecked = true
			break
		end
	end
	
	local strName = wndRuneBuilds:FindChild("Edit:Name"):GetText()
	if #strName > 0 and not self.tRuneBuilds[strName] then
		if not string.find(strName, "%p") then
			bName = true
		end
	end
	
	if bOverride == nil then
		bOverride = true
	end
	wndRuneBuilds:FindChild("Save"):Enable(bChecked and bName and bOverride)
end

function RuneMaster:RuneBuilds_OnToggleFillWithCurr( wndHandler, wndControl, eMouseButton )
	local bFillWithCurr = wndHandler:IsChecked()
	
	for _,wndArmor in pairs(wndRuneBuilds:FindChild("Edit:ArmorList"):GetChildren()) do
		local eArmorSlot = wndArmor:GetData()
		for nSlot,wndRune in pairs(wndArmor:FindChild("Runes"):GetChildren()) do
			local nRuneId = wndRune:GetData().nRuneId
			local bPlan = wndRune:GetData().bPlan
			
			if nRuneId > 0 and (bFillWithCurr or bPlan) then
				wndRune:SetSprite(Item.GetDataFromId(nRuneId):GetIcon())
			else
				wndRune:SetSprite("CRB_Basekit:kitIcon_White_QuestionMark")			
			end
			
			--[[[if bFillWithCurr and nRuneId > 0 then
				wndRune:SetSprite(Item.GetDataFromId(nRuneId):GetIcon())
			else
				if bPlan then
					wndRune:SetSprite(Item.GetDataFromId(nRuneId):GetIcon())
				else
					wndRune:SetSprite("CRB_Basekit:kitIcon_White_QuestionMark")
				end
			end--]]
		end
	end
end

function RuneMaster:RuneBuilds_EditNameChanged( wndHandler, wndControl, strText )
	
	self:RuneBuilds_UpdateSaveBtn()
end

function RuneMaster:RuneBuilds_OnSaveBtn( wndHandler, wndControl, eMouseButton )
	self:RuneBuilds_SwapWindow("BuildList")
	
	self.wndMain:FindChild("Spreadsheet"):Enable(true)
		
	local strName = wndRuneBuilds:FindChild("Edit:Name"):GetText()
	local bFillWithCurr = wndRuneBuilds:FindChild("FillEmpty"):IsChecked()
	self.tRuneBuilds[strName] = {}
	
	for _,wndArmor in pairs(wndRuneBuilds:FindChild("Edit:ArmorList"):GetChildren()) do
		local eArmorSlot = wndArmor:GetData()
		
		local tArmorBuild = {}
		for nSlot,wndRune in pairs(wndArmor:FindChild("Runes"):GetChildren()) do
			local nRuneId = wndRune:GetData().nRuneId
			local bPlan = wndRune:GetData().bPlan
			local nBuildId = nil
			
			if bPlan or bFillWithCurr then
				nBuildId = nRuneId
			end
			
			--if nBuildId > 0 then
				--table.insert(tArmorBuild,nBuildId)
				tArmorBuild[nSlot] = nBuildId
			--end
		end
		--if #tArmorBuild > 0 then
		local bEmpty = true
		for _,_ in pairs(tArmorBuild) do
			bEmpty = false
		end
		if not bEmpty then
			self.tRuneBuilds[strName][eArmorSlot] = tArmorBuild
		end
		--end
	end	
	
	self:RuneBuilds_UpdateBuildList()
end

function RuneMaster:RuneBuilds_OnCancelBtn( wndHandler, wndControl, eMouseButton )
	self:RuneBuilds_SwapWindow("BuildList")
	self.wndMain:FindChild("Spreadsheet"):Enable(true)
end

function RuneMaster:RuneBuilds_OnImportBtn( wndHandler, wndControl, eMouseButton )
	self:RuneBuilds_SwapWindow("Import")
end

function RuneMaster:RuneBuilds_OnImportConfirmBtn( wndHandler, wndControl, eMouseButton )
	local strData = wndRuneBuilds:FindChild("Import:ImportBox"):GetText()
	local strName = string.sub(strData, 1, string.find(strData, "{")-1)
	local strBuild = string.sub(strData, string.find(strData, "{"), #strData)
	local tBuild = JSON.decode(strBuild)
	
	local tFinalBuild = {} --Removes string instances of slots with numbers.
	for eArmorSlot,tRunes in pairs(tBuild) do
		eArmorSlot = tonumber(eArmorSlot)
		tFinalBuild[eArmorSlot] = {}
		for nSlot,nRuneId in pairs(tRunes) do
			tFinalBuild[eArmorSlot][nSlot] = nRuneId
		end
	end
	
	self.tRuneBuilds[strName] = tFinalBuild
	
	self:RuneBuilds_SwapWindow("BuildList")
	
	self:RuneBuilds_UpdateBuildList()
end

function RuneMaster:RuneBuilds_OnToggleArmorEntry( wndHandler, wndControl, eMouseButton )
	local bChecked = wndHandler:IsChecked()
	local eArmorSlot = wndHandler:GetData()
	
	--wndHandler:FindChild("Runes"):DestroyChildren()
	if bChecked then
		wndHandler:FindChild("Runes"):Show(true)
	else
		wndHandler:FindChild("Runes"):Show(false)
	end
	
	self:RuneBuilds_UpdateSaveBtn()
end
