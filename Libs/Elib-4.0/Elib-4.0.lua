--[[
	Description: Titan Panel Lib. Be careful editing it, all plugins can stop working.
	Author: Eliote
--]]

local MAJOR, MINOR = "Elib-4.0", 2
local Elib = LibStub:NewLibrary(MAJOR, MINOR)
if not Elib then return end

local AceLocale = LibStub("AceLocale-3.0")
local Titan_L = AceLocale:GetLocale(TITAN_ID, true)

---@type ElioteDropDownMenu
local EDDM = LibStub("ElioteDropDownMenu-1.0")
local menuFrame = EDDM.UIDropDownMenu_GetOrCreate("ElibDropDown")

local function createTitanOption(id, text, var)
	return {
		text = text,
		func = function()
			TitanPanelRightClickMenu_ToggleVar({ id, var, nil })
		end,
		checked = TitanGetVar(id, var),
		keepShownOnClick = 1
	}
end

local function setDefaultSavedVariables(sv, menus)
	sv.ShowIcon = sv.ShowIcon or 1
	sv.ShowLabelText = sv.ShowLabelText or false

	if menus then
		for k, v in ipairs(menus) do
			if v.var then sv[v.var] = v.def or sv[v.var] or false
			elseif v.type == "rightSideToggle" then sv.DisplayOnRightSide = v.def or false
			end
		end
	end
end

