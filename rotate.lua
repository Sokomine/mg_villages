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


-- accessd through mg_villages.mirror_facedir[ (rotation%2)+1 ][ facedir+1 ]
mg_villages.mirror_facedir =
		{{ 2,  1,  0,  3,	-- 0, 1, 2, 3
		   8,  9, 10, 11,	-- 4, 5, 6, 7
		   4,  5,  6,  7,	-- 8, 9,10,11
		  12, 13, 14, 15,	--12,13,14,15
		  16, 17, 18, 19,	--16,17,18,19
		  22, 21, 20, 23 	--20,21,22,23
		},
		{  0,  3,  2,  1,	-- 0, 1, 2, 3
		   4,  7,  6,  5,	-- 4, 5, 6, 7
		   8,  9, 10, 11,	-- 8, 9,10,11
		  16, 17, 18, 19,	--12,13,14,15
		  12, 15, 14, 13,	--16,17,18,19
		  20, 23, 22, 21 	--20,21,22,23
		}}; 

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
		p2r[5]=1; -- indicate that it is wallmounted
	else
		return { p2, p2, p2, p2 };
	end 
	return p2r;
end


mg_villages.mirrored_node = {};

mg_villages.add_mirrored_node_type = function( name, mirrored_name )
	mg_villages.mirrored_node[ name ] = mirrored_name;
	local id    = minetest.get_content_id( name );
	local id_mi = minetest.get_content_id( mirrored_name );
	local c_ignore = minetest.get_content_id( 'ignore' );
	if( id and id_mi and id ~= c_ignore  and id_mi2 ~= c_ignore ) then
		mg_villages.mirrored_node[ id ] = id_mi;
	end
end

local door_materials = {'wood','steel','glass','obsidian_glass'};
for _,material in ipairs( door_materials ) do 
	mg_villages.add_mirrored_node_type( 'doors:door_'..material..'_b_1', 'doors:door_'..material..'_b_2' );
	mg_villages.add_mirrored_node_type( 'doors:door_'..material..'_t_1', 'doors:door_'..material..'_t_2' );
	mg_villages.add_mirrored_node_type( 'doors:door_'..material..'_b_2', 'doors:door_'..material..'_b_1' );
	mg_villages.add_mirrored_node_type( 'doors:door_'..material..'_t_2', 'doors:door_'..material..'_t_1' );
end
