-- Intllib
local S = mg_villages.intllib

-- villages up to this many nodes in each direction are shown on the map
mg_villages.MAP_RANGE = 1000;


mg_villages.draw_tile = function( content_id, image, x, z, dx, dz, tile_nr )
	if( not( image )) then
		local node_name = minetest.get_name_from_content_id( content_id );
		if( not( node_name )) then
			return '';
		end
		local node_def  = minetest.registered_nodes[ node_name ];
		if( not( node_def )) then
			return '';
		end
		local tiles = node_def.tiles;
		local tile = nil;
		if( tiles ~= nil ) then
			if( not(tile_nr) or tile_nr > #tiles or tile_nr < 1 ) then
				tile_nr = 1;
			end
			tile = tiles[tile_nr];
		end
		if type(tile)=="table" then
			tile=tile["name"]
		end
		image = tile;
		if( not( image )) then
			image = "unknown_object.png";
		end
	end
	return "image["..tostring(x)..",".. tostring(z) ..";"..dx..','..dz..";" .. image .."]";
end


mg_villages.map_of_world = function( pname )

	local player = minetest.get_player_by_name( pname );
	if( not( player )) then
		return '';
	end
	local ppos  = player:get_pos();

	-- also usable: diamond_block, sand, water
	local formspec = "size[14.4,10]"..
			"background[0,0;10,10;"..mg_villages.MAP_BACKGROUND_IMAGE.."]"..
			"label[10,10;x axis]"..
			"label[0,0;z axis]"..
			"label[0,10;|]"..
			"label[0.2,10;->]";


	local r  = mg_villages.MAP_RANGE;
	local f1 = 10/(2*r);

	local map_tiles_shown = math.floor( mg_villages.MAP_RANGE/80 );
	local center_x = math.floor( ppos.x/80 );
	local center_z = math.floor( ppos.z/80 );
	for x = center_x - map_tiles_shown, center_x + map_tiles_shown do
		for z = center_z - map_tiles_shown, center_z + map_tiles_shown do  
			if( mg_villages.mg_generated_map[ x ] and mg_villages.mg_generated_map[ x ][ z ] ) then
				local surface_types     = mg_villages.mg_generated_map[ x ][ z ];
				local content_id        = 0;
				if( type( surface_types )=='table' ) then
					content_id      = surface_types[ 26 ];
				else
					content_id      = surface_types;
				end

				local x1 = f1 * ((x*80) - ppos.x +r);
				local z1 = f1 * ( (2*r) - ((z*80) - ppos.z + r));
				local dx = f1 * 80;
				local dz = f1 * 80;

				formspec = formspec..mg_villages.draw_tile( content_id, nil, x1+0.5, z1-0.5, dx*1.25, dz*1.25, 1 );

				-- if more detailed information is available, draw those tiles that differ from the most common tile
				if( type( surface_types )=='table' and false) then -- TODO: disabled for now
					dx = dx/5;
					dz = dz/5;
					for i,v in ipairs( surface_types ) do
						if( v ~= content_id ) then
							local x2 = x1+( math.floor( (i-1)/5 )*dx); 
							local z2 = z1+( math.floor( (i-1)%5 )*dz);
							formspec = formspec..mg_villages.draw_tile( v, nil, x2+0.5, z2-0.5, dx*1.3, dz*1.3, 1);
						end
					end
				end
			end
		end
	end

	local shown_villages = {};

	r  = mg_villages.MAP_RANGE;
	f1 = 10/(2*r);
	for name,v in pairs( mg_villages.all_villages ) do

		local data = v; --minetest.deserialize( v );
		local x = data.vx - ppos.x;
		local z = data.vz - ppos.z;

		-- show only villages which are at max mg_villages.MAP_RANGE away from player
		if( x and z 
		   and mg_villages.village_type_data[ data.village_type ]
		   and mg_villages.village_type_data[ data.village_type ].texture
		   and math.abs( x ) < r
		   and math.abs( z ) < r ) then

			-- the village size determines the texture size
			local dx = f1 * (data.vs*2) *1.25;
			local dz = f1 * (data.vs*2) *1.0;

			-- center the village texture
			x = x - (data.vs/2);
			z = z + (data.vs/2);

			-- calculate the position for the village texture
			x = f1 * (x+r);
			z = f1 * ( (2*r) -(z+r));

			formspec = formspec..
				"label["..x..",".. z ..";"..tostring( data.nr ).."]"..mg_villages.draw_tile( nil,  mg_villages.village_type_data[ data.village_type ].texture, x, z, dx, dz, 1 );

			shown_villages[ #shown_villages+1 ] = tostring( data.nr )..". "..tostring( v.name or 'unknown' ).."]"; 
		end
	end

	-- code and arrows taken from mapp mod
	local yaw = player:get_look_yaw()
	local rotate = 0;
	if yaw ~= nil then
		-- Find rotation and texture based on yaw.
		yaw = math.deg(yaw)
		yaw = math.fmod (yaw, 360)
		if yaw<0 then yaw = 360 + yaw end
		if yaw>360 then yaw = yaw - 360 end
		if yaw < 90 then
			rotate = 90
		elseif yaw < 180 then
			rotate = 180
		elseif yaw < 270 then
			rotate = 270
		else
			rotate = 0
		end
		yaw = math.fmod(yaw, 90)
		yaw = math.floor(yaw / 10) * 10

	end

	-- show the players yaw
	if rotate ~= 0 then
		formspec = formspec.."image[".. 4.95 ..",".. 4.85 ..";0.4,0.4;d" .. yaw .. ".png^[transformFYR".. rotate .."]"
	else
		formspec = formspec.."image[".. 4.95 ..",".. 4.85 ..";0.4,0.4;d" .. yaw .. ".png^[transformFY]"
	end

	local i = 0.05;
	formspec = formspec.."label[10,-0.4;Village types:]";
	-- explain the meaning of the textures
	if mg_villages.village_types ~= nil then
		for _,typ in ipairs(mg_villages.village_types) do 
			formspec = formspec.."label[10.5,"..tostring(i)..";"..tostring( typ ).."]"..
				             "image[10.0,"..tostring(i+0.1)..";0.4,0.4;"..tostring( mg_villages.village_type_data[ typ ].texture ).."]";
			i = i+0.45;
		end
	end

	i = i+0.45;
	formspec = formspec.."label[10.0,"..tostring(i)..";"..S("Villages shown on this map").." : ]";
	i = i+0.45;
	local j = 1;
	while (i<10.5 and j<=#shown_villages) do
		
		formspec = formspec.."label[10.0,"..tostring(i)..";"..tostring( shown_villages[ j ] ).."]";
		i = i+0.45;
		j = j+1;
	end

	return formspec;
end


minetest.register_chatcommand( 'vmap', {
	description = S("Shows a map of all known villages withhin @1 blocks.", tostring( mg_villages.MAP_RANGE )),
	privs = {},
	func = function(name, param)
		minetest.show_formspec( name, 'mg:world_map', mg_villages.map_of_world( name ));
        end
});

