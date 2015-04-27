

handle_schematics.choose_traders = function( village_type, building_type, replacements )

	if( not( building_type ) or not( village_type )) then
		return;
	end
	
	-- some jobs are obvious
	if(     building_type == 'mill' ) then
		return { 'miller' };
	elseif( building_type == 'bakery' ) then
		return { 'baker' };
	elseif( building_type == 'school' ) then
		return { 'teacher' };
	elseif( building_type == 'forge' ) then
		local traders = {'blacksmith', 'bronzesmith' };
		return { traders[ math.random(#traders)] };
	elseif( building_type == 'shop' ) then
		local traders = {'seeds','flowers','misc','default','ore', 'fruit trader', 'wood'};
		return { traders[ math.random(#traders)] };
	-- there are no traders for these jobs - they'd require specialized mobs
	elseif( building_type == 'tower'
	     or building_type == 'church'
	     or building_type == 'secular'
	     or building_type == 'tavern' ) then
		return {};
	end

	if(     village_type == 'charachoal' ) then
		return { 'charachoal' };
	elseif( village_type == 'claytrader' ) then
		return { 'clay' };
	end

	local res = {};
	if(   building_type == 'shed'
	   or building_type == 'farm_tiny' 
	   or building_type == 'house'
	   or building_type == 'house_large'
	   or building_type=='hut') then
		local traders = { 'stonemason', 'stoneminer', 'carpenter', 'toolmaker',
			'doormaker', 'furnituremaker', 'stairmaker', 'cooper', 'wheelwright',
			'saddler', 'roofer', 'iceman', 'potterer', 'bricklayer', 'dyemaker',
			'dyemakerl', 'glassmaker' }
		-- sheds and farms both contain craftmen
		res = { traders[ math.random( #traders )] };
		if(    building_type == 'shed'
		    or building_type == 'house'
		    or building_type == 'house_large'
		    or building_type == 'hut' ) then
			return res;
		end
	end

	if(   building_type == 'field'
	   or building_type == 'farm_full'
	   or building_type == 'farm_tiny' ) then

		local fruit = 'farming:cotton';
		if( 'farm_full' ) then
			-- RealTest
			fruit = 'farming:wheat';
			if( replacements_group['farming'].traders[ 'farming:soy']) then
				fruit_item = 'farming:soy';
			end
			if( minetest.get_modpath("mobf") ) then
				local animal_trader = {'animal_cow', 'animal_sheep', 'animal_chicken', 'animal_exotic'};
				res[1] = animal_trader[ math.random( #animal_trader )];	
			end
			return { res[1], replacements_group['farming'].traders[ fruit_item ]};
		elseif( #replacements_group['farming'].found > 0 ) then
			-- get a random fruit to grow
			fruit = replacements_group['farming'].found[ math.random( #replacements_group['farming'].found) ];
			return { res[1], replacements_group['farming'].traders[ fruit_item ]};
		else
			return res;
		end
	end

	if( building_type == 'pasture' and minetest.get_modpath("mobf")) then
		local animal_trader = {'animal_cow', 'animal_sheep', 'animal_chicken', 'animal_exotic'};
		return { animal_trader[ math.random( #animal_trader )] };
	end	


	-- TODO: banana,cocoa,rubber from farming_plus?
	-- TODO: sawmill
	if( building_type == 'lumberjack' or village_type == 'lumberjack' ) then
		-- TODO: limit this to single houses
		if( replacements.table and replacements.table[ 'default:wood' ] ) then
			return { replacements_group['wood'].traders[  replacements.table[ 'default:wood' ]] };
		elseif( #replacements_group['wood'].traders > 0 ) then
			return { replacements_group['wood'].traders[ math.random( #replacements_group['wood'].traders) ]};
		else
			return { 'common_wood'};
		end
	end

	
	-- tent, chateau: places for living at; no special jobs associated
	-- nore,taoki,medieval,lumberjack,logcabin,canadian,grasshut,tent: further village types

	return res;
end


handle_schematics.choose_trader_pos = function(pos, minp, maxp, data, param2_data, a, extranodes, replacements, cid, extra_calls, building_nr_in_bpos, village_id, binfo_extra, road_node, traders)

	local trader_pos = {};
	-- determine spawn positions for the mobs
	for i,tr in ipairs( traders ) do
		local tries = 0;
		local found = false;
		local pt = {x=pos.x, y=pos.y, z=pos.z};
		while( tries < 10 and not(found)) do
			-- get a random position for the trader
			pt.x = pos.x+math.random(pos.bsizex);
			pt.z = pos.z+math.random(pos.bsizez);
			-- check if it is inside the area contained in data
			if (pt.x >= minp.x and pt.x <= maxp.x) and (pt.y >= minp.y and pt.y <= maxp.y) and (pt.z >= minp.z and pt.z <= maxp.z) then

				while( pt.y < maxp.y 
				  and (data[ a:index( pt.x, pt.y,   pt.z)]~=cid.c_air
				    or data[ a:index( pt.x, pt.y+1, pt.z)]~=cid.c_air )) do
					pt.y = pt.y + 1;
				end

				-- TODO: check if this position is really suitable? traders standing on the roof are a bit odd
				found = true;
			end
			tries = tries+1;

			-- check if this position has already been assigned to another trader
			for j,t in ipairs( trader_pos ) do
				if( t.x==pt.x and t.y==pt.y and t.z==pt.z ) then
					found = false;
				end
			end
		end
		if( found ) then
			table.insert( trader_pos, {x=pt.x, y=pt.y, z=pt.z, typ=tr, bpos_i = building_nr_in_bpos} );
		end
	end
	return trader_pos;
end
