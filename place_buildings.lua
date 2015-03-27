

-- either uses get_node_or_nil(..) or the data from voxelmanip
-- the function might as well be local (only used by *.mg_drop_moresnow)
mg_villages.get_node_somehow = function( x, y, z, a, data, param2_data )
	if( a and data and param2_data ) then
		return { content = data[a:index(x, y, z)], param2 = param2_data[a:index(x, y, z)] };
	end
	-- no voxelmanip; get the node the normal way
	local node = minetest.get_node_or_nil( {x=x, y=y, z=z} );
	if( not( node ) ) then
		return { content = moresnow.c_ignore, param2 = 0 };
	end
	return { content = minetest.get_content_id( node.name ), param2 = node.param2, name = node.name };
end


-- "drop" moresnow snow on diffrent shapes; works for voxelmanip and node-based setting
mg_villages.mg_drop_moresnow = function( x, z, y_top, y_bottom, a, data, param2_data)

	-- this only works if moresnow is installed
	if( not( mg_villages.moresnow_installed )) then
		return;
	end

	local y = y_top;
	local node_above = mg_villages.get_node_somehow( x, y+1, z, a, data, param2_data );	
	local node_below = nil;
	while( y >= y_bottom ) do

		node_below = mg_villages.get_node_somehow( x, y, z, a, data, param2_data );
		if(     node_above.content == moresnow.c_air
		    and node_below.content
		    and node_below.content ~= moresnow.c_ignore
		    and node_below.content ~= moresnow.c_air ) then

			-- if the node below drops snow when digged (i.e. is either snow or a moresnow node), we're finished
			local get_drop = minetest.get_name_from_content_id( node_below.content );
			if( get_drop ) then
				get_drop = minetest.registered_nodes[ get_drop ];
				if( get_drop and get_drop.drop and type( get_drop.drop )=='string' and get_drop.drop == 'default:snow') then
					return;
				end
			end
			if( not(node_below.content)
			    or  node_below.content == mg_villages.road_node
			    or  node_below.content == moresnow.c_snow ) then
				return;
			end

			local suggested = moresnow.suggest_snow_type( node_below.content, node_below.param2 );

			-- c_snow_top and c_snow_fence can only exist when the node 2 below is a solid one
			if(    suggested.new_id == moresnow.c_snow_top
			    or suggested.new_id == moresnow.c_snow_fence) then	
				local node_below2 = mg_villages.get_node_somehow( x, y-1, z, a, data, param2_data);
				if(     node_below2.content ~= moresnow.c_ignore
				    and node_below2.content ~= moresnow.c_air ) then
					local suggested2 = moresnow.suggest_snow_type( node_below2.content, node_below2.param2 );

					if( suggested2.new_id == moresnow.c_snow ) then
						return { height = y+1, suggested = suggested };
					end
				end
			-- it is possible that this is not the right shape; if so, the snow will continue to fall down
			elseif( suggested.new_id ~= moresnow.c_ignore ) then
					
				return { height = y+1, suggested = suggested };
			end
			-- TODO return; -- abort; there is no fitting moresnow shape for the node below
		end
		y = y-1;
		node_above = node_below;
	end
end


