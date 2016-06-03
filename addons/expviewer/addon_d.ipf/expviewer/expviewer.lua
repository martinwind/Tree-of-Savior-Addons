local acutil = require("acutil");

local settings = {
	showCurrentRequiredExperience = true;
	showCurrentPercent = true;
	showLastGainedExperience = true;
	showKillsTilNextLevel = true;
	showExperiencePerHour = true;
	showTimeTilLevel = true;
	skin = "test_Item_tooltip_normal";
};

function EXPVIEWER_ON_INIT(addon, frame)
	frame:EnableHitTest(1);
	frame:SetEventScript(ui.RBUTTONDOWN, "EXPVIEWER_CONTEXT_MENU");

	addon:RegisterMsg('EXP_UPDATE', 'EXPVIEWER_EXP_UPDATE');
	addon:RegisterMsg('JOB_EXP_UPDATE', 'EXPVIEWER_JOB_EXP_UPDATE');
	addon:RegisterMsg('JOB_EXP_ADD', 'EXPVIEWER_JOB_EXP_UPDATE');
	addon:RegisterMsg("FPS_UPDATE", "EXPVIEWER_CALCULATE_TICK");

	frame:SetSkinName(settings.skin);

	INIT();
end

function EXPVIEWER_CONTEXT_MENU()
	local skinList = {
		"test_Item_tooltip_normal",
		"shadow_box",
		"systemmenu_vertical",
		"chat_window",
		"popup_rightclick",
		"persoanl_shop_basicframe",
		"tutorial_skin",
		"slot_name",
		"padslot_onskin",
		"padslot_offskin2",
		"monster_skill_bg",
		"tab2_btn",
		"fullblack_bg",
		"testjoo_buttons", --clear
		"test_skin_01_btn_cursoron",
		"test_skin_01_btn_clicked",
		"test_normal_button",
		"frame_bg",
		"textview",
		"listbox",
		"box_glass",
		"tooltip1",
		"textballoon",
		"quest_box",
		"guildquest_box",
		"balloonskin_buy",
		"barrack_creat_win",
		"pip_simple_frame"
	}

	local context = ui.CreateContextMenu("EXPVIEWER_RBTN", "Experience Viewer", 0, 0, 300, 100);

	ui.AddContextMenuItem(context, "Reset Session", "RESET()");

	local subContextSkin = ui.CreateContextMenu("SUBCONTEXT_SKIN", "", 0, 0, 0, 0);

	for i=1,#skinList do
		ui.AddContextMenuItem(subContextSkin, skinList[i], string.format("EXPVIEWER_CHANGE_SKIN('%s')", skinList[i]));
	end

	ui.AddContextMenuItem(context, "Skin {img white_right_arrow 18 18}", 	"", nil, 0, 1, subContextSkin);

	local subContextToggle = ui.CreateContextMenu("SUBCONTEXT_TOGGLE", "", 0, 0, 0, 0);
	ui.AddContextMenuItem(subContextToggle, "Current / Required", string.format("EXPVIEWER_TOGGLE_CURRENT();"));
	ui.AddContextMenuItem(subContextToggle, "Current %", string.format("EXPVIEWER_TOGGLE_CURRENT_PERCENT();"));
	ui.AddContextMenuItem(subContextToggle, "Last Gained", string.format("EXPVIEWER_TOGGLE_LAST_GAINED();"));
	ui.AddContextMenuItem(subContextToggle, "TNL", string.format("EXPVIEWER_TOGGLE_TNL();"));
	ui.AddContextMenuItem(subContextToggle, "Exp/Hr", string.format("EXPVIEWER_TOGGLE_EXPERIENCE_PER_HOUR();"));
	ui.AddContextMenuItem(subContextToggle, "ETA", string.format("EXPVIEWER_TOGGLE_TIME_TIL_LEVEL();"));
	ui.AddContextMenuItem(subContextToggle, "Cancel", "None");
	ui.AddContextMenuItem(context, "Toggle {img white_right_arrow 18 18}", "", nil, 0, 1, subContextToggle);

	subContextSkin:Resize(300, subContextSkin:GetHeight());
	subContextToggle:Resize(300, subContextToggle:GetHeight());
	context:Resize(300, context:GetHeight());

	ui.OpenContextMenu(context);
