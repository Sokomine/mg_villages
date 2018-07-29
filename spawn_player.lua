

mg_villages.spawnplayer = function(player)
	if( minetest.settings and minetest.settings:get("static_spawnpoint")) then
		return;
	end

	-- make sure the village types are initialized
	if( not( mg_villages.village_types )) then
		mg_villages.init_weights();
	end

	local noise1 = minetest.get_perlin(12345, 6, 0.5, 256)
	local min_dist = math.huge
	local min_pos = {x = 0, y = 3, z = 0}
	for bx = -20, 20 do
	for bz = -20, 20 do
		local minp = {x = -32 + 80 * bx, y = -32, z = -32 + 80 * bz}
		for _, village in ipairs(mg_villages.villages_at_point(minp, noise1)) do
			if math.abs(village.vx) + math.abs(village.vz) < min_dist then
				min_pos = {x = village.vx, y = village.vh + 2, z = village.vz}
				-- some villages are later adjusted in height; adapt these changes
				local village_id = tostring( village.vx )..':'..tostring( village.vz );
				if(   mg_villages.all_villages[ village_id ] 
				  and mg_villages.all_villages[ village_id ].optimal_height ) then
					min_pos.y = mg_villages.all_villages[ village_id ].vh + 2;
				-- the first villages will have a height of 1 in order to make sure that the player does not end up embedded in stone
				else
					min_pos.y = 1+2;
				end
				min_dist = math.abs(village.vx) + math.abs(village.vz)
			end
		end
	end
	end
	player:set_pos(min_pos)
end

minetest.register_on_newplayer(function(player)
	mg_villages.spawnplayer(player)
end)

minetest.register_on_respawnplayer(function(player)
	mg_villages.spawnplayer(player)
	return true
end)

