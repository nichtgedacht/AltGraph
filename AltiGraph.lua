collectgarbage()

local cell_voltage, cell_count = 0.0, 1
local model, owner = " ", " "
local trans, anAltiSw, anVoltSw, anAltitudeGo, anVoltGo
local rx_voltage = 0.00
local capacity, remaining_capacity_percent = 0, 100
local mincur, maxcur = 99.9, 0
local minvtg, maxvtg = 99, 0
local time, lastTime, newTime, time_scale, lastDisplayTime = 0, 0, 0, 1, 0
local std, min, sec = 0, 0, 0
local minrxv, maxrxv, minrxa, maxrxa = 9.9, 0.0, 9.9, 0.0
local next_altitude_announcement, next_voltage_announcement = 0, 0
local voltage_alarm_voice
local voltage_alarm_thresh, voltage_alarm_dec_thresh
local next_voltage_alarm = 0
local rx_a1, rx_a2, rx_percent = 0, 0, 0
local txtelemetry
local climb = 0.0
local altitude, real_altitude, altitude_offset, max_altitude, altitude_scale = 0.0, 0.0, 0.0, 0.0, 20
local altitude_table = {}
local resetOff, tick, display_tick = false, true, true
local display_climb, display_climb_list = 0.0, {}
local sensorId, vario_param, altitude_param
local sensorIndex = 0
local sensor_id_list = {}
local sensor_label_list = {}
local sensor_param_lists = {}


-- maps cell voltages to remainig capacity
local percentList	=	{{3,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},
						{3.679,10},{3.683,11},{3.689,12},{3.692,13},{3.705,14},{3.71,15},{3.713,16},{3.715,17},{3.72,18},
						{3.731,19},{3.735,20},{3.744,21},{3.753,22},{3.756,23},{3.758,24},{3.762,25},{3.767,26},{3.774,27},
						{3.78,28},{3.783,29},{3.786,30},{3.789,31},{3.794,32},{3.797,33},{3.8,34},{3.802,35},{3.805,36},
						{3.808,37},{3.811,38},{3.815,39},{3.818,40},{3.822,41},{3.825,42},{3.829,43},{3.833,44},{3.836,45},
						{3.84,46},{3.843,47},{3.847,48},{3.85,49},{3.854,50},{3.857,51},{3.86,52},{3.863,53},{3.866,54},
						{3.87,55},{3.874,56},{3.879,57},{3.888,58},{3.893,59},{3.897,60},{3.902,61},{3.906,62},{3.911,63},
						{3.918,64},{3.923,65},{3.928,66},{3.939,67},{3.943,68},{3.949,69},{3.955,70},{3.961,71},{3.968,72},
						{3.974,73},{3.981,74},{3.987,75},{3.994,76},{4.001,77},{4.007,78},{4.014,79},{4.021,80},{4.029,81},
						{4.036,82},{4.044,83},{4.052,84},{4.062,85},{4.074,86},{4.085,87},{4.095,88},{4.105,89},{4.111,90},
						{4.116,91},{4.12,92},{4.125,93},{4.129,94},{4.135,95},{4.145,96},{4.176,97},{4.179,98},{4.193,99},
						{4.2,100}}

-- can be used to translate raw values to what jeti displays
--[[						
if (rxa1 > 34) then a1 = 9 else
if (rxa1 > 27) then a1 = 8 else
if (rxa1 > 22) then a1 = 7 else
if (rxa1 > 18) then a1 = 6 else
if (rxa1 > 14) then a1 = 5 else
if (rxa1 > 10) then a1 = 4 else
if (rxa1 > 6) then a1 = 3 else
if (rxa1 > 3) then a1 = 2 else
if (rxa1 > 0) then a1 = 1 else a1 = 0
--]]
                   
-- Read translations
local function setLanguage()
	local lng=system.getLocale()
	local file = io.readall("Apps/Lang/AltiGraph.jsn")
	local obj = json.decode(file)
	if(obj) then
		trans = obj[lng] or obj[obj.default]
	end
end

