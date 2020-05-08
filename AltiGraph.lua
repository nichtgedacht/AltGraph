collectgarbage()

local setupvars = {}
setupvars.Version = "2.0"
local model, owner = " ", " "
local trans
--local mem, maxmem = 0, 0 -- for debug only
local goregisterTelemetry = nil
local Form, Screen
                   
-- Read translations
local function setLanguage()
	local lng=system.getLocale()
	local file = io.readall("Apps/Lang/AltiGraph.jsn")
	local obj = json.decode(file)
	if(obj) then
		trans = obj[lng] or obj[obj.default]
	end
end

-- Telemetry Page
local function Window()

	Screen.showDisplay()

end

-- remove unused module
local function unrequire(module)
	package.loaded[module] = nil
	_G[module] = nil
end

-- switch to setup context
local function setupForm(formID)
	
	Screen = nil					-- comment out if closeForm not available
	unrequire("AltiGraph/Screen")	-- comment out if closeForm not available
	system.unregisterTelemetry(1)	-- comment out if closeForm not available
	
	collectgarbage()

	Form = require "AltiGraph/Form"

	-- return modified data from user
	setupvars = Form.setup(setupvars)

	collectgarbage()
end

-- switch to telemetry context
local function closeForm()

	Form = nil
	unrequire("AltiGraph/Form")
	
	collectgarbage()
	
	-- register telemetry window again after 500 ms
	goregisterTelemetry = 500 + system.getTimeCounter() -- used in loop()
	
	collectgarbage()

end

local function loop()
	
	-- code of loop from screen module
	if ( Screen ) then
		Screen.loop()
	end

	-- register telemetry display again after form was closed 
	if ( goregisterTelemetry and system.getTimeCounter() > goregisterTelemetry ) then
		
		Screen = require "AltiGraph/Screen"
		Screen.init(setupvars)

		system.registerTelemetry(1, trans.appName .. " " .. setupvars.Version .. "    " .. model, 4, Window) --registers a full size Window
		goregisterTelemetry = nil
		
	end

	-- debug, memory usage
	--mem = math.modf(collectgarbage("count")) + 1
	--if ( maxmem < mem ) then
	--	maxmem = mem
	--	print (maxmem)
	--end

	collectgarbage()
end

local function init()
	model = system.getProperty("Model")
	owner = system.getUserName()
	
	setupvars.cell_count = system.pLoad("cell_count",1)
	setupvars.voltage_alarm_thresh = system.pLoad("voltage_alarm_thresh",0)
	setupvars.voltage_alarm_voice = system.pLoad("voltage_alarm_voice","...")
	setupvars.timeSw = system.pLoad("timeSw")
	setupvars.resSw = system.pLoad("resSw")
	setupvars.anAltiSw = system.pLoad("anAltiSw")
	setupvars.anVoltSw = system.pLoad("anVoltSw")
	setupvars.varioSens = system.pLoad("varioSens", 0)
	setupvars.altitudeSens = system.pLoad("altitudeSens", 0)
	setupvars.deviceId = system.pLoad("deviceId", 0)
	
	setupvars.trans = trans
	
	Screen = require "AltiGraph/Screen"
	Screen.init(setupvars)
	
	system.registerForm(1, MENU_APPS, trans.appName, setupForm, nil, nil, closeForm)
	system.registerTelemetry(1, trans.appName .. " " .. setupvars.Version .. "    " .. model, 4, Window) --registers a full size Window
	
	collectgarbage()
end

setLanguage()
collectgarbage()
return {init=init, loop=loop, author="nichtgedacht", version=setupvars.Version, name=trans.appName}
