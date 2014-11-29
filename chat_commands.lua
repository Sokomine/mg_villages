
minetest.register_privilege("mg_villages", { description = "Allows to teleport to villages via /vist <nr>", give_to_singleplayer = false});

-- this function is only used for the chat command currently
mg_villages.list_villages_formspec = function( player, formname, fields )

	if( not( player ) or fields.quit) then
		return
	end
	local pname = player:get_player_name();
	local ppos  = player:getpos();


	local radius = 1000000;
	-- without the special priv, players can only obtain informatoin about villages which are very close by
	if( not( minetest.check_player_privs( pname, {mg_villages=true}))) then
		radius = mg_villages.VILLAGE_DETECT_RANGE;
	end

	local formspec = 'size[12,12]'..
			'button_exit[4.0,1.5;2,0.5;quit;Quit]'..
			'tablecolumns[' ..
			'text,align=right;'..	-- village number
			'text,align=right;'..	-- distance from player
			'text,align=center;'..	-- name of village
			'text,align=center;'..	-- typ of village
			'text,align=right;'..	-- x
			'text,align=right;'..	-- y
			'text,align=right;'..	-- z
			'text,align=right;'..	-- size
			'text,align=right;'..	-- #houses where inhabitants may live or work
			'text,align=right]'..
                        'table[0.1,2.7;11.4,8.8;'..formname..';';

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
			formspec = formspec..
				v.nr..','..
				tostring( math.floor( dist ))..','..
				tostring( v.name or 'unknown' )..','..
				v.village_type..','..
				tostring( v.vx )..','..
				tostring( v.vh )..','..
				tostring( v.vz )..','..
				tostring( v.vs )..','..
				tostring( v.anz_buildings )..','..
				tostring( is_full_village )..',';
		end
	end

 	formspec = formspec..';]'..
			'tabheader[0.1,2.2;spalte;Nr,Dist,Name of village,Type of village,_X_,_H_,_Z_,Size,Buildings;;true;true]';

	minetest.show_formspec( pname, formname, formspec );
end


minetest.register_chatcommand( 'villages', {
	description = "Shows a list of all known villages.",
	privs = {},
	func = function(name, param)
		mg_villages.list_villages_formspec( minetest.get_player_by_name( name ), "mg:village_list", {});
        end
});


minetest.register_chatcommand( 'visit', {
        description = "Teleports you to a known village.",
	params = "<village number>",
        privs = {},
        func = function(name, param)


		if( mg_villages.REQUIRE_PRIV_FOR_TELEPORT and not( minetest.check_player_privs( name, {mg_villages=true}))) then
			minetest.chat_send_player( name, "You need the 'mg_villages' priv in order to teleport to villages using this command.");
			return;
		end

		if( not( param ) or param == "" ) then
			minetest.chat_send_player( name, "Which village do you want to visit? Please provide the village number!");
			return;
		end

		local nr = tonumber( param );
		for id, v in pairs( mg_villages.all_villages ) do
			-- we have found the village
			if( v and v.nr == nr ) then

				minetest.chat_send_player( name, "Initiating transfer to village no. "..tostring( v.nr )..", called "..( tostring( v.name or 'unknown'))..".");
				local player =  minetest.get_player_by_name( name );
				player:moveto( { x=v.vx, y=(v.vh+1), z=v.vz }, false);
				return;
			end
		end
		-- no village found
		minetest.chat_send_player( name, "There is no village with the number "..tostring( param ).." (yet?).");
        end
});
