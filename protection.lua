-- get the id of the village pos lies in (or nil if outside of villages)
mg_villages.get_town_id_at_pos = function( pos )
	for id, v in pairs( mg_villages.all_villages ) do
		local size = v.vs * 3;
		if(   ( math.abs( pos.x - v.vx ) < size )
		  and ( math.abs( pos.z - v.vz ) < size )
		  and ( pos.y - v.vh < 40 and v.vh - pos.y < 10 )) then
			local village_noise = minetest.get_perlin(7635, 3, 0.5, 16);
			if( mg_villages.inside_village_area( pos.x,  pos.z, v, village_noise)) then

				local node = minetest.get_node( pos );
				-- leaves can be digged in villages
				if( node and node.name ) then
					if(    minetest.registered_nodes[ node.name ]
					   and minetest.registered_nodes[ node.name ].groups
				           and minetest.registered_nodes[ node.name ].groups.leaves ) then
						return nil;
					elseif( node.name=='default:snow' ) then
						return nil;
					-- bones can be digged in villages
					elseif( node.name == 'bones:bones' ) then
						return nil;
					else
						return id;
					end
				else
					return id;
				end
			end
		end
	end
	return nil;
end


-- search the trader (who is supposed to be at the given position) and
-- spawn a new one in case he went missing
mg_villages.plotmarker_search_trader = function( trader, height )

	local obj_list = minetest.get_objects_inside_radius({x=trader.x, y=height, z=trader.z}, 10 );
	for i,obj in ipairs( obj_list ) do
		local e = obj:get_luaentity();
		if( e and e.object ) then
			local p = e.object:getpos();
			if( p and p.x and math.abs(p.x-trader.x)<1.5
			      and p.z and math.abs(p.z-trader.z)<1.5
			      and e.name and e.name=="mobf_trader:trader"
			      and e.trader_typ and e.trader_typ==trader.typ) then
--				minetest.chat_send_player( "singleplayer", "FOUND trader "..tostring( e.trader_typ)); --TODO
			end
		end
	end
end


-- checks if the plot marker is still present; places a new one if needed
-- p: plot data (position, size, orientation, owner, ..)
mg_villages.check_plot_marker = function( p, plot_nr, village_id )
	-- roads cannot be bought
	if( p.btype and p.btype=="road" ) then
		return;
	end
	local plot_pos = { x=p.x, y=p.y, z=p.z };
	if(      p.o==3 ) then
		plot_pos = { x=p.x,            y=p.y+1, z=p.z-1          };
	elseif(  p.o==1 ) then
		plot_pos = { x=p.x+p.bsizex-1, y=p.y+1, z=p.z+p.bsizez   };
	elseif ( p.o==2 ) then
		plot_pos = { x=p.x+p.bsizex,   y=p.y+1, z=p.z            };
	elseif ( p.o==0 ) then
		plot_pos = { x=p.x-1,          y=p.y+1, z=p.z+p.bsizez-1 };
	end
	-- is the plotmarker still present?
	local node = minetest.get_node( plot_pos );
	if( not(node) or not(node.name) or node.name ~= "mg_villages:plotmarker" ) then
		-- place a new one if needed
		minetest.set_node( plot_pos, {name="mg_villages:plotmarker", param2=p.o});
		local meta = minetest.get_meta( plot_pos );
		-- strange error happend; maybe we're more lucky next time...
		if( not( meta )) then
			return;
		end
		meta:set_string('village_id', village_id );
		meta:set_int(   'plot_nr',    plot_nr );
	end
end



