require("util")
require("lib/utilities")
require("lib/strings")
require("lib/conditions")

local initialized = false
local EOL = "\r\n"
local status = global.ccLoggerStatus

defines.wire_type.combined = 10

local function initGlob()
  global = global or {}
  global.ccLoggers = global.ccLoggers or {}
--  global.ccLoggerSet = global.ccLoggerSet or {}
  global.ccLoggerStatus = global.ccLoggerStatus or {logging = false, to_dump = {}, ignored_signals = {}, trigger_off_after = false, trigger_off_ticks = ""}
  status = global.ccLoggerStatus
end

-- start logging if it is stopped
local function trigger_on(event, trigger_name)
  if status.logging == false then
    status.logging = true
    status.last_trigger_on = event.tick
    status.current_log = {}
    status.current_log.start_tick = event.tick
    status.current_log.trigger_on_name = trigger_name
    status.current_log.data = {}
    status.current_log.changes = {} --key is tick of some change in signals, value is always true
    status.current_log.count = 0 
    status.current_log.last_logged_tick = 0
    for _,ccLogger in ipairs(global.ccLoggers) do
      ccLogger.last_signals = { [defines.wire_type.red] = {}, [defines.wire_type.green] = {} }
      ccLogger.current_log = { data = {}, start_tick = event.tick, used_signals = { [defines.wire_type.red] = {}, [defines.wire_type.green] = {} } }
    end
    
    update_gui_players()
  end
end

-- stop logging if it was started and marks logged signals to be dumped into a file
local function trigger_off(event, trigger_name)
  if status.logging == true then
    status.logging = false
    status.current_log.end_tick = event.tick
    status.current_log.trigger_off_name = trigger_name
    table.insert(status.to_dump, status.current_log)
    status.current_log = nil
    status.last_log = {trigger_off_name = trigger_name}
    for _,ccLogger in ipairs(global.ccLoggers) do
      ccLogger.last_signals = { [defines.wire_type.red] = {}, [defines.wire_type.green] = {} }
      ccLogger.to_dump = {} or ccLogger.to_dump
      table.insert(ccLogger.to_dump, ccLogger.current_log)
      ccLogger.current_log = nil
    end
    
    update_gui_players()
  end
end

local function get_ccLogger_log(ccLogger, start_tick)
  local log = ccLogger.to_dump[1]
  while log ~= nil do
    if log.start_tick==start_tick then
      return log
    elseif log.start_tick>start_tick then
      return nil 
    end
    
    table.remove(ccLogger.to_dump,1)
    log = ccLogger.to_dump[1]
  end
  return nil
end

local function add_csv_text(text, csv_line, csv_columns, position)
  while csv_columns<position do
    csv_line = csv_line .. ";"
    csv_columns = csv_columns+1
  end  
  csv_line = csv_line .. text .. ";"
  csv_columns = csv_columns+1
  return csv_line, csv_columns
end

local function get_signals_header(signals, csv_line, csv_columns, csv_position, ccLogger)
  local first = false
  local aliases = ccLogger.signal_aliases or {}
  local binary = ccLogger.binary_signals or {}
  for name,_ in pairs(signals) do
    if (binary[name] ~= nil) then
      for i,binName in pairs(binary[name]) do
        if (not first) then
          first = true
          csv_line, csv_columns = add_csv_text(binName .. "(" .. i .. ")", csv_line, csv_columns, csv_position)
        else
          csv_line = csv_line .. binName .. "(" .. i .. ")" .. ';'
          csv_columns = csv_columns + 1  
        end
      end  
    elseif (aliases[name] ~= nil) then
      name = aliases[name]
    end
    
    if (not first) then
      first = true
      csv_line, csv_columns = add_csv_text(name, csv_line, csv_columns, csv_position)
    else
      csv_line = csv_line .. name .. ';'
      csv_columns = csv_columns + 1  
    end
  end
  
  return csv_line, csv_columns
end

local function combine_signals(signalsA, signalsB)
  combined = {}
  for name,count in pairs(signalsA) do
    combined[name] = count
  end
  
  for name,count in pairs(signalsB) do
    if (combined[name] ~= nil) then
      combined[name] = combined[name] + count
    else
      combined[name] = count
    end
  end  
  
  return combined
end