-- helper function for generate_building
-- places a marker that allows players to buy plots with houses on them (in order to modify the buildings)
local function generate_building_plotmarker( pos, minp, maxp, data, param2_data, a, cid, building_nr_in_bpos, village_id)
	-- position the plot marker so that players can later buy this plot + building in order to modify it
	-- pos.o contains the original orientation (determined by the road and the side the building is
	local p = {x=pos.x, y=pos.y+1, z=pos.z};
	if(     pos.o == 0 ) then
		p.x = p.x - 1;
		p.z = p.z + pos.bsizez - 1;
	elseif( pos.o == 2 ) then
		p.x = p.x + pos.bsizex;
	elseif( pos.o == 1 ) then
		p.z = p.z + pos.bsizez;
		p.x = p.x + pos.bsizex - 1;
	elseif( pos.o == 3 ) then
		p.z = p.z - 1;
	end
	-- actually position the marker
	if(   p.x >= minp.x and p.x <= maxp.x and p.z >= minp.z and p.z <= maxp.z and p.y >= minp.y and p.y <= maxp.y) then
		data[       a:index(p.x, p.y, p.z)] = cid.c_plotmarker;
		param2_data[a:index(p.x, p.y, p.z)] = pos.brotate;
		-- store the necessary information in the marker so that it knows for which building it is responsible
		local meta = minetest.get_meta( p );
		meta:set_string('village_id', village_id );
		meta:set_int(   'plot_nr',    building_nr_in_bpos );
		meta:set_string('infotext',   'Plot No. '..tostring( building_nr_in_bpos ).. ' with '..tostring( mg_villages.BUILDINGS[pos.btype].scm ));
	end
end



-- we do have a list of all nodenames the building contains (the .mts file provided it);
-- we can thus apply all replacements to these nodenames;
-- this also checks param2 and sets some other variables to indicate that it's i.e. a tree or a chest
-- (which both need special handling later on)
local function generate_building_translate_nodenames( nodenames, replacements, cid, binfo_scm, mirror_x, mirror_z )
	
	if( not( nodenames )) then
		return;
	end
	local i;
	local v;
	local new_nodes   = {};
	for i,node_name in ipairs( nodenames ) do

		new_nodes[ i ] = {}; -- array for collecting information about the new content id for nodes with number "i" in their .mts savefile

		-- some nodes may be called differently when mirrored; needed for doors
		local new_node_name = node_name;
		if( new_node_name and ( mirror_x or mirror_z ) and mg_villages.mirrored_node[ new_node_name ] ) then
			new_node_name = mg_villages.mirrored_node[ node_name ];
			new_nodes[ i ].is_mirrored = 1; -- currently unused
		end

		-- apply the replacements
		if( new_node_name and replacements.table[ new_node_name ] ) then
			new_node_name = replacements.table[ new_node_name ];
			new_nodes[ i ].is_replaced = 1; -- currently unused
		end

		-- only existing nodes can be placed
		if( new_node_name and minetest.registered_nodes[ new_node_name ]) then
							
			local regnode = minetest.registered_nodes[ new_node_name ];

			new_nodes[ i ].new_node_name = new_node_name;
			new_nodes[ i ].new_content   = minetest.get_content_id( new_node_name );
			if( regnode.on_construct ) then
				new_nodes[ i ].on_construct = 1;
			end

			local new_content = new_nodes[ i ].new_content;
			if( new_content == cid.c_dirt or new_content == cid.c_dirt_with_grass ) then
				new_nodes[ i ].is_grass     = 1;
		
			elseif( new_content == cid.c_sapling
			     or new_content == cid.c_jsapling
			     or new_content == cid.c_psapling
			     or new_content == cid.c_savannasapling
			     or new_content == cid.c_pinesapling ) then
				-- store that a tree is to be grown there
				new_nodes[ i ].is_tree      = 1;

			elseif( new_content == cid.c_chest
			   or   new_content == cid.c_chest_locked 
			   or   new_content == cid.c_chest_shelf
			   or   new_content == cid.c_chest_ash
			   or   new_content == cid.c_chest_aspen
			   or   new_content == cid.c_chest_birch
			   or   new_content == cid.c_chest_maple
			   or   new_content == cid.c_chest_chestnut
			   or   new_content == cid.c_chest_pine
			   or   new_content == cid.c_chest_spruce) then
				-- we're dealing with a chest that might need filling
				new_nodes[ i ].is_chestlike = 1;

			elseif( new_content == cid.c_chest_private
			   or   new_content == cid.c_chest_work
			   or   new_content == cid.c_chest_storage ) then
				-- we're dealing with a chest that might need filling
				new_nodes[ i ].is_chestlike = 1;
				-- TODO: perhaps use a locked chest owned by the mob living there?
				-- place a normal chest here
				new_nodes[ i ].new_content  = cid.c_chest;

			elseif( new_content == cid.c_sign ) then
				-- the sign may require some text to be written on it
				new_nodes[ i ].is_sign      = 1;
			end


			-- mg_villages.get_param2_rotated( 'facedir', param2 ) needs to be called for nodes
			-- which use either facedir or wallmounted;
			-- realtest rotates some nodes diffrently and does not come with default:ladder
			if(    node_name == 'default:ladder' and not( minetest.registered_nodes[ node_name ])) then
				new_nodes[ i ].change_param2 = {}; --{ 2->1, 5->2, 3->3, 4->0 }	
				new_nodes[ i ].change_param2[2] = 1;
				new_nodes[ i ].change_param2[5] = 2;
				new_nodes[ i ].change_param2[3] = 3;
				new_nodes[ i ].change_param2[4] = 0;
				new_nodes[ i ].paramtype2 = 'facedir';
			-- ..except if they are stairs or ladders
			elseif( string.sub( node_name, 1, 7 ) == 'stairs:' or string.sub( node_name, 1, 6 ) == 'doors:') then
				new_nodes[ i ].paramtype2 = 'facedir';
			-- normal nodes
			elseif( regnode and regnode.paramtype2 and (regnode.paramtype2=='facedir' or regnode.paramtype2=='wallmounted')) then
				new_nodes[ i ].paramtype2 = regnode.paramtype2;
			end
		
		-- we tried our best, but the replacement node is not defined	
		elseif( new_node_name ~= 'mg:ignore' ) then
			mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, 'ERROR: Did not find a suitable replacement for '..tostring( node_name )..' (suggested but inexistant: '..tostring( new_node_name )..'). Building: '..tostring( binfo_scm )..'.');
			new_nodes[ i ].ignore = 1; -- keep the old content
		else -- handle mg:ignore
			new_nodes[ i ].ignore = 1;
		end

		
	end
	return new_nodes;
