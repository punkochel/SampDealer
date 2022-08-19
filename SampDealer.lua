-- I play on Samp-Rp Revolution, Piggly_Wiggly
script_author("punkochel")
script_version("1.0")

MSG_SCRIPT_NOT_ACTIVED = "[SampDealer] {969595}������ ��������. ����� ��������, �������: /dealer"
COLOR_SCRIPTMSG = 0xFC2847

-- lib's
local sampev = require "samp.events"

-- var's
local toggle_script = false

local players_tip = {}
local daily_tips = {}
local player_info = {}

local work_directory = getWorkingDirectory()
local fpath_players_tip = work_directory .. "/config/dealer/players_tip.json"
local fpath_daily_tips = ''
local fpath_player_info = work_directory .. "/config/dealer/player_info.json"

-- Main
function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then 
		return 
	end
   	while not isSampAvailable() do 
   		wait(0) 
   	end

   	-- Welcome information
   	sampAddChatMessage("[SampDealer] {969595}������ ������� ��������. ���������� � {cccccc}/dealerhelp", COLOR_SCRIPTMSG)

   	-- Register command's
   	sampRegisterChatCommand("dealerhelp", dealerHelp)
   	sampRegisterChatCommand("dealer", toggleScript)
   	sampRegisterChatCommand("gettips", getTips)
   	sampRegisterChatCommand("toptips", topTips)
   	sampRegisterChatCommand("toptipsday", topTipsDay)

   	-- Create directories
   	if not doesDirectoryExist(work_directory .. "/config") then
        createDirectory(work_directory .. "/config")
    end
    if not doesDirectoryExist(work_directory .. "/config/dealer") then
        createDirectory(work_directory .. "/config/dealer")
    end
    if not doesDirectoryExist(work_directory .. "/config/dealer/daily_tips") then
        createDirectory(work_directory .. "/config/dealer/daily_tips")
    end

    -- Create / load file with info player
    local f = io.open(fpath_player_info, "r")
	if f then
		local content = f:read("*a")
		if content:len() > 0 then
			player_info = decodeJson(content)
		else
			GeneratePlayerInfoFile()
		end
		f:close()
	else
		GeneratePlayerInfoFile()
	end

	-- Create / load file with players tip
    f = io.open(fpath_players_tip, "r")
	if f then
	    local content = f:read("*a")
	    players_tip = decodeJson(content)
	    f:close()
	else
	    f = io.open(fpath_players_tip, "w")
	    f:write('{"None":0}')
	    f:close()
	end

	-- >>
	GenerateFileNameForDailyTop()

	-- Create / load file with players tip for day
	f = io.open(fpath_daily_tips, "r")
	if f then
	    local content = f:read("*a")
	    daily_tips = decodeJson(content)
	    f:close()
	else
	    f = io.open(fpath_daily_tips, "w")
	    f:write('{"None":0}')
	    f:close()
	end
end

-- Samp events
function sampev.onServerMessage(color, message)
	if not toggle_script then 
		return 
	end

	if string.find(message, " �� �������� (.*) ����, �� (.*)]") then
		local money, nick, id = string.match(message, " �� �������� (%d+) ����, �� (.*)%[(%d+)%]")
		money = tonumber(money)
		id = tonumber(id)

		if CheckTable(nick, players_tip, 1) then
		    players_tip[nick] = players_tip[nick] + money
		else
			players_tip[nick] = money
		end

		if GenerateFileNameForDailyTop() then
    		daily_tips = {}
    		daily_tips[nick] = money
    	else
    		if CheckTable(nick, daily_tips, 1) then
				daily_tips[nick] = daily_tips[nick] + money
			else
				daily_tips[nick] = money
			end
    	end

		lua_thread.create(function()
        	wait(1200)
        	sampSendChat(("%s[%d] ������� ������� �� ������ � [%d ���� / �����: %d ����]"):format(nick, id, money, players_tip[nick]))
    	end)

    	local f = io.open(fpath_players_tip, "w")
    	local content = encodeJson(players_tip)
    	f:write(content)
    	f:close()

	    f = io.open(fpath_daily_tips, "w")
	    content = encodeJson(daily_tips)
	    f:write(content)
	    f:close()

	elseif string.find(message, " SMS: mytips. �����������: (.*)") then
		local nick, id = string.match(message, " SMS: mytips. �����������: (.*)%[(%d+)%]")
		local tips = 0
		local tips_day = 0
		if CheckTable(nick, players_tip, 1) then
			tips = players_tip[nick]
		end
		if CheckTable(nick, daily_tips, 1) then
			tips_day = daily_tips[nick]
		end

		lua_thread.create(function()
        	wait(1200)
        	sampSendChat(("������ ������ %s[%d] � [�� �����: %d $ / �����: %d $]"):format(nick, tonumber(id), tips_day, tips))
    	end)
	end
end

