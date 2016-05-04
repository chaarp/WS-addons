-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
local RuneMaster = Apollo.GetAddon("RuneMaster")

function RuneMaster:HelperBuildItemTooltip(wndArg, itemCurr, bCompare)
	local tArgs = {}
	tArgs.bPrimary = true
	tArgs.bSelling = false
	tArgs.itemCompare = bCompare and itemCurr:GetEquippedItemForItemType() or nil
	
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurr, tArgs)
end

local kUIBody = "ff39b5d4"
local kUICyan = "UI_TextHoloBodyCyan"
function RuneMaster:HelperBuildRunesetTooltip(wndParent, tSet)	
	wndParent:SetTooltipDoc(nil)
	wndParent:SetTooltipDocSecondary(nil)
	
	local wndTooltip = wndParent:LoadTooltipForm(self.xmlDoc, "Helpers_RunesetTooltip", self)
	local wndItems = wndTooltip:FindChild("Items")
	
	local wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndItems)
	wnd:SetAML(string.format("<P Font=\"CRB_Header18\" TextColor=\"%s\">%s</P>", "FFFFFFFF", tSet.strName))
	local nTextWidth, nTextHeight = wnd:SetHeightToContentHeight()
	local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()
	wnd:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + 3)

	wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndItems)
	wnd:SetAML(string.format("<P Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</P>", kUIBody , Apollo.GetString("ItemTooltip_RuneSetBonusText")))
	wnd:SetHeightToContentHeight()

	for idx, tCur in pairs(tSet.arBonuses) do
		wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndItems)

		local strPower = ""
		local strValue = ""
		
		local kSetBonusColor = tSet.nPower >= tCur.nPower and "FF00FF00" or kUICyan
		if tCur.strFlavor then --Spell bonus.
			strPower = string.format("<T TextColor=\"%s\">%s</T>", kUIBody, String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSpellPowerSummaryText"), tCur.nPower))
			strValue = string.format("<T TextColor=\"%s\">%s</T>", kSetBonusColor, String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSetNameFlavor"), tCur.strName, tCur.strFlavor))
		else --Stat bonus.
			local nAdjusted_Value

			if tCur.nValue then
				nAdjusted_Value = tCur.nValue * 100 -- make a %
			else
				nAdjusted_Value = ((tCur.nScalar * 100) - 100) -- make a %
			end

			if nAdjusted_Value >= 0 then
				strValue = string.format("<T TextColor=\"%s\">%s</T>", kSetBonusColor , String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSetPositivePower"), nAdjusted_Value, tCur.strName))
			else
				strValue = string.format("<T TextColor=\"%s\">%s</T>", kSetBonusColor , String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSetNegativePower"), nAdjusted_Value, tCur.strName))
			end
			
			strPower = string.format("<T TextColor=\"%s\">%s</T>", kUIBody, String_GetWeaselString(Apollo.GetString("ItemTooltip_RuneSpellPowerSummaryText"), tCur.nPower))
		end

		wnd:SetAML(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P>", strPower .. strValue ))
		wnd:SetHeightToContentHeight()
	end
	
	local nHeight = wndItems:ArrangeChildrenVert(0)
	wndTooltip:SetAnchorOffsets(10,10,wndTooltip:GetWidth()+10,nHeight+55)
end

function RuneMaster:HelperBuildFusionTooltip(wndParent, tItemInfo)	
	wndParent:SetTooltipDoc(nil)
	wndParent:SetTooltipDocSecondary(nil)
	
	local wndTooltip = wndParent:LoadTooltipForm(self.xmlDoc, "Helpers_RunesetTooltip", self)
	local wndItems = wndTooltip:FindChild("Items")
	
	for _,tCur in pairs(tItemInfo.arSpells) do
		--Header
		local wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndItems)
		wnd:SetAML(string.format("<P Font=\"CRB_Header18\" TextColor=\"%s\">%s</P>", "FFFFFFFF", tCur.strName))
		local nTextWidth, nTextHeight = wnd:SetHeightToContentHeight()
		local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()
		wnd:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nTextHeight + 3)
		
		--Description
		wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndItems)
		local strSpecialType = ""
		if tCur.bActivate then
			strSpecialType = String_GetWeaselString(Apollo.GetString("Tooltips_OnUse"))
		elseif tCur.bOnEquip then
			strSpecialType = String_GetWeaselString(Apollo.GetString("Tooltips_OnSpecial"))
		elseif tCur.bProc then
			strSpecialType = String_GetWeaselString(Apollo.GetString("Tooltips_OnSpecial"))
		end

		if strSpecialType ~= "" then
			local strItemSpellEffect = tCur.strName
			strSpecialType = string.format("<T TextColor=\"%s\">%s</T>", "FFFFFFFF", strSpecialType)
			if tCur.strFlavor ~= "" then
				strItemSpellEffect = string.format("<T TextColor=\"%s\">%s</T>", kUIBody, tCur.strFlavor)
			end
			wnd:SetAML(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P>", strSpecialType..strItemSpellEffect))
			local nWidth, nHeight = wnd:SetHeightToContentHeight()
			local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()
			wnd:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nHeight)
		end

		wnd:SetHeightToContentHeight()
	end
	
		
	local nHeight = wndItems:ArrangeChildrenVert(0)
	wndTooltip:SetAnchorOffsets(10,10,wndTooltip:GetWidth()+10,nHeight+55)
end