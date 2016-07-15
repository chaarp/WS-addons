-- UI_Stats

local RuneMaster = Apollo.GetAddon("RuneMaster")

function RuneMaster:RedrawWishList()

	-- Wish List
	----------------
	
	local wndParent = self.wndMain:FindChild("WishList")
	if not wndParent then return end
	
	wndParent:DestroyChildren()
	
	local runeIDs = {}
	
	-- Create Wish List Items
	local wndRuneList = self.wndMain:FindChild("MainRuneList")
	for k,wndRune in pairs( wndRuneList:GetChildren() ) do
		local glyphid = wndRune:FindChild("Splitter"):GetData()
		if glyphid and glyphid > 0 then
			if not runeIDs[glyphid] then
				runeIDs[glyphid] = true
				self:NewWishListItem( glyphid, wndParent )
			else
				self:UpdateWishListItem( glyphid, wndParent ) 
			end
		end
	end
	
	wndParent:ArrangeChildrenVert( 0 )
	wndParent:RecalculateContentExtents()
	
	wndParent:SetText( (self:GetTableLength( runeIDs ) == 0) and "Wish list is empty" or "" )
	
	-- Shopping List
	----------------
	
	self:RegenerateShoppingList()
end

function RuneMaster:RegenerateShoppingList()
	local wndWishList = self.wndMain:FindChild("WishList")
	if not wndWishList then return end
	
	-- Create shopping list items based on Wish List
	-- First, collect all the different mats
	local mats = {}
	for k, wndItem in pairs( wndWishList:GetChildren() ) do
	
		-- Check how many of the rune still need to be crafted
		wndNumber = wndItem:FindChild("wndNumber")
		local ownCount = Item.GetDataFromId( wndItem:GetData() ):GetBackpackCount()
		local requiredCount = wndNumber:GetData()
		local needCount = requiredCount - ownCount
		if needCount > 0 then
	
			local wndMats = wndItem:FindChild("Materials")
			for l, wndMat in pairs( wndMats:GetChildren() ) do
			
				local id = wndMat:GetData( )
				local nAmount = wndMat:FindChild("Icon"):GetData( )

				if not mats[ id ] then mats[ id ] = 0 end
				mats[ id ] = mats[ id ] + needCount * nAmount
		
			end
		end
	end

	-- Fill shopping list
	
	local wndParent = self.wndMain:FindChild("ShoppingList")
	if not wndParent then return end
	
	wndParent:DestroyChildren()
	
	local empty = true
	for matID, nAmount in pairs( mats ) do
		empty = false
		self:NewShoppingListItem( wndParent, matID, nAmount )
	end

	wndParent:ArrangeChildrenVert( 0 )
	wndParent:RecalculateContentExtents()

	wndParent:SetText( empty and "Shopping list is empty" or "" )
	
end

function RuneMaster:NewShoppingListItem( wndParent, matID, nAmount )

	local itemMaterial = Item.GetDataFromId( matID )
	local nOwned = itemMaterial:GetBackpackCount()
	
	if nOwned >= nAmount then return nil end
	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "ShoppingListItem", wndParent, self)
	local wndMatIcon  = wndItem:FindChild( "wndMatIcon" )
	local wndNumber   = wndItem:FindChild( "wndNumber" )
	local wndItemName = wndItem:FindChild( "wndItemName" )
	local details = itemMaterial:GetDetailedInfo().tPrimary
	local strName = details.strName
	wndItem:SetData( strName ) 
	wndMatIcon:SetData( matID )
	
	wndMatIcon:SetSprite( itemMaterial:GetIcon() )
	wndNumber:SetText( ""..nAmount - nOwned.."  x" )
	wndItemName:SetText( strName )
	wndItemName:SetTextColor( self.QualitySprites[ details.eQuality ].strTextColor )
	
	return wndItem
end

-- Function meant to "add 1" to an existing wish-list item
function RuneMaster:UpdateWishListItem( glyphid, wndParent )
	local wndItem = nil
	for k, v in pairs( wndParent:GetChildren() ) do
		if v:GetData() == glyphid then
			wndItem = v
			break
		end
	end
	
	if not wndItem then return end
	
	wndNumber = wndItem:FindChild("wndNumber")
	local ownCount = Item.GetDataFromId( glyphid ):GetBackpackCount()
	local requiredCount = wndNumber:GetData()
	requiredCount = requiredCount + 1
	wndNumber:SetText( "".. ownCount .. " / " .. requiredCount );
	wndNumber:SetData( requiredCount )
end

