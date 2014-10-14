
-- cover some villages with artificial snow; probability: 1/mg_villages.artificial_snow_probability
mg_villages.artificial_snow_probability = 10;

-- only place roads if there are at least that many buildings in the village
mg_villages.MINIMAL_BUILDUNGS_FOR_ROAD_PLACEMENT = 3;

-- if set to false, villages will not be integrated into the terrain - which looks very bad
mg_villages.ENABLE_TERRAIN_BLEND = true;
-- if set to false, holes digged by cavegen and mudflow inside the village will not be repaired; houses will be destroyed
mg_villages.UNDO_CAVEGEN_AND_MUDFLOW = true;


mg_villages.VILLAGE_CHECK_RADIUS = 2
mg_villages.VILLAGE_CHECK_COUNT = 1
--mg_villages.VILLAGE_CHANCE = 28
--mg_villages.VILLAGE_MIN_SIZE = 20
--mg_villages.VILLAGE_MAX_SIZE = 40
mg_villages.VILLAGE_CHANCE = 28
-- min and max size are only used in case of them beeing not provided by the village type (see buildings.lua)
mg_villages.VILLAGE_MIN_SIZE = 25
mg_villages.VILLAGE_MAX_SIZE = 90 --55
mg_villages.FIRST_ROADSIZE = 3
mg_villages.BIG_ROAD_CHANCE = 0

-- Enable that for really big villages (there are also really slow to generate)
--[[mg_villages.VILLAGE_CHECK_RADIUS = 3
mg_villages.VILLAGE_CHECK_COUNT = 3
mg_villages.VILLAGE_CHANCE = 28
mg_villages.VILLAGE_MIN_SIZE = 100
mg_villages.VILLAGE_MAX_SIZE = 150
mg_villages.FIRST_ROADSIZE = 5
mg_villages.BIG_ROAD_CHANCE = 50]]

-- on average, every n.th node may be one of these trees - and it will be a relatively dense packed forrest
mg_villages.sapling_probability = {};

mg_villages.sapling_probability[ minetest.get_content_id( 'default:sapling' )       ] = 25; -- suitable for a relatively dense forrest of normal trees
mg_villages.sapling_probability[ minetest.get_content_id( 'default:junglesapling' ) ] = 40; -- jungletrees are a bit bigger and need more space
if( minetest.get_modpath( 'mg' )) then
	mg_villages.sapling_probability[ minetest.get_content_id( 'mg:savannasapling'     ) ] = 30; 
	mg_villages.sapling_probability[ minetest.get_content_id( 'mg:pinesapling'        ) ] = 35; 
end
if( minetest.get_modpath( 'moretrees' )) then
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:birch_sapling_ongen'       ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:spruce_sapling_ongen'      ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:fir_sapling_ongen'         ) ] =  90;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:jungletree_sapling_ongen'  ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:beech_sapling_ongen'       ) ] =  30;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:apple_sapling_ongen'       ) ] = 380;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:oak_sapling_ongen'         ) ] = 380; -- ca 20x20; height: 10
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:sequoia_sapling_ongen'     ) ] =  90; -- ca 10x10
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:palm_sapling_ongen'        ) ] =  90;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:pine_sapling_ongen'        ) ] = 200;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:willow_sapling_ongen'      ) ] = 380;
	mg_villages.sapling_probability[ minetest.get_content_id( 'moretrees:rubber_tree_sapling_ongen' ) ] = 380;
end