local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)

	if( not( mg_villages.ENABLE_PROTECTION )) then
		return old_is_protected( pos, name );
	end

	-- allow players with protection_bypass to build anyway
	if( minetest.check_player_privs( name, {protection_bypass=true})) then
		return false;
	end

	local village_id = mg_villages.get_town_id_at_pos( pos );
	if( village_id ) then
		local is_houseowner = false;
		for nr, p in ipairs( mg_villages.all_villages[ village_id ].to_add_data.bpos ) do

			trustedusers = p.can_edit
			trustedUser = false
			if trustedusers ~= nil then
				for _,trusted in ipairs(trustedusers) do
					if trusted == name then
						trustedUser = true
					end
				end
			end

			-- we have located the right plot; the player can build here if he owns this particular plot
			if(   p.x <= pos.x and (p.x + p.bsizex) >= pos.x
			  and p.z <= pos.z and (p.z + p.bsizez) >= pos.z) then

				-- place a new plot marker if necessary
				mg_villages.check_plot_marker( p, nr, village_id );

				-- If player has been trusted by owner, can build
				if (trustedUser) then
					return false;
				-- If player is owner, can build
				elseif( p.owner and p.owner == name ) then
					return false;
				-- the allmende can be used by all
				elseif( mg_villages.BUILDINGS[p.btype] and mg_villages.BUILDINGS[p.btype].typ=="allmende" ) then
					return false;
				-- the player cannot modify other plots, even though he may be house owner of another house and be allowed to modify common ground
				else
					return true;
				end
			-- if the player just owns another plot in the village, check if it's one where villagers may live
			elseif( p.owner and p.owner == name or trustedUser) then
				local btype = mg_villages.all_villages[ village_id ].to_add_data.bpos[ nr ].btype;
				if(   btype ~= 'road'
				  and mg_villages.BUILDINGS[btype]
				  and mg_villages.BUILDINGS[btype].inh
				  and mg_villages.BUILDINGS[btype].inh > 0 ) then
					is_houseowner = true;
					-- check the node below
					local node = minetest.get_node( {x=pos.x, y=pos.y-1, z=pos.z});
					-- replace the fake, inaktive village soil with real farming soil if a player diggs the plant above
					if( node and node.name and node.name=="mg_villages:soil" ) then
						minetest.swap_node( {x=pos.x, y=pos.y-1, z=pos.z}, {name="farming:soil_wet"});
					end
				end
			end
		end
		-- players who own a house in town where villagers may live (not only work!)
		--  are allowed to modify common ground
		if( is_houseowner ) then
			return false;
		end
		return true;
	end
	return old_is_protected(pos, name);
end			 


minetest.register_on_protection_violation( function(pos, name)

	if( not( mg_villages.ENABLE_PROTECTION )) then
		return;
	end

	local found = mg_villages.get_town_id_at_pos( pos );
	if( not( found ) or not( mg_villages.all_villages[ found ]))  then
		minetest.chat_send_player( name, 'Error: This area does not belong to a village.');
		return;
	end

	minetest.chat_send_player( name, "You are inside of the area of the village "..
		tostring( mg_villages.all_villages[ found ].name )..
		". The inhabitants do not allow you any modifications.");
end );



mg_villages.plotmarker_formspec = function( pos, formname, fields, player )

