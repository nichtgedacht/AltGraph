local deviceLabel_list = {}
local deviceId_list = {}
local sensor_lists = {}
local deviceIndex = 0

local function make_lists(deviceId)
	local sensor, i
	if ( not deviceId_list[1] ) then	-- sensors not yet checked or rebooted
		for i,sensor in ipairs(system.getSensors()) do
			if (sensor.param == 0) then	-- new multisensor/device
				deviceLabel_list[#deviceLabel_list + 1] = sensor.label	-- list presented in device select box
				deviceId_list[#deviceId_list + 1] = sensor.id			-- to get id from if sensor changed, same numeric indexing
				if (sensor.id == deviceId) then
					deviceIndex = #deviceId_list
				end
				sensor_lists[#sensor_lists + 1] = {}					-- start new param list only containing label and unit as string
			else														-- subscript is number of param for current multisensor/device
				sensor_lists[#sensor_lists][sensor.param] = sensor.label .. "  " .. sensor.unit -- list presented in sensor select box
			end
		end
	end	
end


local function setup(vars)

	local i, sensor	--	sensor is a list of sensor lists (parameters)
		
	make_lists(vars.deviceId)
			
	form.addRow(1)
    form.addLabel({label=vars.trans.label0,font=FONT_BOLD})
	    
    form.addRow(2)
    form.addLabel({label = vars.trans.labelp0})
    form.addSelectbox(deviceLabel_list, deviceIndex, true,
						function (value)
							if ( not deviceId_list[1] ) then	-- no sensors found
								return
							end
							vars.deviceId  = deviceId_list[value]
							system.pSave("deviceId", vars.deviceId)
							deviceIndex = value
							vars.varioSens = 0     -- prevent error if previous index was higher than possible in this new sensor
							vars.altitudeSens = 0  -- prevent error if previous index was higher than possible in this new sensor
							form.reinit()
						end )

	if ( deviceId_list and deviceIndex > 0 ) then	
		form.addRow(2)
		form.addLabel({label = vars.trans.labelp1})
		form.addSelectbox(sensor_lists[deviceIndex], vars.varioSens, true,
						function (value)
							vars.varioSens = value
							system.pSave("varioSens", vars.varioSens)
						end )
		
		form.addRow(2)
		form.addLabel({label = vars.trans.labelp2})
		form.addSelectbox(sensor_lists[deviceIndex], vars.altitudeSens, true,
							function (value)
								vars.altitudeSens = value
								system.pSave("altitudeSens", vars.altitudeSens)
							end )	
	end	
		
	form.setTitle(vars.trans.title)
				
	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=vars.trans.label1,font=FONT_BOLD})
	
	form.addRow(2)
	form.addLabel({label=vars.trans.anVoltSw, width=220})
	form.addInputbox(vars.anVoltSw,true,
						function (value)
							vars.anVoltSw = value
							system.pSave("anVoltSw", vars.anVoltSw)
						end )
	
	form.addRow(2)
	form.addLabel({label=vars.trans.anAltiSw, width=220})
	form.addInputbox(vars.anAltiSw,true,
						function (value)
							vars.anAltiSw = value
							system.pSave("anAltiSw", vars.anAltiSw)
						end )
	        
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label=vars.trans.label3,font=FONT_BOLD})

	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmVoice})
	form.addAudioFilebox(vars.voltage_alarm_voice,
						function (value)
							vars.voltage_alarm_voice = value
							system.pSave("voltage_alarm_voice", vars.voltage_alarm_voice)
						end )

	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=vars.trans.label2,font=FONT_BOLD})
		
	form.addRow(2)
	form.addLabel({label=vars.trans.cellcnt, width=220})
	form.addIntbox(vars.cell_count, 1, 4, 1, 0, 1,
						function (value)
							vars.cell_count = value
							system.pSave("cell_count", vars.cell_count)
						end, {label=" S"} )
	    
	form.addRow(2)
	form.addLabel({label=vars.trans.voltAlarmThresh, width=220})
	form.addIntbox(vars.voltage_alarm_thresh,0,80,0,1,1,
						function (value)
							vars.voltage_alarm_thresh = value
							system.pSave("voltage_alarm_thresh", vars.voltage_alarm_thresh)
						end, {label=" V"})
	
	form.addSpacer(318,7)
	
	form.addRow(1)
	form.addLabel({label=vars.trans.label4,font=FONT_BOLD})
	
	form.addRow(2)
	form.addLabel({label=vars.trans.timeSw, width=220})
	form.addInputbox(vars.timeSw,true,
						function (value)
							vars.timeSw = value
							system.pSave("timeSw", vars.timeSw)
						end )
	
	form.addRow(2)
	form.addLabel({label=vars.trans.resSw, width=220})
	form.addInputbox(vars.resSw,true,
						function (value)
							vars.resSw = value
							system.pSave("resSw", vars.resSw)
						end )
	
	form.addSpacer(318,7)

	form.addRow(1)
	form.addLabel({label="AltiGraph " .. vars.Version .. " ", font=FONT_MINI, alignRight=true})
    
	collectgarbage()
	return (vars)
end
 
return {
	setup = setup
}

