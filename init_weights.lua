-- Intllib
local S = mg_villages.intllib

-- this functions needs to be called once after *all* village types and buildings have been added
mg_villages.init_weights = function()

	-- create a list of all used village types
	mg_villages.village_types = {};
	for k,v in pairs( mg_villages.village_type_data ) do
		if( not( v.only_single ) and v.supported and v.building_list ) then
			table.insert( mg_villages.village_types, k );
		end
	end
	mg_villages.print(mg_villages.DEBUG_LEVEL_NORMAL,S("Will create villages of the following types").." : "..minetest.serialize( mg_villages.village_types ));



	mg_villages.village_types[ #mg_villages.village_types+1 ] = 'single';
	mg_villages.village_types[ #mg_villages.village_types+1 ] = 'fields';
	mg_villages.village_types[ #mg_villages.village_types+1 ] = 'tower';
	for j,v in ipairs( mg_villages.village_types ) do
	
		local total_weight = 0
		for _, i in ipairs(mg_villages.BUILDINGS) do
			if( not( i.max_weight )) then
				i.max_weight = {};
			end
			if( i.weight and i.weight[ v ] and i.weight[ v ]>0 ) then
				total_weight = total_weight+i.weight[ v ]
				i.max_weight[v] = total_weight
			end
		end
		local multiplier = 3000/total_weight
		for _,i in ipairs(mg_villages.BUILDINGS) do
			if( i.weight and i.weight[ v ] and i.weight[ v ]>0 ) then
				i.max_weight[v] = i.max_weight[ v ]*multiplier
			end
		end
	end
	-- the fields do not exist as an independent type
	mg_villages.village_types[ #mg_villages.village_types ] = nil;
	-- neither does the tower type
	mg_villages.village_types[ #mg_villages.village_types ] = nil;
	-- and neither does the "single" type (==lone houses outside villages)
	mg_villages.village_types[ #mg_villages.village_types ] = nil;
end