-- Telemetry Page1
local function Page1(width, height)
	
	local i, v, l, clmb
	local sum_clmb = 0.0
	
	if ( #display_climb_list == 5 ) then
		table.remove(display_climb_list, 1)
	end	
	
	display_climb_list[#display_climb_list + 1] = climb
		
	if ( display_tick ) then
		
		for i,clmb in ipairs(display_climb_list) do
			sum_clmb = sum_clmb + clmb
		end

		display_climb = sum_clmb / #display_climb_list
		display_tick = false
	end	
	
	-- Coordinates
	lcd.drawLine(115, 2, 115, 107)
	lcd.drawLine(115, 107, 315, 107)
	
	lcd.drawLine(115, 7, 107, 7)
	
	-- ruler
	for  i = 0, 100 do
		if ( i % 5 == 0 ) then
			l = 6
		else
			l = 2
		end
		if ( i % 10 == 0 ) then
			l = 10
		end
		lcd.drawLine(115 + 10 * i, 107, 115 + 10 * i, 107 + l)
	end
	
	lcd.drawText(107, 109, "0", FONT_MINI)    
	lcd.drawText(163 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 50 ))), 109, string.format("%d", time_scale * 50), FONT_MINI)
	lcd.drawText(212 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 100))), 109, string.format("%d", time_scale * 100), FONT_MINI)
	lcd.drawText(263 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 150 ))), 109, string.format("%d", time_scale * 150), FONT_MINI)
	lcd.drawText(313 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 200 ))), 109, string.format("%d", time_scale * 200), FONT_MINI)
		
	-- Graph
	for i,v in pairs(altitude_table) do
		
		if ( i > 0 and altitude_table[i] and altitude_table[i - 1] ) then
			
			lcd.drawLine(115 + i - 1,  107 - math.floor( (altitude_table[i - 1] * altitude_scale ) + 0.5), 115 + i, 107 - math.floor( (v * altitude_scale) + 0.5))
			
		end			
	end
	
	-- Battery
	lcd.drawRectangle( 10, 122, 50, 16)
	lcd.drawRectangle( 59, 126, 5, 7)
	lcd.drawFilledRectangle( 10, 122, math.floor(remaining_capacity_percent / 2 + 0.5), 16)
	-- Voltage
	lcd.drawText(50, 141, "V", FONT_NORMAL)
	lcd.drawText(48 - (lcd.getTextWidth(FONT_BIG, string.format("%1.2f", rx_voltage))), 139, string.format("%1.2f", rx_voltage), FONT_BIG)
	
	-- Antenna
	lcd.drawText(83, 139, "A:", FONT_BIG)
	lcd.drawText(81, 121, "Q:", FONT_BIG)
	lcd.drawText(139, 123, "%", FONT_NORMAL)
	
	lcd.drawText(137 - (lcd.getTextWidth(FONT_BIG, string.format("%d", rx_a1))), 139, string.format("%d", rx_a1), FONT_BIG)
	lcd.drawText(167 - (lcd.getTextWidth(FONT_BIG, string.format("%d", rx_a2))), 139, string.format("%d", rx_a2), FONT_BIG)
	lcd.drawText(137 - (lcd.getTextWidth(FONT_BIG, string.format("%d", rx_percent))), 121, string.format("%d", rx_percent), FONT_BIG)
		
	-- Altitude
	lcd.drawText(93, 42, "m", FONT_Normal)
    lcd.drawText(90 - (lcd.getTextWidth(FONT_MAXI, string.format("%3.1f", real_altitude))), 25, string.format("%3.1f", real_altitude), FONT_MAXI)

	-- Climb
	lcd.drawText(93, 71, "m", FONT_NORMAL)
	lcd.drawLine(92, 89, 107, 89)
	lcd.drawText(96, 86, "s", FONT_NORMAL)
    lcd.drawText(90 - (lcd.getTextWidth(FONT_MAXI, string.format("%2.2f", display_climb))), 70, string.format("%2.2f", display_climb), FONT_MAXI)
	
	-- Max Altitude
	lcd.drawText(93, 1, "m", FONT_NORMAL)
    lcd.drawText(90 - (lcd.getTextWidth(FONT_NORMAL, string.format("%3.1f", max_altitude))), 1, string.format("%3.1f", max_altitude), FONT_NORMAL)
		
	-- Time
	lcd.drawText(250 - (lcd.getTextWidth(FONT_MAXI, string.format("%02d:%02d:%02d", std, min, sec)) / 2), 125, string.format("%02d:%02d:%02d",
						std, min, sec), FONT_MAXI)

	collectgarbage()
