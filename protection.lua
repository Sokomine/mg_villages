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

local old_is_protected = minetest.is_protected
minetest.is_protected = function(pos, name)

	if( not( mg_villages.ENABLE_PROTECTION )) then
		return old_is_protected( pos, name );
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
		or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] )) then
		minetest.chat_send_player( pname, 'Error. This plot marker is not configured correctly.'..minetest.serialize({village_id,plot_nr }));
		return;
	end

	local owner      = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].owner;
	local btype      = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].btype;

	--minetest.chat_send_player( player:get_player_name(),'DATA FOR '..tostring(plot_nr)..': '..minetest.serialize( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] ));
	local original_formspec = "size[8,3]"..
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
