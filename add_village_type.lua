
--  DOCUMENTATION: mg_villages.village_type_data has entries in the following form:
--      key = { data values }   with key beeing the name of the village type
--  meaning of the data values:
--      min, max: the village size will be choosen randomly between these two values;
--                the actual village will have a radius about twice as big (including sourrounding area)
--      space_between_buildings=2  How much space is there between the buildings. 1 or 2 are good values.
--                The higher, the further the buildings are spread apart.
--      mods = {'homedecor','moreblocks'} List of mods that are required for the buildings of this village type.
--                List all the mods the blocks used by your buildings which are not in default.
--      texture = 'wool_white.png'        Texture used to show the location of the village when using the
--                vmap  command.
--      name_prefix = 'Village ',
--      name_postfix = ''                 When creating village names for single houses which are spawned outside
--                of villages, the village name will consist of  name_prefix..village_name..name_postfix
--	sapling_divisor = 1	Villages are sourrounded by a flat area that may contain trees. Increasing this
--				value decreses the mount of trees placed.
--	plant_type = 'farming:wheat_8'  Type of plant that is placed around villages.
--	plant_frequency = 1	The higher this value is, the less plants are placed.

local S = mg_villages.intllib


-- NOTE: Most values of village types added with mg_villages.add_village_type can still be changed later on by
--       changing the global variable mg_villages.village_type_data[ village_type ]
--       Village types where one or more of the required mods (listed in v.mods) are missing will not be
--       available.
-- You can add your own village type by i.e. calling
--         mg_villages.add_village_type( 'town', { min = 10, max = 30, space_between_buildings = 2, mods = {'moreblocks','homedecor'}, texture='default_diamond_block.png'} );
--   This will add a new village type named 'town', which will only be available if the mods moreblocks and homedecor are installed.
--   It will show the texture of the diamond block when showing the position of a village of that type in the map displayed by the /vmap command.
      

-- some villages require special mods as building material for their houses;
-- figure out which village types can be used 
mg_villages.add_village_type = function( type_name, v )
	local found = true;
	if( not( v.mods )) then
		v.mods = {};
	end
	for _,m in ipairs( v.mods ) do
		if( not( minetest.get_modpath( m ))) then
			-- this village type will not be used because not all required mods are installed
			return false;
		end
	end

	if( not( v.only_single ) and (not(v.min) or not(v.max))) then
		mg_villages.print( mg_villages.DEBUG_LEVEL_NORMAL, S("Error: Village type")..' '..tostring( type_name )..' '..S("lacks size information."));
		return false;
	end

	-- set some default values
	if( not( v.sapling_divisor )) then
		v.sapling_divisor = 10;
	end
	if( not( v.plant_type )) then
		v.plant_type      = 'default:grass_5';
		if( not( minetest.registered_nodes[ v.plant_type ])) then
			v.plant_type = 'default:dry_shrub';
		end
	end
	if( not( v.plant_frequency )) then
		v.plant_frequency = 3;
	end

	-- this village type is supported by the mods installed and may be used
	v.supported = 1;

	mg_villages.village_type_data[ type_name ] = v;
	return true;
end


-- build a list of all useable village types the mg_villages mod comes with
mg_villages.village_type_data = {};