local function get_dump_headers(start_tick)
  local headerLoggers = ";Logger name:;"
  local headerWires = ";Wire:;"
  local headerSignals = "Game tick;Play Time;"
  local headerLoggersC = 2
  local headerWiresC = 2
  local headerSignalsC = 2
  for i,ccLogger in ipairs(global.ccLoggers) do
    log = get_ccLogger_log(ccLogger, start_tick)    
    if log ~= nil then
      ccLogger.current_dump_log = log
      local name = ccLogger.name
      if ccLogger.name == nil or ccLogger.name == "" then name = i end
      headerLoggers, headerLoggersC = add_csv_text(name, headerLoggers, headerLoggersC, math.max(headerWiresC, headerSignalsC))
      
      if (ccLogger.log_red) then
        local signals = log.used_signals[defines.wire_type.red]
        headerWires, headerWiresC = add_csv_text("Red", headerWires, headerWiresC, math.max(headerLoggersC-1, headerSignalsC))
        headerSignals, headerSignalsC = get_signals_header(signals, headerSignals, headerSignalsC, headerWiresC-1, ccLogger)
      end  
      if (ccLogger.log_green) then
        local signals = log.used_signals[defines.wire_type.green]
        headerWires, headerWiresC = add_csv_text("Green", headerWires, headerWiresC, math.max(headerLoggersC-1, headerSignalsC))
        headerSignals, headerSignalsC = get_signals_header(signals, headerSignals, headerSignalsC, headerWiresC-1, ccLogger)
      end  
      if (ccLogger.log_combined) then
        local signals = combine_signals(log.used_signals[defines.wire_type.red],log.used_signals[defines.wire_type.green])
        headerWires, headerWiresC = add_csv_text("Combined", headerWires, headerWiresC, math.max(headerLoggersC-1, headerSignalsC))
        headerSignals, headerSignalsC = get_signals_header(signals, headerSignals, headerSignalsC, headerWiresC-1, ccLogger)
        
        log.used_signals[defines.wire_type.combined] = signals
      end  
    end
  end
  
  return headerLoggers .. EOL .. headerWires .. EOL .. headerSignals
end

local function update_logged_signals_values(signals,changeData)
  if (changeData ~= nil) then
    for name,count in pairs(changeData) do
      signals[name] = count
    end
  end
end

local function get_signal_values_csv(signals,binary_signals_def)
  local csv = ""
  for name,count in pairs(signals) do
    if (binary_signals_def ~= nil and binary_signals_def[name] ~= nil) then
      local bin = to_binary(count)
      for i,_ in pairs(binary_signals_def[name]) do
        if (bin[i] ~= nil) then v = bin[i] else v = 0 end
        csv = csv .. v .. ';'
      end
    end
    csv = csv .. count .. ';'
  end
  if csv == "" then csv = ";" end
  return csv
end

local function get_dump_line(change_tick, start_tick)
  local line = change_tick .. ';' .. get_fmt_play_time(change_tick) .. ';'
  for i,ccLogger in ipairs(global.ccLoggers) do
    local log = ccLogger.current_dump_log    
    if log ~= nil then
      local data_change = log.data[change_tick] or {}
      local used_signals = log.used_signals
      if (ccLogger.log_red) then
        update_logged_signals_values(used_signals[defines.wire_type.red],data_change[defines.wire_type.red])
        line = line .. get_signal_values_csv(used_signals[defines.wire_type.red],ccLogger.binary_signals)   
      end      
      if (ccLogger.log_green) then
        update_logged_signals_values(used_signals[defines.wire_type.green],data_change[defines.wire_type.green])
        line = line .. get_signal_values_csv(used_signals[defines.wire_type.green],ccLogger.binary_signals)   
      end      
      if (ccLogger.log_combined) then
        used_signals[defines.wire_type.combined] = combine_signals(used_signals[defines.wire_type.red],used_signals[defines.wire_type.green])
        line = line .. get_signal_values_csv(used_signals[defines.wire_type.combined],ccLogger.binary_signals)   
      end      
    end
  end
  
  return line
end 

