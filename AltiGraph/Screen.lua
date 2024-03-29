local cell_voltage = 0.0
local rx_voltage = 0.00
local display_rx_voltage, rx_voltage_list = 0.0, {}
local remaining_capacity_percent = 100
local time, ancorTime, newTime, time_scale = 0, 0, 0, 1
local std, min, sec = 0, 0, 0
local next_altitude_announcement, next_voltage_announcement, next_time_announcement = 0, 0, 0
local next_voltage_alarm = 0
local rx_a1, rx_a2, rx_percent = 0, 0, 0
local resetSw_val = 0
local altitude, real_altitude, graph_altitude, altitude_offset, max_altitude, altitude_scale = 0.0, 0.0, 0.0, 0.0, 0.0, 20
local first_average_list, average_list = {}, {}
local altitude_table = {}
local max_table_altitude = 0
local resetOff, tick, display_tick = true, false, false
local next_display_tick = 0
local tickOffset = 0
local climb = 0.0
local display_climb, display_climb_list = 0.0, {}
local i_max = 0
local color = true

local vars = {}

-- maps cell voltages of LiPo to remainig capacity
local percentListLi = {{3,0},{3.093,1},{3.196,2},{3.301,3},{3.401,4},{3.477,5},{3.544,6},{3.601,7},{3.637,8},{3.664,9},
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
 
-- maps cell voltages of NiMH to remainig capacity
local percentListNi = {{1.028,0},{1.087,1},{1.118,2},{1.138,3},{1.153,4},{1.165,5},{1.175,6},{1.183,7},{1.190,8},{1.196,9},
                       {1.202,10},{1.207,11},{1.212,12},{1.216,13},{1.220,14},{1.224,15},{1.228,16},{1.231,17},{1.234,18},
                       {1.237,19},{1.240,20},{1.243,21},{1.245,22},{1.248,23},{1.250,24},{1.252,25},{1.254,26},{1.256,27},
                       {1.258,28},{1.259,29},{1.261,30},{1.263,31},{1.264,32},{1.266,33},{1.267,34},{1.268,35},{1.270,36},
                       {1.270,37},{1.272,38},{1.272,39},{1.274,40},{1.275,41},{1.276,42},{1.276,43},{1.277,44},{1.278,45},
                       {1.279,46},{1.280,47},{1.281,48},{1.282,49},{1.282,50},{1.283,51},{1.284,52},{1.284,53},{1.285,54},
                       {1.285,55},{1.286,56},{1.287,57},{1.287,58},{1.287,59},{1.288,60},{1.288,61},{1.289,62},{1.289,63},
                       {1.290,64},{1.290,65},{1.290,66},{1.291,67},{1.292,68},{1.292,69},{1.292,70},{1.293,71},{1.294,72},
                       {1.294,73},{1.295,74},{1.296,75},{1.298,76},{1.299,77},{1.300,78},{1.302,79},{1.303,80},{1.305,81},
                       {1.308,82},{1.310,83},{1.314,84},{1.317,85},{1.321,86},{1.326,87},{1.331,88},{1.337,89},{1.343,90},
                       {1.351,91},{1.358,92},{1.366,93},{1.375,94},{1.386,95},{1.397,96},{1.410,97},{1.425,98},{1.445,99},
                       {1.487,100}}

local function init (stpvars)

  local device

  device = system.getDeviceType()

  if ( device == "JETI DC-16" or
       device == "JETI DS-16" or
       device == "JETI DC-14" or
       device == "JETI DS-14" or
       device == "JETI DS-12" ) then
    color =  false
  end

  vars = stpvars
  voltage_alarm_dec_thresh = vars.voltage_alarm_thresh / 10
  ancorTime = system.getTimeCounter()
  altitude_table[0] = 0.0

end	
                   
local function average(list)
  local i 
  local sum = 0
  for i in next, list do
    sum = sum + list[i]
  end
  return sum / #list
end

-- Telemetry Page
local function showDisplay()

  local i, v, l, clmb
  local sum_clmb = 0.0
  local r, g, b

  if ( color ) then
    lcd.setColor(0,0,0)
    r,g,b = lcd.getFgColor()
  end

  if ( #display_climb_list == 10 ) then
    table.remove(display_climb_list, 1)
  end	

  display_climb_list[#display_climb_list + 1] = climb

  if ( #rx_voltage_list == 10 ) then
    table.remove(rx_voltage_list, 1)
  end	

  rx_voltage_list[#rx_voltage_list + 1] = rx_voltage	

  if ( display_tick ) then
    display_tick = false
    display_climb = average(display_climb_list)
    display_rx_voltage = average(rx_voltage_list)
  end	

  -- Coordinates
  lcd.drawLine(115, 2, 115, 107)
  lcd.drawLine(115, 107, 315, 107)

  lcd.drawLine(115, 7, 107, 7)

  -- ruler
  for  i = 0, 100 do
    if ( i % 50 == 0 ) then
      l = 10
    elseif (i % 25 == 0 ) then
      l = 7
    elseif (i % 5 == 0 ) then	
      l = 4
    else
      l = 2
    end

    lcd.drawLine(115 + 2 * i, 107, 115 + 2 * i, 107 + l)
  end

  lcd.drawText(107, 109, "0", FONT_MINI)    
  lcd.drawText(163 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 50 ))), 111, string.format("%d", time_scale * 50), FONT_MINI)
  lcd.drawText(212 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 100))), 111, string.format("%d", time_scale * 100), FONT_MINI)
  lcd.drawText(263 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 150 ))), 111, string.format("%d", time_scale * 150), FONT_MINI)
  lcd.drawText(313 - (lcd.getTextWidth(FONT_MINI, string.format("%d", time_scale * 200 ))), 111, string.format("%d", time_scale * 200), FONT_MINI)

  -- max altitude line, draw before graph prevent destroying points of the graph
  if ( color ) then
    lcd.setColor(255,0,0)
    lcd.drawLine (115 + i_max , 107 - math.floor( (max_table_altitude * altitude_scale) + 0.5), 115 + i_max, 107 )
    lcd.setColor(r,g,b)
  else
    lcd.drawFilledRectangle(115 + i_max, 107 - math.floor( (max_table_altitude * altitude_scale) + 0.5), 1, math.floor( (max_table_altitude * altitude_scale) + 0.5), FONT_GRAYED)
  end

  max_table_altitude = 0	-- reinit search of maximum, because data could be compressed inbetween
  -- Graph
  for i,v in pairs(altitude_table) do

    if ( i > 0 and altitude_table[i] and altitude_table[i - 1] ) then

      if ( max_table_altitude < altitude_table[i] ) then
        max_table_altitude = altitude_table[i]
        i_max = i
      end

      lcd.drawLine(115 + i - 1,  107 - math.floor( (altitude_table[i - 1] * altitude_scale ) + 0.5), 115 + i, 107 - math.floor( (v * altitude_scale) + 0.5))

    end
  end

  -- Battery
  lcd.drawRectangle( 10, 122, 52, 16)
  lcd.drawRectangle( 61, 126, 5, 7)

  if ( color ) then
    if ( rx_voltage <= voltage_alarm_dec_thresh ) then
      lcd.setColor(255,0,0)
    else
      lcd.setColor(0,255,0)
    end	
    lcd.drawFilledRectangle( 11, 123, math.floor(remaining_capacity_percent / 2 + 0.5), 14)

    lcd.setColor(r,g,b)
  else
    if ( rx_voltage <= voltage_alarm_dec_thresh ) then
      lcd.drawFilledRectangle( 11, 123, math.floor(remaining_capacity_percent / 2 + 0.5), 14, FONT_GRAYED)
    else
      lcd.drawFilledRectangle( 11, 123, math.floor(remaining_capacity_percent / 2 + 0.5), 14)
    end
  end	

  -- Voltage
  lcd.drawText(50, 141, "V", FONT_NORMAL)
  lcd.drawText(48 - (lcd.getTextWidth(FONT_BIG, string.format("%1.2f", display_rx_voltage))), 139, string.format("%1.2f", display_rx_voltage), FONT_BIG)

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

