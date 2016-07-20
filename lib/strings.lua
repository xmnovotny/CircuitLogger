function split_string( text, inSplitPattern, outResults )

   if not outResults then
      outResults = {}
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( text, inSplitPattern, theStart )
   while theSplitStart do
      table.insert( outResults, string.sub( text, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( text, inSplitPattern, theStart )
   end
   table.insert( outResults, string.sub( text, theStart ) )
   return outResults
end

function split_key_value_string( text, inSplitPattern, keyValueSplitPattern, outResults )

   if not outResults then
      outResults = {}
   end
   local theStart = 1
   local theSplitStart, theSplitEnd = string.find( text, inSplitPattern, theStart )
   while theSplitStart do
      local spl = split_string(string.sub( text, theStart, theSplitStart-1 ), keyValueSplitPattern)
      outResults[spl[1]] = spl[2]
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( text, inSplitPattern, theStart )
   end
   local spl = split_string(string.sub( text, theStart ), keyValueSplitPattern)
   outResults[spl[1]] = spl[2]
   return outResults
end


function join(data, glue)

   outResults = ""
   
   if (data ~= nil) then
     if (not glue) then glue = "," end
     for _,str in pairs(data) do
       if (outResults ~= "") then
        outResults = outResults .. glue
       end
       outResults = outResults .. str
     end
   end   
   return outResults
end

function join_key_value(data, glue_key, glue_items)

   outResults = ""
   
   if (data ~= nil) then
     if (not glue_key) then glue_key = "=" end
     if (not glue_items) then glue_items = "," end
     for key,str in pairs(data) do
       if (outResults ~= "") then
        outResults = outResults .. glue_items
       end
       outResults = outResults .. key .. glue_key .. str
     end
   end   
   return outResults
end