end

local function sensorChanged(value)
	
	if ( not sensor_id_list[1] ) then	-- no sensors found
		return
	end
	
	sensorId  = sensor_id_list[value]
	system.pSave("sensorId", sensorId)
	sensorIndex = value
	vario_param = 0     -- prevent error if previous index was higher than possible in this new sensor
	altitude_param = 0  -- prevent error if previous index was higher than possible in this new sensor
	form.reinit()
end

local function paramVarioChanged(value)
	vario_param = value
	system.pSave("vario_param", vario_param)
end

local function paramAltitudeChanged(value)
	altitude_param = value
	system.pSave("altitude_param", altitude_param)
end	

local function capacityChanged(value)
	capacity = value
	system.pSave("capacity", capacity)
end

local function cell_countChanged(value)
	cell_count = value
	system.pSave("cell_count", cell_count)
end

local function timeSwChanged(value)
	timeSw = value
	system.pSave("timeSw", timeSw)
end

local function resSwChanged(value)
	resSw = value
	system.pSave("resSw", resSw)
end

local function anVoltSwChanged(value)
	anVoltSw = value
	system.pSave("anVoltSw", anVoltSw)
end

local function anAltiSwChanged(value)
	anAltiSw = value
	system.pSave("anAltiSw", anAltiSw)
end

local function voltage_alarm_threshChanged(value)
	voltage_alarm_thresh=value
	voltage_alarm_dec_thresh = voltage_alarm_thresh / 10
	system.pSave("voltage_alarm_thresh", voltage_alarm_thresh)
end

local function voltage_alarm_voiceChanged(value)
	voltage_alarm_voice=value
	system.pSave("voltage_alarm_voice", voltage_alarm_voice)
end

local function setupForm(formID)
	
	local i, sensor
	
	if ( not sensor_id_list[1] ) then	-- sensors not yet checked or rebooted
		for i,sensor in ipairs(system.getSensors()) do
			if (sensor.param == 0) then	-- new multisensor/device
				sensor_label_list[#sensor_label_list + 1] = sensor.label -- list presented in sensor select box
				sensor_id_list[#sensor_id_list + 1] = sensor.id          -- to get id from if sensor changed, same numeric indexing
				if (sensor.id == sensorId) then
					sensorIndex = #sensor_id_list
				end
				sensor_param_lists[#sensor_param_lists + 1] = {}           -- start new param list only containing label and unit as string
			else                                                         -- subscript is number of param for current multisensor/device
				sensor_param_lists[#sensor_param_lists][sensor.param] = sensor.label .. "  " .. sensor.unit -- list presented in param select box
			end
		end
	end	
			
	form.addRow(1)
    form.addLabel({label=trans.label0,font=FONT_BOLD})
	    
    form.addRow(2)
    form.addLabel({label = "Sensor"})
    form.addSelectbox(sensor_label_list, sensorIndex, true, sensorChanged)
		

	if ( sensor_id_list and sensorIndex > 0 ) then	
		form.addRow(2)
		form.addLabel({label = "Parameter Vario"})
		form.addSelectbox(sensor_param_lists[sensorIndex], vario_param, true, paramVarioChanged)
		
		form.addRow(2)
		form.addLabel({label = trans.paramAlti})
		form.addSelectbox(sensor_param_lists[sensorIndex], altitude_param, true, paramAltitudeChanged)
	end	
		
	form.setTitle(trans.title)
				
	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=trans.label1,font=FONT_BOLD})
	
	form.addRow(2)
	form.addLabel({label=trans.anVoltSw, width=220})
	form.addInputbox(anVoltSw,true,anVoltSwChanged)
	
	form.addRow(2)
	form.addLabel({label=trans.anAltiSw, width=220})
	form.addInputbox(anAltiSw,true,anAltiSwChanged)
	        
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=trans.label3,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=trans.voltAlarmVoice, width=140})
	form.addAudioFilebox(voltage_alarm_voice,voltage_alarm_voiceChanged)
        	
	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=trans.label2,font=FONT_BOLD})
		
	form.addRow(2)
	form.addLabel({label=trans.cellcnt, width=220})
	form.addIntbox(cell_count, 1, 2, 1, 0, 1, cell_countChanged, {label=" S"})
	    
	form.addRow(2)
	form.addLabel({label=trans.voltAlarmThresh, width=220})
	form.addIntbox(voltage_alarm_thresh,0,80,0,1,1,voltage_alarm_threshChanged, {label=" V"})
	
	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=trans.label4,font=FONT_BOLD})
	
	form.addRow(2)
	form.addLabel({label=trans.timeSw, width=220})
	form.addInputbox(timeSw,true,timeSwChanged)
	
	form.addRow(2)
	form.addLabel({label=trans.resSw, width=220})
	form.addInputbox(resSw,true,resSwChanged)
	
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label="AltiGraph " .. Version .. " ", font=FONT_MINI, alignRight=true})
    
	collectgarbage()
