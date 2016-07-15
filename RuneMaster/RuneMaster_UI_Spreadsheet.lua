-- UI_Spreadsheet

local RuneMaster = Apollo.GetAddon("RuneMaster")

function RuneMaster:RedrawGridNew( delay )

	self.wndMain:FindChild("btnRefresh"):Enable( false )
	self:EnableRunesetHeaders( false )

	self:ClearCellsRegistered()
	
	-- Clear the grid
	local wndRunes = self.wndMain:FindChild("MainRuneList")
	if not wndRunes then return end
	
	wndRunes:DestroyChildren()

	local wndRuneSets = self.wndMain:FindChild("RuneSets")
	if not wndRuneSets then return end
	
	wndRuneSets:DestroyChildren()

	-- Start the redraw timer
	self.redrawgridtimer1 = ApolloTimer.Create( delay or 0.01, true, "OnRedrawGridTimer1", self)
end

function RuneMaster:OnRedrawGridTimer1()
	self.redrawgridtimer1:Stop()
	
	self:RedrawHeaders()

	-- Start the next timer
	self.redrawgridtimer2 = ApolloTimer.Create(0.01, true, "OnRedrawGridTimer2", self)
end

function RuneMaster:OnRedrawGridTimer2()
	self.redrawgridtimer2:Stop()
	
	self:RedrawEntries()
	
	-- Start the next timer  (the last step of RedrawEntries (split up in timers too) will do this
--	self.redrawwishlisttimer = ApolloTimer.Create(0.01, true, "OnRedrawWishListTimer", self)
end

function RuneMaster:OnRedrawWishListTimer()
	self.redrawwishlisttimer:Stop()

	-- Wish List
	self:RedrawWishList()   

	self:EnableRunesetHeaders( true )
	self.wndMain:FindChild("btnRefresh"):Enable( true )
end

local ALL = 999
function RuneMaster:RedrawHeaders()

	local wndParent = self.wndMain:FindChild("RuneSets")
	if not wndParent then return end
	
	-- Get the list of rune sets and make headers
	local lastType = ""
	local lastClass = -1
	local first = false
	local properties = {}
	local wndHeader = {}
	for k, runeset in pairs( self.RuneSets ) do
		properties = self.RuneSetProperties[ runeset ]
		
		if self.classId == properties.eClass or properties.eClass == ALL or self.bShowAllClasses then
		
			first = properties.strType ~= lastType or (properties.strType == "CLASS" and properties.eClass ~= lastClass)
		
			if not self.settings.profiles[ self.settings.curprof ].hiderunesets[ runeset ] then

				-- create new header
				wndHeader = self:NewHeaderEntry( runeset, properties, wndParent, first )

				-- next iteration	
				lastType = properties.strType
				lastClass = properties.eClass
			end
			
		end
		
	end
	
	wndParent:ArrangeChildrenHorz(0)
	wndParent:RecalculateContentExtents()
	
	self.wndMain:FindChild("btnRestoreColumns"):Enable( 0 ~= self:GetTableLength( self.settings.profiles[ self.settings.curprof ].hiderunesets ) )
end

function RuneMaster:NewHeaderEntry(runeset, properties, wndParent, firstOfType)

	local wndHeader = Apollo.LoadForm(self.xmlDoc, "RuneSetHeader", wndParent, self)
	
	local headerData = {} -- this is going to be an array of Cells belonging to this column
	wndHeader:SetData( headerData )
	 	
	if not firstOfType then
		wndHeader:FindChild("Vertical"):Show( false )
	end
	
	wndHeader:FindChild("Name"):SetText( self.RuneSetProperties[runeset].strLocale )
	wndHeader:FindChild("Name"):SetData( runeset ) -- ID to find the column by (in case name ever becomes different)
	
	-- Set tooltip for the header (based on the 'random' rune picked for this runeset
	if properties.iGlyphId and properties.iGlyphId > 0 then -- "Other" has no tooltip
		local sigilItemData = Item.GetDataFromId(properties.iGlyphId)
		self:HelperBuildItemTooltip(wndHeader, sigilItemData)
	end
	
	return wndHeader	
end

-- When the profiles dropdown opens/closes, it uses this to prevent Headers from catching mouse-events + showing tooltips
function RuneMaster:EnableRunesetHeaders( enable )
	self.wndMain:FindChild( "RuneSets" ):Enable( enable )
end

function RuneMaster:RedrawEntries()

	-- Get the list of equipped, 'glyphable' , items on Player
	local tItems = CraftingLib.GetItemsWithRuneSlots(true, false)

	self.tItemsToDraw = {}
	self.tNextItem = {}
	self.curdrawitem = nil
	
	local prevItem = nil
	
	-- Loop over all items
	for k, itemSource in ipairs( tItems ) do
		
		if prevItem then
			self.tNextItem[ prevItem ] = k
		else
			self.curdrawitem = k -- the first index that shall be drawn
		end
		prevItem = k
		
		self.tItemsToDraw[ k ] = itemSource
	end
	
	if self.curdrawitem then
		-- Start timer to draw first item
		self.drawitemtimer = ApolloTimer.Create(0.01, true, "OnDrawItemTimer", self)
	else
		-- No items, continue to next high level draw step
		wndParent:SetText(self:GetTableLength(self.wndMain:FindChild("MainRuneList"):GetChildren()) == 0 and "You don't have any items with runeslots equipped" or "")
		self.redrawwishlisttimer = ApolloTimer.Create(0.01, true, "OnRedrawWishListTimer", self)
	end

end

function RuneMaster:OnDrawItemTimer()
	self.drawitemtimer:Stop()
	
	local wndParent = self.wndMain:FindChild("MainRuneList")
	if not wndParent then return end

	if not self.curdrawitem then return end
	
	self:NewItem( self.tItemsToDraw[ self.curdrawitem ] , wndParent)
	
	wndParent:ArrangeChildrenVert(0)
	wndParent:RecalculateContentExtents()
	
	self:UpdateHeaderCounts()
	self:UpdateTotals()
	
	-- Next
	self.curdrawitem = self.tNextItem[ self.curdrawitem ]
	if self.curdrawitem then
		-- Continue to next item
		self.drawitemtimer = ApolloTimer.Create(0.01, true, "OnDrawItemTimer", self)
	else
		-- Done with all items, move on to next drawing step
		wndParent:SetText(self:GetTableLength(self.wndMain:FindChild("MainRuneList"):GetChildren()) == 0 and "You don't have any items with runeslots equipped" or "")
		self.redrawwishlisttimer = ApolloTimer.Create(0.01, true, "OnRedrawWishListTimer", self)
	end
end

function RuneMaster:NewItem(itemSource, wndParent)

	local tSigilData = itemSource:GetRuneSlots()
	if not tSigilData or not tSigilData.bIsDefined then return end

	local tDetailedInfo = itemSource:GetDetailedInfo()
	if not tDetailedInfo then return end
	
	local first = true
	for idx, sigil in pairs(tSigilData.arRuneSlots) do
		self:NewRune(itemSource, idx, sigil, wndParent, first)
		
		first = false
	end
	
end

-- Function to create rune row (+ item icon if first) and its cells (radiobuttons)
function RuneMaster:NewRune(itemSource, idx, sigil, wndParent, firstOfItem)

	local wndEntry = Apollo.LoadForm(self.xmlDoc, "RuneEntry", wndParent, self)
	local runetypeicon = wndEntry:FindChild("RuneTypeIcon")

	-- Set item icon + tooltip
	if firstOfItem then
		wndEntry:FindChild("ItemIcon"):SetSprite(itemSource:GetIcon())
		Tooltip.GetItemTooltipForm(self, wndEntry :FindChild("ItemIcon"), itemSource, { bPrimary = true, bSelling = false })
		
		local data = self.QualitySprites[itemSource:GetDetailedInfo().tPrimary.eQuality]
		wndEntry:FindChild("Quality"):SetSprite( data.strSprite )
		wndEntry:FindChild("Quality"):SetOpacity( data.opacity, 1 )
	else
		wndEntry:FindChild("Horizontal"):Show( false )
		wndEntry:FindChild("Horizontal2"):Show( false )
	end
	
	-- Set rune type icon + color
	runetypeicon:SetSprite( self.karSigilElementsToSprite[sigil.eType].strBright )
	runetypeicon:SetBGColor( ApolloColor.new( self.karSigilElementsToSprite[sigil.eType].strColor ) );
	runetypeicon:SetTooltip( self.karSigilElementsToSprite[sigil.eType].strName );
	
	-- String as unique identifier of the row (item+rune)
	local strID = ""..itemSource:GetDetailedInfo().tPrimary.nId .."."..idx.."."..sigil.eType
	wndEntry:SetData( strID )
	
	-- Show/hide lock-icon	
	runetypeicon:FindChild("wndRuneLocked"):Show( not sigil.bUnlocked )
	
	-- Create the cells
	local wndCells = wndEntry:FindChild("Cells")
	-- wndCells:DestroyChildren() -- there aren't any

	-- On wndCells, remember which cells have icons 
	local prevCells = {}
	wndCells:SetData( prevCells )

	-- Get the list of rune sets and make cells
	local properties = {}
	local wndCell = {}
	for k, runeset in pairs( self.RuneSets ) do
	
		properties = self.RuneSetProperties[runeset]
		
		if (self.classId == properties.eClass or properties.eClass == ALL or self.bShowAllClasses)
			and not self.settings.profiles[ self.settings.curprof ].hiderunesets[ runeset ] then
			
			wndCell = self:NewRuneCell(itemSource, idx, sigil, runeset, wndCells )
				
		end
		
	end
	
	-- Position children
	wndCells:ArrangeChildrenHorz(0)
	wndCells:RecalculateContentExtents()
	
	-- Check if there is a rune in the slot, OR whether there is a 'plan' for the rune
	self:UpdateRuneOpen( wndCells, sigil.idRune > 0 or self.settings.profiles[ self.settings.curprof ].runeplan[strID] )
	
end

local Omni = Item.CodeEnumRuneType.Omni

-- Function to create each individual cell (radiobutton + img)
function RuneMaster:NewRuneCell(itemSource, idx, sigil, runeset, wndParent)

	-- sigil.idGlyph > 0    then there's something in the slot

	local wndCell = Apollo.LoadForm(self.xmlDoc, "RuneCell", wndParent, self)
	local wndIcon = wndCell:FindChild("Icon")
	local btnIcon = wndCell:FindChild("IconButton")
	
	-- Check if rune-type is compatible with the rune set

	-- Rune-type not compatible with set, don't show radio-button and icon
	if sigil.eType ~= Omni and not self:RuneSetUsesType( runeset, sigil.eType ) then
		wndIcon:Show( false )
		btnIcon:Show( false )
		return wndCell
	end

	-- Register this cell to the possible stats
	self:RegisterCellToStats( wndCell, runeset, sigil )
	
	-- Store data in radio-button for use in events
	local cellData = {}
	cellData.runeset = runeset
	cellData.sigil = sigil
	cellData.header = self:FindColumn( runeset ) -- Store link to header-window
	cellData.bContributesStatic = false
	cellData.bContributesDynamic = false
	btnIcon:SetData( cellData )
	
	-- Register cell to the column (Row is its owner, that's easy to find)
	if cellData.header then -- This would error if you click on columns to hide them fast (before redraw finished)
		cellData.header:GetData()[wndCell] = btnIcon
	end

	local runesetidofglyph = self:GetRuneSetIDbyGlyphID( sigil.idRune )
	if sigil.idRune > 0 and runesetidofglyph == runeset then
		cellData.bContributesStatic = true
		wndParent:GetData().staticCell = btnIcon
	end -- store whether this actual slot is contributing to the set, regardless of saved data, regardless of what will be shown
		
	-- Determine what the cell should show
	self:DetermineCellContents( btnIcon )
	
	-- Set the highlighting
	self:UpdateStatHighlight( wndCell )
	
	return wndCell
end

function RuneMaster:DetermineCellContents( btnIcon )
	local wndIcon = btnIcon:GetParent():FindChild("Icon")
	local cellData = btnIcon:GetData()
	local sigil = cellData.sigil
	local runeset = cellData.runeset
	local wndCells = wndIcon:GetParent():GetParent()
	local strID = wndCells:GetParent():GetData()  -- retrieve item+rune ID
	cellData.bContributesDynamic = false
	
	local runesetidofglyph = self:GetRuneSetIDbyGlyphID( sigil.idRune )
	local savedruneid = self.settings.profiles[ self.settings.curprof ].runeplan[strID]
	local runesetidofsaved = self:GetRuneSetIDbyGlyphID( savedruneid )

	if savedruneid ~= nil and savedruneid == sigil.idRune then
		-- saved rune is actually slotted, just forget about it then
		
		self.settings.profiles[ self.settings.curprof ].runeplan[strID] = nil
		savedruneid = nil
	end
		
	if savedruneid ~= nil then  -- something was saved

		if runesetidofsaved == runeset then -- it is for this set
		
			cellData.bContributesDynamic = true
			wndCells:GetData().dynamicCell = btnIcon
			if savedruneid == sigil.idRune then
				self:SetIconToCell( wndIcon, savedruneid, 0.8, false )
			else
				self:SetIconToCell( wndIcon, savedruneid, 1.0, true )
			end
			
		elseif runesetidofglyph == runeset then -- it was for another set, but actual slotted thing matches
		
			self:SetIconToCell( wndIcon, sigil.idRune, 0.5, false )
		
		else
		
			self:SetIconToCell( wndIcon, 0, 0.8, false )
			
		end
	
	else -- nothing was saved	
	
		if runesetidofglyph == runeset and sigil.idRune > 0 then -- show what is slotted
		
			cellData.bContributesDynamic = true
			self:SetIconToCell( wndIcon, sigil.idRune, 0.8, false )
			
		elseif sigil.idRune > 0 then
		
			self:SetIconToCell( wndIcon, 0, 0.8, false )
		
		else

			self:SetIconToCell( wndIcon, 0, 0.8, false )
			
		end
		
	end
	
end

function RuneMaster:SetIconToCell( wndIcon, glyphid, opacity, bShowChanged )
	local sigilItemData = Item.GetDataFromId( glyphid )
	
	wndIcon:SetOpacity( opacity, 1 )
	local wndChanged = wndIcon:FindChild("Changed")
	if bShowChanged then
		wndChanged:Show( true )
		wndChanged:SetOpacity( 1.0, 1 )
		
		local wndSplitter = wndIcon:GetParent():GetParent():GetParent():FindChild("Splitter")
		-- Eww, abuse the splitter window to store glyph id (used by wishlist)
		wndSplitter:SetData( glyphid )

	else
		wndChanged:SetOpacity( 0.0, 1 )
	end
	
	if sigilItemData then
		wndIcon:SetSprite( sigilItemData:GetIcon() )
		self:HelperBuildItemTooltip(wndIcon, sigilItemData)
	else
		wndIcon:SetSprite( nil )
		wndIcon:SetTooltip( "" )
	end
	
end

---------------------------------------------------------------------------------------------------
-- RuneCell Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnCellClick( wndHandler, wndControl, eMouseButton )
	local wndCellInfo = self.wndMain:FindChild("wndCellInfo")
	
	local lstRuneOptions = wndCellInfo:FindChild("lstRuneOptions")
	
	local celldata = wndControl:GetData()
	-- runeset, sigil
	
	-- Set header
	wndCellInfo:FindChild("wndRuneSetName"):SetText( "  ".. self.RuneSetProperties[celldata.runeset].strLocale )
	wndCellInfo:FindChild("wndRuneSetName"):SetTextColor( self.karSigilElementsToSprite[celldata.sigil.eType].strColor )
	
	wndCellInfo:SetData( wndControl ) -- Store reference to clicked cell in the window
	
	local enable = self.wndMain:FindChild("btnGridLock"):IsChecked()
	
	-- Add items to the list of options
	
	lstRuneOptions:DestroyChildren()
	
	-- Loop through all possible runes
	if celldata.sigil.eType == Omni then
		for eType, stattable in pairs( self.RunePossible[ celldata.runeset ] ) do
			for stat, glyphid in pairs( stattable ) do
				self:NewRuneOption( stat, glyphid, lstRuneOptions, enable and glyphid ~= celldata.sigil.idRune)
			end
		end
	else
		for stat, glyphid in pairs( self.RunePossible[ celldata.runeset ][ celldata.sigil.eType ] ) do
			self:NewRuneOption( stat, glyphid, lstRuneOptions, enable and glyphid ~= celldata.sigil.idRune )
		end
	end
	
	lstRuneOptions:ArrangeChildrenVert( 0 )
	lstRuneOptions:RecalculateContentExtents()
	lstRuneOptions:SetVScrollPos( 0 )
	
	local x, y = self:GetRealPos( wndControl )
	wndCellInfo:Move(x - 16, y - 157, 218, 145)
	wndCellInfo:Show( true )
end

function RuneMaster:NewRuneOption( stat, glyphid, wndParent, enable )

	local wndRuneOption = Apollo.LoadForm(self.xmlDoc, "RuneOption", wndParent, self)
	
	local btn = wndRuneOption:FindChild("Button")
	local icon = wndRuneOption:FindChild("Icon")
	local text = wndRuneOption:FindChild("Text")
	
	btn:SetData( glyphid )
	btn:Enable( enable )
	if enable then
		text:SetTextColor( "gray" )
	else
		text:SetTextColor( "vdarkgray" )
	end
	
	local sigilItemData = Item.GetDataFromId(glyphid)
	icon:SetSprite(sigilItemData:GetIcon())
--	self:HelperBuildItemTooltip(btn, sigilItemData) -- I find the tooltip in the scroll-list to be annoying
	
	text:SetText( self.tStatToText[ stat ].strLocale )

end

function RuneMaster:OnCellMouseDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() ~= "IconButton" or eMouseButton ~= 1 then return end
	
	-- Prevent use if grid is locked
	if not self.wndMain:FindChild("btnGridLock"):IsChecked() then return end
	
	-- Only accept right-click on the cell that is/was showing the icon
	if wndControl:GetParent():GetParent():GetData().dynamicCell ~= wndControl then return end

	self:SetCell( wndControl, nil )	
	
end

---------------------------------------------------------------------------------------------------
-- RuneOption Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnRuneOptionClick( wndHandler, btnRuneOption, eMouseButton )
	local wndCellInfo = btnRuneOption:GetParent():GetParent():GetParent()
	
	local btnCell = wndCellInfo:GetData()
	local glyphid = btnRuneOption:GetData()
	
	self:SetCell( btnCell, glyphid )
		
	-- Hide the options-picker window
	wndCellInfo:Show( false )
end

function RuneMaster:SetCell( btnCell, glyphid )
	local cellData = btnCell:GetData()
	
	-- Store choice in Settings
	local wndCells = btnCell:GetParent():GetParent()
	local strID = wndCells:GetParent():GetData()  -- retrieve item+rune ID
	self.settings.profiles[ self.settings.curprof ].runeplan[strID] = glyphid -- will assign nil to clear, is good
	
	local wndSplitter = btnCell:GetParent():GetParent():GetParent():FindChild("Splitter")
 	wndSplitter:SetData( nil )

	-- Re-determine what is shown in cell  (but also how previous selected cells should show)
	local dynamicCell = wndCells:GetData().dynamicCell
	if dynamicCell and dynamicCell ~= btnCell then
		self:DetermineCellContents( dynamicCell )
		self:UpdateDynamicColumn( dynamicCell:GetData().header )
	end
	self:DetermineCellContents( btnCell )
	self:UpdateDynamicColumn( btnCell:GetData().header )
	local staticCell = wndCells:GetData().staticCell
	if staticCell and staticCell ~= btnCell and staticCell ~= dynamicCell then
		self:DetermineCellContents( staticCell )
		self:UpdateDynamicColumn( staticCell:GetData().header )
	end
	
	-- Update the opacity of "Rune slot is open"
	self:UpdateRuneOpen( wndCells, cellData.sigil.idRune > 0 or glyphid ~= nil )
	
	-- Update sums
	self:UpdateTotals()
	
	-- Update wish list
	self:RedrawWishList()

end

function RuneMaster:UpdateRuneOpen( wndCells, bCheck )

	-- Update the icon opacity to indicate whether it's in use
	local wndRuneTypeIcon = wndCells:GetParent():FindChild("RuneTypeIcon")
	local wndRuneOpen = wndRuneTypeIcon:FindChild("wndRuneOpen")
	if bCheck then
		wndRuneTypeIcon:SetOpacity( 0.7 )
		wndRuneOpen:Show( false )
	else
		wndRuneTypeIcon:SetOpacity( 1 )
		wndRuneOpen:Show( true )
	end
	
	-- Traverse over children cells (that are visible)
	for k, cell in pairs( wndCells:GetChildren() ) do
		if bCheck then
			cell:FindChild("IconButton"):SetOpacity( 0.7, 1 )
			cell:FindChild("Highlight"):SetOpacity( 0.5, 1 )
		else
			cell:FindChild("IconButton"):SetOpacity( 1.0, 1 )
			cell:FindChild("Highlight"):SetOpacity( 1.0, 1 )
		end
	end

end

function RuneMaster:OnRuneOptionWindowClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() ~= "wndCellInfo" then return end
	
	wndControl:Show( false )
end

function RuneMaster:OnRuneOptionsCloseClick( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show( false )
end


function RuneMaster:OnCellInfoShow( wndHandler, wndControl )
	self.wndMain:FindChild("wndStats"):Enable( false )
end

function RuneMaster:OnCellInfoHide( wndHandler, wndControl )
	self.wndMain:FindChild("wndStats"):Enable( true )
end

---------------------------------------------------------------------------------------------------
-- RuneSetHeader Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnHeaderMouseDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() ~= "w24" then return end
	
	if eMouseButton == 1 then -- Rightclick
	
		if not self.wndMain:FindChild("btnGridLock"):IsChecked() then return end
	
		self.settings.profiles[ self.settings.curprof ].hiderunesets[ wndControl:FindChild("Name"):GetData() ] = true
	
		self:RedrawGridNew()
	
		self.wndMain:FindChild("btnRestoreColumns"):Enable( true )

	elseif eMouseButton == 0 then -- Leftclick

		-- Possible future functionality	
		
	end
	
end

function RuneMaster:OnRestoreColumnsClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() and Apollo.IsControlKeyDown() then
		self.bShowAllClasses = true
	else
		self.bShowAllClasses = false
	end
	
	self.settings.profiles[ self.settings.curprof ].hiderunesets = {}
	wndControl:Enable( false )
	self:RedrawGridNew()
	
end

-- Function that inializes the totals in the runeset-headers
function RuneMaster:UpdateHeaderCounts()

	local wndHeaders = self.wndMain:FindChild("RuneSets")
	if not wndHeaders then return end
	
	-- Loop through headers
	for k, wndHeader in ipairs( wndHeaders:GetChildren() ) do

		-- Set static count
		self:UpdateStaticColumn( wndHeader )

		-- Set dynamic count
		self:UpdateDynamicColumn( wndHeader )
		
	end

end

---------------------------------------------------------------------------------------------------
-- Spreadsheet Helper Functions
---------------------------------------------------------------------------------------------------

-- Update the dynamic number in the column
function RuneMaster:UpdateDynamicColumn( wndHeader )

	if not wndHeader then return end
	
	local nContribute = 0
	for wndCell, btnIcon in pairs( wndHeader:GetData() ) do
		if btnIcon:GetData().bContributesDynamic then
			nContribute = nContribute + 1
		end
	end
	
	self:SetNumberAndColor( wndHeader:FindChild( "Dynamic" ), nContribute , false )
	if nContribute > 0 then
		wndHeader:FindChild("Name"):SetTextColor("gray")
	else
		wndHeader:FindChild("Name"):SetTextColor("darkgray")	
	end
		
end

-- Update the static number in the column
function RuneMaster:UpdateStaticColumn( wndHeader )

	if not wndHeader then return end
	
	local nContribute = 0
	for wndCell, btnIcon in pairs( wndHeader:GetData() ) do
		if btnIcon:GetData().bContributesStatic then
			nContribute = nContribute + 1
		end
	end
	
	self:SetNumberAndColor( wndHeader:FindChild( "Static" ), nContribute, true )
	
end

-- Sets the Text of the wndText and set its color based on the number
function RuneMaster:SetNumberAndColor( wndText, number, bDark )
	if not wndText or not number then return end
	
	wndText:SetText( ""..number )
	wndText:SetData( number )
	
	local color = "vdarkgray" -- for 0
	if number > 0 then
		if bDark then
			color = "xkcdBrownYellow"
		else
			color = "xkcdLemonYellow"
		end
		
		local arThresholds = self.RuneSetProperties[ wndText:GetParent():FindChild("Name"):GetData() ].arThresholds 
		if arThresholds then
		
			for i, t in ipairs(arThresholds) do
				if t == number then
					if bDark then
						color = "xkcdDarkGreen"
					else
						color = "xkcdGreen"
					end
				end
			end
			
		end
	end
	wndText:SetTextColor( color )
end

-- Return the RuneSetHeader of matching to the argument
function RuneMaster:FindColumn( runeset )

	local wndHeaders = self.wndMain:FindChild( "RuneSets" )
	
	for k, wndHeader in ipairs( wndHeaders:GetChildren() ) do
		if wndHeader:FindChild("Name"):GetData() == runeset then
			return wndHeader
		end
	end
	
	return nil
	
end

-- Update the totals in the top left corner
function RuneMaster:UpdateTotals()
	
	local wndEntries = self.wndMain:FindChild("MainRuneList")
	if not wndEntries then return end
	
	-- Get total number of runes
	local nRunes = 0
	for k, wndEntry in pairs( wndEntries:GetChildren() ) do
		nRunes = nRunes + 1
	end
	
	-- Sum Static columns
	-- Sum Dynamic colums
	local nStatic = 0
	local nDynamic = 0
	local wndSets = self.wndMain:FindChild("RuneSets")
	for k, wndSet in pairs( wndSets:GetChildren() ) do
		nStatic = nStatic + wndSet:FindChild("Static"):GetData()
		nDynamic = nDynamic + wndSet:FindChild("Dynamic"):GetData()
	end
	
	-- Fill texts
	self.wndMain:FindChild("StaticTotal"):SetText( ""..nStatic.." / "..nRunes )
	self.wndMain:FindChild("DynamicTotal"):SetText( ""..nDynamic.." / "..nRunes )

end