StaticPopupDialogs["ELIB_DEFAULT_RESET_COLOR_DIALOG"] = {
	text = "%s",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function(_, data)
		if not data then return end
		TitanSetVar(data.id, data.var, data.def)
		TitanPanelButton_UpdateButton(data.id)
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

function Elib.Register(easyObject)
	local function initializeMenu(self, level, menuList)
		local id = easyObject.id

		if easyObject.prepareMenu then
			return easyObject.prepareMenu(EDDM, self, easyObject.id, level, menuList)
		end

		EDDM.UIDropDownMenu_AddButton({
			text = TitanPlugins[id].menuText,
			hasArrow = false,
			isTitle = true,
			isUninteractable = true,
			notCheckable = true
		})

		EDDM.UIDropDownMenu_AddButton(createTitanOption(id, Titan_L["TITAN_PANEL_MENU_SHOW_ICON"], "ShowIcon"))
		EDDM.UIDropDownMenu_AddButton(createTitanOption(id, Titan_L["TITAN_PANEL_MENU_SHOW_LABEL_TEXT"], "ShowLabelText"))

		local menus = easyObject.menus
		if menus then
			for k, v in ipairs(menus) do
				if v.type == "rightSideToggle" then
					local info = {}
					info.text = Titan_L["TITAN_CLOCK_MENU_DISPLAY_ON_RIGHT_SIDE"]
					info.func = function()
						TitanToggleVar(id, "DisplayOnRightSide");
						TitanPanel_InitPanelButtons()
					end
					info.checked = TitanGetVar(id, "DisplayOnRightSide")
					EDDM.UIDropDownMenu_AddButton(info)
				end
			end
		end

		EDDM.UIDropDownMenu_AddSeparator()

		if menus then
			for k, v in ipairs(menus) do
				if v.type == "toggle" then
					local info = {}
					info.text = v.text
					info.func = v.func or function()
						TitanToggleVar(id, v.var);
						TitanPanelButton_UpdateButton(id)
					end
					info.checked = TitanGetVar(id, v.var)
					info.keepShownOnClick = v.keepShown
					EDDM.UIDropDownMenu_AddButton(info)
				elseif v.type == "space" then
					EDDM.UIDropDownMenu_AddSpace()
				elseif v.type == "button" then
					local info = {}
					info.text = v.text
					info.func = v.func
					info.notCheckable = true
					info.arg1 = v.arg1
					info.arg2 = v.arg2
					EDDM.UIDropDownMenu_AddButton(info)
				elseif v.type == "title" then
					local info = {}
					info.text = v.text
					info.notCheckable = true
					info.isTitle = true
					EDDM.UIDropDownMenu_AddButton(info)
				elseif v.type == "color" then
					local colorHex = TitanGetVar(id, v.var) or v.def or "FF000000"
					local info = {}
					info.text = v.text
					info.r, info.g, info.b = CreateColorFromHexString(colorHex):GetRGB()
					info.func = v.func or function()
						local dialog = StaticPopup_Show("ELIB_DEFAULT_RESET_COLOR_DIALOG", v.dialogText or "Do you want to reset this color?")
						if dialog then
							dialog.data = { id = id, var = v.var, def = v.def }
						end
					end
					info.swatchFunc = v.swatchFunc or function()
						local color = CreateColor(ColorPickerFrame:GetColorRGB())
						TitanSetVar(id, v.var, color:GenerateHexColor())
						TitanPanelButton_UpdateButton(id)
					end
					info.cancelFunc = v.cancelFunc or function(previousValues)
						if previousValues then
							TitanSetVar(id, v.var, CreateColor(previousValues.r, previousValues.g, previousValues.b):GenerateHexColor())
						end
					end
					info.arg1 = v.arg1
					info.arg2 = v.arg2
					info.notCheckable = true
					info.hasColorSwatch = true
					EDDM.UIDropDownMenu_AddButton(info)
				end
			end
			EDDM.UIDropDownMenu_AddButton({ text = "", notCheckable = true, notClickable = true, disabled = 1 })
		end

		EDDM.UIDropDownMenu_AddButton({
			notCheckable = true,
			text = Titan_L["TITAN_PANEL_MENU_HIDE"],
			func = function() TitanPanelRightClickMenu_Hide(id) end
		})
		EDDM.UIDropDownMenu_AddSeparator()
		EDDM.UIDropDownMenu_AddButton({ notCheckable = true, text = CANCEL, keepShownOnClick = false })
	end

	-- Main button frame and addon base
	local frame = CreateFrame("Button", "TitanPanel" .. easyObject.id .. "Button", CreateFrame("Frame", nil, UIParent), "TitanPanelComboTemplate")
	frame:SetFrameStrata("FULLSCREEN")
	frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	frame:RegisterEvent("ADDON_LOADED")
	frame:SetScript("OnClick", function(self, button, ...)
		local handled = easyObject.onClick and easyObject.onClick(self, button, ...)
		if not handled and button == "RightButton" then
			EDDM.UIDropDownMenu_Initialize(menuFrame, initializeMenu, "MENU")
			EDDM.ToggleDropDownMenu(1, nil, menuFrame, "cursor", 3, -3)
		end
	end)

	if easyObject.eventsTable then
		for event, func in pairs(easyObject.eventsTable) do
			frame[event] = func
			frame:RegisterEvent(event)
		end
	end

	function frame:ADDON_LOADED()
		self:UnregisterEvent("ADDON_LOADED")
		self.ADDON_LOADED = nil

		if easyObject.onLoad then easyObject.onLoad(self, easyObject.id) end

		local sv = easyObject.savedVariables or {}
		setDefaultSavedVariables(sv, easyObject.menus)

		self.registry = {
			id = easyObject.id,
			menuText = easyObject.name .. "|r",
			buttonTextFunction = easyObject.getButtonText and "TitanPanelButton_Get" .. easyObject.id .. "ButtonText",
			tooltipTitle = easyObject.tooltip,
			tooltipTextFunction = easyObject.getTooltipText and "TitanPanelButton_Get" .. easyObject.id .. "TooltipText",
			frequency = (easyObject.onUpdate and easyObject.frequency) or 1,
			icon = easyObject.icon,
			iconWidth = 16,
			category = easyObject.category,
			version = easyObject.version,
			tooltipCustomFunction = easyObject.customTooltip,
			savedVariables = sv
		}

		if easyObject.onUpdate then
			local elap = 0
			self:SetScript("OnUpdate", function(this, a1)
				elap = elap + a1
				if elap < 1 then return end

				if easyObject.onUpdate(self, easyObject.id) then elap = 0 end
			end)
		end
	end

	if easyObject.getButtonText then
		_G["TitanPanelButton_Get" .. easyObject.id .. "ButtonText"] = function(...)
			return easyObject.getButtonText(frame, easyObject.id, ...)
		end
	end

	if easyObject.getTooltipText then
		_G["TitanPanelButton_Get" .. easyObject.id .. "TooltipText"] = function(...)
			return easyObject.getTooltipText(frame, easyObject.id, ...)
		end
	end

	return frame
end
