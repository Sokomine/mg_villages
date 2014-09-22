mg_villages.deepcopy = function(orig)
    return minetest.deserialize(minetest.serialize(orig))
end

mg_villages.rotate_facedir = function(facedir)
	return ({1, 2, 3, 0,
		13, 14, 15, 12,
		17, 18, 19, 16,
		9, 10, 11, 8,
		5, 6, 7, 4,
		21, 22, 23, 20})[facedir+1]
end

mg_villages.rotate_wallmounted = function(wallmounted)
	return ({0, 1, 5, 4, 2, 3})[wallmounted+1]
end

mg_villages.get_param2_rotated = function( paramtype2, p2 )
	local p2r = {};
	p2r[ 1 ] = p2;
	if(     paramtype2 == 'wallmounted' ) then
		for i = 2,4 do
			p2r[ i ] = mg_villages.rotate_wallmounted( p2r[ i-1 ]);
		end
	elseif( paramtype2 == 'facedir' ) then
		for i = 2,4 do
			p2r[ i ] = mg_villages.rotate_facedir(     p2r[ i-1 ]);
		end
	else
		return { p2, p2, p2, p2 };
	end 
	return p2r;
end

mg_villages.rotate_scm_once = function(scm)
	local ysize = #scm
	local xsize = #scm[1]
	local zsize = #scm[1][1]
	new_scm = {}
	for i=1, ysize do
		new_scm[i] = {}
		for j=1, zsize do
			new_scm[i][j] = {}
		end
	end
	
	for y = 1, ysize do
	for x = 1, xsize do
	for z = 1, zsize do
		local old = scm[y][x][z]
		local newx = z
		local newz = xsize-x+1
		if type(old) ~= "table" or old.rotation == nil then
			new_scm[y][newx][newz] = old
		elseif old.rotation == "wallmounted" then
			new = mg_villages.deepcopy(old)
			new.node.param2 = mg_villages.rotate_wallmounted(new.node.param2)
			new_scm[y][newx][newz] = new
		elseif old.rotation == "facedir" then
			new = mg_villages.deepcopy(old)
			new.node.param2 = mg_villages.rotate_facedir(new.node.param2)
			new_scm[y][newx][newz] = new
		end
	end
	end
	end
	return new_scm
end

-- called from villages.lua
mg_villages.rotate_scm = function(scm, times)
	for i=1, times do
		scm = mg_villages.rotate_scm_once(scm)
	end
	return scm
end
