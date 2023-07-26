local function setup(vars)

  local sensorList = {}
  local selectList={}
  local varioIndex = -1
  local altitudeIndex = -1
  
  for index,sensor in ipairs(system.getSensors()) do
    if(sensor.param > 0) then
      -- both lists have same index and contain sensors only
      selectList[#selectList+1] = string.format("%s - %s", sensor.sensorName, sensor.label)
      sensorList[#sensorList+1] = sensor
      -- regenerate index even if other sensors or whole devices were enabled disabled
      if (sensor.param == vars.altitudeSens and sensor.id == vars.altitudeDeviceId) then
        altitudeIndex = #sensorList
      end
      -- regenerate index even if other sensors or whole devices were enabled disabled
      if (sensor.param == vars.varioSens and sensor.id == vars.varioDeviceId) then
        varioIndex = #sensorList
      end
    end
  end
  
  form.addRow(1)
  form.addLabel({label=vars.trans.label0,font=FONT_BOLD})
    
  form.addRow(2)
  form.addLabel({label = vars.trans.labelp1, width=85})
  form.addSelectbox (selectList, varioIndex, true,
            function (value)
              if value>0 then
                vars.varioDeviceId  = sensorList[value].id
                system.pSave("varioDeviceId", vars.varioDeviceId)
                vars.varioSens = sensorList[value].param
                system.pSave("varioSens", vars.varioSens)
               end      
            end, {alignRight = false, width = 240} )
      
  form.addRow(2)
  form.addLabel({label = vars.trans.labelp2, width=85})
  form.addSelectbox (selectList, altitudeIndex, true,
            function (value)
              if value>0 then
                vars.altitudeDeviceId  = sensorList[value].id
                system.pSave("altitudeDeviceId", vars.altitudeDeviceId)
                vars.altitudeSens = sensorList[value].param
                system.pSave("altitudeSens", vars.altitudeSens)
              end      
            end, {alignRight = false, width = 240} )
    
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

