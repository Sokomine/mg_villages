--  scm="bla"		Name of the file that holds the buildings' schematic. Supported types: .we and .mts (omit the extension!)
--  sizex, sizez, ysize: obsolete
--  yoff=0		how deep is the building burried?
--  pervillage=1	Never generate more than this amount of this building and this type (if set) of building per village.
--  axis=1		Building needs to be mirrored along the x-axis instead of the z-axis because it is initially rotated
--  inh=2  		maximum amount of inhabitants the building may hold (usually amount of beds present)
--			if set to i.e. -1, this indicates that a mob is WORKING, but not LIVING here 
--   we_origin		Only needed for very old .we files (savefile format version 3) which do not start at 0,0,0 but have an offset.
--  price               Stack that has to be paid in order to become owner of the plot the building stands on and the building;
--                      overrides mg_villages.prices[ building_typ ].
--  guests		Negative value, i.e. -2: 2 of the beds will belong to the family working here; the rest will be guests.
--                      For building type "chateau", guest names the number of servants/housemaids instead of guests.

-- Intllib
local S = mg_villages.intllib

mg_villages.all_buildings_list = {}


-- read the data files and fill in information like size and nodes that need on_construct to be called after placing;
-- skip buildings that cannot be used due to missing mods
mg_villages.add_building = function( building_data )

	local file_name = building_data.mts_path .. building_data.scm;
	-- a building will only be used if it is used by at least one supported village type (=mods required for that village type are installed)
	local is_used = false;
	for typ,weight in pairs( building_data.weight ) do
		if( typ and weight and typ ~= 'single' and mg_villages.village_type_data[ typ ] and mg_villages.village_type_data[ typ ].supported ) then
			is_used = true;
		end
		-- add the building to the menu list for the build chest ("single" would be too many houses)
		-- the empty plots are added to each village and of no intrest here
		if( build_chest and build_chest.add_entry and typ and typ ~= 'single' and (not( building_data.typ ) or building_data.typ ~= 'empty')) then
			build_chest.add_entry( {'main','mg_villages', typ, building_data.scm, file_name });
		end
	end
	-- buildings as such may have a type as well
	if( build_chest and build_chest.add_entry and building_data.typ ) then
		build_chest.add_entry( {'main','mg_villages', building_data.typ, building_data.scm, file_name });
	end


	if( not( is_used )) then
		-- do nothing; skip this file
		mg_villages.print(mg_villages.DEBUG_LEVEL_INFO, S("SKIPPING").." "..tostring( building_data.scm )..' '..S("due to village type not supported."));
		-- building cannot be used
		building_data.not_available = 1;
		return false;
	end


	-- read the size of the building;
	-- convert to .mts for later usage if necessary
	-- true: no entry in the build_chest (we did that manually already)
	local res  = handle_schematics.analyze_file( file_name, building_data.we_origin, building_data.mts_path .. building_data.scm, building_data, true );

	if( not( res )) then
		mg_villages.print(mg_villages.DEBUG_LEVEL_WARNING, S("SKIPPING").." "..tostring( building_data.scm ).." "..S("due to import failure."));
		building_data.not_available = 1;
		return false;
	-- provided the file could be analyzed successfully (now covers both .mts and .we files)
	elseif( res and res.size and res.size.x ) then

		building_data = res;
		-- identify front doors, calculate paths from beds/workplaces to front of house
		building_data = mg_villages.analyze_building_for_mobs( building_data, file_name, mg_villages.path_info);

	-- missing data regarding building size - do not use this building for anything
	elseif( not( building_data.sizex )    or not( building_data.sizez )
		or   building_data.sizex == 0 or      building_data.sizez==0) then

		-- no village will use it
		mg_villages.print( mg_villages.DEBUG_LEVEL_INFO, S("No schematic found for building \'@1\'. Will not use that building.", tostring( building_data.scm )));
		building_data.weight = {};
		building_data.not_available = 1;
		return false;

	else
		-- the file has to be handled by worldedit; it is no .mts file
		building_data.is_mts = 0;
	end


	if( not( building_data.weight ) or type( building_data.weight ) ~= 'table' ) then
		mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, S("SKIPPING").." "..tostring( building_data.scm ).." "..S("due to missing weight information."));
		building_data.not_available = 1;
		return false;
	end


	-- handle duplicates; make sure buildings always get the same number;
	-- check if the building has been used in previous runs and got an ID there

	-- create a not very unique, but for this case sufficient "id";
	-- (buildings with the same size and name are considered to be drop-in-replacements
	local building_id = building_data.sizex..'x'..building_data.sizez..'_'..building_data.scm;
	-- if the building is new, it will get the next free id
	local building_nr = #mg_villages.all_buildings_list + 1;
	for i,v in ipairs( mg_villages.all_buildings_list ) do
		if( v==building_id ) then
			-- we found the building
			building_nr = i;
		end
	end

	-- if it is a new building, then save the list
	if( building_nr == #mg_villages.all_buildings_list+1 ) then
		mg_villages.all_buildings_list[ building_nr ] = building_id;
		-- save information about previously imported buildings
		save_restore.save_data( 'mg_villages_all_buildings_list.data', mg_villages.all_buildings_list );
	end

	-- determine the internal number for the building; this number is used as a key and can be found in the mg_all_villages.data file
	if( not( mg_villages.BUILDINGS )) then
		mg_villages.BUILDINGS = {};
	end
	-- actually store the building data
	mg_villages.BUILDINGS[ building_nr ] = minetest.deserialize( minetest.serialize( building_data ));


	-- create lists for all village types containing the buildings which may be used for that village
	for typ, data in pairs( mg_villages.village_type_data ) do
		local total_weight = 0;
		if( not( data.building_list ) or not( data.max_weight_list )) then
			data.building_list   = {};
			data.max_weight_list = {};
		elseif( #data.max_weight_list > 0 ) then
			-- get the last entry - that one will determine the current total_weight
			total_weight = data.max_weight_list[ #data.max_weight_list ];
		end

		if( building_data.weight[ typ ] and building_data.weight[ typ ] > 0 ) then
			local index = #data.building_list+1;
			data.building_list[   index ] = building_nr; 
			data.max_weight_list[ index ] = total_weight + building_data.weight[ typ ];
		end
	end

	-- print it for debugging usage
 	--print( building_data.scm .. ': '..tostring(building_data.sizex)..' x '..tostring(building_data.sizez)..' x '..tostring(building_data.ysize)..' h');
	return true;
end


-- this list contains some information about previously imported buildings so that they will get the same id
mg_villages.all_buildings_list =  save_restore.restore_data( 'mg_villages_all_buildings_list.data' );

-- information about beds, positions to stand next to the beds, paths to the doors, and doors
--mg_villages.path_info = {};
--mg_villages.path_info =  save_restore.restore_data( 'mg_villages_path_info.data' );

-- TODO: not ideal; needed by analyze_building_for_mobs.lua:
mg_villages.file_name_offset = string.len( minetest.get_modpath( "mg_villages" ))-11+1;

-- this table will hold the buildings
mg_villages.BUILDINGS = {};

-- roads are built in a diffrent way
mg_villages.BUILDINGS["road"] = {yoff = 0, ysize = 2, scm = {}}

-- save the path data; wait a bit so that all mods may have registered their buildings
-- Note: uncomment the following line if you have added a larger amount of new buildings; then, after
--       WORLDNAME/mg_villages_path_info.data has been written, copy that file over to your
--       mods/mg_villages/ folder and replace the old one. Add
--           mg_villages.path_info = ..
--       at the start of the table so that a dofile can execute it.
--minetest.after( 10, save_restore.save_data, 'mg_villages_path_info.data', mg_villages.path_info );