--	if( not( mg_villages.ENABLE_PROTECTION )) then
--		return;
--	end
	if( not( pos )) then
		return;
	end
	local meta = minetest.get_meta( pos );
	if( not( meta )) then
		return;
	end
	local village_id = meta:get_string('village_id');
	local plot_nr    = meta:get_int(   'plot_nr');
	local pname      = player:get_player_name();

	if( not( village_id )
		or not( mg_villages.all_villages )
		or not( mg_villages.all_villages[ village_id ] )
		or not( plot_nr )
		or not( mg_villages.all_villages[ village_id ].to_add_data )
		or not( mg_villages.all_villages[ village_id ].to_add_data.bpos )
		or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] )) then
		minetest.chat_send_player( pname, 'Error. This plot marker is not configured correctly.'..minetest.serialize({village_id,plot_nr }));
		return;
	end

	local village    = mg_villages.all_villages[ village_id ];
	local plot       = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ];

	local owner_name = plot.owner;
	if( not( owner_name ) or owner_name == "" ) then
		if( plot.btype=="road" ) then
			owner_name = "- the village community -";
		else
			owner_name = "- for sale -";
		end
	end

	local building_name = mg_villages.BUILDINGS[ plot.btype ].mts_path..mg_villages.BUILDINGS[ plot.btype ].scm;

	-- show coordinates of the village center to the player
	local village_pos = minetest.pos_to_string( {x=village.vx, y=village.vh, z=village.vz});
	-- distance from village center
	local distance = math.floor( math.sqrt( (village.vx - pos.x ) * (village.vx - pos.x )
					      + (village.vh - pos.y ) * (village.vh - pos.y )
					      + (village.vz - pos.z ) * (village.vz - pos.z ) ));

	if( fields and fields.inhabitants ) then
		minetest.chat_send_player( player:get_player_name(), mg_villages.inhabitants.print_house_info( village.to_add_data.bpos, plot_nr ));

		if( not( minetest.get_modpath( "mob_world_interaction"))) then
			return;
		end
		-- TODO: only for testing
		local bpos = village.to_add_data.bpos[ plot_nr ];
		if( bpos and bpos.beds ) then
			for i,bed in ipairs( bpos.beds ) do
				-- find a place next to the bed where the mob can stand
				local p_next_to_bed = mob_world_interaction.find_place_next_to( bed, 0, {x=0,y=0,z=0});
				if( not( p_next_to_bed ) or p_next_to_bed.iteration==99 ) then
					minetest.chat_send_player("singleplayer", "Bed Nr. "..tostring(i).." at "..minetest.pos_to_string( bed )..": FAILED to find a place to stand.");
				else
					-- position in front of the building, with the building stretching equally to the right and left
					-- get a diffrent one for each mob
					local p_in_front = handle_schematics.get_pos_in_front_of_house( bpos, i );
					local path = mob_world_interaction.find_path( p_next_to_bed, p_in_front, { collisionbox = {1,0,3,4,2}});
					local str = "";
					if( path ) then
						str = str.."Bed Nr. "..tostring(i).." at "..minetest.pos_to_string( bed )..": "..tostring( table.getn( path )).." Steps to outside.";
						local front_door_pos = nil;
						for j,p in ipairs( path ) do
							local n = minetest.get_node( p );
							if( n and n.name and mob_world_interaction.door_type[ n.name ]=="door_a_b") then
								front_door_pos = p;
							end
						end
						if( front_door_pos ) then
							str = str.." Front door found at: "..minetest.pos_to_string( front_door_pos );
						end
					else
						str = str.." FAILED to find a path from bed "..minetest.pos_to_string(bed )..", standing at "..minetest.pos_to_string( p_next_to_bed )..", to front of house.";
					end
					minetest.chat_send_player("singleplayer", str );
				end
			end
		end


		return;
	end

	-- create the header
	local formspec = "size[13,10]"..
		"label[3.3,0.0;Plot No.: "..tostring( plot_nr )..", with "..tostring( mg_villages.BUILDINGS[ plot.btype ].scm ).."]"..
		"label[0.3,0.4;Located at:]"      .."label[3.3,0.4;"..(minetest.pos_to_string( pos ) or '?')..", which is "..tostring( distance ).." m away]"
		                                  .."label[7.3,0.4;from the village center]"..
		"label[0.3,0.8;Part of village:]" .."label[3.3,0.8;"..(village.name or "- name unknown -").."]"
		                                  .."label[7.3,0.8;located at "..(village_pos).."]"..
		"label[0.3,1.2;Owned by:]"        .."label[3.3,1.2;"..(owner_name).."]"..
		"label[3.3,1.6;Click on a menu entry to select it:]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
                            build_chest.show_size_data( building_name );