end

function EXPVIEWER_CHANGE_SKIN(skin)
	local frame = ui.GetFrame("expviewer");
	frame:SetSkinName(skin);
end

--cause I'm lazy...
function EXPVIEWER_TOGGLE_CURRENT()
	settings.showCurrentRequiredExperience = not settings.showCurrentRequiredExperience;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_CURRENT_PERCENT()
	settings.showCurrentPercent = not settings.showCurrentPercent;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_LAST_GAINED()
	settings.showLastGainedExperience = not settings.showLastGainedExperience;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_TNL()
	settings.showKillsTilNextLevel = not settings.showKillsTilNextLevel;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_EXPERIENCE_PER_HOUR()
	settings.showExperiencePerHour = not settings.showExperiencePerHour;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_TOGGLE_TIME_TIL_LEVEL()
	settings.showTimeTilLevel = not settings.showTimeTilLevel;
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

--[[START EXPERIENCE DATA]]
local ExperienceData = {}
ExperienceData.__index = ExperienceData

setmetatable(ExperienceData, {
	__call = function (cls, ...)
		return cls.new(...)
	end,
})

function ExperienceData.new()
	local self = setmetatable({}, ExperienceData)

	self.firstUpdate = true;
	self.currentExperience = 0;
	self.requiredExperience = 0;
	self.previousCurrentExperience = 0;
	self.previousRequiredExperience = 0;
	self.currentPercent = 0;
	self.lastExperienceGain = 0;
	self.killsTilNextLevel = 0;
	self.experiencePerHour = 0;
	self.experienceGained = 0;
	self.timeTilLevel = 0;

	return self
end

function ExperienceData:reset()
	self.firstUpdate = true;
	self.currentExperience = 0;
	self.requiredExperience = 0;
	self.previousCurrentExperience = 0;
	self.previousRequiredExperience = 0;
	self.currentPercent = 0;
	self.lastExperienceGain = 0;
	self.killsTilNextLevel = 0;
	self.experiencePerHour = 0;
	self.experienceGained = 0;
	self.timeTilLevel = 0;
end
--[[END EXPERIENCE DATA]]

_G["EXPERIENCE_VIEWER"] = {};
_G["EXPERIENCE_VIEWER"]["baseExperienceData"] = _G["EXPERIENCE_VIEWER"]["baseExperienceData"] or ExperienceData();
_G["EXPERIENCE_VIEWER"]["classExperienceData"] = _G["EXPERIENCE_VIEWER"]["classExperienceData"] or ExperienceData();
_G["EXPERIENCE_VIEWER"]["startTime"] = _G["EXPERIENCE_VIEWER"]["startTime"] or os.clock();
_G["EXPERIENCE_VIEWER"]["elapsedTime"] = _G["EXPERIENCE_VIEWER"]["elapsedTime"] or os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);
_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] = _G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] or 3600;
_G["EXPERIENCE_VIEWER"]["headerTablePositions"] = _G["EXPERIENCE_VIEWER"]["headerTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["baseTablePositions"] = _G["EXPERIENCE_VIEWER"]["baseTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["classTablePositions"] = _G["EXPERIENCE_VIEWER"]["classTablePositions"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["frameWidths"] = _G["EXPERIENCE_VIEWER"]["frameWidths"] or { 0, 0, 0, 0, 0, 0 };
_G["EXPERIENCE_VIEWER"]["padding"] = _G["EXPERIENCE_VIEWER"]["padding"] or 5;

function SET_WINDOW_POSITION_GLOBAL()
	local expFrame = ui.GetFrame("expviewer");

	if expFrame ~= nil then
		_G["EXPERIENCE_VIEWER"]["POSITION_X"] = expFrame:GetX();
		_G["EXPERIENCE_VIEWER"]["POSITION_Y"] = expFrame:GetY();
	end

	SAVE_POSITION_TO_FILE(expFrame:GetX(), expFrame:GetY());
end

function MOVE_WINDOW_TO_STORED_POSITION()
	local expFrame = ui.GetFrame("expviewer");

	if expFrame ~= nil then
		expFrame:Move(0, 0);
		expFrame:SetOffset(_G["EXPERIENCE_VIEWER"]["POSITION_X"], _G["EXPERIENCE_VIEWER"]["POSITION_Y"]);
	end
end

function INIT()
	LOAD_POSITION_FROM_FILE();
	local expFrame = ui.GetFrame("expviewer");
	expFrame:ShowWindow(1);
	UPDATE_BUTTONS(expFrame);
	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_EXP_UPDATE(frame, msg, argStr, argNum)
	if msg == 'EXP_UPDATE' then
		_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

		--SET BASE CURRENT/REQUIRED EXPERIENCE
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].previousRequiredExperience = _G["EXPERIENCE_VIEWER"]["baseExperienceData"].requiredExperience;
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].currentExperience = session.GetEXP();
		_G["EXPERIENCE_VIEWER"]["baseExperienceData"].requiredExperience = session.GetMaxEXP();

		--CALCULATE EXPERIENCE
		CALCULATE_EXPERIENCE_DATA(_G["EXPERIENCE_VIEWER"]["baseExperienceData"], _G["EXPERIENCE_VIEWER"]["elapsedTime"]);

		UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	end