-- Flight time neu
local function FlightTime()
    
  local timeSw_val = system.getInputsVal(vars.timeSw)
  resetSw_val = system.getInputsVal(vars.resSw)
        
  newTime = system.getTimeCounter()

  if (newTime >= next_display_tick ) then
    display_tick = true
  end

  if (display_tick == false) then
    next_display_tick = newTime + 500
  end

  if (timeSw_val == 1) then

    timeDiff = newTime - (ancorTime + tickOffset)

    if ( timeDiff >= 1000 ) then
      tick = true
      time = time + 1
      if ( time == 360000 ) then -- max 99 hours
        time = 0
      end
      tickOffset = tickOffset + 1000
      std = math.floor(time / 3600)
      min = math.floor(time / 60) - std * 60
      sec = time % 60
    end
  else
    ancorTime = newTime - time * 1000  -- keep previous time     
  end     

  collectgarbage()
end

-- Count percentage from cell voltage
local function get_capacity_remaining()

  -- LiPo
  if (  cell_voltage > 2 ) then
    if (cell_voltage > 4.2 or cell_voltage < 3.00) then
      if (cell_voltage > 4.2)then
        result=100
      end
      if (cell_voltage < 3.00) then
        result=0
      end
    else
      for i,v in ipairs(percentListLi) do
        if ( v[1] >= cell_voltage ) then
          result = v[2]
          break
        end
      end
    end
  -- NiMH	
  else
    if (cell_voltage > 1.445 or cell_voltage < 1.028) then
      if (cell_voltage > 1.445) then
        result=100
      end
      if (cell_voltage < 1.028) then
        result=0
      end
    else		
      for i,v in ipairs(percentListNi) do
        if ( v[1] >= cell_voltage ) then
          result = v[2]
          break
        end
      end
    end	
  end

