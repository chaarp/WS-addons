-----------------------------------------------------------------------------------------------
-- Client Lua Script for RuneMaster
-- Copyright (c) Tyler T. Hardy (Potato Rays/perterter/daperterter). All rights reserved
-----------------------------------------------------------------------------------------------
 
--TODO: Finish those marked with UNF
 
local RuneMaster = Apollo.GetAddon("RuneMaster")

local tStatData = {
  [5] = {--Focus Pool --UNFINISHED?
	fBase = Unit.CodeEnumProperties.BaseFocusPool,
	fCoeff = 1,
	bNoPercent = true
   },
  [6] = {--Focus Recovery Rating
	ePercentId = Unit.CodeEnumProperties.BaseFocusRecoveryInCombat,
	fBase = 0.01,
	fCoeff = 0.000002,
	fSoftCap = 0.0150,
	nDR = 2000
  },
  [7] = {--Max Health --UNFINISHED?
	fBase = Unit.CodeEnumProperties.BaseHealth,
	fCoeff = 1,
	bNoPercent = true
  },
  [25] = {--Lifesteal Rating
	ePercentId = Unit.CodeEnumProperties.BaseLifesteal,
	fBase = 0.00,
	fCoeff = 0.000021,
	fSoftCap = 0.10,
	nDR = 6200
  },
  [29] = {--Multi-Hit Rating
	ePercentId = Unit.CodeEnumProperties.BaseMultiHitChance,
	fBase = 0.05,
	fCoeff = 0.00006,
	fSoftCap = 0.60,
	nDR = 5000
  },
  [32] = {--Strikethrough Rating
	ePercentId = Unit.CodeEnumProperties.BaseAvoidReduceChance,
	fBase = 0.00,
	fCoeff = 0.00003,
	fSoftCap = 0.30,
	nDR = 5000
  },
  [33] = {--Deflect Chance Rating
	ePercentId = Unit.CodeEnumProperties.BaseAvoidChance,
	fBase = 0.05,
	fCoeff = 0.000015,
	fSoftCap = 0.30,
	nDR = 7000
  },
  [34] = {--Critical Hit Rating
	ePercentId = Unit.CodeEnumProperties.BaseCritChance,
	fBase = 0.05,
	fCoeff = 0.000025,
	fSoftCap = 0.30,
	nDR = 7000
  },
  [37] = {--Critical Mitigation Rating
	ePercentId = Unit.CodeEnumProperties.BaseCriticalMitigation,
	fBase = 0.00,
	fCoeff = 0.00015,
	fSoftCap = 1.5,
	nDR = 2750
  },
  [42] = {--Armor --TODO: This is special because of the 3 resists. Do something.
	ePercentId = nil, --UNF
	fBase = 0.00,
	fCoeff = 0.00008,
	fSoftCap = 0,
	nDR = 7250
  },
  [47] = {--Critical Hit Severity Rating
	ePercentId = Unit.CodeEnumProperties.CriticalHitSeverityMultiplier,
	fBase = 1.50,
	fCoeff = 0.0001,
	fSoftCap = 2.5,
	nDR = 5500
  },
  [56] = {--Intensity Rating
	ePercentId = Unit.CodeEnumProperties.BaseIntensity,
	fBase = 0.00,
	fCoeff = 0.000028,
	fSoftCap = 0.30,
	nDR = 5000
  },
  [57] = {--Vigor Rating
	ePercentId = Unit.CodeEnumProperties.BaseVigor,
	fBase = 0.00,
	fCoeff = 0.000028,
	fSoftCap = 0.30,
	nDR = 5000
  },
  [58] = {--Glance Rating
	ePercentId = Unit.CodeEnumProperties.BaseGlanceChance,
	fBase = 0.05,
	fCoeff = 0.0000275,
	fSoftCap = 0.30,
	nDR = 4000
  },
  [63] = {--Reflect Rating --UNF
	--[[fBase = Unit.CodeEnumProperties.BaseDamageReflectChance,
	fCoeff = 0.00005,
	fSoftCap = UNK,
	nDR = UNK--]]
  },
  [64] = {--CC Resilience Rating --UNF
	--[[fBase = Unit.CodeEnumProperties.CCDurationModifier,--0.00,
	fCoeff = 0.00004,
	fSoftCap = 0.25,
	nDR = UNK (Cause of comment out)--]]
  }
}

