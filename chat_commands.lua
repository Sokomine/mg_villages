-- Intllib
local S = mg_villages.intllib

minetest.register_privilege("mg_villages", { description = S("Allows to teleport to villages via").." /vist <nr>", give_to_singleplayer = false});

-- store per player which list of villages was offered
mg_villages.tmp_player_village_list = {};

-- list all plots of a village:
--   plot_nr, type of building, #inhabitants, occupation, name
mg_villages.list_plots_formspec = function( player, formname, fields )

	if( not( player ) or fields.quit or not( fields.village_id) or not( mg_villages.all_villages[ fields.village_id ])) then
		return
	end
	local pname = player:get_player_name();

	-- analyze the road network (this has not been done from the beginning..)
	mg_villages.get_road_list( fields.village_id, false );

	-- allow to click through the villages using prev/next buttons
	local liste = mg_villages.tmp_player_village_list[ pname ];
	local prev_next_button = "button[8.5,11.6;1,0.5;back_to_villagelist;Back]";
	if(   liste and #liste>1 and liste[1]~=fields.village_id ) then
		prev_next_button = prev_next_button..'button[9.5,11.6;1,0.5;prev;Prev]';
	end
	if(   liste and #liste>1 and liste[#liste]~=fields.village_id ) then
		prev_next_button = prev_next_button..'button[10.5,11.6;1,0.5;next;Next]';
	end

	local formspec = 'size[12,12]'..
			'field[20,20;0.1,0.1;village_id;VillageID;'..minetest.formspec_escape( fields.village_id ).."]"..
			'button_exit[4.0,1.0;2,0.5;quit;Exit]'..
			'button[9.5,1.0;3,0.5;back_to_villagelist;Back to village list]'..
			prev_next_button..
			'tablecolumns[' ..
			'text,align=right;'..	-- plot nr
			'text,align=center;'..	-- type of building
			'text,align=center;'..	-- amount of inhabitants
			'text,align=center;'..  -- occupation of first inhabitant
			'text,align=center;'..  -- name of first inhabitat
			'text,align=center]'..	-- comment
                        'table[0.1,2.0;11.4,8.8;'..formname..';'..
			'PlotNr,Type of building,'..minetest.formspec_escape('#Inhab.')..
				',Job,Owner,Comment,';

	local bpos_list = mg_villages.all_villages[ fields.village_id ].to_add_data.bpos;
	for plot_nr,bpos in ipairs( bpos_list ) do

		formspec = formspec..plot_nr..',';
		if( bpos.btype and bpos.btype ~= "road" and mg_villages.BUILDINGS[ bpos.btype ]) then
			formspec = formspec..mg_villages.BUILDINGS[ bpos.btype ].typ..',';
		else
			formspec = formspec..tostring( bpos.btype )..',';
		end
		if( not( bpos.beds ) or #bpos.beds<1 ) then
			if( bpos.worker and bpos.worker.lives_at and bpos_list[ bpos.worker.lives_at ]
			  and bpos_list[ bpos.worker.lives_at ].beds
			  and bpos_list[ bpos.worker.lives_at ].beds[1]) then
				local btype2 = mg_villages.BUILDINGS[ bpos_list[ bpos.worker.lives_at ].btype];
				local worker_plot = bpos_list[ bpos.worker.lives_at ];
				formspec = formspec..'-,'..
					( worker_plot.beds[1].title or '-')..','..
					( worker_plot.beds[1].first_name or '-')..','..
					"lives in the "..tostring( btype2.typ ).." on plot "..tostring( bpos.worker.lives_at )..',';
			elseif( bpos.belongs_to and bpos_list[ bpos.belongs_to ]) then
				formspec = formspec..'-,-,-,';
				local owner_plot = bpos_list[ bpos.belongs_to ];
				if( owner_plot and owner_plot.beds and owner_plot.beds[1] ) then
					formspec = formspec.."owned by "..
							( owner_plot.beds[1].title or '?')..' '..
							( owner_plot.beds[1].first_name or '?')..
							minetest.formspec_escape(" [plot "..tostring( bpos.belongs_to )..']')..',';
				else
					formspec = formspec.."owned by "..minetest.formspec_escape(" [plot "..tostring( bpos.belongs_to )..']')..',';
				end
			elseif( bpos.btype == "road" ) then
				if( not( bpos.parent_road_plot )) then
					formspec = formspec..'-,-,-,road stump,';
				elseif( bpos.parent_road_plot==0 ) then
					formspec = formspec..'-,-,-,main road,';
				else
					formspec = formspec..'-,-,-,road nr. '..tostring( bpos.road_nr)..
						minetest.formspec_escape(', sideroad of ');
					if( bpos_list[ bpos.parent_road_plot ].parent_road_plot == 0 ) then
						formspec = formspec..'the main road,';
					else
						formspec = formspec..'road nr. '..
							tostring( bpos_list[ bpos.parent_road_plot ].road_nr)..',';
					end
				end
			else
				formspec = formspec..'-,-,-,-,';
			end
		else
			formspec = formspec..tostring( #bpos.beds )..','..
				( bpos.beds[1].title or '-')..','..
				( bpos.beds[1].first_name or '-')..',';
			if( bpos.beds[1].works_at
			  and bpos.beds[1].works_at ~= plot_nr
			  and bpos_list[ bpos.beds[1].works_at ]) then
				local btype2 = mg_villages.BUILDINGS[ bpos_list[ bpos.beds[1].works_at].btype];
				formspec = formspec.."works at the "..tostring( btype2.typ ).." on plot "..tostring(bpos.beds[1].works_at)..",";
			else
				formspec = formspec.."-,";
			end
		end
	end
	formspec = formspec..';1]';
	minetest.show_formspec( pname, formname, formspec );
end


-- list all villages withhin a certain range of the player's position:
--   village_nr, distance from player, name of village, population,
--   type (i.e. "medieval"), x, y, z, diameter, #buildings, village/single house
-- this function is only used for the chat command "/villages" currently
mg_villages.list_villages_formspec = function( player, formname, fields )

	if( not( player ) or fields.quit) then
		return
	end
	local pname = player:get_player_name();
	local ppos  = player:get_pos();

	local radius = 1000000;
	-- without the special priv, players can only obtain informatoin about villages which are very close by
	if( not( minetest.check_player_privs( pname, {mg_villages=true}))) then
		radius = mg_villages.VILLAGE_DETECT_RANGE;
	end

	local formspec = 'size[12,12]'..
			'button_exit[4.0,1.0;2,0.5;quit;Exit]'..
			'tablecolumns[' ..
			'text,align=right;'..	-- village number
			'text,align=right;'..	-- distance from player
			'text,align=center;'..	-- name of village
			'text,align=center;'..  -- inhabitants
			'text,align=center;'..	-- typ of village
			'text,align=right;'..	-- x
			'text,align=right;'..	-- y
			'text,align=right;'..	-- z
			'text,align=right;'..	-- size
			'text,align=center;'..	-- #houses where inhabitants may live or work
			'text,align=right]'..
                        'table[0.1,2.0;11.4,8.8;'..formname..';'..
			'Nr,Dist,Name of village,Population,Type of village,_X_,_H_,_Z_,Size,'..minetest.formspec_escape('#Buildings')..',,';

	mg_villages.tmp_player_village_list[ pname ] = {};
	for k,v in pairs( mg_villages.all_villages ) do

		local dx = math.abs( v.vx - ppos.x );
		local dz = math.abs( v.vz - ppos.z );
		-- distance in y direction is less relevant here and may be ignored
		if( dx + dz < radius ) then
			local dist = math.sqrt( dx * dx + dz * dz );
			local is_full_village = 'village';
			if( v.is_single_house ) then
				is_full_village = '';
			end
			-- count the inhabitants
			if( not( v.population )) then
				v.population = 0;
				for _,pos in ipairs( v.to_add_data.bpos ) do
					if( pos and pos.beds ) then
						v.population = v.population + #pos.beds;
					end
				end
			end
			local show_population = v.population;
			if( show_population == 0 ) then
				show_population = "-";
			end
			formspec = formspec..
				v.nr..','..
				tostring( math.floor( dist ))..','..
				tostring( v.name or 'unknown' )..','..
				show_population..','..
				v.village_type..','..
				tostring( v.vx )..','..
				tostring( v.vh )..','..
				tostring( v.vz )..','..
				tostring( v.vs )..','..
				tostring( v.anz_buildings )..','..
				tostring( is_full_village )..',';

			-- store which list we have shown to this particular player
			table.insert( mg_villages.tmp_player_village_list[ pname ], k );
		end
	end
	formspec = formspec..';1]';
--		'tabheader[0.1,2.6;spalte;Nr,Dist,Name of village,Population,Type of village,_X_,_H_,_Z_,Size,'..minetest.formspec_escape('#Buildings')..';;true;true]';

	minetest.show_formspec( pname, formname, formspec );
end


minetest.register_chatcommand( 'villages', {
	description = S("Shows a list of all known villages."),
	privs = {},
	func = function(name, param)
		mg_villages.list_villages_formspec( minetest.get_player_by_name( name ), "mg_villages:formspec_list_villages", {});
        end
});


minetest.register_chatcommand( 'visit', {
        description = S("Teleports you to a known village."),
	params = "<village number>",
        privs = {},
        func = function(name, param)


		if( mg_villages.REQUIRE_PRIV_FOR_TELEPORT and not( minetest.check_player_privs( name, {mg_villages=true}))) then
			minetest.chat_send_player( name, S("You need the 'mg_villages' priv in order to teleport to villages using this command."));
			return;
		end

		if( not( param ) or param == "" ) then
			minetest.chat_send_player( name, S("Which village do you want to visit? Please provide the village number!"));
			return;
		end

		local nr = tonumber( param );
		for id, v in pairs( mg_villages.all_villages ) do
			-- we have found the village
			if( v and v.nr == nr ) then

				minetest.chat_send_player( name, S("Initiating transfer to village no. @1, called @2.", tostring( v.nr ), tostring( v.name or 'unknown')));
				local player =  minetest.get_player_by_name( name );
				player:move_to( { x=v.vx, y=(v.vh+1), z=v.vz }, false);
				return;
			end
		end
		-- no village found
		minetest.chat_send_player( name, "There is no village with the number "..tostring( param ).." (yet?).");
        end
});

minetest.register_chatcommand( 'village_mob_repopulate', {
        description = "Discards old mob data and assigns beds and workplaces anew. Mobs get new names.",
	params = "<village number>",
        privs = {},
        func = function(name, param)


		if( not( minetest.check_player_privs( name, {protection_bypass=true}))) then
			minetest.chat_send_player( name, "You need the 'protection_bypass' priv in order to delete all the old mob data of a village and to recalculate it anew.");
			return;
		end

		if( not( param ) or param == "" ) then
			minetest.chat_send_player( name, "Which village do you want to repopulate? Please provide the village number!");
			return;
		end

		local nr = tonumber( param );
		for id, v in pairs( mg_villages.all_villages ) do
			-- we have found the village
			if( v and v.nr == nr ) then

				minetest.chat_send_player( name, "Deleting information about workplaces and beds. Recalculating. Assigning new data for village no. "..tostring( v.nr )..", called "..( tostring( v.name or 'unknown'))..".");
				-- move the player to the center of the village he just changed
				local player =  minetest.get_player_by_name( name );
				player:move_to( { x=v.vx, y=(v.vh+1), z=v.vz }, false);

				local village_id = tostring( v.vx )..':'..tostring( v.vz );
				-- actually do the reassigning
				mg_villages.inhabitants.assign_mobs( v, village_id, true);
				-- save the modified data
				save_restore.save_data( 'mg_all_villages.data', mg_villages.all_villages );

				-- adjust beds and workplaces
				mg_villages.inhabitants.prepare_metadata( v, village_id, nil, nil );
				return;
			end
		end
		-- no village found
		minetest.chat_send_player( name, S("There is no village with the number @1 (Yet?)."), tostring( param ));
        end
});