collectgarbage()
  return result
end

local function loop()

  local anAltitudeGo = system.getInputsVal(vars.anAltiSw)
  local anVoltGo = system.getInputsVal(vars.anVoltSw)
  local txtelemetry
  local i

  FlightTime()

  txtelemetry = system.getTxTelemetry()
  rx_voltage = txtelemetry.rx1Voltage
  rx_percent = txtelemetry.rx1Percent

  rx_a1 = txtelemetry.RSSI[1]
  rx_a2 = txtelemetry.RSSI[2]

  cell_voltage = rx_voltage / vars.cell_count

  remaining_capacity_percent = get_capacity_remaining()

  sensor = system.getSensorValueByID(vars.varioDeviceId, vars.varioSens)
  if(sensor and sensor.valid) then
    climb = sensor.value
    if ( climb == nil ) then
      climb = 0.0
    end
  else
    climb = 0.0
  end
  sensor = system.getSensorValueByID(vars.altitudeDeviceId, vars.altitudeSens)
  if(sensor and sensor.valid) then
--  if(sensor) then
    altitude = sensor.value
    -- altitude = 10

    if (altitude == nil ) then
      altitude = 0.0
    end

    real_altitude = altitude - altitude_offset

--  real_altitude = altitude

    if ( real_altitude < 0.0 ) then real_altitude = 0 end     

    if real_altitude > max_altitude then max_altitude = real_altitude end

    -- keep 29 + 1 values which is maximum near 1 second if loop is called every 20-30ms
    if ( #first_average_list == 30 ) then
      table.remove(first_average_list, 1)
    end

    first_average_list[#first_average_list + 1] = real_altitude

    if ( tick ) then
      tick = false

      graph_altitude = average(first_average_list)

      if ( time <= 200 ) then
        time_scale = 1
        if ( max_altitude > 5 ) then
          altitude_scale = 100 / max_altitude
        end
        altitude_table[time] = graph_altitude
      else
        -- compress data
        if ( #altitude_table == 200 and time <= 6400 ) then
          for i = 1, 100 do
            altitude_table[i-1] = (altitude_table[i-1] + altitude_table[i]) / 2
            table.remove(altitude_table, i)
          end
        end
        average_list[#average_list + 1] = graph_altitude -- collect subsamples
        if ( time <= 400 ) then
          time_scale = 2
          if ( time % 2 == 0 ) then
            if ( max_altitude > 5 ) then
              altitude_scale = 100 / max_altitude
            end
            -- average 
            altitude_table[ ((time - 200) / 2 ) + 100 ] = average(average_list)
            average_list = {}
          end
        elseif ( time <= 800 ) then
          time_scale = 4
          if ( time % 4 == 0 ) then
            if ( max_altitude > 5 ) then
              altitude_scale = 100 / max_altitude
            end
            altitude_table[ ((time - 400) / 4 ) + 100 ] = average(average_list)
            average_list = {}
          end
        elseif ( time <= 1600 ) then
          time_scale = 8
          if ( time % 8 == 0 ) then
            if ( max_altitude > 5 ) then
              altitude_scale = 100 / max_altitude
            end
            altitude_table[ ((time - 800) / 8 ) + 100 ] = average(average_list)
            average_list = {}
          end
        elseif ( time <= 3200 ) then
          time_scale = 16
          if ( time % 16 == 0 ) then
            if ( max_altitude > 5 ) then
              altitude_scale = 100 / max_altitude
            end
            altitude_table[ ((time - 1600) / 16 ) + 100 ] = average(average_list)
            average_list = {}
          end
        elseif ( time <= 6400 ) then
          time_scale = 32
          if ( time % 32 == 0 ) then
            if ( max_altitude > 5 ) then
              altitude_scale = 100 / max_altitude
            end
            altitude_table[ ((time - 3200) / 32 ) + 100 ] = average(average_list)
            average_list = {}
          end
        end
      end
    end

    if(anAltitudeGo == 1 and anVoltGo ~= 1 and newTime >= next_altitude_announcement) then
      system.playNumber(real_altitude, 1, "m", "AltRelat.")
      next_altitude_announcement = newTime + 10000 -- say battery percentage every 10 seconds
    end

    if(anVoltGo == 1 and anAltitudeGo ~= 1 and newTime >= next_voltage_announcement) then
      system.playNumber(rx_voltage, 2, "V", "U Battery")
      next_voltage_announcement = newTime + 10000 -- say battery voltage every 10 seconds
    end

    if(anVoltGo == 1 and anAltitudeGo == 1 and newTime >= next_time_announcement) then
      system.playNumber(std, 1, "h")
      system.playNumber(min, 1, "min")
      system.playNumber(sec, 1, "s")
      next_time_announcement = newTime + 10000 -- say battery voltage every 10 seconds
    end


    if ( rx_voltage <= voltage_alarm_dec_thresh and vars.voltage_alarm_voice ~= "..." and newTime >= next_voltage_alarm ) then
      system.messageBox(vars.trans.voltWarn,2)
      system.playFile(vars.voltage_alarm_voice,AUDIO_QUEUE)
      next_voltage_alarm = newTime + 3000 -- battery voltage alarm every 3 second
    end

  else
    rx_voltage = 0
    display_rx_voltage = 0
    remaining_capacity_percent = 0
    rx_a1 = 0
    rx_a2 = 0
    rx_percent = 0
    real_altitude = 0.0
    average_list = {}
    first_average_list = {}
  end

  if (resetSw_val == 1) then	-- use the edge only because momentary switch is used for flight mode too
    if ( resetOff ) then	-- transition to reset position (edge)
      resetOff = false
      altitude_table = {}
      altitude_table[0] = 0.0
      if (vars.resAlti == 1) then
        altitude_offset = altitude;
      end
      max_altitude = 0
      time = 0
      std = 0
      min = 0
      sec = 0
      ancorTime = newTime
      tickOffset = 0
      altitude_scale = 20				-- 5m full scale
      next_altitude_announcement = 0
      next_voltage_announcement = 0
      next_voltage_alarm = 0
      average_list = {}
      first_average_list = {}
    end
  else
    resetOff = true -- reset transition to reset position
  end

  collectgarbage()
  -- print(collectgarbage("count"))   
end
 
return {

  showDisplay = showDisplay,
  loop = loop,
  init = init,

}

