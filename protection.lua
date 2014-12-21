
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
				if( node
				   and node.name
				   and minetest.registered_nodes[ node.name ]
				   and minetest.registered_nodes[ node.name ].groups
				   and minetest.registered_nodes[ node.name ].groups.leaves ) then
					return nil;
				else
					return id;
				end
			end
		end
	end
	return nil;
end

local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)

	local village_id = mg_villages.get_town_id_at_pos( pos );
	if( village_id ) then
		for nr, p in ipairs( mg_villages.all_villages[ village_id ].to_add_data.bpos ) do
			if( p.owner and p.owner == name
			    and p.x <= pos.x and (p.x + p.bsizex) >= pos.x
			    and p.z <= pos.z and (p.z + p.bsizez) >= pos.z) then
				return false;
			end
		end
		return true;
	end
	return old_is_protected(pos, name);
end             

minetest.register_on_protection_violation( function(pos, name)
	local found = mg_villages.get_town_id_at_pos( pos );
	if( not( found ) or not( mg_villages.all_villages[ found ]))  then
		minetest.chat_send_player( name, 'Error: This area does not belong to a village.');
		return;
	end

	minetest.chat_send_player( name, "You are inside of the area of the village "..tostring( mg_villages.all_villages[ found ].name )..". The inhabitants do not allow you any modifications.");
end );

-- TODO: add a limited griefing liscence/buying of houses or plots for players


mg_villages.plotmarker_formspec = function( pos, formname, fields, player )

	local meta = minetest.get_meta( pos );
	if( not( meta )) then
		return;
	end
	local village_id = meta:get_string('village_id');
	local plot_nr    = meta:get_int(   'plot_nr');

	local pname      = player:get_player_name();

	if( not( village_id ) or not( mg_villages.all_villages ) or not( mg_villages.all_villages[ village_id ] )
	    or not( plot_nr ) or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] )) then

		minetest.chat_send_player( pname, 'Error. This plot marker is not configured correctly.'..minetest.serialize({village_id,plot_nr }));
		return;
	end
	local owner      = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner;
	local btype      = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].btype;
	
	local plot_descr = 'Plot No. '..tostring( plot_nr ).. ' with '..tostring( mg_villages.BUILDINGS[btype].scm);
	local formspec = "size[6,3]"..
			 "label[1.0,0.5;Plot No.: "..tostring( plot_nr ).."]"..
			 "label[2.5,0.5;Building:]"..
			 "label[3.5,0.5;"..tostring( mg_villages.BUILDINGS[btype].scm ).."]"..
			 "field[20,20;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string( pos ).."]";
	if(     owner == pname and fields['abandom'] ) then
		formspec = formspec.."label[0,2;You have abandomed this plot.]";
		mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = nil;
		meta:set_string('infotext', plot_descr );
		mg_villages.save_data();

	elseif( (not(owner) or owner=='') and fields['buy'] ) then
		-- TODO: check if the price can be paid
		formspec = formspec.."label[0,0;Congratulations! You have bought this plot.]";
		mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner = pname;
		meta:set_string('infotext', plot_descr..' (owned by '..tostring( pname )..')');
		mg_villages.save_data();
	end
	-- update the owner information
	owner      = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner;


	if( owner == pname ) then
		formspec = formspec.."label[1,1;This is your plot. You have bought it.]"..
				"button_exit[2,2.5;2.0,0.5;abandom;Abandom plot]"..
				"button_exit[4,2.5;1.5,0.5;abort;Exit]";
	elseif( not( owner ) or owner=="" ) then
		-- TODO: make price configurable
		formspec = formspec.."label[1,1;You can buy this plot for 2 gold ingots.]".. 
				"button_exit[2,2.5;1.5,0.5;buy;Buy plot]"..
				"button_exit[4,2.5;1.5,0.5;abort;Exit]";
	else
		formspec = formspec.."label[1,1;"..tostring( owner ).." owns this plot.]"..
				"button_exit[3,2.5;1.5,0.5;abort;Exit]";
	end

	minetest.show_formspec( pname, "mg_villages:plotmarker", formspec );
end



mg_villages.form_input_handler = function( player, formname, fields)
	if( (formname == "mg_villages:plotmarker") and fields.pos2str and not( fields.abort )) then
		local pos = minetest.string_to_pos( fields.pos2str );
		mg_villages.plotmarker_formspec( pos, formname, fields, player );
		return true;
	end
	return false;
end


minetest.register_on_player_receive_fields( mg_villages.form_input_handler )