end

-- Fligt time
local function FlightTime()
	newTime = system.getTimeCounter()
	local ltimeSw = system.getInputsVal(timeSw)
	resetSw = system.getInputsVal(resSw)
	     
	if (ltimeSw ~= 1) then
		lastTime = newTime -- properly start of first interval
	end

	if (newTime >= lastDisplayTime + 500) then
		display_tick = true
		lastDisplayTime = newTime
	end	
	
	if newTime >= (lastTime + 1000) then  -- one second
		lastTime = newTime
		if (ltimeSw == 1) then 
			time = time + 1
			tick = true
			if ( time == 360000 ) then -- max 99 hours
				time = 0
			end	
		end
	end
	
	std = math.floor(time / 3600)
	min = math.floor(time / 60) - std * 60
	sec = time % 60
	
	collectgarbage()
end
    
-- Count percentage from cell voltage
local function get_capacity_remaining()
	result=0
	if(cell_voltage > 4.2 or cell_voltage < 3.00)then
		if(cell_voltage > 4.2)then
			result=100
		end
		if(cell_voltage < 3.00)then
			result=0
		end
	else
		for i,v in ipairs(percentList) do
			if ( v[1] >= cell_voltage ) then
				result =  v[2]
				break
			end
		end
	end
	collectgarbage()
	return result
end

