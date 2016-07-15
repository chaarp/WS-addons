-- UI

require "Window"

local RuneMaster = Apollo.GetAddon("RuneMaster")
local Info = Apollo.GetAddonInfo("RuneMaster")

function RuneMaster:InitUI()

    self.wndMain = Apollo.LoadForm(self.xmlDoc, "RuneMasterForm", nil, self)
	if self.wndMain == nil then
		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		return
	end

    self.wndMain:Show(false, true)

	self.wndMain:SetSizingMinimum( 486, 486 )
	self.wndMain:SetSizingMaximum( 1033, 2000 )
	
	self.wndMain:FindChild("Title"):SetText("RuneMaster "..self.Version)

end

-- on SlashCommand "/runemaster"
function RuneMaster:OnRuneMasterOn()

	if not self.didFirstDraw then
		self:FirstDraw()
		self.didFirstDraw = true
	else
		-- Profiles window
		self.wndMain:FindChild("wndProfiles"):Show( false )	
		self.wndMain:FindChild("btnProfiles"):SetCheck( false )	
		self:EnableRunesetHeaders( true )
		self.wndMain:FindChild("wndNew"):Show( false )	
		self:RedrawProfiles()
		self.wndMain:FindChild("wndStats"):Enable( true )
		self.wndMain:FindChild( "wndRuneslist" ):Enable( true )
		
		-- Hide CellInfo window
		self.wndMain:FindChild("wndCellInfo"):Show( false )
		
		-- Wish List stuff
		self:UpdateMaterialCounts()
		self:RegenerateShoppingList()
	end
	
	-- Jump to the last open tab
	if self.settings.lastTab then
		self:ShowTab( self.settings.lastTab )
	else
		self:ShowTab( 1 )
	end
	
	self.wndMain:Invoke() -- show the window
end

function RuneMaster:FirstDraw()

	local unitPlayer = GameLib.GetPlayerUnit()
	self.classId = unitPlayer:GetClassId()

	-- If no profiles loaded, make a default one
	--------------------------------------------
	if self:GetTableLength( self.settings.profiles ) == 0 then
		self:NewProfile("Default")
		self:ActivateProfile( "Default", false, true )
	end
	
	-- Fill the locale-translations of runesets
	self:FillLocaleTextRuneSets()
	
	-- Draw stats list
	self:RedrawStatsList()
	
	-- Profiles stuff
	local lblProfile = self.wndMain:FindChild("lblProfile")
	if not lblProfile then return end
	lblProfile:SetText(""..self.settings.curprof )
	self:RedrawProfiles()

	-- Set Grid-Lock check/uncheck
	self.wndMain:FindChild("btnGridLock"):SetCheck( not self.settings.profiles[ self.settings.curprof ].lockgrid )
	
	-- Restore window settings
	if self.settings.profiles[ self.settings.curprof ].window then
		self.wndMain:SetAnchorOffsets(
			self.settings.profiles[ self.settings.curprof ].window.left,
			self.settings.profiles[ self.settings.curprof ].window.top,
			self.settings.profiles[ self.settings.curprof ].window.right,
			self.settings.profiles[ self.settings.curprof ].window.bottom)
	end
	
	-- Tutorial
	if not self.bSkipTutorial then
		self.wndMain:FindChild("wndTutorial"):Show( true )
		self.wndMain:FindChild("wndTutorialText"):SetText( self.sTutorial )
	end
	
	-- Draw grid
	self:RedrawGridNew( 0.2 )
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
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", RuneMaster, {false, "RuneMaster", 0})
end

---------------------------------------------------------------------------------------------------
-- RuneMasterNewForm Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnCheckSpreadsheet( wndHandler, wndControl, eMouseButton )
	self:ShowTab( 1 );
end

function RuneMaster:OnCheckWishlist( wndHandler, wndControl, eMouseButton )
	self:ShowTab( 2 );
end

function RuneMaster:ShowTab( nTab )
	if nTab < 1 or nTab > 2 then return end
	
	self.wndMain:FindChild( "wndSpreadsheet" ):Show( nTab == 1 )
	self.wndMain:FindChild( "btnSpreadsheet" ):SetCheck( nTab == 1 )
	self.wndMain:FindChild( "wndWishlist" ):Show( nTab == 2 )
	self.wndMain:FindChild( "btnWishlist" ):SetCheck( nTab == 2 )
	
	self.settings.lastTab = nTab
end

-----------------------------------------------------------------------------------------------
-- RuneMasterForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function RuneMaster:OnOK()
	
	self:StoreWindowToProfile()

	self.wndMain:Close() -- hide the window
end

-- when the Refresh button is clicked
function RuneMaster:OnRefresh()
	self:RedrawGridNew()
end

