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

local function isFollower(id)
	return ((id >= 1736 and id <= 1741) or id == 1733 or id == 1975) and id
end

-- @return current, maximun, color
local function GetValueAndMaximum(standingID, barValue, follower)
	if (follower) then
		-- Conjurer Margoss
		if (follower == 1975) then
			if (standingID == 1) then
				return barValue, 8400, "|cFFEE6622"
			elseif (standingID == 2) then
				return barValue - 8400, 8400, "|cFFFFFF00"
			elseif (standingID == 3) then
				return barValue - 16800, 8400, "|cFF00FF00"
			elseif (standingID == 4) then
				return barValue - 25200, 8400, "|cFF00FF88"
			elseif (standingID == 5) then
				return barValue - 33600, 8400, "|cFF00FFCC"
			else
				return barValue - 41999, 8400, "|cFF00FFFF"
			end
		end

		-- Draenor
		if (standingID == 1) then
			return barValue, 10000, "|cFFFFFF00"
		else
			return barValue - 10000, 10000, "|cFF00FF88"
		end
	end

	if standingID == 1 then
		return barValue + 42000, 36000, "|cFFCC2222"
	elseif standingID == 2 then
		return barValue + 6000, 3000, "|cFFFF0000"
	elseif standingID == 3 then
		return barValue + 3000, 3000, "|cFFEE6622"
	elseif standingID == 4 then
		return barValue, 3000, "|cFFFFFF00"
	elseif standingID == 5 then
		return barValue - 3000, 6000, "|cFF00FF00"
	elseif standingID == 6 then
		return barValue - 9000, 12000, "|cFF00FF88"
	elseif standingID == 7 then
		return barValue - 21000, 21000, "|cFF00FFCC"
	elseif standingID == 8 then
		return barValue - 42000, 1000, "|cFF00FFFF"
	end

	-- just in case
	return barValue, barValue, ""
end

local function GetStanding(standingId, follower)
	if follower then
		return ""
	end

	return " (" .. ((SEX == 2 and _G["FACTION_STANDING_LABEL" .. standingId]) or _G["FACTION_STANDING_LABEL" .. standingId .. "_FEMALE"]) .. ")"
end

local function GetButtonText(self, id)
	local name, standingID, bottomValue, topValue, barValue, factionId = GetWatchedFactionInfo()

	if not name then
		return "", ""
	end
	local value, max, color = GetValueAndMaximum(standingID, barValue, isFollower(factionId))

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
					local value, max, color = GetValueAndMaximum(standingId, earnedValue, isFollower(factionId))
					local nameColor = (atWarWith and Color.RED) or Color.WHITE
					local standing = GetStanding(standingId, isFollower(factionId))

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
						local value, max, color = GetValueAndMaximum(standingId, earnedValue, isFollower(factionId))
						local nameColor = (atWarWith and Color.RED) or ""
						local standing = GetStanding(standingId, isFollower(factionId))

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