end



local function generate_building(pos, minp, maxp, data, param2_data, a, extranodes, replacements, cid, extra_calls, building_nr_in_bpos, village_id)

	local binfo = mg_villages.BUILDINGS[pos.btype]
	local scm

	-- the building got removed from mg_villages.BUILDINGS in the meantime
	if( not( binfo )) then
		return;
	end

	-- schematics of .mts type are not handled here; they need to be placed using place_schematics
	if( binfo.is_mts == 1 ) then
		return;
	end

	if( pos.btype ~= "road" ) then
		generate_building_plotmarker( pos, minp, maxp, data, param2_data, a, cid, building_nr_in_bpos, village_id );
	end

	-- skip building if it is not located at least partly in the area that is currently beeing generated
	if(   pos.x > maxp.x or pos.x + pos.bsizex < minp.x
	   or pos.z > maxp.z or pos.z + pos.bsizez < minp.z ) then
		return;
	end


	if( pos.btype ~= "road" and
	  ((     binfo.sizex ~= pos.bsizex and binfo.sizex ~= pos.bsizez )
	    or ( binfo.sizez ~= pos.bsizex and binfo.sizez ~= pos.bsizez )
	    or not( binfo.scm_data_cache ))) then
		mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, 'ERROR: This village was created using diffrent buildings than those known know. Cannot place unknown building.');
		return;
	end

	if( binfo.scm_data_cache )then
		scm = binfo.scm_data_cache;
	else
		scm = binfo.scm
	end

	-- the fruit is set per building, not per village as the other replacements
	if( binfo.farming_plus and binfo.farming_plus == 1 and pos.fruit ) then
		mg_villages.get_fruit_replacements( replacements, pos.fruit);
	end

	local c_ignore = minetest.get_content_id("ignore")
	local c_air = minetest.get_content_id("air")
	local c_snow                 = minetest.get_content_id( "default:snow");
	local c_dirt                 = minetest.get_content_id( "default:dirt" );
	local c_dirt_with_grass      = minetest.get_content_id( "default:dirt_with_grass" );
	local c_dirt_with_snow       = minetest.get_content_id( "default:dirt_with_snow" );

	local scm_x = 0;
	local scm_z = 0;
	local step_x = 1;
	local step_z = 1;
	local scm_z_start = 0;

	if(     pos.brotate == 2 ) then
		scm_x  = pos.bsizex+1;
		step_x = -1;
	end
	if(     pos.brotate == 1 ) then
		scm_z  = pos.bsizez+1;
		step_z = -1;
		scm_z_start = scm_z;
	end
		
	local mirror_x = false;
	local mirror_z = false;
	if( pos.mirror ) then
		if( binfo.axis and binfo.axis == 1 ) then
			mirror_x = true;
			mirror_z = false;
		else
			mirror_x = false;
			mirror_z = true;
		end
	end

	-- translate all nodenames and apply the replacements
	local new_nodes = generate_building_translate_nodenames( binfo.nodenames, replacements, cid, binfo.scm, mirror_x, mirror_z );

	for x = 0, pos.bsizex-1 do
	scm_x = scm_x + step_x;
	scm_z = scm_z_start;
	for z = 0, pos.bsizez-1 do
		scm_z = scm_z + step_z;

		local xoff = scm_x;
		local zoff = scm_z;
		if(     pos.brotate == 2 ) then
			if( mirror_x ) then
				xoff = pos.bsizex - scm_x + 1;
			end
			if( mirror_z ) then
				zoff = scm_z;
			else
				zoff = pos.bsizez - scm_z + 1;
			end
		elseif( pos.brotate == 1 ) then
			if( mirror_x ) then
				xoff = pos.bsizez - scm_z + 1;
			else
				xoff = scm_z;
			end
			if( mirror_z ) then
				zoff = pos.bsizex - scm_x + 1;
			else
				zoff = scm_x;
			end
		elseif( pos.brotate == 3 ) then
			if( mirror_x ) then
				xoff = pos.bsizez - scm_z + 1;
			else
				xoff = scm_z;
			end
			if( mirror_z ) then
				zoff = scm_x;
			else
				zoff = pos.bsizex - scm_x + 1;
			end
		elseif( pos.brotate == 0 ) then
			if( mirror_x ) then
				xoff = pos.bsizex - scm_x + 1;
			end
			if( mirror_z ) then
				zoff = pos.bsizez - scm_z + 1;
			end
		end

		local has_snow    = false;
		local ground_type = c_dirt_with_grass; 
		for y = 0, binfo.ysize-1 do
			local ax = pos.x+x;
			local ay = pos.y+y+binfo.yoff;
			local az = pos.z+z;
			if (ax >= minp.x and ax <= maxp.x) and (ay >= minp.y and ay <= maxp.y) and (az >= minp.z and az <= maxp.z) then
	
				local new_content = c_air;
				local t = scm[y+1][xoff][zoff];

				if( binfo.yoff+y == 0 ) then
					local node_content = data[a:index(ax, ay, az)];
					-- no snow on the gravel roads
					if( node_content == c_dirt_with_snow or data[a:index(ax, ay+1, az)]==c_snow) then
						has_snow    = true;
					end

					ground_type = node_content;
				end
	
				if( t and type(t)=='table' and #t==2 and t[1] and t[2]) then
					local n = new_nodes[ t[1] ]; -- t[1]: id of the old node
					if( not( n.ignore )) then
						new_content = n.new_content;
					end

					-- replace all dirt and dirt with grass at that x,z coordinate with the stored ground grass node;
					if( n.is_grass ) then
						new_content = ground_type;
					end

					if( n.on_construct ) then
						if( not( extra_calls.on_constr[ new_content ] )) then
							extra_calls.on_constr[ new_content ] = { {x=ax, y=ay, z=az}};
						else
							table.insert( extra_calls.on_constr[ new_content ], {x=ax, y=ay, z=az});
						end
					end

					-- do not overwrite plotmarkers
					if( new_content ~= cid.c_air or data[ a:index(ax,ay,az)] ~= cid.c_plotmarker ) then
						data[       a:index(ax, ay, az)] = new_content;
					end

					-- store that a tree is to be grown there
					if(     n.is_tree ) then
						table.insert( extra_calls.trees,  {x=ax, y=ay, z=az, typ=new_content, snow=has_snow});

					-- we're dealing with a chest that might need filling
					elseif( n.is_chestlike ) then
						table.insert( extra_calls.chests, {x=ax, y=ay, z=az, typ=new_content, bpos_i=building_nr_in_bpos});

					-- the sign may require some text to be written on it
					elseif( n.is_sign ) then
						table.insert( extra_calls.signs,  {x=ax, y=ay, z=az, typ=new_content, bpos_i=building_nr_in_bpos});
					end

					-- handle rotation
					if(     n.paramtype2 ) then
						local param2 = t[2];
						if( n.change_param2 and  n.change_param2[ t[2] ]) then
							param2 = n.change_param2[ param2 ];
						end
	
						if(     mirror_x ) then
							np2 = rotation_table[ n.paramtype2 ][ param2+1 ][ pos.brotate+1 ][ 2 ];
						elseif( mirror_z ) then
							np2 = rotation_table[ n.paramtype2 ][ param2+1 ][ pos.brotate+1 ][ 3 ];
						else
							np2 = rotation_table[ n.paramtype2 ][ param2+1 ][ pos.brotate+1 ][ 1 ];
						end

--[[
						local param2list = mg_villages.get_param2_rotated( n.paramtype2, param2);
						local np2 = param2list[ pos.brotate + 1];
						-- mirror
						if(     mirror_x ) then
							if(     #param2list==5) then
								np2 = mg_villages.mirror_facedir[ ((pos.brotate+1)%2)+1 ][ np2+1 ];
							elseif( #param2list<5 
							       and  ((pos.brotate%2==1 and (np2==4 or np2==5)) 
						 	          or (pos.brotate%2==0 and (np2==2 or np2==3)))) then 
								np2 = param2list[ (pos.brotate + 2)%4 +1];
							end

						elseif( mirror_z ) then
							if(     #param2list==5) then
								np2 = mg_villages.mirror_facedir[ (pos.brotate     %2)+1 ][ np2+1 ];
							elseif( #param2list<5 
							       and  ((pos.brotate%2==0 and (np2==4 or np2==5)) 
						 	          or (pos.brotate%2==1 and (np2==2 or np2==3)))) then 
								np2 = param2list[ (pos.brotate + 2)%4 +1];
							end
						end
--]]

						param2_data[a:index(ax, ay, az)] = np2;
					else
						param2_data[a:index(ax, ay, az)] = t[2];
					end

				-- air and gravel (the road is structured like this)
				elseif (type(t) ~= 'table' and t ~= c_ignore) then
	
					new_content = t;
					if( t and replacements.ids[ t ] ) then
						new_content = replacements.ids[ t ];
					end
					if( t and t==c_dirt or t==c_dirt_with_grass ) then
						new_content = ground_type;
					end
					if( data[a:index(ax,ay,az)]==c_snow ) then
						has_snow = true;
					end
					data[a:index(ax, ay, az)] = new_content;
					-- param2 is not set here
				end
			end
		end

		local ax = pos.x + x;
		local az = pos.z + z;
		local y_top    = pos.y+binfo.yoff+binfo.ysize;
		if( y_top+1 > maxp.y ) then
			y_top = maxp.y-1;
		end
		local y_bottom = pos.y+binfo.yoff;
		if( y_bottom < minp.y ) then
			y_bottom = minp.y;
		end
		if( has_snow and ax >= minp.x and ax <= maxp.x and az >= minp.z and az <= maxp.z ) then
			local res = mg_villages.mg_drop_moresnow( ax, az, y_top, y_bottom-1, a, data, param2_data);
			if( res and data[ a:index(ax, res.height, az)]==cid.c_air) then
				data[       a:index(ax, res.height, az)] = res.suggested.new_id;
				param2_data[a:index(ax, res.height, az)] = res.suggested.param2;
				has_snow = false;
			end
		end
	end
	end
end



-- actually place the buildings (at least those which came as .we files; .mts files are handled later on)
-- this code is also responsible for tree placement
mg_villages.place_buildings = function(village, minp, maxp, data, param2_data, a, cid, village_id)
	local vx, vz, vs, vh = village.vx, village.vz, village.vs, village.vh
	local village_type = village.village_type;
	local seed = mg_villages.get_bseed({x=vx, z=vz})

	local bpos             = village.to_add_data.bpos;

	village.to_grow = {}; -- TODO this is a temporal solution to avoid flying tree trunks
	--generate_walls(bpos, data, a, minp, maxp, vh, vx, vz, vs, vnoise)
	local pr = PseudoRandom(seed)
	for _, g in ipairs(village.to_grow) do
		if pos_far_buildings(g.x, g.z, bpos) then
			mg.registered_trees[g.id].grow(data, a, g.x, g.y, g.z, minp, maxp, pr)
		end
	end

	local replacements = mg_villages.get_replacement_table( village.village_type, nil, village.to_add_data.replacements );

	cid.c_chest            = mg_villages.get_content_id_replaced( 'default:chest',          replacements );
	cid.c_chest_locked     = mg_villages.get_content_id_replaced( 'default:chest_locked',   replacements );
	cid.c_chest_private    = mg_villages.get_content_id_replaced( 'cottages:chest_private', replacements );
	cid.c_chest_work       = mg_villages.get_content_id_replaced( 'cottages:chest_work',    replacements );
	cid.c_chest_storage    = mg_villages.get_content_id_replaced( 'cottages:chest_storage', replacements );
	cid.c_chest_shelf      = mg_villages.get_content_id_replaced( 'cottages:shelf',         replacements );
	cid.c_chest_ash        = mg_villages.get_content_id_replaced( 'trees:chest_ash',        replacements );
	cid.c_chest_aspen      = mg_villages.get_content_id_replaced( 'trees:chest_aspen',      replacements );
	cid.c_chest_birch      = mg_villages.get_content_id_replaced( 'trees:chest_birch',      replacements );
	cid.c_chest_maple      = mg_villages.get_content_id_replaced( 'trees:chest_maple',      replacements );
	cid.c_chest_chestnut   = mg_villages.get_content_id_replaced( 'trees:chest_chestnut',   replacements );
	cid.c_chest_pine       = mg_villages.get_content_id_replaced( 'trees:chest_pine',       replacements );
	cid.c_chest_spruce     = mg_villages.get_content_id_replaced( 'trees:chest_spruce',     replacements );
	cid.c_sign             = mg_villages.get_content_id_replaced( 'default:sign_wall',      replacements );
--print('REPLACEMENTS: '..minetest.serialize( replacements.table )..' CHEST: '..tostring( minetest.get_name_from_content_id( cid.c_chest ))); -- TODO

	local extranodes = {}
	local extra_calls = { on_constr = {}, trees = {}, chests = {}, signs = {} };

	-- count the buildings
	local anz_buildings = 0;
	for i, pos in ipairs(bpos) do
		if( pos.btype and not(pos.btype == 'road' )) then 
			local binfo = mg_villages.BUILDINGS[pos.btype];
			-- count buildings which can house inhabitants as well as those requiring workers
			if( binfo and binfo.inh and binfo.inh ~= 0 ) then
				anz_buildings = anz_buildings + 1;
			end
		end
	end
	village.anz_buildings = anz_buildings;
	for i, pos in ipairs(bpos) do
		-- roads are only placed if there are at least mg_villages.MINIMAL_BUILDUNGS_FOR_ROAD_PLACEMENT buildings in the village
		if( not(pos.btype) or pos.btype ~= 'road' or anz_buildings > mg_villages.MINIMAL_BUILDUNGS_FOR_ROAD_PLACEMENT )then 
			-- replacements are in table format for mapgen-based building spawning
			generate_building(pos, minp, maxp, data, param2_data, a, extranodes, replacements, cid, extra_calls, i, village_id )
		end
	end

	-- replacements are in list format for minetest.place_schematic(..) type spawning
	return { extranodes = extranodes, bpos = bpos, replacements = replacements.list, dirt_roads = village.to_add_data.dirt_roads,
			plantlist = village.to_add_data.plantlist, extra_calls = extra_calls };
end


-- add the dirt roads
mg_villages.place_dirt_roads = function(village, minp, maxp, data, param2_data, a, c_road_node)
	local c_air = minetest.get_content_id( 'air' );
	for _, pos in ipairs(village.to_add_data.dirt_roads) do
		local param2 = 0;
		if( pos.bsizex > 2 ) then
			param2 = 1;
		end
		for x = 0, pos.bsizex-1 do
			for z = 0, pos.bsizez-1 do
				local ax = pos.x+x;
				local az = pos.z+z;
			
                      			if (ax >= minp.x and ax <= maxp.x) and (pos.y >= minp.y and pos.y <= maxp.y-2) and (az >= minp.z and az <= maxp.z) then
					-- roads have a height of 1 block
					data[ a:index( ax, pos.y, az)] = c_road_node;
					param2_data[ a:index( ax, pos.y, az)] = param2;
					-- ...with air above
					data[ a:index( ax, pos.y+1, az)] = c_air;
					data[ a:index( ax, pos.y+2, az)] = c_air;
				end
			end
		end
	end
end

if( minetest.get_modpath('moresnow' )) then
	mg_villages.moresnow_installed = true;
end