local function loop()

	local anAltitudeGo = system.getInputsVal(anAltiSw)
	local anVoltGo = system.getInputsVal(anVoltSw)
	local i
	
	FlightTime()
	
	txtelemetry = system.getTxTelemetry()
	rx_voltage = txtelemetry.rx1Voltage
	rx_percent = txtelemetry.rx1Percent
	
	rx_a1 = txtelemetry.RSSI[1]
	rx_a2 = txtelemetry.RSSI[2]
	
	rx_a1 = 66
	rx_a2 = 88
	rx_percent = 100
	
	-- rx_voltage = 3.9
	
	cell_voltage = rx_voltage / cell_count
	
	remaining_capacity_percent = get_capacity_remaining()
	
	sensor = system.getSensorValueByID(sensorId, vario_param)
	if(sensor and sensor.valid) then
		climb = sensor.value
		if ( climb == nil ) then
			climb = 0.0
		end
	else
		climb = 0.0
		display_climb = 0.0
	end
	sensor = system.getSensorValueByID(sensorId, altitude_param)
	if(sensor and sensor.valid) then
		altitude = sensor.value
		if (altitude == nil ) then
			altitude = 0.0
		end
		
		real_altitude = altitude - altitude_offset
		     
		if ( real_altitude < 0.0 ) then real_altitude = 0 end     
		     
		if real_altitude > max_altitude then max_altitude = real_altitude end
		 
		if ( tick ) then
			tick = false
			if ( time <= 200 ) then
				time_scale = 1
				if ( max_altitude > 5 ) then
					altitude_scale = 100 / max_altitude
				end
				altitude_table[time] = real_altitude
			else
				if ( #altitude_table == 200 and time <= 1600 ) then
					for i = 1, 100 do
						table.remove(altitude_table, i)
					end
				end
				if ( time <= 400 ) then
					time_scale = 2
					if ( time % 2 == 0 ) then
						if ( max_altitude > 5 ) then
							altitude_scale = 100 / max_altitude
						end
						altitude_table[ ((time - 200) / 2 ) + 100 ] = real_altitude
					end
				elseif ( time <= 800 ) then
					time_scale = 4
					if ( time % 4 == 0 ) then
						if ( max_altitude > 5 ) then
							altitude_scale = 100 / max_altitude
						end
						altitude_table[ ((time - 400) / 4 ) + 100 ] = real_altitude
					end
				elseif ( time <= 1600 ) then
					time_scale = 8
					if ( time % 8 == 0 ) then
						if ( max_altitude > 5 ) then
							altitude_scale = 100 / max_altitude
						end
						altitude_table[ ((time - 800) / 8 ) + 100 ] = real_altitude
					end
				end
			end
		end
						
		if(anAltitudeGo == 1 and newTime >= next_altitude_announcement) then
			system.playNumber(real_altitude, 1, "m", "AltRelat.")
			next_altitude_announcement = newTime + 10000 -- say battery percentage every 10 seconds
		end
			
		if(anVoltGo == 1 and newTime >= next_voltage_announcement) then
			system.playNumber(rx_voltage + 0.01, 2, "V", "U Battery")
			next_voltage_announcement = newTime + 10000 -- say battery voltage every 10 seconds
		end
		
		if ( rx_voltage <= voltage_alarm_dec_thresh and voltage_alarm_voice ~= "..." and newTime <= next_voltage_alarm ) then
			system.messageBox(trans.voltWarn,2)
			system.playFile(voltage_alarm_voice,AUDIO_QUEUE)
			next_voltage_alarm = newTime + 3000 -- battery voltage alarm every 3 second
		end
			     
	else
		rx_voltage = 0
		rx_a1 = 0
		rx_a2 = 0
		rx_percent = 0
		real_altitude = 0.0
	end
	
	if (resetSw == 1) then    -- use the edge only because momentary switch is used for flight mode too
		if ( resetOff ) then  -- transition to reset position (edge)
			altitude_table = {}
		    altitude_table[0] = 0.0 
			altitude_offset = altitude;
			max_altitude = 0
		    time = 0
			lastTime = system.getTimeCounter()
			altitude_scale = 20
		    resetOff = false
			tick = true
			next_altitude_announcement = 0
			next_voltage_announcement = 0
			next_voltage_alarm = 0
		end
	else
		resetOff = true -- reset transition to reset position
	end
		     
	collectgarbage()
	-- print(collectgarbage("count"))   
end

local function init(code)
	model = system.getProperty("Model")
	owner = system.getUserName()
	cell_count = system.pLoad("cell_count",1)
	voltage_alarm_thresh = system.pLoad("voltage_alarm_thresh",0)
	voltage_alarm_dec_thresh = voltage_alarm_thresh / 10             
	voltage_alarm_voice = system.pLoad("voltage_alarm_voice","...")
	timeSw = system.pLoad("timeSw")
	resSw = system.pLoad("resSw")
	anAltiSw = system.pLoad("anAltiSw")
	anVoltSw = system.pLoad("anVoltSw")
	altitude_table[0] = 0.0
	
	vario_param = system.pLoad("vario_param", 0)
	altitude_param = system.pLoad("altitude_param", 0)
	sensorId = system.pLoad("sensorId", 0)

	system.registerForm(1, MENU_APPS, trans.appName, setupForm)
	system.registerTelemetry(1, trans.appName .. "   " .. model, 4, Page1) --registers a full size Window
	
	collectgarbage()
end

Version = "1.3"
setLanguage()
collectgarbage()
return {init=init, loop=loop, author="nichtgedacht", version=Version, name=trans.appName}