--[[
	if( plot and plot.traders ) then -- TODO: deprecated; but may be useful in a new form for mobs that live in the house
		if( #plot.traders > 1 ) then
			formspec = formspec.."label[0.3,7.0;Some traders live here. One works as a "..tostring(plot.traders[1].typ)..".]";
			for i=2,#plot.traders do
				formspec = formspec.."label[0.3,"..(6.0+i)..";Another trader works as a "..tostring(plot.traders[i].typ)..".]";
			end
		elseif( plot.traders[1] and plot.traders[1].typ) then
			formspec = formspec..
				"label[0.3,7.0;A trader lives here. He works as a "..tostring( plot.traders[1].typ )..".]";
		else
			formspec = formspec..
				"label[0.3,7.0;No trader currently works at this place.]";
		end
		-- add buttons for visiting (teleport to trader), calling (teleporting trader to plot) and firing the trader
		for i,trader in ipairs(plot.traders) do
			local trader_entity = mg_villages.plotmarker_search_trader( trader, village.vh );

			formspec = formspec..
					"button[6.0,"..(6.0+i)..";1.2,0.5;visit_trader_"..i..";visit]"..
					"button[7.4,"..(6.0+i)..";1.2,0.5;call_trader_"..i..";call]"..
					"button[8.8,"..(6.0+i)..";1.2,0.5;fire_trader_"..i..";fire]";

			if( fields[ "visit_trader_"..i ] ) then

				player:moveto( {x=trader.x, y=(village.vh+1), z=trader.z} );
				minetest.chat_send_player( pname, "You are visiting the "..tostring( trader.typ )..
					" trader, who is supposed to be somewhere here. He might also be on a floor above you.");
				return;
			end
			if( fields[ "visit_call_"..i ] ) then
				-- TODO: spawning: mob_basics.spawn_mob( {x=v.x, y=v.y, z=v.z}, v.typ, nil, nil, nil, nil, true );
			end
			-- TODO: fire mob
		end
		formspec = formspec.."button[3.75,"..(7.0+math.max(1,#plot.traders))..";3.5,0.5;hire_trader;Hire a new random trader]";
		-- TODO: hire mob
	end
--]]

	local replace_row = -1;
	-- the player selected a material which ought to be replaced
	if(     fields.build_chest_replacements ) then
                local event = minetest.explode_table_event( fields.build_chest_replacements );
                if( event and event.row and event.row > 0 ) then
                        replace_row = event.row;
			fields.show_materials = "show_materials";
                end

	-- the player provided the name of the material for the replacement of the currently selected
	elseif( fields.store_replacement    and fields.store_repalcement    ~= ""
	    and fields.replace_row_with     and fields.replace_row_with     ~= ""
	    and fields.replace_row_material and fields.replace_row_material ~= "") then

                build_chest.replacements_apply( pos, meta, fields.replace_row_material, fields.replace_row_with, village_id );
		fields.show_materials = "show_materials";


	-- group selections for easily changing several nodes at once
	elseif( fields.wood_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'wood',    fields.wood_selection,    fields.set_wood,    village_id );
                fields.set_wood    = nil;
		fields.show_materials = "show_materials";

	elseif( fields.farming_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'farming', fields.farming_selection, fields.set_farming, village_id );
                fields.set_farming = nil;
		fields.show_materials = "show_materials";

	elseif( fields.roof_selection ) then
                build_chest.replacements_apply_for_group( pos, meta, 'roof',    fields.roof_selection,    fields.set_roof,    village_id );
                fields.set_roof    = nil;
		fields.show_materials = "show_materials";


	-- actually store the new group replacement
	elseif(  (fields.set_wood    and fields.set_wood     ~= "")
	      or (fields.set_farming and fields.set_farming ~= "" )
	      or (fields.set_roof    and fields.set_roof    ~= "" )) then
		minetest.show_formspec( pname, "mg_villages:plotmarker",
				handle_schematics.get_formspec_group_replacement( pos, fields, formspec ));
		return;
	end

	-- show which materials (and replacements!) where used for the building
        if( (fields.show_materials       and fields.show_materials ~= "" )
	 or (fields.replace_row_with     and fields.replace_row_with ~= "")
	 or (fields.replace_row_material and fields.replace_row_material ~= "")) then

		formspec = formspec.."button[9.9,0.4;2,0.5;info;Back]";
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			-- do not allow any changes; just show the materials and their replacements
			minetest.show_formspec( pname, "mg_villages:plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 0, meta, village_id, building_name, replace_row ));
		else
			minetest.show_formspec( pname, "mg_villages:plotmarker",
				formspec..build_chest.replacements_get_list_formspec( pos, nil, 1, nil,  village_id, building_name, replace_row ));
		end
		return;

	-- place the building again
	elseif(   (fields.reset_building  and fields.reset_building  ~= "")
           or (fields.remove_building and fields.remove_building ~= "")) then

		formspec = formspec.."button[9.9,0.4;2,0.5;back;Back]";

		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			minetest.show_formspec( pname, "mg_villages:plotmarker", formspec..
				"label[3,3;You need the protection_bypass priv in order to use this functin.]" );
			return;
		end

		local selected_building = build_chest.building[ building_name ];
		local start_pos = {x=plot.x, y=plot.y, z=plot.z, brotate=plot.brotate};
		if( selected_building.yoff ) then
			start_pos.y = start_pos.y + selected_building.yoff;
		end
		local end_pos = {x=plot.x+plot.bsizex-1,
				 y=plot.y+selected_building.yoff-1+selected_building.ysize,
				 z=plot.z+plot.bsizez-1};

		local replacements = build_chest.replacements_get_current( meta, village_id );

		if( fields.remove_building and fields.remove_building ~= "" ) then
			-- clear the space above ground, put dirt below ground, but keep the
			-- surface intact
			handle_schematics.clear_area( start_pos, end_pos, pos.y-1);
			-- also clear the meta data to avoid strange effects
			handle_schematics.clear_meta( start_pos, end_pos );
			formspec = formspec.."label[3,3;The plot has been cleared.]";
		else
			-- actually place it (disregarding mirroring)
			local error_msg = handle_schematics.place_building_from_file(
						start_pos,
						end_pos,
						building_name,
						replacements,
						plot.o,
						build_chest.building[ building_name ].axis, plot.mirror, 1, true );
			formspec = formspec.."label[3,3;The building has been reset.]";
			if( error_msg ) then
				formspec = formspec..'label[4,3;Error: '..tostring( fields.error_msg ).."]";
	                end
		end
		minetest.show_formspec( pname, "mg_villages:plotmarker", formspec );
		return;

	elseif( fields.info and fields.info ~= "" ) then
		local show_material_text = "Change materials used";
		if( not( minetest.check_player_privs( pname, {protection_bypass=true}))) then
			show_material_text = "Show materials used";
		end

		minetest.show_formspec( pname, "mg_villages:plotmarker",
			formspec..
				"button[9.9,0.4;2,0.5;back;Back]"..
				"button[3,3;5,0.5;create_backup;Create backup of current stage]"..
				"button[4,4;3,0.5;show_materials;"..show_material_text.."]"..
				"button[4,5;3,0.5;reset_building;Reset building]"..
				"button[4,6;3,0.5;remove_building;Remove building]");
		return;
	end

	local owner      = plot.owner;
	local btype      = plot.btype;


	local original_formspec = "size[8,3]"..
		"button[7.0,0.0;1.0,0.5;info;Info]"..
		"button[6.0,1.0;2.0,0.5;inhabitants;Who lives here]"..
		"label[1.0,0.5;Plot No.: "..tostring( plot_nr ).."]"..
		"label[2.5,0.5;Building:]"..
		"label[3.5,0.5;"..tostring( mg_villages.BUILDINGS[btype].scm ).."]"..
		"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
		local formspec = "";
	local ifinhabit = "";

	-- Get Price
	local price = "default:gold_ingot 2";

	if (btype ~= 'road' and mg_villages.BUILDINGS[btype]) then
		local plot_descr = 'Plot No. '..tostring( plot_nr ).. ' with '..tostring( mg_villages.BUILDINGS[btype].scm)

		if (mg_villages.BUILDINGS[btype].price) then
			price = mg_villages.BUILDINGS[btype].price;
		elseif (mg_villages.BUILDINGS[btype].typ and mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ]) then
			price = mg_villages.prices[ mg_villages.BUILDINGS[btype].typ ];
		end
		-- Get if is inhabitant house
		if (mg_villages.BUILDINGS[btype].inh and mg_villages.BUILDINGS[btype].inh > 0 ) then
			ifinhabit = "label[1,1.5;Owners of this plot count as village inhabitants.]";
		end
	end
	-- Determine price depending on building type
	local price_stack= ItemStack( price );


	-- If nobody owns the plot
	if (not(owner) or owner=='') then

		formspec = original_formspec ..
			"label[1,1;You can buy this plot for]".. 
			"label[3.8,1;"..tostring( price_stack:get_count() ).." x ]"..
			"item_image[4.3,0.8;1,1;"..(  price_stack:get_name() ).."]"..
			ifinhabit..
			"button[2,2.5;1.5,0.5;buy;Buy plot]"..
			"button_exit[4,2.5;1.5,0.5;abort;Exit]";

		-- On Press buy button
		if (fields['buy']) then
			local inv = player:get_inventory();

			if not mg_villages.all_villages[village_id].ownerlist then
				mg_villages.all_villages[village_id].ownerlist = {}
			end

			-- Check if player already has a house in the village
			if mg_villages.all_villages[village_id].ownerlist[pname] then
				formspec = formspec.."label[1,1.9;Sorry. You already have a plot in this village.]";

			-- Check if the price can be paid
			elseif( inv and inv:contains_item( 'main', price_stack )) then
				formspec = original_formspec..
					"label[1,1;Congratulations! You have bought this plot.]"..
					"button_exit[5.75,2.5;1.5,0.5;abort;Exit]";
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = pname;
				if mg_villages.all_villages[village_id].ownerlist then
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				else
					mg_villages.all_villages[village_id].ownerlist[pname] = true;
				end
				meta:set_string('infotext', 'Plot No. '..tostring( plot_nr ).. ' with '..tostring( mg_villages.BUILDINGS[btype].scm)..' (owned by '..tostring( pname )..')');
				-- save the data so that it survives server restart
				mg_villages.save_data();
				-- substract the price from the players inventory
				inv:remove_item( 'main', price_stack );
			else
				formspec = formspec.."label[1,1.9;Sorry. You are not able to pay the price.]";
			end
		end

	-- If player is the owner of the plot
	elseif (owner==pname) then

		-- Check if inhabitant house
		if(btype ~= 'road'
			and mg_villages.BUILDINGS[btype]
			and mg_villages.BUILDINGS[btype].inh
			and mg_villages.BUILDINGS[btype].inh > 0 ) then

			ifinhabit = "label[1,1.5;You are allowed to modify the common village area.]";
		end

		formspec = original_formspec.."size[8,3]"..
			"label[1,1;This is your plot. You have bought it.]"..
			"button[0.75,2.5;3,0.5;add_remove;Add/Remove Players]"..
			ifinhabit..
			"button_exit[3.75,2.5;2.0,0.5;abandon;Abandon plot]"..
			"button_exit[5.75,2.5;1.5,0.5;abort;Exit]";

		-- If Player wants to abandon plot
		if(fields['abandon'] ) then
			formspec = original_formspec..
				"label[1,1;You have abandoned this plot.]"..
				"button_exit[5.75,2.5;1.5,0.5;abort;Exit]";
			mg_villages.all_villages[village_id].ownerlist[pname] = nil;
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit = {}
			mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = nil;
			-- Return price to player
			local inv = player:get_inventory();
			inv:add_item( 'main', price_stack );
			meta:set_string('infotext', 'Plot No. '..tostring( plot_nr ).. ' with '..tostring( mg_villages.BUILDINGS[btype].scm) );
			mg_villages.save_data();
		end

		-- If Player wants to add/remove trusted players
		if (fields['add_remove']) then
			local previousTrustees = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit
			local output = "";
			if previousTrustees == nil then
				previousTrustees = {}
			else
				for _, player in ipairs(previousTrustees) do
					output = output..player.."\n"
				end
			end
			formspec = "size[8,3]"..
				"field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]"..
				"textarea[0.3,0.2;8,2.5;ownerplayers;Trusted Players;"..output.."]"..
				"button[3.25,2.5;1.5,0.5;savetrustees;Save]";

			mg_villages.save_data()
		end

		-- Save trusted players
		if (fields["savetrustees"] == "Save") then

			if not mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit then
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit = {}
			end

			local x = 1;
			for _, player in ipairs(fields.ownerplayers:split("\n")) do
				mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].can_edit[x] = player
				x = x + 1
			end

			mg_villages.save_data();
		end

	-- If A different Player owns plot
	else
		formspec = original_formspec.."label[1,1;"..tostring( owner ).." owns this plot.]"..
					"button_exit[3,2.5;1.5,0.5;abort;Exit]";
	end

	minetest.show_formspec( pname, "mg_villages:plotmarker", formspec );
end



mg_villages.form_input_handler = function( player, formname, fields)
--	mg_villages.print(mg_villages.DEBUG_LEVEL_NORMAL,minetest.serialize(fields));
	if( not( mg_villages.ENABLE_PROTECTION )) then
		return false;
	end
	if( (formname == "mg_villages:plotmarker") and fields.pos2str and not( fields.abort )) then
		local pos = minetest.string_to_pos( fields.pos2str );
		mg_villages.plotmarker_formspec( pos, formname, fields, player );
		return true;
	end
	return false;
end


minetest.register_on_player_receive_fields( mg_villages.form_input_handler )
