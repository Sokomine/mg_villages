handle_schematics.analyze_we_file = function(scm, we_origin)
	local c_ignore = minetest.get_content_id("ignore")

	-- this table will contain the nodes read
	local nodes = {}

	-- check if it is a worldedit file
	-- (no idea why reading that is done in such a complicated way; a simple deserialize and iteration over all nodes ought to do as well)
	local f, err = io.open( scm..".we", "r")
	if not f then
		f, err = io.open( scm..".wem", "r")
		if not f then
			error("Could not open schematic '" .. scm .. ".we': " .. err)
			return nil;
		end
	end

	local value = f:read("*a")
	f:close()

	local nodes = worldedit_file.load_schematic(value, we_origin)

	-- create a list of nodenames
	local nodenames    = {};
	local nodenames_id = {};
	for i,ent in ipairs( nodes ) do
		if( ent and ent.name and not( nodenames_id[ ent.name ])) then
			nodenames_id[ ent.name ] = #nodenames + 1;
			nodenames[ nodenames_id[ ent.name ] ] = ent.name;
		end
	end

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

		scm[ent.y][ent.x][ent.z] = { nodenames_id[ ent.name ], ent.param2 }; --TODO ent.meta

	end

	for y = 1, maxy do
		if scm[y] == nil then
			scm[y] = {}
		end
		for x = 1, maxx do
			if scm[y][x] == nil then
				scm[y][x] = {}
			end
		end
	end

	local size = {};
	size.y = math.max(maxy,0);
	size.x = math.max(maxx,0);
	size.z = math.max(maxz,0);

	return { size = { x=size.x, y=size.y, z=size.z}, nodenames = nodenames, on_constr = {}, after_place_node = {}, rotated=0, burried=0, scm_data_cache = scm };
end