function RuneMaster:NewWishListItem( glyphid, wndParent )
	
	local wndItem = Apollo.LoadForm(self.xmlDoc, "WishListItem", wndParent, self)
	local runename 			= wndItem:FindChild("RuneName")
	local wndRuneIcon 		= wndItem:FindChild("wndRuneIcon")
	local wndRuneTypeIcon	= wndItem:FindChild("wndRuneTypeIcon")
	local wndNumber 		= wndItem:FindChild("wndNumber")
	local btnCraft          = wndItem:FindChild("btnCraft")
	wndItem:SetData( glyphid )

	-- Item data	
    local sigilItemData = Item.GetDataFromId( glyphid )
	local details = sigilItemData:GetDetailedInfo().tPrimary
	if not sigilItemData or not details then return end
	
	-- Count text
	local ownCount = sigilItemData:GetBackpackCount()
	local requiredCount = 1 -- can be increased by method call of "UpdateWishListItem"
	wndNumber:SetText( "".. ownCount .. " / " .. requiredCount )
	wndNumber:SetData( requiredCount )

	-- Rune Icon
	wndRuneIcon:SetSprite( sigilItemData:GetIcon() )
	self:HelperBuildItemTooltip(wndRuneIcon, sigilItemData)
	
	-- Rune name text
	runename:SetText( details.strName )
	runename:SetTextColor( self.karSigilElementsToSprite[details.tRuneInfo.eType].strColor )
	
	-- Materials
	------------
	local wndMats = wndItem:FindChild("Materials")
	wndMats:DestroyChildren()
	
	local nSchematic = self.kItemToSchematic[ glyphid ]
	if not nSchematic then 
		btnCraft:Show( false )
		wndMats:SetText("No known schematic")
		return
	end
  	local tSchematic = CraftingLib.GetSchematicInfo( nSchematic )
	if not tSchematic then 
		btnCraft:Show( false )
		wndMats:SetText("No known schematic")
		return
	end
	
	btnCraft:SetData( nSchematic )
	local allMatsEnough = true
	for i, matdata in ipairs( tSchematic.tMaterials ) do
		if not self:NewWishListItemMaterial( wndMats, matdata.itemMaterial, matdata.nAmount ) then
			allMatsEnough = false
		end
	end
	btnCraft:Enable( allMatsEnough )
	
	wndMats:ArrangeChildrenHorz(0)
	wndMats:RecalculateContentExtents()

end

function RuneMaster:NewWishListItemMaterial( wndParent, itemMaterial, nAmount )
	local wndMat = Apollo.LoadForm(self.xmlDoc, "WishListItemMaterial", wndParent, self)
	local wndIcon = wndMat:FindChild("Icon")
	
	wndMat:SetData( itemMaterial:GetDetailedInfo().tPrimary.nId )
	wndIcon:SetData( nAmount )
	
	wndIcon:SetSprite( itemMaterial:GetIcon() )
	self:HelperBuildItemTooltip(wndIcon, itemMaterial )
	local nOwned = itemMaterial:GetBackpackCount()
	wndIcon:SetText( ""..nOwned.."/"..nAmount )
	
	if nAmount > nOwned then
		wndIcon:SetBGColor("xkcdDeepRed")
	end

	return nOwned >= nAmount
end

function RuneMaster:OnUpdateInventory()
	if self.didFirstDraw and self.wndMain:IsVisible() then
		self:UpdateMaterialCounts()
		self:RegenerateShoppingList()
	end
end

function RuneMaster:UpdateMaterialCounts()
	local wndParent = self.wndMain:FindChild("WishList")
	if not wndParent then return end 
	
	-- For all items listed
	for k, wndItem in pairs( wndParent:GetChildren() ) do
		local glyphid = wndItem:GetData()
		local wndNumber = wndItem:FindChild("wndNumber")
		local wndRuneIcon = wndItem:FindChild("wndRuneIcon")
		local wndMats = wndItem:FindChild("Materials")
		local btnCraft = wndItem:FindChild("btnCraft")

		-- Update the count of runes already in bag
	    local sigilItemData = Item.GetDataFromId( glyphid )
		local ownCount = sigilItemData:GetBackpackCount()
		local requiredCount = wndNumber:GetData()
		wndNumber:SetText( "".. ownCount .. " / " .. requiredCount )
	
		-- Update all mats
		local allMatsEnough = true
		for _, wndMat in pairs( wndMats:GetChildren() ) do
			local wndIcon = wndMat:FindChild( "Icon" )
		
			local itemMaterial = Item.GetDataFromId( wndMat:GetData() )
			local nAmount = wndIcon:GetData()
			local nOwned = itemMaterial:GetBackpackCount()
			
			wndIcon:SetText( ""..nOwned.."/"..nAmount )

			if nAmount > nOwned then
				wndIcon:SetBGColor("xkcdDeepRed")
				allMatsEnough = false
			else
				wndIcon:SetBGColor("UI_WindowBGDefault")
			end
		end
		btnCraft:Enable( allMatsEnough )
		
	end
end

---------------------------------------------------------------------------------------------------
-- WishListItem Functions
---------------------------------------------------------------------------------------------------

function RuneMaster:OnWishListCraftClick( wndHandler, wndControl, eMouseButton )

	CraftingLib.CraftItem( wndHandler:GetData() ) -- Schematic Id
	
end