end

function EXPVIEWER_JOB_EXP_UPDATE(frame, msg, str, exp, tableinfo)
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

	--CALCULATE EXPERIENCE
	local currentTotalClassExperience = exp;
	local currentClassLevel = tableinfo.level;

	--SET CLASS CURRENT/REQUIRED EXPERIENCE
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].previousRequiredExperience = _G["EXPERIENCE_VIEWER"]["classExperienceData"].requiredExperience;
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].currentExperience = exp - tableinfo.startExp;
	_G["EXPERIENCE_VIEWER"]["classExperienceData"].requiredExperience = tableinfo.endExp - tableinfo.startExp;

	--CALCULATE EXPERIENCE
	CALCULATE_EXPERIENCE_DATA(_G["EXPERIENCE_VIEWER"]["classExperienceData"], _G["EXPERIENCE_VIEWER"]["elapsedTime"]);

	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function CALCULATE_EXPERIENCE_DATA(experienceData, elapsedTime)
	if experienceData.firstUpdate == true then
		experienceData.previousCurrentExperience = experienceData.currentExperience;
		experienceData.firstUpdate = false;
		return;
	end

	--[[PERFORM CALCULATIONS]]
	--if we leveled up...
	if experienceData.requiredExperience > experienceData.previousRequiredExperience then
		experienceData.lastExperienceGain = (experienceData.previousRequiredExperience - experienceData.previousCurrentExperience) + experienceData.currentExperience;
	else
		experienceData.lastExperienceGain = experienceData.currentExperience - experienceData.previousCurrentExperience;
	end

	experienceData.experienceGained = experienceData.experienceGained + experienceData.lastExperienceGain;
	experienceData.currentPercent = experienceData.currentExperience / experienceData.requiredExperience * 100;

	if experienceData.lastExperienceGain == 0 then
		experienceData.killsTilNextLevel = "INF";
	else
		experienceData.killsTilNextLevel = math.ceil((experienceData.requiredExperience - experienceData.currentExperience) / experienceData.lastExperienceGain);
	end

	experienceData.experiencePerHour = (experienceData.experienceGained * (_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] / _G["EXPERIENCE_VIEWER"]["elapsedTime"]));

	local experienceRemaining = experienceData.requiredExperience - experienceData.currentExperience;
	local experiencePerSecond = experienceData.experienceGained / _G["EXPERIENCE_VIEWER"]["elapsedTime"];

	experienceData.timeTilLevel = os.date("!%X", experienceRemaining / experiencePerSecond);

	--[[END OF UPDATES, SET PREVIOUS]]
	experienceData.previousCurrentExperience = experienceData.currentExperience;
end

