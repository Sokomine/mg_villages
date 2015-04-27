

mg_villages.choose_traders = function( village_type, building_type, replacements )

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
	   or building_type == 'farm_tiny' ) then
		local traders = { 'stonemason', 'stoneminer', 'carpenter', 'toolmaker',
			'doormaker', 'furnituremaker', 'stairmaker', 'cooper', 'wheelwright',
			'saddler', 'roofer', 'iceman', 'potterer', 'bricklayer', 'dyemaker',
			'dyemakerl', 'glassmaker' }
		-- sheds and farms both contain craftmen
		res = { traders[ math.random( #traders )] };
		if(    building_type == 'shed' ) then
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

	-- house, hut, house_large, tent, chateau: places for living at; no special jobs associated
	-- nore,taoki,medieval,lumberjack,logcabin,canadian,grasshut,tent: further village types

	return res;
end
