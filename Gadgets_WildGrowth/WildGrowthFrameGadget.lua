--[[
	This file is part of Wildtide's WT Addon Framework
	The Code was Hijacked from DoomSprout's Warden tracking tool
	
--]]

local toc, data = ...
local AddonId = toc.identifier
local TXT=Library.Translate
local unitName = nil
local unitBuffName = nil
-- wtWildGrowthFrame provides a simple bar for the player's charge


local iconWG = "Data/\\UI\\ability_icons\\spiritoftree1a.dds"

local WildGrowthFrames = {}
local CoolDown = 60
local wgEnabled = false

local function OnUnitSet(unitFrame, unitId)
	unitFrame.beginWG = nil
	unitFrame.LastCastWG = nil
	unitFrame.buffWG = nil
	unitFrame.durationWG = nil	
	WT.Units[unitId].cdWG = nil
	WT.Units[unitId].percentWG = nil
end

local function OnUnitCleared(unitFrame)
	unitFrame.LastCastWG = nil
	unitFrame.beginWG = nil
	unitFrame.buffWG = nil
	unitFrame.durationWG = nil	
end

local function OnUnitChanged(unitFrame, unitId)
	if unitId then
		OnUnitSet(unitFrame, unitId)
	else
		OnUnitCleared(unitFrame)
	end		
end


local function OnBuffAdded(unitFrame, buff)
	local unitId = Inspect.Unit.Lookup(unitFrame.UnitSpec) 
	if not unitId then return end
	if unitId ~= buff.caster then return end
	if buff.name == unitBuffName then
		unitFrame.buffWG = buff.id
		unitFrame.beginWG = buff.begin
		unitFrame.LastCastWG = buff.begin
		unitFrame.durationWG = buff.duration
		WT.Units[unitId].cdWG = CoolDown
	end
end

local function OnBuffChanged(unitFrame, buff)

	local unitId = Inspect.Unit.Lookup(unitFrame.UnitSpec) 
	if not unitId then return end

	if WT.Player and WT.Player.id ~= buff.caster then return end
	detail = Inspect.Unit.Detail(unitId)
	unitName = detail.name

	if buff.name == unitBuffName then
		--WT.Units[unitId].cdWG = buff.stack or 1
	end
	
end

local function OnBuffRemoved(unitFrame, buff)

	local unitId = Inspect.Unit.Lookup(unitFrame.UnitSpec) 
	if not unitId then return end
	
	if buff.id == unitFrame.buffWG then
		WT.Units[unitId].percentWG = 0
		unitFrame.beginWG = nil
		unitFrame.buffWG = nil
		unitFrame.durationWG = nil	
		--WT.Units[unitId].cdWG = nil
	end
end

local function OnUnitNameChanged(frame, name)
	local unitId = Inspect.Unit.Lookup(frame.UnitSpec) 
	if unitId ~= nil then
		detail = Inspect.Unit.Detail(unitId) 
		if detail ~= nil then
			if wgEnabled == false then wgEnabled = true	end
			local unitName = detail.name
			frame:EventMacroSet(Event.UI.Input.Mouse.Left.Down, "raid " .. unitName .. " Cast Wild Growth")
			frame:EventMacroSet(Event.UI.Input.Mouse.Right.Down, "yell " .. unitName .. " Cast Wild Growth")
		end
	end
end


