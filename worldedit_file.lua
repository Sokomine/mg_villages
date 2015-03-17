------------------------------------------------------------------------------------------
-- This is the file
--   https://github.com/Uberi/Minetest-WorldEdit/blob/master/worldedit/serialization.lua
-- Changes:
--  * worldedit namespace renamed to worldeit_file
--  * eliminiated functions that are not needed
--  * made function load_schematic non-local
--  * originx, originy and originz are now passed as parameters to worldedit_file.load_schematic;
--    they are required for an old file format
------------------------------------------------------------------------------------------

worldedit_file = {} -- add the namespace

--- Schematic serialization and deserialiation.
-- @module worldedit.serialization

worldedit_file.LATEST_SERIALIZATION_VERSION = 5
local LATEST_SERIALIZATION_HEADER = worldedit_file.LATEST_SERIALIZATION_VERSION .. ":"


--[[
Serialization version history:
  1: Original format.  Serialized Lua table with a weird linked format...
  2: Position and node seperated into sub-tables in fields `1` and `2`.
  3: List of nodes, one per line, with fields seperated by spaces.
      Format: <X> <Y> <Z> <Name> <Param1> <Param2>
  4: Serialized Lua table containing a list of nodes with `x`, `y`, `z`,
      `name`, `param1`, `param2`, and `meta` fields.
  5: Added header and made `param1`, `param2`, and `meta` fields optional.
      Header format: <Version>,<ExtraHeaderField1>,...:<Content>
--]]


--- Reads the header of serialized data.
-- @param value Serialized WorldEdit data.
-- @return The version as a positive natural number, or 0 for unknown versions.
-- @return Extra header fields as a list of strings, or nil if not supported.
-- @return Content (data after header).
function worldedit_file.read_header(value)
	if value:find("^[0-9]+[%-:]") then
		local header_end = value:find(":", 1, true)
		local header = value:sub(1, header_end - 1):split(",")
		local version = tonumber(header[1])
		table.remove(header, 1)
		local content = value:sub(header_end + 1)
		return version, header, content
	end
	-- Old versions that didn't include a header with a version number
	if value:find("([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)") and not value:find("%{") then -- List format
		return 3, nil, value
	elseif value:find("^[^\"']+%{%d+%}") then
		if value:find("%[\"meta\"%]") then -- Meta flat table format
			return 2, nil, value
		end
		return 1, nil, value -- Flat table format
	elseif value:find("%{") then -- Raw nested table format
		return 4, nil, value
	end
	return nil
end


--- Loads the schematic in `value` into a node list in the latest format.
-- Contains code based on [table.save/table.load](http://lua-users.org/wiki/SaveTableToFile)
-- by ChillCode, available under the MIT license.
-- @return A node list in the latest format, or nil on failure.
function worldedit_file.load_schematic(value, we_origin)
	local version, header, content = worldedit_file.read_header(value)
	local nodes = {}
	if version == 1 or version == 2 then -- Original flat table format
		local tables = minetest.deserialize(content)
		if not tables then return nil end

		-- Transform the node table into an array of nodes
		for i = 1, #tables do
			for j, v in pairs(tables[i]) do
				if type(v) == "table" then
					tables[i][j] = tables[v[1]]
				end
			end
		end
		nodes = tables[1]

		if version == 1 then --original flat table format
			for i, entry in ipairs(nodes) do
				local pos = entry[1]
				entry.x, entry.y, entry.z = pos.x, pos.y, pos.z
				entry[1] = nil
				local node = entry[2]
				entry.name, entry.param1, entry.param2 = node.name, node.param1, node.param2
				entry[2] = nil
			end
		end
	elseif version == 3 or version=="3" then -- List format
		if( not( we_origin ) or #we_origin <3) then
			we_origin = { 0, 0, 0 };
		end
		for x, y, z, name, param1, param2 in content:gmatch(
				"([+-]?%d+)%s+([+-]?%d+)%s+([+-]?%d+)%s+" ..
				"([^%s]+)%s+(%d+)%s+(%d+)[^\r\n]*[\r\n]*") do
			param1, param2 = tonumber(param1), tonumber(param2)
			table.insert(nodes, {
				x = we_origin[1] + tonumber(x),
				y = we_origin[2] + tonumber(y),
				z = we_origin[3] + tonumber(z),
				name = name,
				param1 = param1 ~= 0 and param1 or nil,
				param2 = param2 ~= 0 and param2 or nil,
			})
		end
	elseif version == 4 or version == 5 then -- Nested table format
		if not jit then
			-- This is broken for larger tables in the current version of LuaJIT
			nodes = minetest.deserialize(content)
		else
			-- XXX: This is a filthy hack that works surprisingly well - in LuaJIT, `minetest.deserialize` will fail due to the register limit
			nodes = {}
			content = content:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1) -- remove the starting and ending values to leave only the node data
			local escaped = content:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
			local startpos, startpos1, endpos = 1, 1
			while true do -- go through each individual node entry (except the last)
				startpos, endpos = escaped:find("},%s*{", startpos)
				if not startpos then
					break
				end
				local current = content:sub(startpos1, startpos)
				local entry = minetest.deserialize("return " .. current)
				table.insert(nodes, entry)
				startpos, startpos1 = endpos, endpos
			end
			local entry = minetest.deserialize("return " .. content:sub(startpos1)) -- process the last entry
			table.insert(nodes, entry)
		end
	else
		return nil
	end
	return nodes
end
