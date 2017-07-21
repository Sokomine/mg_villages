


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

			player:moveto( {x=trader.x, y=(village.vh+1), z=trader.z} );
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

