-- UI_Stats

local RuneMaster = Apollo.GetAddon("RuneMaster")

function RuneMaster:RedrawStatsList()

	local wndParent = self.wndMain:FindChild("wndStats")
	if not wndParent then return end
	wndParent:DestroyChildren()
	
	-- Get the list of stats and make check-box-entries
	for k, stat in pairs( self.Stats ) do
		
		-- create new header
		self:NewStatEntry( stat, wndParent )
	
	end
	
	wndParent:ArrangeChildrenVert(0)
	wndParent:RecalculateContentExtents()
	
end

function RuneMaster:NewStatEntry( stat, wndParent )

	local icondata = self.StatIcons[ stat ]

	local wndStat = Apollo.LoadForm(self.xmlDoc, "Stat", wndParent, self)
	wndStat:SetData( stat )
	
	local wndStatCheck = wndStat:FindChild("wndStatCheck")
	local cells = {}
	wndStatCheck :SetData( cells )
	
	if self.settings.profiles[ self.settings.curprof ].stats and
	   self.settings.profiles[ self.settings.curprof ].stats[stat] then
		wndStatCheck :FindChild("wndCheck"):Show( true )
	end
	
	local icon = wndStat:FindChild("Icon")
	icon:SetSprite( icondata.strIcon )
	icon:SetBGColor( icondata.strColor )
	icon:SetOpacity( icondata.opacity, 1 )
	
	local text = wndStat:FindChild("Text")
	text:SetText( self.tStatToText[stat].strLocale )
	
end

local Omni = Item.CodeEnumRuneType.Omni

function RuneMaster:RegisterCellToStats( wndCell, runeset, sigil )
	if sigil.eType == Omni then
		for eType, stattable in pairs( self.RunePossible[ runeset ] ) do
			for stat, glyphid in pairs( stattable ) do
				self:RegisterCellToStat( wndCell, stat )
			end
		end
	else
		for stat, glyphid in pairs( self.RunePossible[ runeset ][ sigil.eType ] ) do
			self:RegisterCellToStat( wndCell, stat )
		end
	end
end

function RuneMaster:RegisterCellToStat( wndCell, stat )

	local wndStats = self.wndMain:FindChild("wndStats")
	if not wndStats then return end

	-- Look for stat checkbox
	for k, wndStat in pairs( wndStats:GetChildren() ) do
		if wndStat:GetData() == stat then

			-- Register cell to the Stat-button
			wndStat:FindChild("wndStatCheck"):GetData()[wndCell] = wndCell
			
			break
			
		end
	end
	
end

function RuneMaster:ClearCellsRegistered()
	local wndStats = self.wndMain:FindChild("wndStats")
	if not wndStats then return end

	for k, wndStat in pairs( wndStats:GetChildren() ) do
		local cells = {}
		wndStat:FindChild("wndStatCheck"):SetData( cells )
	end
	
end


---------------------------------------------------------------------------------------------------
-- Stat Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnStatMouseDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() ~= "wndStatCheck" then return end
	
	if wndControl:FindChild("wndCheck"):IsVisible() then
		self:OnStatUncheck( wndHandler, wndControl, eMouseButton )
	else 
		self:OnStatCheck( wndHandler, wndControl, eMouseButton )
	end
end

function RuneMaster:OnStatCheck( wndHandler, wndControl, eMouseButton )

	-- Remember setting
	self.settings.profiles[ self.settings.curprof ].stats[wndControl:GetParent():GetData()] = true
	
	wndControl:FindChild("wndCheck"):Show( true )

	-- Update the highlighting in the grid
	for k, wndCell in pairs( wndControl:GetData() ) do
		self:UpdateStatHighlight( wndCell )
	end
	
end

function RuneMaster:OnStatUncheck( wndHandler, wndControl, eMouseButton )

	-- Remember setting
	self.settings.profiles[ self.settings.curprof ].stats[wndControl:GetParent():GetData()] = nil

	wndControl:FindChild("wndCheck"):Show( false )
		
	-- Update the highlighting in the grid
	for k, wndCell in pairs( wndControl:GetData() ) do
		self:UpdateStatHighlight( wndCell )
	end
	
end

function RuneMaster:UpdateStatHighlight( wndCell )
	if not wndCell then return end
	
	local highlight = false
	
	local celldata = wndCell:FindChild("IconButton"):GetData()
	-- Determine whether there is (still) a stat to highlight on this cell
	if celldata.sigil.eType == Omni then
		for eType, stattable in pairs( self.RunePossible[ celldata.runeset ] ) do
			for stat, glyphid in pairs( stattable ) do
				if self.settings.profiles[ self.settings.curprof ].stats[ stat ] then
					highlight = true
					break
				end
			end
		end
	else
		for stat, glyphid in pairs( self.RunePossible[ celldata.runeset ][ celldata.sigil.eType ] ) do
			if self.settings.profiles[ self.settings.curprof ].stats[ stat ] then
				highlight = true
				break
			end
		end
	end
	
	wndCell:FindChild("Highlight"):Show( highlight, true )
end

