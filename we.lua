local function numk(tbl)
	local i = 0
	for a, b in pairs(tbl) do
		i = i + 1
	end
	return i
end

mg_villages.import_scm = function(scm)
	local c_ignore = minetest.get_content_id("ignore")

	-- this table will contain the nodes read
	local nodes = {}

--[[
	-- .bld file support did not work very well

	-- first check if it's a .bld file from mauvebics mm2 modpack; code taken from said modpack from mauvebic and adjusted
	local bldfile, bld_err = io.open(mg_villages.modpath..'/schems/'..scm..'.bld', "r");
	if( bldfile ) then
		local line = bldfile:read("*line")
		while line ~= nil do
			local nodename, coords,param2 = unpack(line:split("~"))
			if not string.find(nodename,'mbbase:') then
				local p = {}
				p.x, p.y, p.z = string.match(coords, "^([%d.-]+)[, ] *([%d.-]+)[, ] *([%d.-]+)$")
				if p.x and p.y and p.z then
					table.insert( nodes, {x = tonumber(math.ceil(p.x)),y= tonumber(math.ceil(p.y)),z = tonumber(math.ceil(p.z)),name=nodename,param2=param2})
				end
			end
			line = bldfile:read("*line")
		end
		io.close(bldfile)
	end
--]]

	-- check if it is a worldedit file
	-- (no idea why reading that is done in such a complicated way; a simple deserialize and iteration over all nodes ought to do as well)
	local f, err = io.open( mg_villages.modpath.."/schems/"..scm..".we", "r")
	if not f then
		error("Could not open schematic '" .. scm .. ".we': " .. err)
		return {};
	end

	value = f:read("*a")
	f:close()
	value = value:gsub("return%s*{", "", 1):gsub("}%s*$", "", 1)
	local escaped = value:gsub("\\\\", "@@"):gsub("\\\"", "@@"):gsub("(\"[^\"]*\")", function(s) return string.rep("@", #s) end)
	local startpos, startpos1, endpos = 1, 1
	while true do
		startpos, endpos = escaped:find("},%s*{", startpos)
		if not startpos then
			break
		end
		local current = value:sub(startpos1, startpos)
		table.insert(nodes, minetest.deserialize("return " .. current))
		startpos, startpos1 = endpos, endpos
	end
	table.insert(nodes, minetest.deserialize("return " .. value:sub(startpos1)))


	scm = {}
	local maxx, maxy, maxz = -1, -1, -1
	for i = 1, #nodes do
		local ent = nodes[i]
		ent.x = ent.x + 1
		ent.y = ent.y + 1
		ent.z = ent.z + 1
		if ent.x > maxx then
			maxx = ent.x
		end
		if ent.y > maxy then
			maxy = ent.y
		end
		if ent.z > maxz then
			maxz = ent.z
		end
		if scm[ent.y] == nil then
			scm[ent.y] = {}
		end
		if scm[ent.y][ent.x] == nil then
			scm[ent.y][ent.x] = {}
		end
		if ent.param2 == nil then
			ent.param2 = 0
		end
		if ent.meta == nil then
			ent.meta = {fields={}, inventory={}}
		end
		local paramtype2 = minetest.registered_nodes[ent.name] and minetest.registered_nodes[ent.name].paramtype2
		local on_constr  = minetest.registered_nodes[ent.name] and minetest.registered_nodes[ent.name].on_construct
		if( on_constr ) then
			on_constr = true;
		end
		-- unkown nodes have to be treated specially; they are not allowed to be of type wallmounted or facedir or to need on_construct
		if( not( minetest.registered_nodes[ ent.name ] )) then
			-- stairs are always of type facedir
			if( string.sub( ent.name, 1, 7 ) == 'stairs:' ) then
				scm[ent.y][ent.x][ent.z] = {
					node = {
						name    = ent.name,
						param2  = ent.param2,
						param2list = mg_villages.get_param2_rotated( 'facedir', ent.param2 ),
					}}
			else
				scm[ent.y][ent.x][ent.z] = {
					node = {
						name    = ent.name,
						param2  = ent.param2,
					}}
			end
		elseif ent.name == "mg:ignore" then
				scm[ent.y][ent.x][ent.z] = minetest.get_content_id('ignore');
		elseif not paramtype2 then
				if( on_constr ) then
					scm[ent.y][ent.x][ent.z] = {
						node = {
							content = minetest.get_content_id(ent.name),
							name    = ent.name,
							on_constr = true
						}}
				else
					scm[ent.y][ent.x][ent.z] = c_ignore
				end
		elseif numk(ent.meta.fields) == 0 and numk(ent.meta.inventory) == 0 then
			if paramtype2 ~= "facedir" and paramtype2 ~= "wallmounted" then
				if( not( on_constr )) then
					scm[ent.y][ent.x][ent.z] = minetest.get_content_id(ent.name)
				else
					scm[ent.y][ent.x][ent.z] = {
						node = {
							content = minetest.get_content_id(ent.name),
							on_constr = true
						}}
				end
			else
				scm[ent.y][ent.x][ent.z] = {
					node = {
						content = minetest.get_content_id(ent.name),
						on_constr = on_constr,
						name   = ent.name,param2 = ent.param2, param2list = mg_villages.get_param2_rotated( paramtype2, ent.param2 )},
					rotation = paramtype2}
			end
		else
			if paramtype2 ~= "facedir" and paramtype2 ~= "wallmounted" then
				scm[ent.y][ent.x][ent.z] = {extranode = true,
					node = {
						content = minetest.get_content_id(ent.name),
						on_constr = on_constr,
						name = ent.name, param2 = ent.param2},
					meta = ent.meta}
			else
				scm[ent.y][ent.x][ent.z] = {extranode = true,
					node = {
						content = minetest.get_content_id(ent.name),
						on_constr = on_constr,
						name = ent.name, param2 = ent.param2, param2list = mg_villages.get_param2_rotated( paramtype2, ent.param2 )},
					meta = ent.meta,
					rotation = paramtype2}
			end
		end
	end
	local c_air = minetest.get_content_id("air")
	for x = 1, maxx do
		for y = 1, maxy do
			for z = 1, maxz do
				if scm[y] == nil then
					scm[y] = {}
				end
				if scm[y][x] == nil then
					scm[y][x] = {}
				end
				if scm[y][x][z] == nil then
					scm[y][x][z] = c_air
				end
			end
		end
	end
	return scm
end
