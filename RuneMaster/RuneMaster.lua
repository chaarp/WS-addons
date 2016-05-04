-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
--TODO:
--	Remove [No Fusion Bonus] from feet, legs, shoulders. Implement in runeminer.
--  Mine new fusion runes
--  Pass over craft queue and make in line with Slot and Rune queues. DO AGAIN EVEN AFTER BUGFIX

require "Window"
 
-----------------------------------------------------------------------------------------------
-- RuneMaster Module Definition
-----------------------------------------------------------------------------------------------
local RuneMaster = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local bDebug = true
Debug = function(...)
	if bDebug then
		local strResult = ""
		local nMax = arg.n
		for i=1,nMax do
			v = arg[i]
			if i ~= 1 then
				strResult = strResult .. ", "
			end
			if v == nil then
				strResult = strResult .. "NIL" 
			else
				strResult = strResult .. tostring(v)
			end
		end
		ChatSystemLib.PostOnChannel(3,strResult)
	end
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function RuneMaster:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function RuneMaster:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- RuneMaster OnLoad
-----------------------------------------------------------------------------------------------
function RuneMaster:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("RuneMaster.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- RuneMaster OnDocLoaded
-----------------------------------------------------------------------------------------------
function RuneMaster:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("rm", "OpenMainUI", self)
		Apollo.RegisterEventHandler("RuneMaster_Show", "OpenMainUI", self)
		
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		
		-- Do additional Addon initialization here
		Apollo.LoadSprites("RMSprites.xml","RMSprites")
		
		self:InitSettings() --TODO: Move to slash command?
	end
end

function RuneMaster:OnInterfaceMenuListHasLoaded()
	
	-- Communicate with the 'button in the bottom left corner'
	Event_FireGenericEvent(
			"InterfaceMenuList_NewAddOn",
			"RuneMaster",
				{"RuneMaster_Show",
				"",
				""})
 
	self:UpdateInterfaceMenuAlerts()
end

function RuneMaster:UpdateInterfaceMenuAlerts()
	--Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", RuneMaster, {false, "RuneMaster", 0})
end


function RuneMaster:OpenMainUI()
	if not self.wndMain then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "RuneMasterForm", nil, self)
		self.wndMain:Show(true)
		self:InitMainUI()
		self:Spreadsheet_InitNewSs()
		self:RuneChoice_Init()
		self:RuneBuilds_Init()
	else
		self:CloseMainUI()
	end
end

function RuneMaster:InitMainUI()
	self.wndMain:FindChild("BG:HeaderNav:PlanBtn"):AttachWindow(self.wndMain:FindChild("BG:Content:Plan"))
	self.wndMain:FindChild("BG:HeaderNav:CraftAndRuneBtn"):AttachWindow(self.wndMain:FindChild("BG:Content:CraftAndRune"))
	self.wndMain:FindChild("BG:SettingsBtn"):AttachWindow(self.wndMain:FindChild("BG:Content:Settings"))
end

function RuneMaster:CloseMainUI()
	self.wndMain:Show(false)
    self.wndMain:Destroy()
	self.wndMain = nil
	self.wndRuneChoice:Show(false)
    self.wndRuneChoice:Destroy()
	self.wndRuneChoice = nil
end

function RuneMaster:OnMainUIClosed( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	
	self:CloseMainUI()
end

function RuneMaster:AttachEventHandlers(tEventHandlers)
	for _,tEvent in pairs(tEventHandlers) do
		Apollo.RemoveEventHandler(tEvent[1], self)
		Apollo.RegisterEventHandler(tEvent[1], tEvent[2], self)
	end
end

function RuneMaster:InitSettings()
	if self.settings and self.settings.curprof then
		self.settings = nil
	end
	self.settings = self.settings or {
		filters = {
			stats = {},
			sets = {},
			level = nil
		},
		showlevelnames = false,
		disclaimer = false
	}
	self.tRunePlans = self.tRunePlans or {}
	self.tRuneBuilds = self.tRuneBuilds or {}
end

local tDim = nil
function RuneMaster:OnMainUIMoved(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
	if wndHandler ~= wndControl then return end

	--Reroute resizes to resize function.
	local tCurrDim = {wndHandler:GetWidth(),wndHandler:GetHeight()}
	if tDim then
		for key,val in pairs(tDim) do
			if val ~= tCurrDim[key] then
				tDim = tCurrDim
				self:OnMainUIResized(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
				return
			end
		end
	end
	
	tDim = tCurrDim
end

--[[local nBorder = 290
nItemWidth = nil
bIncreasing = false
bDecreasing = false
nOldWidth = nil
nColumns = nil--]]
--[[nBorder = 290
local nColumns = nil
local fColumns = nil
local nItemWidth = nil
local bDecreasing = false--]]
function RuneMaster:OnMainUIResized(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
	self.wndMain:FindChild("Spreadsheet"):FindChild("Items"):ArrangeChildrenTiles()
	--[[if not nItemWidth then
		nItemWidth = self.wndMain:FindChild("Spreadsheet"):FindChild("Items"):GetChildren()[1]:GetWidth()+10
	end
	
	local tOffsets = {self.wndMain:GetAnchorOffsets()}
	local nWidth = self.wndMain:GetWidth()
	if nOldWidth then
		bIncreasing = nOldWidth < nWidth
		bDecreasing = nOldWidth > nWidth
		
		local nDiff = 0
		if bIncreasing then
			nDiff = 1
		elseif bDecreasing then
			nDiff = -1
		end
		nColumns = math.floor(self.wndMain:FindChild("Items"):GetWidth()/nItemWidth)
		nColumns = nColumns + nDiff
		self.wndMain:RemoveEventHandler("WindowSizeChanged")
		self.wndMain:SetAnchorOffsets(tOffsets[1],tOffsets[2],tOffsets[1]+nBorder+nColumns*nItemWidth,tOffsets[4])
		self.wndMain:AddEventHandler("WindowSizeChanged", "OnMainUIMoved", self)
	end
	bIncreasing, bDecreasing = false, false
	nOldWidth = nWidth--]]

	--[[if not nItemWidth then
		nItemWidth = self.wndMain:FindChild("Spreadsheet"):FindChild("Items"):GetChildren()[1]:GetWidth()+10
	end
	
	local fNewColumns = self.wndMain:FindChild("Items"):GetWidth()/nItemWidth
	local nNewColumns = math.floor(fNewColumns)
	local tOffsets = self.wndMain:GetAnchorOffsets()
	if nColumns then
		if nColumns ~= nNewColumns then
			local nOffset = nil
			if fNewColumns > fColumns then
				nOffset = nItemWidth*nNewColumns
			elseif fNewColumns < fColumns then
				nOffset = 
			end
			self.wndMain:SetAnchorOffsets(tOffsets[1],tOffsets[2],tOffsets[1]+,tOffsets[4])
			self.wndMain:FindChild("Spreadsheet"):FindChild("Items"):ArrangeChildrenTiles()
		end
	end
	nColumns = nNewColumns
	fColumns = fNewColumns--]]
end 

function RuneMaster:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tData = {
		settings = self.settings,
		runeplans = self.tRunePlans,
		runebuilds = self.tRuneBuilds
	}
	return tData
end

function RuneMaster:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	self.settings = tData.settings
	self.tRunePlans = tData.runeplans
	self.tRuneBuilds = tData.runebuilds
end

-----------------------------------------------------------------------------------------------
-- RuneMaster Instance
-----------------------------------------------------------------------------------------------
local RuneMasterInst = RuneMaster:new()
RuneMasterInst:Init()