local ktEnumPercentToRating = {
	[Unit.CodeEnumProperties.BaseFocusPool] = 5,
	[Unit.CodeEnumProperties.BaseFocusRecoveryInCombat] = 6,
	[Unit.CodeEnumProperties.BaseHealth] = 7,
	[Unit.CodeEnumProperties.BaseLifesteal] = 25,
	[Unit.CodeEnumProperties.BaseMultiHitChance] = 29,
	--[Unit.CodeEnumProperties.BaseMultiHitAmount] = 60, --112
	[Unit.CodeEnumProperties.BaseAvoidReduceChance] = 32,
	[Unit.CodeEnumProperties.BaseAvoidChance] = 33,
	[Unit.CodeEnumProperties.BaseCritChance] = 34,
	[Unit.CodeEnumProperties.BaseCriticalMitigation] = 37,
	--[] = 42,
	[Unit.CodeEnumProperties.CriticalHitSeverityMultiplier] = 47,
	[Unit.CodeEnumProperties.BaseIntensity] = 56,
	[Unit.CodeEnumProperties.BaseVigor] = 57,
	[Unit.CodeEnumProperties.BaseGlanceChance] = 58,
	[Unit.CodeEnumProperties.BaseDamageReflectChance] = 63,
	[Unit.CodeEnumProperties.CCDurationModifier] = 64,
}

 tStatReview_Armors = {}
function RuneMaster:StatReview_UpdateArmorSlot(eArmorSlot, tStatReview)
	tStatReview_Armors = tStatReview_Armors or {}
	tStatReview_Armors[eArmorSlot] = tStatReview
end