local function Create(configuration)

	local iconSize = 20
	local iconSpacing = 1
	local barLength = 150
	local barLength12 = (barLength / 14) * 12

	local WildGrowthFrame = WT.UnitFrame:Create(configuration.unitSpec)
	unitBuffName = configuration.buffName
	CoolDown = tonumber(configuration.buffCoolDown)
	WildGrowthFrame:SetWidth(iconSize + (iconSpacing * 3) + barLength)
	WildGrowthFrame:SetHeight(iconSize * 2 + iconSpacing * 3)
	WildGrowthFrame:SetBackgroundColor(0.2,0.2,0.2,0.4)

	WildGrowthFrame.Add = OnBuffAdded
	WildGrowthFrame.Update = OnBuffChanged
	WildGrowthFrame.Remove = OnBuffRemoved
	WildGrowthFrame.Done = function() end
	WildGrowthFrame.CanAccept = function(frame, buff) return true end

	WildGrowthFrame:RegisterBuffSet(WildGrowthFrame)

	WildGrowthFrame:CreateBinding("id", WildGrowthFrame, OnUnitChanged, false)
	WildGrowthFrame:CreateBinding("name", WildGrowthFrame, OnUnitNameChanged, false)
	
	local barWG01 = WildGrowthFrame:CreateElement(
	{
		id="barWG01", type="Bar", layer=20,
		attach = {{ point="TOPLEFT", element="frame", targetPoint="TOPLEFT", offsetX=iconSpacing, offsetY=iconSpacing }},
		width=barLength + iconSpacing + iconSize, height=iconSize,
		media="wtDiagonal", binding="healthPercent", backgroundColor={r=0,g=0,b=0,a=1.0}, color={r=0,g=0.8,b=0,a=1.0},
	});

	WildGrowthFrame:CreateElement(
	{
		-- Generic Element Configuration
		id="wfLabel", type="Label", parent="frame", layer=30,
		attach = {{ point="CENTERLEFT", element="barWG01", targetPoint="CENTERLEFT", offsetX=4, offsetY=0 }},
		text="{nameShort}", fontSize=iconSize * 0.6, binding="unitName",
	});

	local imgWG01 = WildGrowthFrame:CreateElement(
	{
		-- Generic Element Configuration
		id="imgWG01", type="Image", parent="frame", layer=20,
		attach = {{ point="TOPLEFT", element="barWG01", targetPoint="BOTTOMLEFT", offsetX=0, offsetY=iconSpacing }},
		width=iconSize,height=iconSize,texAddon="Rift",texFile=iconWG,
	});

	local barCD01 = WildGrowthFrame:CreateElement(
	{
		id="barCD01", type="Bar", layer=20,
		attach = {{ point="TOPLEFT", element="imgWG01", targetPoint="TOPRIGHT", offsetX=iconSpacing, offsetY=0 }},
		width=barLength12, height=iconSize,
		media="wtHealbot", binding="percentWG", 
		backgroundColor={r=0,g=0,b=0,a=0.3},
		color={r=0.2,g=0.4,b=0.6,a=1.0},
	});

	local mx = (barLength - barLength12) / 2

	WildGrowthFrame:CreateElement(
	{
		-- Generic Element Configuration
		id="txtSS", type="Label", parent="frame", layer=30,
		attach = {{ point="CENTER", element="barCD01", targetPoint="CENTERRIGHT", offsetX=mx, offsetY=0 }},
		text="{cdWG}", fontSize=iconSize * 0.6,
	});



	WildGrowthFrames[WildGrowthFrame] = true

	WildGrowthFrame:SetSecureMode("restricted")
	barWG01:SetSecureMode("restricted")
	--barWG01.Event.LeftDown = "raid {nameShort} Cast Wild Growth "
	--barWG01.Event.RightDown = "yell {nameShort} Cast Wild Growth "
	barWG01:SetMouseMasking("limited")
	
	imgWG01:SetSecureMode("restricted")
	barCD01:SetSecureMode("restricted")
	--imgWG01.Event.LeftDown = "raid {nameShort} Cast Wild Growth "
	--imgWG01.Event.RightDown = "yell {nameShort} Cast Wild Growth "
	--barCD01.Event.LeftDown = "raid {nameShort} Cast Wild Growth "
	--barCD01.Event.RightDown = "yell {nameShort} Cast Wild Growth "

	WildGrowthFrame:SetMouseoverUnit(configuration.unitSpec)
	imgWG01:SetMouseoverUnit(configuration.unitSpec)
	barCD01:SetMouseoverUnit(configuration.unitSpec)
	barWG01:SetMouseoverUnit(configuration.unitSpec)

	WildGrowthFrame:ApplyDefaultBindings()

	return WildGrowthFrame
