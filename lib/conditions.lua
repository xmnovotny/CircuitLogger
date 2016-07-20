local signal_cache = {}

local function compare_condition(val1, val2, comparator)
  if comparator == "<" then
    return (val1 < val2)
  elseif comparator == "=" then
    return (val1 == val2)
  else
    return (val1 > val2)  
  end
end

local function get_logistic_condition_state(entity,condition) 
	local signal = condition.condition.first_signal	
	if signal == nil or signal.name == nil then return(nil)	end
	
	local network = entity.logistic_network
	
	if network == nil then return(nil) end
	
	local val = network.get_item_count(signal.name)
	local signal2 = condition.condition.second_signal	
  local comp_val = 0
  
  if (signal2 == nil or signal2.name == nil) then
    comp_val = condition.condition.constant
  else
    comp_val = network.get_item_count(signal2.name)
  end
  
  return compare_condition(val,comp_val,condition.condition.comparator)
end

local function get_signal_value(network_r,network_g,signal)
  local result = 0
  if (network_r ~= nil) then result = network_r.get_signal(signal) end
  if (network_g ~= nil) then result = result + network_g.get_signal(signal) end
  return result  
end

local function get_signals(network_r,network_g)
  local result = {}
  local sign_id = nil
  if network_r ~= nil then 
  	for _,signal in ipairs(network_r.signals) do
      result[signal.signal.name] = signal.count
    end
  end  
  if network_g ~= nil then 
  	for _,signal in ipairs(network_g.signals) do
      if (result[signal.signal.name] == nil) then 
        result[signal.signal.name] = signal.count
      else
        result[signal.signal.name] = result[signal.signal.name] + signal.count
      end
    end
  end
  
  return result  
end

local function get_circuit_condition_state(entity,condition) 
	local signal = condition.condition.first_signal	
	if signal == nil or signal.name == nil then return(nil)	end
	
	local network_r = entity.get_circuit_network(defines.wire_type.red)
  local network_g = entity.get_circuit_network(defines.wire_type.green)
	
	if network_g == nil and network_r == nil then return(nil) end
  
	local signal2 = condition.condition.second_signal	
  local comp_val = 0
  
  if (signal2 == nil or signal2.name == nil) then
    comp_val = condition.condition.constant
  else
    comp_val = get_signal_value(network_r,network_g,signal2)
  end
  
  local result = false
  if (signal.name == "signal-everything") then
    signals = get_signals(network_r,network_g);
  
    result = true
		for signal_name,signal_count in pairs(signals) do
      if compare_condition(signal_count,comp_val,condition.condition.comparator) == false then
        result = false
        break
      end
    end
  elseif (signal.name == "signal-anything") then
    signals = get_signals(network_g,network_r);
		for signal_name,signal_count in pairs(signals) do
      if compare_condition(signal_count,comp_val,condition.condition.comparator) == true then
        result = true
        break
      end
    end
  else
  	local val = get_signal_value(network_r,network_g, signal)
    result = compare_condition(val,comp_val,condition.condition.comparator)
  end  
  
  return result
end


function get_condition_state(entity)
	local behavior = entity.get_control_behavior()
	if behavior == nil then	return(nil)	end
	
	local condition = behavior.circuit_condition
	if condition == nil then
    return(nil) 
  end

  local result = nil
  result = get_circuit_condition_state(entity,condition)
  if (result ~= false and behavior.connect_to_logistic_network) then
	  condition = behavior.logistic_condition
  	if condition ~= nil then
      result = get_logistic_condition_state(entity,condition)  
    end
  end
  
  return result
end


-- TODO: create signal and condition state caching for better performance (maybe needed only for signal-everything or signal-anything conditions) 
function clear_signal_cache(entity)
  if (entity == nil) then
    -- entity not specified, clear all cache
    signal_cache = {}
  end
  if (entity.valid and entity.unit_number) then
    signal_cache[entity.unit_number] = nil
  end
end

function get_cached_signal(entity)
  if (entity ~= nil and entity.valid and entity.unit_number) then
    return signal_cache[entity.unit_number] 
  end    
end