function EXPVIEWER_CALCULATE_TICK()
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = os.difftime(os.clock(), _G["EXPERIENCE_VIEWER"]["startTime"]);

	EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(_G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(_G["EXPERIENCE_VIEWER"]["classExperienceData"]);

	EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(_G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(_G["EXPERIENCE_VIEWER"]["classExperienceData"]);

	UPDATE_UI("baseExperience", _G["EXPERIENCE_VIEWER"]["baseExperienceData"]);
	UPDATE_UI("classExperience", _G["EXPERIENCE_VIEWER"]["classExperienceData"]);
end

function EXPVIEWER_CALCULATE_EXPERIENCE_PER_HOUR(experienceData)
	experienceData.experiencePerHour = (experienceData.experienceGained * (_G["EXPERIENCE_VIEWER"]["SECONDS_IN_HOUR"] / _G["EXPERIENCE_VIEWER"]["elapsedTime"]));
end

function EXPVIEWER_CALCULATE_TIME_TIL_LEVEL(experienceData)
	local experienceRemaining = experienceData.requiredExperience - experienceData.currentExperience;
	local experiencePerSecond = experienceData.experienceGained / _G["EXPERIENCE_VIEWER"]["elapsedTime"];

	experienceData.timeTilLevel = os.date("!%X", experienceRemaining / experiencePerSecond);
end

function UPDATE_UI(experienceTextName, experienceData)
	if ui ~= nil then
		local expFrame = ui.GetFrame("expviewer");

		if expFrame ~= nil then
			UPDATE_BUTTONS(expFrame);

			--this might be the worst code I've ever written, but who cares? it works!

			--SET EXPERIENCE TEXT
			if experienceTextName == "baseExperience" or experienceTextName == "classExperience" then
				local xPosition = 15;
				local yPosition = 14;

				for i=0,5 do
					local columnKey = "headerTablePositions";
					local richText = expFrame:GetChild("header_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Current / Required",
							settings.showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}%",
							settings.showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Gain",
							settings.showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}TNL",
							settings.showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}Exp/Hr",
							settings.showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s18}ETA",
							settings.showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			if experienceTextName == "baseExperience" then
				local xPosition = 15;
				local yPosition = 49;

				for i=0,5 do
					local columnKey = "baseTablePositions";
					local richText = expFrame:GetChild("base_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.currentExperience) .." / " .. GetCommaedText(experienceData.requiredExperience),
							settings.showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. string.format("%.2f", experienceData.currentPercent) .. "%",
							settings.showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.lastExperienceGain),
							settings.showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.killsTilNextLevel),
							settings.showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(string.format("%i", experienceData.experiencePerHour)),
							settings.showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. experienceData.timeTilLevel,
							settings.showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			if experienceTextName == "classExperience" then
				local xPosition = 15;
				local yPosition = 74;

				for i=0,5 do
					local columnKey = "classTablePositions";
					local richText = expFrame:GetChild("class_"..i);

					richText:Resize(0, 20);

					if i == 0 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.currentExperience) .." / " .. GetCommaedText(experienceData.requiredExperience),
							settings.showCurrentRequiredExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 1  then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. string.format("%.2f", experienceData.currentPercent) .. "%",
							settings.showCurrentPercent,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 2 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.lastExperienceGain),
							settings.showLastGainedExperience,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 3 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(experienceData.killsTilNextLevel),
							settings.showKillsTilNextLevel,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 4 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. GetCommaedText(string.format("%i", experienceData.experiencePerHour)),
							settings.showExperiencePerHour,
							xPosition,
							yPosition,
							columnKey
						);
					elseif i == 5 then
						xPosition = UPDATE_CELL(
							i,
							richText,
							"{@st41}{s16}" .. experienceData.timeTilLevel,
							settings.showTimeTilLevel,
							xPosition,
							yPosition,
							columnKey
						);
					end
				end
			end

			local size = CALCULATE_FRAME_SIZE() + 20; --extra 20 for reset button
			expFrame:Resize(size, 108);
		end
	end
end