end


local dialog = false

local function ConfigDialog(container)	
	dialog = WT.Dialog(container)
		:Label(TXT.WildGrowthGadgetConfigDesc)
		:Combobox("buffName", TXT.WhatBuffToTrack, "Wild Growth",
			{
				{text="Wild Growth", value="Wild Growth"},
			}, false) 
		:Combobox("buffCoolDown", TXT.WhatBuffToTrack, "60",
			{
				{text="15", value=15},
				{text="30", value=30},
				{text="60", value=60},
				{text="120", value=120},
			}, false) 
		:Combobox("unitSpec", TXT.UnitToTrack, "player",
			{
				{text="Player", value="player"},
				{text="Target", value="player.target"},
				{text="Focus", value="focus"},
				{text="Group 1, Slot 1", value="group01"},
				{text="Group 1, Slot 2", value="group02"},
				{text="Group 1, Slot 3", value="group03"},
				{text="Group 1, Slot 4", value="group04"},
				{text="Group 1, Slot 5", value="group05"},
				{text="Group 2, Slot 1", value="group06"},
				{text="Group 2, Slot 2", value="group07"},
				{text="Group 2, Slot 3", value="group08"},
				{text="Group 2, Slot 4", value="group09"},
				{text="Group 2, Slot 5", value="group10"},
				{text="Group 3, Slot 1", value="group11"},
				{text="Group 3, Slot 2", value="group12"},
				{text="Group 3, Slot 3", value="group13"},
				{text="Group 3, Slot 4", value="group14"},
				{text="Group 3, Slot 5", value="group15"},
				{text="Group 4, Slot 1", value="group16"},
				{text="Group 4, Slot 2", value="group17"},
				{text="Group 4, Slot 3", value="group18"},
				{text="Group 4, Slot 4", value="group19"},
				{text="Group 4, Slot 5", value="group20"},
			}, false) 
		
end

local function GetConfiguration()
	return dialog:GetValues()
end

local function SetConfiguration(config)
	dialog:SetValues(config)
end

-- Get the list of our buffs --
local function PrintMyBuffs()
	local buff_list = Inspect.Buff.List("player")
	-- Sometimes the buff list isn't available so we need to prevent nil operations --
	if not buff_list then return end 
	
        -- Lets get all the details of our new list using the table --
        local buff_details = Inspect.Buff.Detail("player",buff_list)

	-- Step through the buff list table and print information on each one --
	for k, v in pairs(buff_details) do
                print(tostring(v))
		-- Now step through the buff's detail table --
                for a, b in pairs(v) do
                        -- this will print something like "name, Buff Name" --
                        print("		" .. tostring(a) .. "		" .. tostring(b))
                end	
	end
end

WT.Gadget.RegisterFactory("WildGrowthFrame",
	{
		name=TXT.WildGrowthGadget_name, 
		description=TXT.WildGrowthGadget_desc,
		author="Mael",
		version="0.0.1",
		["Create"] = Create,
		["ConfigDialog"] = ConfigDialog,
		["GetConfiguration"] = GetConfiguration, 
		["SetConfiguration"] = SetConfiguration, 
	})

local function OnTick()
	if wgEnabled then
		local now = Inspect.Time.Frame()
		for frame in pairs(WildGrowthFrames) do
			local unitId = Inspect.Unit.Lookup(frame.UnitSpec)
			if unitId then
				if frame.beginWG then			
					local elapsed = now - frame.beginWG
					WT.Units[unitId].percentWG = ((frame.durationWG - elapsed) / frame.durationWG) * 100
				end
				if WT.Units[unitId].cdWG ~= nil and WT.Units[unitId].cdWG > 0 then
					local elapsedCast = now - frame.LastCastWG
					WT.Units[unitId].cdWG = CoolDown - elapsedCast
				end
			end
		end
	end
end

Command.Event.Attach(Event.System.Update.Begin, OnTick, "_WildGrowthFrameTick")