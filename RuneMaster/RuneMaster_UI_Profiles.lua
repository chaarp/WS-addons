-- UI_Profiles

local RuneMaster = Apollo.GetAddon("RuneMaster")

function RuneMaster:RedrawProfiles()

	local wndParent = self.wndMain:FindChild("lstProfiles")
	wndParent:DestroyChildren()
	
	for name, table in pairs( self.settings.profiles ) do
		self:NewProfileMenu( name, wndParent )
	end
	
	wndParent:ArrangeChildrenVert(0)
	wndParent:RecalculateContentExtents()

end

function RuneMaster:NewProfileMenu( name, wndParent )

	local btnProfile = Apollo.LoadForm(self.xmlDoc, "ProfileButton", wndParent, self)

	btnProfile:SetText( "  "..name );
	btnProfile:SetData( name );
	btnProfile:Enable( name ~= self.settings.curprof ); -- disable if active profile
	
end

---------------------------------------------------------------------------------------------------
-- btnProfile Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnBtnProfilesMouseEnter( wndHandler, wndControl, x, y )
	if wndControl:GetName() ~= "btnProfiles" then return end
	wndControl:FindChild("btnProfilesDropdown"):SetSprite("CRB_QuestTrackerSprites:btnQT_TrackerMinimizeFlyby")
end

function RuneMaster:OnBtnProfilesMouseExit( wndHandler, wndControl, x, y )
	if wndControl:GetName() ~= "btnProfiles" then return end
	wndControl:FindChild("btnProfilesDropdown"):SetSprite("CRB_QuestTrackerSprites:btnQT_TrackerMinimizeNormal")
end

function RuneMaster:OnProfileDropdownShow( wndHandler, wndControl )
	self:EnableRunesetHeaders( false )
	self.wndMain:FindChild( "wndStats" ):Enable( false )
	self.wndMain:FindChild( "wndRuneslist" ):Enable( false )
end

function RuneMaster:OnProfileDropdownHide( wndHandler, wndControl )
	self:EnableRunesetHeaders( true )
	self.wndMain:FindChild( "wndStats" ):Enable( true )
	self.wndMain:FindChild( "wndRuneslist" ):Enable( true )
	self.wndMain:FindChild( "btnProfiles" ):SetCheck( false )
end

function RuneMaster:OnBtnProfilesChecked( wndHandler, wndControl, eMouseButton )
	local wndProfiles = self.wndMain:FindChild("wndProfiles")
	self:OnBtnProfilesClicked( wndHandler, wndControl, eMouseButton )
	wndProfiles:Show( true )
	wndProfiles:FindChild("chkDeleteProfile"):SetCheck( false )
end

function RuneMaster:OnBtnProfilesUnchecked( wndHandler, wndControl, eMouseButton )
	local wndProfiles = self.wndMain:FindChild("wndProfiles")
	self:OnBtnProfilesClicked( wndHandler, wndControl, eMouseButton )
	wndProfiles:Show( false )
end

function RuneMaster:OnBtnProfilesClicked( wndHandler, wndControl, eMouseButton )
	local wndNew = self.wndMain:FindChild("wndNew")
	wndNew:Show( false )
end


function RuneMaster:OnBtnNewClick( wndHandler, wndControl, eMouseButton )
	local wndNew = self.wndMain:FindChild("wndNew")
	
	if not wndNew:IsVisible() then
		wndNew:FindChild("edtNew"):SetText("")
		wndNew:Show( true )
		wndNew:FindChild("edtNew"):SetFocus()
	else
		wndNew:Show( false )
	end
end

function RuneMaster:OnBtnNewOKClick( wndHandler, wndControl, eMouseButton )
	local edtNew = wndControl:GetParent():FindChild("edtNew")
	
	local name = edtNew:GetText()
	if type(name) ~= "string" then return end
	if name:len() == 0 then return end
	if self.settings.profiles[ name ] then return end -- already exists
	if name:len() > 25 then return end
	
	wndControl:GetParent():Show( false )
	self.wndMain:FindChild("wndProfiles"):Show( false )

	self:StoreWindowToProfile()
	
	self.settings.profiles[ name ] = {}
	self.settings.profiles[ name ] = self:CopyTable( self.settings.profiles[ self.settings.curprof ] )
	
	self:ActivateProfile( name )
	
end

function RuneMaster:NewProfile( name )
	self.settings.profiles[ name ] = {}
	self.settings.profiles[ name ].stats = {}
	self.settings.profiles[ name ].hiderunesets = {}
	self.settings.profiles[ name ].runeplan = {}
	self.settings.profiles[ name ].lockgrid = false
end

function RuneMaster:OnBtnActivateProfile( wndHandler, wndControl, eMouseButton )

	-- Delete checkbox is clicked
	if self.wndMain:FindChild("chkDeleteProfile"):IsChecked() then
	
		self.settings.profiles[ wndControl:GetData() ] = nil
		self.wndMain:FindChild("chkDeleteProfile"):SetCheck(false)
		self:RedrawProfiles()
		
	else -- Activate profile
	
		self:ActivateProfile( wndControl:GetData() );
		
		self.wndMain:FindChild( "wndProfiles" ):Show( false )
		self.wndMain:FindChild( "btnProfiles" ):SetCheck( false )	
--		self:EnableRunesetHeaders( true )  -- covered by onhide
		self.wndMain:FindChild( "wndNew" ):Show( false )
	
	end
	
end

function RuneMaster:ActivateProfile( name, first, dontredraw )

	-- Before changing, store window in old profile
	if self.wndMain and not first then
		self:StoreWindowToProfile()
	end

	-- Check if profile exists and set it
	if self.settings.profiles[ name ] then
		self.settings.curprof = name
	end
	
	if self.wndMain and self.wndMain:FindChild("btnProfiles") then
		self.wndMain:FindChild("lblProfile"):SetText(""..self.settings.curprof )

		-- Redraw window elements
		self:RedrawStatsList()
		self:RedrawProfiles()
		
		-- Reposition the window
		if self.settings.profiles[ self.settings.curprof ].window then
			self.wndMain:SetAnchorOffsets(
				self.settings.profiles[ self.settings.curprof ].window.left,
				self.settings.profiles[ self.settings.curprof ].window.top,
				self.settings.profiles[ self.settings.curprof ].window.right,
				self.settings.profiles[ self.settings.curprof ].window.bottom)
		end

		-- Set Grid-Lock check/uncheck
		self.wndMain:FindChild("btnGridLock"):SetCheck( not self.settings.profiles[ self.settings.curprof ].lockgrid )

		if not dontredraw then
			self:RedrawGridNew()
		end
	end
	
end

function RuneMaster:StoreWindowToProfile()

	-- Store new window-size 
	if self.settings.profiles[ self.settings.curprof ] then -- this is false if no settings were loaded
		self.settings.profiles[ self.settings.curprof ].window = {}
		self.settings.profiles[ self.settings.curprof ].window.left,
		self.settings.profiles[ self.settings.curprof ].window.top,
		self.settings.profiles[ self.settings.curprof ].window.right,
		self.settings.profiles[ self.settings.curprof ].window.bottom = self.wndMain:GetAnchorOffsets()
	end
	
end
