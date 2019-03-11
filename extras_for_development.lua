


-- provide a list of roads; function mg_villages.identify_parent_roads got lost somehow
mg_villages.extra_show_road_list = function( village_id )
	if( not( village_id ) or not( mg_villages.all_villages[ village_id ] )) then
		return;
	end
	local str = "List of roads:\n";
	local bpos_list = mg_villages.all_villages[ village_id ].village.to_add_data.bpos;
	-- find out which road branches off from which other road
	mg_villages.identify_parent_roads( bpos_list );
	for i,pos in ipairs( bpos_list ) do
		if( pos.btype and pos.btype=="road" ) then
			str = str.." Plot "..tostring(i)..": road nr. "..tostring(pos.road_nr)..
				" branching off from road on plot nr "..tostring(pos.parent_road)..
				"\n     data: "..minetest.serialize( pos ).."\n";
		end
	end
	minetest.chat_send_player(pname, str );
end

-- DEPRECATED
-- search the trader (who is supposed to be at the given position) and
-- spawn a new one in case he went missing
mg_villages.plotmarker_search_trader = function( trader, height )

	local obj_list = minetest.get_objects_inside_radius({x=trader.x, y=height, z=trader.z}, 10 );
	for i,obj in ipairs( obj_list ) do
		local e = obj:get_luaentity();
		if( e and e.object ) then
			local p = e.object:get_pos();
			if( p and p.x and math.abs(p.x-trader.x)<1.5
			      and p.z and math.abs(p.z-trader.z)<1.5
			      and e.name and e.name=="mobf_trader:trader"
			      and e.trader_typ and e.trader_typ==trader.typ) then
--				minetest.chat_send_player( "singleplayer", "FOUND trader "..tostring( e.trader_typ)); --TODO
			end
		end
	end
end


-- TODO: deprecated; but may be useful in a new form for mobs that live in the house
mg_villages.plotmarker_list_traders = function( plot, formspec )
	if( not( plot ) or not( plot.traders )) then
		return formspec;
	end

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

			player:move_to( {x=trader.x, y=(village.vh+1), z=trader.z} );
			minetest.chat_send_player( pname, "You are visiting the "..tostring( trader.typ )..
				" trader, who is supposed to be somewhere here. He might also be on a floor above you.");
			return formspec;
		end
		if( fields[ "visit_call_"..i ] ) then
			-- TODO: spawning: mob_basics.spawn_mob( {x=v.x, y=v.y, z=v.z}, v.typ, nil, nil, nil, nil, true );
		end
		-- TODO: fire mob
	end
	formspec = formspec.."button[3.75,"..(7.0+math.max(1,#plot.traders))..";3.5,0.5;hire_trader;Hire a new random trader]";
	-- TODO: hire mob
	return formspec;
end


-- provide debug information about mobs, let mobf_traders work around to some degree etc
mg_villages.mob_spanwer_on_rightclick = function( pos, node, clicker, itemstack, pointed_thing)
	if( not( clicker )) then
		return;
	end
	local meta = minetest.get_meta( pos );
	if( not( meta )) then
		return;
	end
	local village_id = meta:get_string( "village_id" );
	local plot_nr    = meta:get_int(    "plot_nr" );
	local bed_nr     = meta:get_int(    "bed_nr" );
	-- direction for the mob to look at
	local yaw        = meta:get_int(    "yaw" );

	local mob_info = mg_villages.inhabitants.get_mob_data( village_id, plot_nr, bed_nr );

	local str = "Found: ";
	local mob_pos = nil;
	local mob = nil;
	if( mob_info.mob_id and mob_basics) then
		mob = mob_basics.find_mob_by_id( mob_info.mob_id, "trader" );
		if( mob ) then
			mob_pos = mob.object:get_pos();
			if( mob_pos and mob_pos.x == pos.x and mob_pos.z == pos.z ) then
				str = str.." yes, waiting right here. ";
				mob.trader_does = "stand";
			-- TODO: detect "in his bed"
			elseif( mob.trader_does == "sleep" and mob.trader_uses and mob.trader_uses.x ) then
				str = str.." yes, sleeping in bed at "..minetest.pos_to_string( mob.trader_uses )..". ";
			else
				str = str.." yes, at "..minetest.pos_to_string( mob_pos)..". Teleporting here.";
				mob.trader_does = "stand";
				mob_world_interaction.stand_at( mob, pos, yaw );
			end
		else
			str = str.." - not found -. ";
		end
	end

	local res = mg_villages.get_plot_and_building_data( village_id, plot_nr );
	if( not( res ) or not( res.bpos ) or not( mob_info.mob_id ) or not( mob ) or not( mob_world_interaction) or not( movement)) then
		minetest.chat_send_player( clicker:get_player_name(), str.."Mob data: "..minetest.serialize(mob_info));
		return;
	end
	-- use door_nr 1;
	local path = nil;
	if( mob and mob.trader_does == "sleep" ) then
		path = mg_villages.get_path_from_bed_to_outside( village_id, plot_nr, bed_nr, 1 );
		-- get out of the bed, walk to the middle of the front of the house
		if( path and #path>0 ) then
			mob_world_interaction.stand_at( mob, path[1], yaw );
			-- last step: go back to the mob spawner that belongs to the mob
			table.insert( path, pos );
			str = str.." The mob plans to get up from his bed and stand in front of his house.\n";
		else
			str = str.." FAILED to get a path from bed to outside.\n";
		end
	else
		-- go to bed and sleep
		path = mg_villages.get_path_from_outside_to_bed( village_id, plot_nr, bed_nr, 1 );
		str = str.." The mob plans to go to his bed and start sleeping.\n";

--			local target_plot_nr = 9; -- just for testing..
--			path = mg_villages.get_path_from_pos_to_plot_via_roads( village_id, pos, target_plot_nr );
--			str = str.." The mob plans to go to plot nr. "..tostring(target_plot_nr).."\n";
	end
	local move_obj = movement.getControl(mob);
	move_obj:walk_path( path, 1, {find_path == true});

	minetest.chat_send_player( clicker:get_player_name(), str.."Mob data: "..minetest.serialize(mob_info));
end



-- check if all mobs have beds and paths from beds to mob spawners in front of the house can be calculated;
-- deprecated since pathfinding is now done in the blueprints
mg_villages.debug_inhabitants = function( village, plot_nr)
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
					str = str.."Bed Nr. "..tostring(i).." at "..minetest.pos_to_string( bed )..", standing at "..minetest.pos_to_string( p_next_to_bed )..": "..tostring( table.getn( path )).." Steps to outside.";
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
end