function RuneMaster:OnShowTutorialClick( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("wndTutorialText"):SetText( self.sTutorial )
	self.wndMain:FindChild("wndTutorial"):Show( true )
end

function RuneMaster:OnBtnTutorialCloseClick( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show( false )
end

---------------------------------------------------------------------------------------------------
-- Helper code
---------------------------------------------------------------------------------------------------



function RuneMaster:OnGridLockToggle( wndHandler, wndControl, eMouseButton )

	-- Store lock-setting in profile
	self.settings.profiles[ self.settings.curprof ].lockgrid = not wndControl:IsChecked()
	
end


function RuneMaster:GetRealPos( window )

	local startx, starty = window:GetPos()
	if window:GetParent() ~= nil  then
	local curwindow = window:GetParent()
    repeat
		local x, y = curwindow:GetPos()
		startx = startx + x
		starty = starty + y
		curwindow = curwindow:GetParent()
	until curwindow == nil or curwindow == self.wndMain end
	
    return startx, starty
end

-----------------------------------------------------------------------------------------------
-- Debug code (to test whether the rune-data is complete)
-----------------------------------------------------------------------------------------------

function RuneMaster:TestIsRuneInMatrix( finditemid )

	-- For all RuneSets
	for i, runeset in ipairs( self.RuneSets ) do
	
		-- For all types supported by the runeset
		for j, t in pairs( self.RunePossible[runeset] ) do
		
			-- For all specific runes of this type for this runeset
			for stat, itemid in pairs( t ) do

				if finditemid == itemid then return true end
							
			end
		end
	end

	return false

end

function RuneMaster:TestFindSchematics()

	local found = 0
	local total = 0
	
	self.kItemsFound = {}

	-- For all RuneSets
	for i, runeset in ipairs( self.RuneSets ) do
	
		-- For all types supported by the runeset
		for j, t in pairs( self.RunePossible[runeset] ) do
		
			-- For all specific runes of this type for this runeset
			for stat, itemid in pairs( t ) do
			
				local data = Item.GetDataFromId( itemid ):GetDetailedInfo().tPrimary
				
				total = total + 1
				if self:HelperFindSchematicForItem(itemid, data.tRuneInfo.eType) then
					found = found + 1
					
					self.kItemsFound[ itemid ] = true
					
				else
				
					Print( "Missing: stat ".. stat .. " itemid ".. itemid )
				
				end
			end
		end
	end
	
	Print( "Schematics found: "..found.." of ".. total )
end

function RuneMaster:HelperFindSchematicForItem( itemid, eType )

	local elementFilter = self.karSigilElementsToSprite[ eType ].craftingID

	for idx, tCurrSchematic in pairs(CraftingLib.GetSchematicList(CraftingLib.CodeEnumTradeskill.Runecrafting, elementFilter, nil, false)) do
	
		local tSchematicInfo = CraftingLib.GetSchematicInfo(tCurrSchematic.nSchematicId)
		local tItemData = tSchematicInfo.itemOutput:GetDetailedInfo()
		
		if tItemData.tPrimary.nId and tItemData.tPrimary.nId == itemid then
			return tCurrSchematic.nSchematicId
		end
		
	end
	
	return nil
end

--[[
function RuneMaster:FillTable_ItemToSchematic()

	self.kItemToSchematic = {}
	
	local count = 0
	
	for eType, kt in pairs(self.karSigilElementsToSprite) do
		if eType ~= Omni then

			for idx, tCurrSchematic in pairs(CraftingLib.GetSchematicList(CraftingLib.CodeEnumTradeskill.Runecrafting, kt.craftingID, nil, false)) do
				
				count = count + 1
				local tSchematicInfo = CraftingLib.GetSchematicInfo(tCurrSchematic.nSchematicId)
				local tItemData = tSchematicInfo.itemOutput:GetDetailedInfo()
				
				if tItemData.tPrimary.nId then
					
					self.kItemToSchematic[ tItemData.tPrimary.nId ] = tCurrSchematic.nSchematicId
					
				end
			end
		end
	end

--  DEBUG print all schematics	
	for itemid, schematicid in pairs( self.kItemToSchematic ) do
		Print( "["..itemid.."] = "..schematicid.."," )
	end
--

--	Print ( "Total schematics: ".. count .. " (probably div 2)" )  -- Debug
-- DEBUG code to find all missing runes
	local i = 0
	for itemid, schematicid in pairs( self.kItemToSchematic ) do
		
		if not self:TestIsRuneInMatrix( itemid ) then
			local data = Item.GetDataFromId( itemid ):GetDetailedInfo().tPrimary
			local eName = self.karSigilElementsToSprite[data.tRuneInfo.eType].strName
			local setname = "none-set"
			if data.tRuneInfo.tSet and data.tRuneInfo.tSet.strName then
				setname = data.tRuneInfo.tSet.strName
			end
			Print( ""..i..": ".. itemid .. ": (".. setname .. "," .. eName ..") ".. data.strName )
			i = i + 1

		end		
		
		-- if i > 20 then break end
	end
--
end
--]]


---------------------------------------------------------------------------------------------------
-- Non-addon-specific Helper Functions
---------------------------------------------------------------------------------------------------

-- Helper function to set tooltip on an object
-- Copy/Paste of Runecrafting addon
function RuneMaster:HelperBuildItemTooltip(wndArg, itemCurr)
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurr, { bPrimary = true, bSelling = false, itemCompare = itemCurr:GetEquippedItemForItemType() })
end

