--[[
	Description: Titan Panel plugin that shows your Reputations
	Author: Eliote
--]]

local ADDON_NAME, L = ...;
local VERSION = GetAddOnMetadata(ADDON_NAME, "Version")


local Color = {}
Color.WHITE = "|cFFFFFFFF"
Color.RED = "|cFFDC2924"
Color.YELLOW = "|cFFFFF244"
Color.GREEN = "|cFF3DDC53"
Color.ORANGE = "|cFFE77324"

local SEX = UnitSex("player")


-- @return current, maximun, color, standingText
local function GetValueAndMaximum(standingId, barValue, bottomValue, topValue, factionId)
	local current = barValue - bottomValue
	local maximun = topValue - bottomValue
	local color = "|cFF00FF00"
	local stantingText = " (" .. ((SEX == 2 and _G["FACTION_STANDING_LABEL" .. standingId]) or _G["FACTION_STANDING_LABEL" .. standingId .. "_FEMALE"]) .. ")"

	local friendID, friendRep, friendMaxRep, friendName, friendText, friendTexture, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(factionId)
	if (friendID) then
		stantingText = " (" .. friendTextLevel .. ")"

		if (nextFriendThreshold) then
			maximun, current = nextFriendThreshold - friendThreshold, friendRep - friendThreshold
		else
			maximun, current = 1, 1
		end
	else
		if standingId == 1 then
			color = "|cFFCC2222"
		elseif standingId == 2 then
			color = "|cFFFF0000"
		elseif standingId == 3 then
			color = "|cFFEE6622"
		elseif standingId == 4 then
			color = "|cFFFFFF00"
		elseif standingId == 5 then
			color = "|cFF00FF00"
		elseif standingId == 6 then
			color = "|cFF00FF88"
		elseif standingId == 7 then
			color = "|cFF00FFCC"
		elseif standingId == 8 then
			color = "|cFF00FFFF"
		end
	end

	return current, maximun, color, stantingText
end

local function GetButtonText(self, id)
	local name, standingID, bottomValue, topValue, barValue, factionId = GetWatchedFactionInfo()

	if not name then
		return "", ""
	end
	local value, max, color = GetValueAndMaximum(standingID, barValue, bottomValue, topValue, factionId)

	local text = "" .. color

	local showvalue = TitanGetVar(id, "ShowValue")
	local hideMax = TitanGetVar(id, "HideMax")
	if showvalue then
		text = text .. value

		if not hideMax then
			text = text .. "/" .. max
		end
	end
	if TitanGetVar(id, "ShowPercent") then
		local percent = math.floor((value) * 100 / (max))

		if showvalue then
			text = text .. " (" .. percent .. "%)"
		else
			text = text .. percent .. "%"
		end
	end

	return name .. ":", text
end

local function GetTooltipText(self, id)
	local factionIndex = 1

	local text = ""

	local hideNeutral = TitanGetVar(id, "HideNeutral")
	local showHeaders = TitanGetVar(id, "ShowHeaders")

	local numFactions = GetNumFactions()

	while (factionIndex < numFactions) do
		local name, _, standingId, bottomValue, topValue, earnedValue, atWarWith, _, isHeader, _, hasRep, isWatched, _, factionId = GetFactionInfo(factionIndex)

		if name then
			if not IsFactionInactive(factionIndex) then
				local lText = ""

				local headerText = (showHeaders and Color.WHITE .. name .. "|r\n") or ""

				if hasRep then
					local value, max, color, standing = GetValueAndMaximum(standingId, earnedValue, bottomValue, topValue, factionId)
					local nameColor = (atWarWith and Color.RED) or Color.WHITE

					headerText = ""
					lText = lText .. nameColor .. name .. "\t" .. color .. value .. "/" .. max .. standing .. "|r\n"
				end

				while (factionIndex < numFactions) do
					name, _, standingId, bottomValue, topValue, earnedValue, atWarWith, _, isHeader, _, hasRep, isWatched, _, factionId = GetFactionInfo(factionIndex + 1)

					if not name or isHeader then break end

					local hideExalted = TitanGetVar(id, "HideExalted")
					local show = true

					if not isWatched then
						if IsFactionInactive(factionIndex + 1) then
							show = false
						elseif hideNeutral and standingId <= 4 then
							show = false
						elseif hideExalted and standingId == 8 then
							show = false
						end
					end

					if show then
						local value, max, color, standing = GetValueAndMaximum(standingId, earnedValue, bottomValue, topValue, factionId)
						local nameColor = (atWarWith and Color.RED) or ""

						if isWatched then
							text = nameColor .. name .. "\t" .. color .. value .. "/" .. max .. standing .. "|r\n\n" .. text
						else
							lText = lText .. "-" .. nameColor .. name .. "\t" .. color .. value .. "/" .. max .. standing .. "|r\n"
						end
					end

					factionIndex = factionIndex + 1
				end

				if lText ~= "" then
					text = text .. headerText .. lText
				end
			end
		end

		factionIndex = factionIndex + 1
	end

	return text
end

local eventsTable = {
	PLAYER_ENTERING_WORLD = function(self)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")

		TitanPanelButton_UpdateButton(self.registry.id)
	end,
	UPDATE_FACTION = function(self)
		TitanPanelButton_UpdateButton(self.registry.id)
	end
}

local function OnClick(self, button)
	if (button == "LeftButton") then
		ToggleCharacter("ReputationFrame");
	end
end

local menus = {
	{ type = "space" },
	{ type = "toggle", text = L["HideNeutral"], var = "HideNeutral", def = false, keepShown = true },
	{ type = "toggle", text = L["ShowValue"], var = "ShowValue", def = true, keepShown = true },
	{ type = "toggle", text = L["ShowPercent"], var = "ShowPercent", def = true, keepShown = true },
	{ type = "toggle", text = L["ShowHeaders"], var = "ShowHeaders", def = true, keepShown = true },
	{ type = "toggle", text = L["HideMax"], var = "HideMax", def = false, keepShown = true },
	{ type = "toggle", text = L["HideExalted"], var = "HideExalted", def = false, keepShown = true },
	{ type = "space" },
	{ type = "rightSideToggle" }
}

L.Elib({
	id = "TITAN_REPUTATION_XP",
	name = L["Reputation"],
	tooltip = L["Reputation"],
	icon = "Interface\\Icons\\INV_MISC_NOTE_02",
	category = "Information",
	version = VERSION,
	getButtonText = GetButtonText,
	getTooltipText = GetTooltipText,
	eventsTable = eventsTable,
	menus = menus,
	onClick = OnClick
})


