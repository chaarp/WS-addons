-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
--TODO: Make a pass over and rename window names to proper names.
 
local RuneMaster = Apollo.GetAddon("RuneMaster")

local tSettingsUI = {
	{"Header","General Settings"},
	{"CheckBox","Show rune type name instead of rune item level","showlevelnames","OnShowLevelNames"},
	{"Header","Auto-Rune Settings"},
	{"CheckBox","Auto rune without accepting the disclaimer.".."\n".."WARNING: Money/runes lost as a result are your responsibility.","disclaimer"}
}

local wndSettings = nil
function RuneMaster:OnSettingsBtn( wndHandler, wndControl, eMouseButton )
	wndSettings = self.wndMain:FindChild("BG:Settings")
	self:Settings_Init()
end

function RuneMaster:Settings_Init()
	--Load in left side settings
	wndSettings:FindChild("Left"):DestroyChildren()
	for _,tSetting in pairs(tSettingsUI) do
		local strType = tSetting[1]
		local strLabel = tSetting[2]
		local strVariable = tSetting[3]
		local strFunction = tSetting[4]
		
		local wndSetting = Apollo.LoadForm(self.xmlDoc, "Settings_"..strType, wndSettings:FindChild("Left"), self)
		local strFont = "Default"
		wndSetting:SetText(strLabel)
		if strType == "CheckBox" then
			strFont = "DefaultButton"
			wndSetting:SetCheck(self.settings[strVariable])
			wndSetting:SetData({var=strVariable,func=strFunction})
		elseif strType == "Slider" then
		
		end
		--Resize to fit text.
		local nHeight, nWidth = wndSetting:GetHeight(), wndSetting:GetWidth()
		local nTextWidth = Apollo.GetTextWidth(strFont, strLabel)
		local nLines = math.ceil(nTextWidth/nWidth)
		if nLines > 1 then
			wndSetting:SetAnchorOffsets(0,0,0,nLines*nHeight)
		end
	end
	wndSettings:FindChild("Left"):ArrangeChildrenVert()
	
	--Load in rune plans on right
	wndSettings:FindChild("Right:Container"):DestroyChildren()
	for nItemId,tPlan in pairs(self.tRunePlans) do
		local wndRunePlan = Apollo.LoadForm(self.xmlDoc, "Settings_RunePlan", wndSettings:FindChild("Right:Container"), self)
		local itemArmor = Item.GetDataFromId(nItemId)
		wndRunePlan:FindChild("ItemIcon"):SetSprite(itemArmor:GetIcon())
		self:HelperBuildItemTooltip(wndRunePlan:FindChild("ItemIcon"), itemArmor, false)
		wndRunePlan:FindChild("ItemName"):SetText(itemArmor:GetName())
		wndRunePlan:FindChild("RemoveBtn"):SetData(nItemId)

		for nSlot=1,itemArmor:GetRuneSlots().nMaximum do
			local wndRune = Apollo.LoadForm(self.xmlDoc, "Settings_Rune", wndRunePlan:FindChild("Runes"), self)
			if tPlan[nSlot] then
				local itemRune = Item.GetDataFromId(tPlan[nSlot])
				wndRune:SetSprite(itemRune:GetIcon())
				self:HelperBuildItemTooltip(wndRune, itemRune, false)
			end
		end
		wndRunePlan:FindChild("Runes"):ArrangeChildrenHorz(1)
	end
	wndSettings:FindChild("Right:Container"):ArrangeChildrenVert()
end

function RuneMaster:Settings_OnCheckBox(wndHandler, wndControl, eMouseButton)
	local tData = wndHandler:GetData()
	
	self.settings[tData.var] = wndHandler:IsChecked()
	
	if tData.func then
		self["Settings_"..tData.func](self, wndHandler, wndControl, eMouseButton)
	end
end

function RuneMaster:Settings_OnShowLevelNames(wndHandler, wndControl, eMouseButton)
	self.wndRuneChoice:Destroy()
	self.wndRuneChoice = nil
	self:RuneChoice_Init()
end


function RuneMaster:Settings_RemoveRunePlanBtn(wndHandler, wndControl, eMouseButton)
	local nItemId = wndHandler:GetData()
	self.tRunePlans[nItemId] = nil
	wndHandler:GetParent():Destroy()
	wndSettings:FindChild("Right:Container"):ArrangeChildrenVert()
end
