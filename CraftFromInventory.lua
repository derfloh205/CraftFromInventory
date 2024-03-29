local InventoryOnly = false
local craftable = true

local function roundToNthDecimal(num, n)
  local mult = 10^(n or 0)
  return math.floor(num * mult + 0.5) / mult
end

function adaptColor(is, need, reagentObject)
	if is < need then
		reagentObject.Icon:SetVertexColor(0.5, 0.5, 0.5);
		reagentObject.Name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
		--craftable = false;
	else
		reagentObject.Icon:SetVertexColor(1.0, 1.0, 1.0);
		reagentObject.Name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	end
end

function updateCFI()
	print("cfi update")
	if not TradeSkillFrame.DetailsFrame.Contents:IsVisible() then
		print("error blocked")
		return
	end

	-- move to better event handlers
	local currentRecipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()
	if currentRecipeID == nil then
		print("error blocked")
		return
	end
	local numberOfReagents = C_TradeSkillUI.GetRecipeNumReagents(currentRecipeID)
	local contents = TradeSkillFrame.DetailsFrame.Contents
	local currentReagentObject = nil
	local reagentNeed = 0
	local reagentName = ""
	local playerAmount = 0
	local reagentInPlayerBagString = ""
	local reagentInPlayerBankString = ""
	-- loop
	craftable = true

	if numberOfReagents == nil then
		print("error blocked")
		return
	end

	for currentReagent = 1, numberOfReagents do
		reagentName, _, reagentNeed, playerAmount = C_TradeSkillUI.GetRecipeReagentInfo(currentRecipeID, currentReagent)
		local reagentInPlayerBag = GetItemCount(reagentName, false, false)
		reagentInPlayerBagString = reagentInPlayerBag..""
		reagentInPlayerBankString = playerAmount..""

		if reagentInPlayerBag > 1000 then
			reagentInPlayerBag = roundToNthDecimal(reagentInPlayerBag / 1000, 1)
			reagentInPlayerBagString = reagentInPlayerBag.."k"
		end
		if playerAmount > 1000 then
			local playerAmountRounded = roundToNthDecimal(playerAmount / 1000, 1)
			reagentInPlayerBankString = playerAmountRounded.."k"
		end
		-- dirty hack due to getglobal with string not working.. wtf
		if currentReagent == 1 then
			currentReagentObject = contents.Reagent1
		elseif currentReagent == 2 then
			currentReagentObject = contents.Reagent2
		elseif currentReagent == 3 then
			currentReagentObject = contents.Reagent3
		elseif currentReagent == 4 then
			currentReagentObject = contents.Reagent4
		elseif currentReagent == 5 then
			currentReagentObject = contents.Reagent5
		elseif currentReagent == 6 then
			currentReagentObject = contents.Reagent6
		end

		local repeating = C_TradeSkillUI.IsRecipeRepeating(currentRecipeID)

		if CheckButtonFrame:GetChecked() then
			-- inventory only mode
			adaptColor(reagentInPlayerBag, reagentNeed, currentReagentObject)
			if string.len(reagentInPlayerBagString) >= 3 then
				reagentInPlayerBagString = reagentInPlayerBagString.."\n"
			end
			if (reagentInPlayerBag < (reagentNeed + reagentInPlayerBag)) and repeating or 
				(reagentInPlayerBag < reagentNeed) then
				-- disable button and fire cancel cast event
				craftable = false
			end
			currentReagentObject.Count:SetText(reagentInPlayerBagString.." /"..reagentNeed)
		else
			-- include bank mode
			adaptColor(playerAmount, reagentNeed, currentReagentObject)
			if string.len(reagentInPlayerBankString) >= 3 then
				reagentInPlayerBankString = reagentInPlayerBankString.."\n"
			end
			if (playerAmount < (reagentNeed + playerAmount)) and repeating or 
				(playerAmount < reagentNeed) then
				-- disable button and fire cancel cast event
				craftable = false
			end
			currentReagentObject.Count:SetText(reagentInPlayerBankString.." /"..reagentNeed)
		end
	end
	toggleCraftable(craftable)
end

function toggleCraftable(craftable)
	if craftable then
		TradeSkillFrame.DetailsFrame.CreateButton:SetEnabled(true)
		TradeSkillFrame.DetailsFrame.CreateAllButton:SetEnabled(true)
		TradeSkillFrame.DetailsFrame.CreateMultipleInputBox:SetEnabled(true)
	else
		print("stoprepeat")
		C_TradeSkillUI.StopRecipeRepeat()
		TradeSkillFrame.DetailsFrame.CreateButton:SetEnabled(false)
		TradeSkillFrame.DetailsFrame.CreateAllButton:SetEnabled(false)
		TradeSkillFrame.DetailsFrame.CreateMultipleInputBox:SetEnabled(false)
	end
end

function updateRecipeCFI(event)
	if event == "CURRENT_SPELL_CAST_CHANGED" then
		updateCFI()
	end
end

local checkButton = CreateFrame("CheckButton", "CheckButtonFrame", TradeSkillFrame.DetailsFrame.Contents, "UICheckButtonTemplate")
_G[checkButton:GetName().."Text"]:SetText("Inventory Only")
checkButton:SetPoint("CENTER", TradeSkillFrame.DetailsFrame.Contents.ResultIcon, "CENTER", 100, -5)
checkButton:Show()
checkButton:SetScript("OnClick", updateCFI)
checkButton:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
hooksecurefunc(TradeSkillFrame.DetailsFrame, "RefreshDisplay", updateCFI)
TradeSkillFrame.DetailsFrame.Contents:HookScript("OnShow", function() checkButton:SetChecked(false) end)
checkButton:HookScript("OnEvent", function(self, event, ...) updateRecipeCFI(event); end)