local function numk(tbl)
	local i = 0
	for a, b in pairs(tbl) do
		i = i + 1
	end
	return i
end

mg_villages.import_scm = function(scm, we_origin)
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
			return {};
		end
	end

	local value = f:read("*a")
	f:close()

	local nodes = worldedit_file.load_schematic(value, we_origin)

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

		scm[ent.y][ent.x][ent.z] = mg_villages.decode_one_node( ent.name, ent.param2, ent.meta );

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