-- dumps first pending log to a file
local function dump_pending()
  if (#status.to_dump>0) then
    local log = status.to_dump[1]
    local filename = log.start_tick .. "-" .. log.end_tick
    
    local pt_st = get_fmt_play_time(log.start_tick)
    local pt_end = get_fmt_play_time(log.end_tick)
    
    data = "Start tick: ".. log.start_tick .. "(" .. pt_st .. ")" .. EOL
    data = data .. "End tick: " .. log.end_tick .. "(" .. pt_end .. ")" .. EOL
    data = data .. "Trigger on: " .. log.trigger_on_name .. EOL
    data = data .. "Trigger off: " .. log.trigger_off_name .. EOL
    
    data = data .. get_dump_headers(log.start_tick) .. EOL
    
    for tick,_ in pairs(log.changes) do
      data = data .. get_dump_line(tick, log.start_tick) .. EOL
    end
    
   	game.write_file("circuit_logger/" .. filename .. ".csv", data)

    table.remove(status.to_dump, 1)
  end
end

-- logs different signals into log table
local function log_diff_signals(diff_signals, ccLogger, wire_type, tick)
  local data = ccLogger.current_log.data
  data[tick] = data[tick] or {}
  data[tick][wire_type] = diff_signals
  status.current_log.changes[tick] = true
  add_to_signal_list(diff_signals, ccLogger.current_log.used_signals, wire_type)
  if (tick ~= status.current_log.last_logged_tick) then
    status.current_log.last_logged_tick = tick
    status.current_log.count = status.current_log.count + 1
  end 
end

-- logs signals of one wire of logger, returns true if there is some change of signals
local function log_logger_wire(ccLogger,wire_type,tick)
  local signals_new = get_wire_signals(ccLogger.entity, wire_type)
  local signals_old = ccLogger.last_signals[wire_type]
  
  if (signals_new == nil) then
    signals_new = {}
  end 
  if (not compare_signals(signals_old, signals_new)) then
    local diff = changed_signals(signals_old, signals_new, ccLogger.ignored_signals)
    if (diff ~= false) then
      log_diff_signals(diff, ccLogger, wire_type, tick)
    end  
    ccLogger.last_signals[wire_type] = signals_new
  end
end

-- logs circuit signals of one logger 
local function log_logger_signals(ccLogger,tick)
  if (ccLogger.log_green or ccLogger.log_combined) then
    log_logger_wire(ccLogger, defines.wire_type.green, tick)
  end
  if (ccLogger.log_red or ccLogger.log_combined) then
    log_logger_wire(ccLogger, defines.wire_type.red, tick)
  end
end

-- logs circuit signals of all connected loggers
local function log_loggers_signals(event)
  if (status.logging) then 
    for _,ccLogger in ipairs(global.ccLoggers) do
      log_logger_signals(ccLogger, event.tick)
    end
  end  
end

local function remove_invalid_loggers()
  for i=#global.ccLoggers,1,-1 do
    if not is_valid(global.ccLoggers[i].entity) then
      debugDump("Removed logger "..i, true)
      table.remove(global.ccLoggers, i)
    end
  end
end

local function check_trigger_conditions(event)
  local is_trigger_off = false
  local is_trigger_on = false
  local logging_on = false
  local trigger_on_name = {}
  local trigger_off_name = {}
  
  --check loggers circuit contitions
  for i,ccLogger in ipairs(global.ccLoggers) do
    if (ccLogger.trigger_on or ccLogger.trigger_off or ccLogger.logging_on) and is_valid(ccLogger.entity) then
      local cond_state = get_condition_state(ccLogger.entity)
      if (cond_state and ccLogger.logging_on) then
        logging_on = true
        if (not status.logging) then
          is_trigger_on = true
          table.insert(trigger_on_name, ccLogger.name or ("#"..i))
        end   
      end
      if (cond_state and not ccLogger.last_condition_state) then
        -- condition was just met
        if (ccLogger.trigger_on) then 
          is_trigger_on = true 
          table.insert(trigger_on_name, ccLogger.name or ("#"..i)) 
        end
        if (not logging_on and ccLogger.trigger_off) then 
          is_trigger_off = true
          table.insert(trigger_off_name, ccLogger.name or ("#"..i)) 
        end
      elseif (not cond_state and ccLogger.last_condition_state) then
       -- condition is now not fulfilled
        if (ccLogger.logging_on and not logging_on) then
          is_trigger_off = true
          table.insert(trigger_off_name, ccLogger.name or ("#"..i)) 
        end    
      end
      ccLogger.last_condition_state = cond_state
    end    
  end
  
  -- check global time based off trigger
  if is_trigger_off == false and status.logging and status.trigger_off_after and not is_trigger_on and not logging_on and status.last_trigger_on+status.trigger_off_ticks<=event.tick then
    is_trigger_off = true
    table.insert(trigger_off_name, "Time")
  end
  
  if (is_trigger_off and not logging_on and status.logging) then
    trigger_off(event, join(trigger_off_name,","))
  end
  if (is_trigger_on and not status.logging) then
    trigger_on(event, join(trigger_on_name,","))
  end
  if (is_trigger_on or is_logging) then
    status.last_trigger_on = event.tick
  end
end

-- ---------------- EVENTS --------------------- 

function on_tick(event)  
	if global.ccLoggers == nil or #global.ccLoggers == 0 then return end
  
  if (not initialized) then
    initGlob()
  	for _, player in pairs(game.players) do
  		init_gui(player)
	  end
    
    remove_invalid_loggers()
    initialized = true
  end
	
	if event.tick%10==7 then
		for _,player in pairs(game.players) do
			if is_valid(player.opened) and player.opened.name == "circuit-logger" then
				if not player.gui.left.circuit_logger then
					new_ccLogger_gui(player, find_ccLogger(global.ccLoggers,player.opened))
				end
			elseif player.gui.left.circuit_logger ~= nil then
				player.gui.left.circuit_logger.destroy()
			end
		end
	end

  check_trigger_conditions(event)
  
  if status.logging then
    log_loggers_signals(event)
  end
  
	if (event.tick%30==17) and (#status.to_dump>0) then
    dump_pending()
  end
  
	if (event.tick%60==42) and status.logging then
    update_gui_players(true)
  end  
    
end

function on_gui_click(event)
	local player = game.players[event.player_index]
	local element = event.element
  local name = element.name
  
	local entity
	if is_valid(player.opened) and player.opened.name == "circuit-logger" then
		entity = player.opened
	end
	
	if entity ~= nil and name == "ccl_save" then
		ccLogger = find_ccLogger(global.ccLoggers,player.opened)
		update_ccLogger(player.gui.left.circuit_logger,ccLogger)
		ccLogger.last_condition_state = false
	elseif (name == "circuit-logger-button") then
		expand_gui(player)
	elseif (name == "circuit_logger_trigger_on") then
		trigger_on(event, "Manually")
	elseif (name == "circuit_logger_trigger_off") then
		trigger_off(event, "Manually")
	elseif (name == "ccl_save_settings") then
		update_settings(player)
  end  
	
end 

function on_init()
  initGlob()
	for _, player in pairs(game.players) do
		init_gui(player)
	end
end

function on_configuration_changed(event)
  initGlob()
	for _, player in pairs(game.players) do
		init_gui(player)
	end
end

function on_remove_entity(event)
  remove_invalid_loggers()
end

function on_built_entity(event)
	if is_valid(event.created_entity) and event.created_entity.name == "circuit-logger" then
		
		ccLogger = {}
		ccLogger.trigger_on = false
		ccLogger.trigger_off = false
		ccLogger.logging_on = false
    ccLogger.name = ""
    ccLogger.log_red = false
    ccLogger.log_green = false
    ccLogger.log_combined = false
    ccLogger.disabled = false
    
		ccLogger.entity = event.created_entity
		ccLogger.position = event.created_entity.position
		
		ccLogger.last_condition_state = false
		ccLogger.condition_state = false
    ccLogger.current_log = {}
    ccLogger.to_dump = {}
    ccLogger.ignored_signals = {}
    ccLogger.signal_aliases = {}
    ccLogger.binary_signals = {}
		
		player = ccLogger.player
		ccLogger.surface = ccLogger.entity.surface
		surface = ccLogger.surface
		
		table.insert(global.ccLoggers,ccLogger)
	end
	
end


script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_tick, on_tick)

script.on_init(on_init)
script.on_configuration_changed(on_configuration_changed)

script.on_event(defines.events.on_built_entity, on_built_entity)
script.on_event(defines.events.on_robot_built_entity, on_built_entity)

script.on_event(defines.events.on_entity_died, on_remove_entity)
script.on_event(defines.events.on_player_mined_item, on_remove_entity)
script.on_event(defines.events.on_robot_mined, on_remove_entity)

script.on_event(defines.events.on_research_finished, function(event)
	if (event.research.name == "circuit-logger") then
		for _, player in pairs(game.players) do
			if (event.research.force.name == player.force.name) then
				init_gui(player)
			end
		end
	end
end)

-- ----------- GUI --------------------

function get_status_text()
  local txtStatus
  if (status.logging) then txtStatus = {"status-logging"} else txtStatus = {"status-stopped"} end
  return txtStatus
end

function get_trigger_text()
  if (status.logging) then 
    return status.current_log.trigger_on_name
  else
    if (status.last_log ~= nil) then
      return status.last_log.trigger_off_name
    end  
  end  
  return ""
end

function get_count_records()
  if (status.logging) then 
    return status.current_log.count
  else  
    return ""
  end  
end

function init_gui(player)
	if (not player.force.technologies["circuit-logger"].researched) then
		return
	end

	if (not player.gui.top["circuit-logger-button"]) then
		player.gui.top.add{type="button", name="circuit-logger-button", style="circuit-logger-button-main"}
	end
end

function expand_gui(player)
	local frame = player.gui.left.circuit_logger_settings
	if (frame) then
		frame.destroy()
	else
		frame = player.gui.left.add{type="frame", name="circuit_logger_settings", direction="vertical", caption={"dlg-settings"}}
    
		status_fl = frame.add{type="flow", name="status_fl", direction="horizontal"}
		status_fl.add{type="label", name="circuit_logger_status_label", caption={"circuit-logger-status"}}        
		status_fl.add{type="label", name="circuit_logger_status", caption=get_status_text()}
		status_fl.add{type="label", caption="("}
		status_fl.add{type="label", name="circuit_logger_trigger_name", caption=get_trigger_text()}
		status_fl.add{type="label", caption="), "}
		status_fl.add{type="label", caption={"logged-records"}}
		status_fl.add{type="label", name="circuit_logger_records", caption=get_count_records()}

		trigger_fl = frame.add{type="flow", name="trigger_fl", direction="horizontal"}
		trigger_fl.add{type="checkbox", name="ccl_trigger_off_after", caption={"trigger-off-after-ticks"}, state = status.trigger_off_after==true}
		trigger_fl.add{type="textfield", name="ccl_trigger_off_ticks", text = status.trigger_off_ticks, style="number_textbox_style_circuit_logger"}

		ignored_fl = frame.add{type="flow", name="ignored_fl", direction="horizontal"}
		ignored_fl.add{type="label", caption={"ignored-signals-caption"}}        
		ignored_fl.add{type="textfield", name="ccl_ignored_main", text=join(status.ignored_signals,","), style="wide_textbox_style_circuit_logger"}


    
		buttons = frame.add{type="flow", name="buttons", direction="horizontal"}
		buttons.add{type="button", name="ccl_save_settings", caption={"msg-button-save"}}
		buttons.add{type="button", name="circuit_logger_trigger_on", caption={"msg-checkbox-trigger-on"}}
		buttons.add{type="button", name="circuit_logger_trigger_off", caption={"msg-checkbox-trigger-off"}}
	end
end

function update_settings(player)
  local frame = player.gui.left.circuit_logger_settings
  if (frame) then
    status.ignored_signals = split_string(frame.ignored_fl.ccl_ignored_main.text, ",")
    status.trigger_off_ticks = tonumber(frame.trigger_fl.ccl_trigger_off_ticks.text)
    if status.trigger_off_ticks~=nil then
      if status.trigger_off_ticks<1 then status.trigger_off_ticks = 1 end
      status.trigger_off_after = frame.trigger_fl.ccl_trigger_off_after.state
    else
      status.trigger_off_after = false
      status.trigger_off_ticks = ""                 
    end
    
    update_gui_players()
  end
end

function update_gui_players(only_info)
  for _,player in pairs(game.players) do
    update_gui(player, only_info)
  end
end

function update_gui(player, only_info)
  local frame = player.gui.left.circuit_logger_settings
  if (frame) then
    frame.status_fl.circuit_logger_status.caption = get_status_text() 
    frame.status_fl.circuit_logger_trigger_name.caption = get_trigger_text() 
    frame.status_fl.circuit_logger_records.caption = get_count_records()
    if (not only_info) then 
      frame.trigger_fl.ccl_trigger_off_after.state = status.trigger_off_after
      frame.trigger_fl.ccl_trigger_off_ticks.text = status.trigger_off_ticks or ""
    end  
  end
  local btn = player.gui.top["circuit-logger-button"]
  if (status.logging) then
    btn.style = "circuit-logger-button-main-on"
  else
    btn.style = "circuit-logger-button-main"
  end  
     
end

function new_ccLogger_gui(player,ccLogger)
  if (is_valid(player) and ccLogger ~= nil) then
  	player_gui = player.gui.left
    
  	gui = gui_or_new(player_gui,{type="frame", name="circuit_logger", caption={"msg-window-title"}, direction="vertical" })
    
   	name_flow = gui_or_new(gui,{type="flow", name="name_flow",direction="horizontal"})
  	gui_or_new(name_flow,{type="label", name="ccl_name_label", caption={"msg-name-caption"}})
  	gui_or_new(name_flow,{type="textfield", name="ccl_name", text=ccLogger.name})
    
  	checkboxes = gui_or_new(gui,{type="flow", name="checkboxes",direction="horizontal"})
  	gui_or_new(checkboxes,{type="checkbox", name="ccl_trigger_on",caption={"msg-checkbox-trigger-on"}, state = ccLogger.trigger_on})
  	gui_or_new(checkboxes,{type="checkbox", name="ccl_trigger_off",caption={"msg-checkbox-trigger-off"}, state = ccLogger.trigger_off})
  	gui_or_new(checkboxes,{type="checkbox", name="ccl_logging_on",caption={"msg-checkbox-logging-on"}, state = ccLogger.logging_on})
    
  	checkboxes2 = gui_or_new(gui,{type="flow", name="checkboxes2",direction="horizontal"})
  	gui_or_new(checkboxes2,{type="checkbox", name="ccl_log_red",caption={"msg-checkbox-log-red"}, state = ccLogger.log_red})
  	gui_or_new(checkboxes2,{type="checkbox", name="ccl_log_green",caption={"msg-checkbox-log-green"}, state = ccLogger.log_green})
  	gui_or_new(checkboxes2,{type="checkbox", name="ccl_log_combined",caption={"msg-checkbox-log-combined"}, state = ccLogger.log_combined})
    
   	ignored_flow = gui_or_new(gui,{type="flow", name="ignored_flow",direction="horizontal"})
  	gui_or_new(ignored_flow,{type="label", name="ccl_ignored_label", caption={"ignored-signals-caption"}})
  	gui_or_new(ignored_flow,{type="textfield", name="ccl_ignored", text=join(ccLogger.ignored_signals,","), style="wide_textbox_style_circuit_logger"})
    
   	aliases_flow = gui_or_new(gui,{type="flow", name="aliases_flow",direction="horizontal"})
  	gui_or_new(aliases_flow,{type="label", name="ccl_aliases_label", caption={"signal-aliases-caption"}})
  	gui_or_new(aliases_flow,{type="textfield", name="ccl_aliases", text=join_key_value(ccLogger.signal_aliases,"=",","), style="wide_textbox_style_circuit_logger"})

  	buttons = gui_or_new(gui,{type="flow", name="buttons",direction="horizontal"})
  	gui_or_new(buttons,{type="button", name="ccl_save", caption={"msg-button-save"}, })
    
  end  
  return gui
end

function parse_binary_signals_settings(ccLogger)
  ccLogger.binary_signals = {}
  for name,value in pairs(ccLogger.signal_aliases) do
    if (string.find(value,"{") == 1) then
      local text = string.sub(value, 2, string.len(value)-1)
      ccLogger.binary_signals[name] = split_key_value_string(text,";",":")
    end
  end
end

function update_ccLogger(gui,ccLogger)
	if gui ~= nil and ccLogger ~= nil then
    ccLogger.trigger_on = gui.checkboxes.ccl_trigger_on.state
    ccLogger.trigger_off = gui.checkboxes.ccl_trigger_off.state
    ccLogger.logging_on = gui.checkboxes.ccl_logging_on.state
    ccLogger.log_green = gui.checkboxes2.ccl_log_green.state
    ccLogger.log_red = gui.checkboxes2.ccl_log_red.state
    ccLogger.log_combined = gui.checkboxes2.ccl_log_combined.state
    ccLogger.name = gui.name_flow.ccl_name.text
    local text = gui.ignored_flow.ccl_ignored.text
    ccLogger.ignored_signals = split_string(text, ",")
    text = gui.aliases_flow.ccl_aliases.text
    ccLogger.signal_aliases = split_key_value_string(text,",","=")
    parse_binary_signals_settings(ccLogger)
    ccLogger.last_condition_state = get_condition_state(ccLogger.entity)
	end
end

