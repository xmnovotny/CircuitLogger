function gui_or_new(parent,new_element)
	if parent[new_element.name] == nil then
		parent.add(new_element)
	end
	
	return parent[new_element.name]
end

function table_or_new(table_a)
	if table_a == nil then
		return {}
	else
		return table_a
	end
end
	
function is_valid(entity)
	return (entity ~= nil and entity.valid)
end

function set_debug(value)
	global.debug_level = value
end

function debugDump(var, force)
  if false or force then
    for _, player in pairs(game.players) do
      local msg
      if type(var) == "string" then
        msg = var
      else
        msg = serpent.dump(var, {name="var", comment=false, sparse=false, sortkeys=true})
      end
      player.print(msg)
    end
  end
end

function get_wire_signals(entity, wire)
  if is_valid(entity) then
    netw = entity.get_circuit_network(wire)
    if is_valid(netw) then
      return netw.signals
    end
  end
end

function find_ccLogger(ccLoggers,ccLoggerA)
	for _,ccLoggerB in ipairs(ccLoggers) do
		if is_valid(ccLoggerA) and is_valid(ccLoggerB.entity) and ccLoggerB.entity == ccLoggerA then
			return ccLoggerB
		end
	end
end


function get_fmt_play_time(tick)
  local play_time = {}
  play_time.seconds = math.floor(tick/60)
  play_time.minutes = math.floor(play_time.seconds/60)
  play_time.hours = math.floor(play_time.minutes/60)
  play_time.days = math.floor(play_time.hours/24)
  
  return string.format("%d:%02d:%02d", play_time.hours, play_time.minutes % 60, play_time.seconds % 60) 
end

function to_binary(value)
  local res = {}
  local i = 1
  while value>0 do
    if (value%2 == 1) then res[tostring(i)] = 1 end
    value = math.floor(value / 2)
    i = i+1     
  end
  return res;
end 


-- compare signals from a circuit network and return true if signals are equal
function compare_signals(signals_old, signals_new)
  if #signals_old ~= #signals_new then return false end
  
  for i,signal in ipairs(signals_old) do
    if (signal.signal.name ~= signals_new[i].signal.name or signal.count ~= signals_new[i].count) then return false end
  end
  
  return true
end

-- returns table of changed signals (table key is a name of the signal, table value is a count of the signal)
function changed_signals(signals_old, signals_new, logger_ignored_signals, global_ignored_signals)
  diff = {}
  count = 0
  
  for _,signal in ipairs(signals_new) do
    diff[signal.signal.name] = signal.count
    count = count + 1
  end
    
  for _,signal in ipairs(signals_old) do
    if (diff[signal.signal.name] == nil) then 
      diff[signal.signal.name] = 0
      count = count + 1
    elseif (diff[signal.signal.name] == signal.count) then 
      diff[signal.signal.name] = nil
      count = count - 1
    end 
  end  

  if count>0 and global_ignored_signals ~= nil and #global_ignored_signals > 0 then
    for _,name in ipairs(global_ignored_signals) do
      if (diff[name] ~= nil) then
        diff[name] = nil
        count = count - 1
      end  
    end
  end
  
  if count>0 and logger_ignored_signals ~= nil and #logger_ignored_signals > 0 then
    for _,name in ipairs(logger_ignored_signals) do
      if (diff[name] ~= nil) then
        diff[name] = nil
        count = count - 1
      end  
    end
  end
  
  if (count>0) then
    return diff
  else
    return false
  end  
end

-- adds new signals in diff (key is the name of signal) to a list of used signals
function add_to_signal_list(diff_signals, used_signals, wire_type)
  for name,count in pairs(diff_signals) do
    used_signals[wire_type][name] = 0
  end
end