-- CMD function's
function dealerHelp()
	local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
	sampAddChatMessage("� {969595}/dealer � ��������/��������� ������", COLOR_SCRIPTMSG)
	sampAddChatMessage("� {969595}/gettips � ��������� ������", COLOR_SCRIPTMSG)
	sampAddChatMessage("� {969595}/toptips � ��������� � ��� ����� ��� �� ������", COLOR_SCRIPTMSG)
	sampAddChatMessage("� {969595}/toptipsday � ��������� � ��� ��� �� ������ �� ����", COLOR_SCRIPTMSG)
	sampAddChatMessage(("� {969595}/sms %d mytips � ������� � ��� ���������� �� ������ ������"):format(id), COLOR_SCRIPTMSG)
	sampAddChatMessage("��� {969595}���������� ������: {cccccc}5536 9138 3677 4212 {969595}(Tinkoff)", COLOR_SCRIPTMSG)
end

function toggleScript()
	if not toggle_script then
		sampAddChatMessage("[SampDealer] {969595}������ �����������. ����� ���������, �������: /dealer", COLOR_SCRIPTMSG)
	else
		sampAddChatMessage("[SampDealer] {969595}������ �������������", COLOR_SCRIPTMSG)
	end
	toggle_script = not toggle_script
end

function getTips()
	if not toggle_script then
		sampAddChatMessage(MSG_SCRIPT_NOT_ACTIVED, COLOR_SCRIPTMSG)
		return
	end

	local total_tips, day_tips = 0, 0
	if players_tip then
		for k, v in pairs(players_tip) do
			total_tips = total_tips + v
		end
	end
	if daily_tips then
		for _, v in pairs(daily_tips) do
			day_tips = day_tips + v
		end
	end
	sampAddChatMessage(("[SampDealer] {969595}���������� � ������ � [�� �����: %d $ / �����: %d $]"):format(day_tips, total_tips), COLOR_SCRIPTMSG)
end

function topTips()
	if not toggle_script then
		sampAddChatMessage(MSG_SCRIPT_NOT_ACTIVED, COLOR_SCRIPTMSG)
		return
	end
	SendTopTips(players_tip, "����� ���")
end

function topTipsDay()
	if not toggle_script then
		sampAddChatMessage(MSG_SCRIPT_NOT_ACTIVED, COLOR_SCRIPTMSG)
		return
	end
	SendTopTips(daily_tips, "��� �� �����")
end

-- Subfunction cmd
function SendTopTips(table_, text_)
	if not table_ then
		sampAddChatMessage("[SampDealer] {969595}���������� � ������ �� �������", COLOR_SCRIPTMSG)
		return
	end

	local arr_keys = {}
	local arr_values = {}
	for k, v in pairs(table_) do
		arr_keys[#arr_keys+1] = k
		arr_values[#arr_values+1] = v
	end

	for i = 1, #arr_values do
		for j = 1, #arr_values do
			if arr_values[i] > arr_values[j] then
				arr_values[i], arr_values[j] = arr_values[j], arr_values[i]
				arr_keys[i], arr_keys[j] = arr_keys[j], arr_keys[i]
			end
		end
	end
	lua_thread.create(function()
		local str = "/do [������ / " .. text_ .. "] "
		if #arr_values then
			str = ("%s 1. %s � %d $"):format(str, arr_keys[1], arr_values[1])
			if #arr_values > 1 then
				str = ("%s / 2. %s � %d $"):format(str, arr_keys[2], arr_values[2])
			end
			sampSendChat(str)
		end
		wait(1500)

		str = "/do [������ / " .. text_ .. "] "
		if #arr_values > 2 then
			str = ("%s 3. %s � %d $"):format(str, arr_keys[3], arr_values[3])
			if #arr_values > 3 then
				str = ("%s / 4. %s � %d $"):format(str, arr_keys[4], arr_values[4])
			end
			sampSendChat(str)
		end

	end)
end

-- Other
function GeneratePlayerInfoFile()
	local s = {
		pDateDailyTop = "01.01.1970"
	}
	local f = io.open(fpath_player_info, "w")
	s = encodeJson(s)
	player_info = decodeJson(s)
	f:write(s)
	f:close()
end

function GenerateFileNameForDailyTop()
	local date = os.date("%d_%m_%Y", os.time())
	fpath_daily_tips = work_directory .. "/config/dealer/daily_tips/" .. date .. ".json"
	if date ~= player_info['pDateDailyTop'] then
		player_info['pDateDailyTop'] = date
		local content = encodeJson(player_info)
		local f = io.open(fpath_player_info, "w")
		f:write(content)
		f:close()
		return true
	end
	return false
end

function CheckTable(arg, table_, mode)
    if mode == 1 then
        for k, v in pairs(table_) do
            if k == arg then
                return true
            end
        end
    else
        for k, v in pairs(table_) do
            if v == arg then
                return true
            end
        end
    end
    return false
end