function UPDATE_CELL(i, richTextComponent, label, showField, xPosition, yPosition, columnKey)
	if showField then
		richTextComponent:SetText(label);

		_G["EXPERIENCE_VIEWER"][columnKey][i+1] = richTextComponent:GetWidth();

		richTextComponent:Resize(richTextComponent:GetWidth(), 20);
		richTextComponent:Move(0, 0);
		richTextComponent:SetOffset(xPosition, yPosition);
		richTextComponent:ShowWindow(1);

		xPosition = xPosition + CALCULATE_MAX_COLUMN_WIDTH(i)  + _G["EXPERIENCE_VIEWER"]["padding"];
	else
		_G["EXPERIENCE_VIEWER"][columnKey][i+1] = 0;
		richTextComponent:SetText("");
		richTextComponent:Move(0, 0);
		richTextComponent:SetOffset(xPosition, yPosition);
		richTextComponent:ShowWindow(0);
	end

	return xPosition;
end

function CALCULATE_MAX_COLUMN_WIDTH(tableIndex)
	return math.max(_G["EXPERIENCE_VIEWER"]["headerTablePositions"][tableIndex+1], _G["EXPERIENCE_VIEWER"]["baseTablePositions"][tableIndex+1], _G["EXPERIENCE_VIEWER"]["classTablePositions"][tableIndex+1]);
end

function CALCULATE_FRAME_SIZE()
	local frameWidth = 0;

	for i = 1,6 do
		local max = math.max(_G["EXPERIENCE_VIEWER"]["headerTablePositions"][i], _G["EXPERIENCE_VIEWER"]["baseTablePositions"][i], _G["EXPERIENCE_VIEWER"]["classTablePositions"][i]);
		frameWidth = frameWidth + max + _G["EXPERIENCE_VIEWER"]["padding"];
	end

	frameWidth = frameWidth + (_G["EXPERIENCE_VIEWER"]["padding"] * 2);

	return frameWidth;
end

function UPDATE_BUTTONS(expFrame)
	--MOVE RESET BUTTON TO TOPRIGHT CORNER
	local resetButton = expFrame:GetChild("resetButton");
	if resetButton ~= nil then
		resetButton:Move(0, 0);
		resetButton:SetOffset(expFrame:GetWidth() - 35, 5);
		resetButton:SetText("{@sti7}{s16}R");
		resetButton:Resize(30, 30);
	end

	--MOVE START BUTTON TO TOPLEFT CORNER
	local startButton = expFrame:GetChild("startButton");
	if startButton ~= nil then
		startButton:Move(0, 0);
		startButton:SetOffset(5, 5);
		startButton:SetText("{@sti7}{s16}S");
		startButton:Resize(30, 30);
		startButton:ShowWindow(0);
	end
end

function PRINT_EXPERIENCE_DATA(experienceData)
	ui.SysMsg(experienceData.currentExperience .. " / " .. experienceData.requiredExperience .. "   " .. experienceData.lastExperienceGain .. " gained   " .. experienceData.currentPercent .. "%" .. "   " .. experienceData.killsTilNextLevel .. " tnl   " .. experienceData.experiencePerHour .. " exp/hr");
end

function RESET()
	ui.SysMsg("Resetting experience session!");

	_G["EXPERIENCE_VIEWER"]["startTime"] = os.clock();
	_G["EXPERIENCE_VIEWER"]["elapsedTime"] = 0;
	_G["EXPERIENCE_VIEWER"]["baseExperienceData"]:reset();
	_G["EXPERIENCE_VIEWER"]["classExperienceData"]:reset();

	SET_WINDOW_POSITION_GLOBAL();
end

function LOAD_POSITION_FROM_FILE()
	local file, error = io.open("../addons/expviewer/settings.txt", "r");

	if error then
		return;
	end

	_G["EXPERIENCE_VIEWER"]["POSITION_X"] = file:read();
	_G["EXPERIENCE_VIEWER"]["POSITION_Y"] = file:read();

	MOVE_WINDOW_TO_STORED_POSITION();
end

function SAVE_POSITION_TO_FILE(xPosition, yPosition)
	local file, error = io.open("../addons/expviewer/settings.txt", "w");

	if error then
		return;
	end

	file:write(xPosition .. "\n" .. yPosition);
	file:flush();
	file:close();
end