function RuneMaster:StatReview_PopulateStatReview(tStatReview, itemCurrRune, itemPlanRune)
	local tCurrRuneInfo = itemCurrRune and itemCurrRune:GetDetailedInfo().tPrimary
	local tPlanRuneInfo = itemPlanRune and itemPlanRune:GetDetailedInfo().tPrimary
	
	--tStatReview Table Format as: tStatReview={stats={[eStat]={curr=#,plan=#}},sets={[eSet]={curr=#,plan=#}}}
	--------------------------------------------------------------------------------------------
	if tCurrRuneInfo then
		local tStat = tCurrRuneInfo.arBudgetBasedProperties or tCurrRuneInfo.arInnateProperties
		if tStat then
			local eStat = tStat[1].eProperty
			local nValue = tStat[1].nValue
			tStatReview.stats[eStat] = tStatReview.stats[eStat] or {curr=0,plan=0}
			tStatReview.stats[eStat].curr = tStatReview.stats[eStat].curr+nValue
		end
		
		local tRuneSet = tCurrRuneInfo.tRuneSet
		if tRuneSet then
			local nSetId = tRuneSet.nSetId
			local nPower = tRuneSet.nPower
			tStatReview.sets[nSetId] = tStatReview.sets[nSetId] or {curr=0,plan=0}
			tStatReview.sets[nSetId].curr = tStatReview.sets[nSetId].curr+nPower
		end
	end	
	
	if not tPlanRuneInfo then tPlanRuneInfo = tCurrRuneInfo end
	if tPlanRuneInfo then
		local tStat = tPlanRuneInfo.arBudgetBasedProperties or tPlanRuneInfo.arInnateProperties
		if tStat then
			local eStat = tStat[1].eProperty
			local nValue = tStat[1].nValue
			tStatReview.stats[eStat] = tStatReview.stats[eStat] or {curr=0,plan=0}
			tStatReview.stats[eStat].plan = tStatReview.stats[eStat].plan+nValue
		end
		
		local tRuneSet = tPlanRuneInfo.tRuneSet
		if tRuneSet then
			local nSetId = tRuneSet.nSetId
			local nPower = tRuneSet.nPower
			tStatReview.sets[nSetId] = tStatReview.sets[nSetId] or {curr=0,plan=0}
			tStatReview.sets[nSetId].plan = tStatReview.sets[nSetId].plan+nPower
		end
	end
end

function RuneMaster:StatReview_UpdateStatReviewV2() --V2
	--[[{
	  bDefault = true,
	  eProperty = 154,
	  nPower = 2,
	  nScalar = 0,
	  nSortOrder = 0,
	  nValue = 0.0035000001080334,
	  strName = "Multi-Hit Chance"
	}--]]
	
	
	--TODO: Move this to self.ktSets
	local ktSetsTemp = CraftingLib.GetRuneSets()
	local ktSets = {}
	for _,tSet in pairs(ktSetsTemp) do
		ktSets[tSet.nSetId] = tSet
	end
	ktSetsTemp = nil
	
	--tStatReview Table Format as: tStatReview={stats={[eStat]={curr=#,plan=#}},sets={[eSet]={curr=#,plan=#}}}
	local tStatsCurrent, tStatsPlanned = {}, {}
	local tBonusesCurrent, tBonusesPlanned = {}, {}
	local tCurrBonTotals, tPlanBonTotals = {}, {}
	for nArmorSlot,tStatReview in pairs(tStatReview_Armors) do
		for eStat,tCurrVsPlan in pairs(tStatReview.stats) do
			tStatsCurrent[eStat] = tStatsCurrent[eStat] and tStatsCurrent[eStat]+tCurrVsPlan.curr or tCurrVsPlan.curr
			tStatsPlanned[eStat] = tStatsPlanned[eStat] and tStatsPlanned[eStat]+tCurrVsPlan.plan or tCurrVsPlan.plan
		end
		
		for nSetId,tCurrVsPlan in pairs(tStatReview.sets) do
			--Print(ktSets[nSetId].strName)
			--Print("-------------------")
			local nCurrPower, nPlanPower = tCurrVsPlan.curr, tCurrVsPlan.plan
			for _,tBonus in pairs(ktSets[nSetId].arBonuses) do --TODO: self.ktSets
				--Print(nCurrPower..":"..tBonus.nPower)
				local bFound = false
				if nCurrPower >= tBonus.nPower then
					local eStat = tBonus.eProperty
					local nValue = tBonus.nValue --tBonus.nScalar --TODO: Issue with nScalar
					if nValue then
						table.insert(tBonusesCurrent, {eStat,nValue})
					else
						Print(string.format("[RM] Bonus Error with %s (%s), nScalar: %s",tostring(Item.GetPropertyName(eStat)), tostring(eStat), tostring(tBonus.nScalar)))
					end
					bFound = true
				end
				if nPlanPower >= tBonus.nPower then
					local eStat = tBonus.eProperty
					local nValue = tBonus.nValue --tBonus.nScalar --TODO: Issue with nScalar
					if nValue then
						table.insert(tBonusesPlanned, {eStat,nValue})
					else
						--Print(string.format("[RM] Bonus Error with %s (%s), nScalar: %s",Item.GetPropertyName(eStat), eStat, tostring(tBonus.nScalar)))
					end
					bFound = true
				end
				if not bFound then
					break
				end
			end
			--Print("-------------------")
		end
	end
	
	for _,tBonus in pairs(tBonusesCurrent) do
		local eStat = tBonus[1]
		local fValue = tBonus[2]
		tCurrBonTotals[eStat] = tCurrBonTotals[eStat] and tCurrBonTotals[eStat]+fValue or fValue
	end
	for _,tBonus in pairs(tBonusesPlanned) do
		local eStat = tBonus[1]
		local fValue = tBonus[2]
		tPlanBonTotals[eStat] = tPlanBonTotals[eStat] and tPlanBonTotals[eStat]+fValue or fValue
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	local tArmorRatings = {}
	local tStats = {}
	for eStat,nRuneRating in pairs(tStatsCurrent) do
		local tStatInfo = tStatData[eStat]
		if tStatInfo.fBase then --TODO: Hacky check to override unfinished stats.
			local fSetPercent = 0
			local ePercentId = tStatInfo.ePercentId
			if ePercentId then
				--if tCurrBonTotals[ePercentId] then	
					fSetPercent = tCurrBonTotals[ePercentId] or 0
					local fCalcBase = unitPlayer:GetUnitProperty(ePercentId).fValue - fSetPercent
					tStatData[eStat].fBase = fCalcBase
					
					--[[Print(Item.GetPropertyName(eStat))
					Print("-------------------")
					Print(string.format("Base: %.0f%%",fCalcBase*100))
					Print(string.format("Sets: %.2f%%",fSetPercent*100))--]]
				--end
			end
			
			local nArmorRating = unitPlayer:GetUnitProperty(eStat).fValue - nRuneRating
			tArmorRatings[eStat] = nArmorRating
			--[[Print(string.format("Armor: %s rating.",nArmorRating))
			Print(string.format("Runes: %s rating.",nRuneRating))
			Print(string.format("Final: %.2f%%", self:StatReview_GetStatDR(eStat, nArmorRating+nRuneRating, fSetPercent)))
			Print("-------------------")--]]
			if not tStats[eStat] then
				tStats[eStat] = {curr={},plan={}}
			end
			tStats[eStat].curr = {self:StatReview_GetStatDR(eStat, nArmorRating+nRuneRating, fSetPercent)}
		end
	end
	for eStat,nRuneRating in pairs(tStatsPlanned) do
		local tStatInfo = tStatData[eStat]
		if tStatInfo.fBase then --TODO: Hacky check to override unfinished stats.
			local fSetPercent = 0
			local ePercentId = tStatInfo.ePercentId
			if ePercentId then
				if tPlanBonTotals[ePercentId] then	
					fSetPercent = tPlanBonTotals[ePercentId]		
					
					--[[Print(Item.GetPropertyName(eStat))
					Print("-------------------")
					Print(string.format("Base: %.0f%%",tStatInfo.fBase*100))
					Print(string.format("Sets: %.2f%%",fSetPercent*100))--]]
				end
			end
			
			--local nArmorRating = unitPlayer:GetUnitProperty(eStat).fValue - nRuneRating --TODO: Error here.
			local nArmorRating = tArmorRatings[eStat]
			--[[Print(string.format("Armor: %s rating.",nArmorRating))
			Print(string.format("Runes: %s rating.",nRuneRating))
			Print(string.format("Final: %.2f%%", self:StatReview_GetStatDR(eStat, nArmorRating+nRuneRating, fSetPercent)))
			Print("-------------------")--]]
			if not tStats[eStat] then
				tStats[eStat] = {curr={},plan={}}
			end
			tStats[eStat].plan = {self:StatReview_GetStatDR(eStat, nArmorRating+nRuneRating, fSetPercent)}
		end
	end
	
	--Make GUI
	self.wndMain:FindChild("wndStatReview"):DestroyChildren()
	local unitPlayer = GameLib.GetPlayerUnit() --TODO: Too many unitplayer calls.
	for eStat,tPercent in pairs(tStats) do
		local wndStat = Apollo.LoadForm(self.xmlDoc, "StatReview_StatEntry", self.wndMain:FindChild("wndStatReview"), self)
		local strStat = string.gsub(Item.GetPropertyName(eStat)," Rating","") --TODO: Figure out how to handle this better. Locale?
		wndStat:FindChild("Name"):SetText(strStat) --TODO: Locale
		
		local fCurrPct, bCurrDR = unpack(tPercent.curr)
		local fPlanPct, bPlanDR = unpack(tPercent.plan)
		if not tStatData[eStat].bNoPercent then
			wndStat:FindChild("Curr"):SetText(string.format("%.2f%%",fCurrPct*100))
			--wndStat:FindChild("Curr"):SetTooltip(math.floor(nCurr).." Rating")
			wndStat:FindChild("Plan"):SetText(string.format("%.2f%%",fPlanPct*100))
			--wndStat:FindChild("Plan"):SetTooltip(math.floor(nFinal).." Rating")
		else
			local fCurrPct, bCurrDR = unpack(tPercent.curr)
			local fPlanPct, bPlanDR = unpack(tPercent.plan)
			wndStat:FindChild("Curr"):SetText(math.floor(fCurrPct))
			wndStat:FindChild("Plan"):SetText(math.floor(fPlanPct))
		end
		if bCurrDR then
			wndStat:FindChild("Curr"):SetTextColor("FFDDDD00")
		end
		if bPlanDR then
			wndStat:FindChild("Plan"):SetTextColor("FFDDDD00")
		end
	end
	self.wndMain:FindChild("wndStatReview"):ArrangeChildrenVert()
end


function RuneMaster:StatReview_UpdateStatReview() --V3
	--TODO: Move this to self.ktSets
	local ktSetsTemp = CraftingLib.GetRuneSets()
	local ktSets = {}
	for _,tSet in pairs(ktSetsTemp) do
		ktSets[tSet.nSetId] = tSet
	end
	ktSetsTemp = nil
	
	--GUI Prep
	self.wndMain:FindChild("wndStatReview"):DestroyChildren()
	
	--tStatReview Table Format as: tStatReview={stats={[eStat]={curr=#,plan=#}},sets={[eSet]={curr=#,plan=#}}}
	--Get stats
	 tStats = {}
	for nArmorSlot,tStatReview in pairs(tStatReview_Armors) do
		--Rune stats
		for eStatId, tRating in pairs(tStatReview.stats) do
			tStats[eStatId] = tStats[eStatId] or {rating={curr=0,plan=0},percent={curr=0,plan=0}}
			tStats[eStatId].rating.curr = tStats[eStatId].rating.curr + tRating.curr
			tStats[eStatId].rating.plan = tStats[eStatId].rating.plan + tRating.plan
		end
		
		--Set stats (ePercent -> eStat)
		for eSetId, tSetPower in pairs(tStatReview.sets) do
			--ktSets[eSetId]
			
			local tPercents = {}
			for _,tBonus in pairs(ktSets[eSetId].arBonuses) do --TODO: self.ktSets
				--Print(nCurrPower..":"..tBonus.nPower)
				local bFound = false
				if tSetPower.curr >= tBonus.nPower then
					local ePercentId = tBonus.eProperty
					local fValue = tBonus.nValue --tBonus.nScalar --TODO: Issue with nScalar
					if fValue then
						tPercents[ePercentId] = tPercents[ePercentId] or {curr=0,plan=0}
						tPercents[ePercentId].curr = tPercents[ePercentId].curr + fValue
					else
						--Print(string.format("[RM] Bonus Error with %s (%s), nScalar: %s",tostring(Item.GetPropertyName(eStat)), tostring(eStat), tostring(tBonus.nScalar)))
					end
					bFound = true
				end
				if tSetPower.plan >= tBonus.nPower then
					local ePercentId = tBonus.eProperty
					local fValue = tBonus.nValue --tBonus.nScalar --TODO: Issue with nScalar
					if fValue then
						tPercents[ePercentId] = tPercents[ePercentId] or {curr=0,plan=0}
						tPercents[ePercentId].plan = tPercents[ePercentId].plan + fValue
					else
						--Print(string.format("[RM] Bonus Error with %s (%s), nScalar: %s",Item.GetPropertyName(eStat), eStat, tostring(tBonus.nScalar)))
					end
					bFound = true
				end
				if not bFound then
					break
				end
			end

			for ePercentId, tPercent in pairs(tPercents) do
				local eStatId = ktEnumPercentToRating[ePercentId]
				if eStatId then
					tStats[eStatId] = tStats[eStatId] or {rating={curr=0,plan=0},percent={curr=0,plan=0}}
					tStats[eStatId].percent.curr = tStats[eStatId].percent.curr + tPercent.curr
					tStats[eStatId].percent.plan = tStats[eStatId].percent.plan + tPercent.plan
				else
					tStats[ePercentId] = tStats[ePercentId] or {rating={curr=0,plan=0},percent={curr=0,plan=0}}
					tStats[ePercentId].percent.curr = tStats[ePercentId].percent.curr + tPercent.curr
					tStats[ePercentId].percent.plan = tStats[ePercentId].percent.plan + tPercent.plan
				
					--Print(string.format("[RuneMaster] ERR-SR01 - %s %s - Please report to Curse.", ePercentId, Item.GetPropertyName(ePercentId)))
				end
			end
		end
	end
	
	local unitPlayer = GameLib.GetPlayerUnit()
	--Print("Stat // fBaseTotal, fBaseSets, fBase")
	for eStatId, tInfo in pairs(tStats) do
		local tStatInfo = tStatData[eStatId]
		
		if tStatInfo then
			local fBaseTotal, fBase, fBaseArmor, fBaseSets = 0, 0, 0
			if tStatInfo.ePercentId then
				fBaseTotal = unitPlayer:GetUnitProperty(tStatInfo.ePercentId).fValue
				fBaseSets = tInfo.percent.curr or 0
				fBase = fBaseTotal - fBaseSets
				--Print(string.format("%s // %.3f,%.3f,%.3f", Item.GetPropertyName(tStatInfo.ePercentId), fBaseTotal, fBaseSets, fBase))
			end
			
			local nArmorRating = unitPlayer:GetUnitProperty(eStatId).fValue - tInfo.rating.curr
			--Print(Item.GetPropertyName(eStatId).." Armor Rating: "..string.format("%.0f",nArmorRating))	
			--tArmorRatings[eStat] = nArmorRating
			
			local fBasePlan = tInfo.percent.plan
			--self:StatReview_GetStatDR(eStat, nRating, fBase) returns fPercent, bDR
			local fCurr, bCurrDR = self:StatReview_GetStatDRV2(eStatId, tInfo.rating.curr + nArmorRating, fBaseTotal)
			local fPlan, bPlanDR = self:StatReview_GetStatDRV2(eStatId, tInfo.rating.plan + nArmorRating, fBase+fBasePlan)
			--Print(string.format("%s - Current: %.2f (%s), Planned: %.2f (%s)", Item.GetPropertyName(eStatId), fCurr, tostring(bCurrDR), fPlan, tostring(bPlanDR)))
			
			--Make GUI
			local wndStat = Apollo.LoadForm(self.xmlDoc, "StatReview_StatEntry", self.wndMain:FindChild("wndStatReview"), self)
			local strStat = string.gsub(Item.GetPropertyName(eStatId)," Rating","") --TODO: Figure out how to handle this better. Locale?
			wndStat:FindChild("Name"):SetText(strStat) --TODO: Locale
			
			local fDiff = fPlan-fCurr
			local strMod = ""
			if fDiff > 0 then
				strMod = "+"
				wndStat:FindChild("Diff"):SetTextColor("FF33DD33")
			elseif fDiff < 0 then
				wndStat:FindChild("Diff"):SetTextColor("FFDD3333")
			end
			if not tStatInfo.bNoPercent then
				wndStat:FindChild("Curr"):SetText(string.format("%.2f%%",fCurr*100))
				--wndStat:FindChild("Curr"):SetTooltip(math.floor(nCurr).." Rating")
				wndStat:FindChild("Plan"):SetText(string.format("%.2f%%",fPlan*100))
				--wndStat:FindChild("Plan"):SetTooltip(math.floor(nFinal).." Rating")
				wndStat:FindChild("Diff"):SetText(string.format(strMod.."%.2f%%",fDiff*100))
			else
				wndStat:FindChild("Curr"):SetText(math.floor(fCurr))
				wndStat:FindChild("Plan"):SetText(math.floor(fPlan))
				wndStat:FindChild("Diff"):SetText(strMod..math.floor(fDiff))
			end
			if bCurrDR then
				wndStat:FindChild("Curr"):SetTextColor("FFDDDD00")
			end
			if bPlanDR then
				wndStat:FindChild("Plan"):SetTextColor("FFDDDD00")
			end
		else
			local wndStat = Apollo.LoadForm(self.xmlDoc, "StatReview_StatEntry", self.wndMain:FindChild("wndStatReview"), self)
			local strStat = string.gsub(Item.GetPropertyName(eStatId)," Rating","") --TODO: Figure out how to handle this better. Locale?
			wndStat:FindChild("Name"):SetText(strStat) --TODO: Locale
			--wndStat:FindChild("Name"):SetTooltip("This stat is unsupported by RuneMaster. Please comment with the stat name on RuneMaster's Curse page.")
			
			local fCurr = tInfo.percent.curr
			local fPlan = tInfo.percent.plan
			local fDiff = fPlan-fCurr
			local strMod = ""
			if fDiff > 0 then
				strMod = "+"
				wndStat:FindChild("Diff"):SetTextColor("FF33DD33")
			elseif fDiff < 0 then
				wndStat:FindChild("Diff"):SetTextColor("FFDD3333")
			end
			wndStat:FindChild("Curr"):SetText(string.format("%.2f%%",fCurr*100))
			--wndStat:FindChild("Curr"):SetTooltip(math.floor(nCurr).." Rating")
			wndStat:FindChild("Plan"):SetText(string.format("%.2f%%",fPlan*100))
			--wndStat:FindChild("Plan"):SetTooltip(math.floor(nFinal).." Rating")
			wndStat:FindChild("Diff"):SetText(string.format(strMod.."%.2f%%",fDiff*100))
		end
	end
	self.wndMain:FindChild("wndStatReview"):ArrangeChildrenVert()
end

function RuneMaster:StatReview_GetStatDR(eStat, nRating, fSetPercent)
	--Returns fRating, bDR, bNoPercent
	local tStatInfo = tStatData[eStat]
	local unitPlayer = GameLib.GetPlayerUnit()
	if tStatInfo and tStatInfo.fCoeff then --TODO: Hacky check to see if the stat values exist. When all stats are finalized, fix this.
		local fSoftCap = tStatInfo.fSoftCap
		local fCoeff = tStatInfo.fCoeff
		local fBase = tStatInfo.fBase + fSetPercent
		local nDR = tStatInfo.nDR --Figure out what DR represents.
		
		local fPreDRVal = nRating*fCoeff+fBase
		--fBase/fCoeff = nRatingBase
		local nTotalRating = fPreDRVal/fCoeff
		
		if fSoftCap then
			local nSCRating = fSoftCap/fCoeff
			local nOR = math.max(nTotalRating-nSCRating,0) --Figure out what OR represents.
			
			if fPreDRVal <= fSoftCap then
				return fPreDRVal, false
			else
				return fCoeff*nOR*math.cos(math.pi/2*(nOR/(nOR+(nDR))))+fSoftCap, true
			end
		else
			return nRating, false
		end
	else
		return 0
	end
end

function RuneMaster:StatReview_GetStatDRV2(eStat, nRating, fBase)
	--Returns fRating, bDR, bNoPercent
	local tStatInfo = tStatData[eStat]
	local unitPlayer = GameLib.GetPlayerUnit()
	if tStatInfo and tStatInfo.fCoeff then --TODO: Hacky check to see if the stat values exist. When all stats are finalized, fix this.
		local fSoftCap = tStatInfo.fSoftCap
		local fCoeff = tStatInfo.fCoeff
		local nDR = tStatInfo.nDR --Figure out what DR represents.
		
		local fPreDRVal = nRating*fCoeff+fBase
		--fBase/fCoeff = nRatingBase
		local nTotalRating = fPreDRVal/fCoeff
		
		if fSoftCap then
			local nSCRating = fSoftCap/fCoeff
			local nOR = math.max(nTotalRating-nSCRating,0) --Figure out what OR represents.
			
			if fPreDRVal <= fSoftCap then
				return fPreDRVal, false
			else
				return fCoeff*nOR*math.cos(math.pi/2*(nOR/(nOR+(nDR))))+fSoftCap, true
			end
		else
			return nRating, false
		end
	else
		return 0
	end
end
