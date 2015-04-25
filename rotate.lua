local rotate_facedir = function(facedir)
	return ({1, 2, 3, 0,
		13, 14, 15, 12,
		17, 18, 19, 16,
		9, 10, 11, 8,
		5, 6, 7, 4,
		21, 22, 23, 20})[facedir+1]
end


-- accessd through handle_schematics.mirror_facedir[ (rotation%2)+1 ][ facedir+1 ]
handle_schematics.mirror_facedir =
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

local rotate_wallmounted = function(wallmounted)
	return ({0, 1, 5, 4, 2, 3})[wallmounted+1]
end

handle_schematics.get_param2_rotated = function( paramtype2, p2 )
	local p2r = {};
	p2r[ 1 ] = p2;
	if(     paramtype2 == 'wallmounted' ) then
		for i = 2,4 do
			p2r[ i ] = rotate_wallmounted( p2r[ i-1 ]);
		end
	elseif( paramtype2 == 'facedir' ) then
		for i = 2,4 do
			p2r[ i ] = rotate_facedir(     p2r[ i-1 ]);
		end
		p2r[5]=1; -- indicate that it is wallmounted
	else
		return { p2, p2, p2, p2 };
	end 
	return p2r;
end


handle_schematics.mirrored_node = {};

handle_schematics.add_mirrored_node_type = function( name, mirrored_name )
	handle_schematics.mirrored_node[ name ] = mirrored_name;
	local id    = minetest.get_content_id( name );
	local id_mi = minetest.get_content_id( mirrored_name );
	local c_ignore = minetest.get_content_id( 'ignore' );
	if( id and id_mi and id ~= c_ignore  and id_mi ~= c_ignore ) then
		handle_schematics.mirrored_node[ id ] = id_mi;
	end
end

local door_materials = {'wood','steel','glass','obsidian_glass'};
for _,material in ipairs( door_materials ) do 
	handle_schematics.add_mirrored_node_type( 'doors:door_'..material..'_b_1', 'doors:door_'..material..'_b_2' );
	handle_schematics.add_mirrored_node_type( 'doors:door_'..material..'_t_1', 'doors:door_'..material..'_t_2' );
	handle_schematics.add_mirrored_node_type( 'doors:door_'..material..'_b_2', 'doors:door_'..material..'_b_1' );
	handle_schematics.add_mirrored_node_type( 'doors:door_'..material..'_t_2', 'doors:door_'..material..'_t_1' );
end




handle_schematics.rotation_table = {};
handle_schematics.rotation_table[ 'facedir'     ] = {};
handle_schematics.rotation_table[ 'wallmounted' ] = {};


for paramtype2,v in pairs( handle_schematics.rotation_table ) do
	for param2 = 0,23 do

		if( param2 < 6 or  paramtype2 == 'facedir' ) then
			local param2list = handle_schematics.get_param2_rotated( paramtype2, param2);

			handle_schematics.rotation_table[ paramtype2 ][ param2+1 ] = {};

			for rotation = 0,3 do
				local np2 = param2list[ rotation + 1];
				local mirror_x = np2;
				local mirror_z = np2;

				-- mirror_x
				if(     #param2list==5) then
					mirror_x = handle_schematics.mirror_facedir[ (( rotation +1)%2)+1 ][ np2+1 ];
				elseif( #param2list<5
				  and  (( rotation%2==1 and (np2==4 or np2==5))
				     or ( rotation%2==0 and (np2==2 or np2==3)))) then
					mirror_x = param2list[ ( rotation + 2)%4 +1];
				end

				-- mirror_z
				if(     #param2list==5) then
					mirror_z = handle_schematics.mirror_facedir[ (rotation      %2)+1 ][ np2+1 ];
				elseif( #param2list<5
				  and  (( rotation%2==0 and (np2==4 or np2==5))
				     or ( rotation%2==1 and (np2==2 or np2==3)))) then
					mirror_z = param2list[ ( rotation + 2)%4 +1];
				end

				handle_schematics.rotation_table[ paramtype2 ][ param2+1 ][ rotation+1 ] = { np2, mirror_x, mirror_z };
			end
		end
	end
end
