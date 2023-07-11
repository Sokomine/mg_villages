-- reserve namespace for the villages
mg_villages = {}

local S = minetest.get_translator("mg_villages")
mg_villages.intllib = S

mg_villages.all_villages  = {}
mg_villages.mg_generated_map = {}
mg_villages.anz_villages = 0;

mg_villages.modpath = minetest.get_modpath("mg_villages");


mg_villages.DEBUG_LEVEL_NONE    = -1 -- -1: disable all printed messages
mg_villages.DEBUG_LEVEL_NORMAL  =  0 -- 0: print information about which village spawned where plus important errors
mg_villages.DEBUG_LEVEL_WARNING =  1 -- 1: warnings/errors which may not be particulary helpful for non-developers
mg_villages.DEBUG_LEVEL_INFO    =  2 -- 2: print even less important warnings
mg_villages.DEBUG_LEVEL_TIMING  =  3 -- 3: detailled performance information

mg_villages.print = function( level, msg )
	if( level <= mg_villages.DEBUG_LEVEL ) then
		print( "[mg_villages] "..msg );
	end
end


-- save_restore is now part of handle_schematics
--dofile(mg_villages.modpath.."/save_restore.lua")
mg_villages.all_villages     = save_restore.restore_data( 'mg_all_villages.data' ); -- read mg_villages.all_villages data saved for this world from previous runs
mg_villages.mg_generated_map = save_restore.restore_data( 'mg_generated_map.data' );

dofile(mg_villages.modpath.."/config.lua")

-- adds a special gravel node which will neither fall nor be griefed by mapgen
dofile(mg_villages.modpath.."/nodes.lua")


-- the default game no longer provides helpful tree growing code
-- (but some mods may not have the default tree, jungletree and pinetree)
if(minetest.registered_nodes["default:sapling"]) then
       dofile(mg_villages.modpath.."/trees_default.lua")
end
-- RealTest has its own tree growing code
if(minetest.registered_nodes["trees:maple_sapling"]) then
       dofile(mg_villages.modpath.."/trees_realtest.lua")
end
-- general tree growing (used by mapgen.lua)
dofile(mg_villages.modpath.."/trees.lua")


dofile(mg_villages.modpath.."/replacements.lua")

-- fill mg_villages.all_buildings_list with precalculated paths
dofile(mg_villages.modpath.."/mg_villages_path_info.data");

-- multiple diffrent village types with their own sets of houses are supported
-- The function mg_villages.add_village_type( village_type_name, village_type_data )
--   allows other mods to add new village types.
dofile(mg_villages.modpath.."/add_village_type.lua")

-- calls path calculation and stores front doors etc.; only called in mg_villages.add_building
dofile(mg_villages.modpath.."/analyze_building_for_mobs.lua")

-- Note: the "buildings" talbe is not in the mg_villages.* namespace
-- The function mg_villages.add_building( building_data ) allows other mods to add buildings.
dofile(mg_villages.modpath.."/add_building.lua")

-- mg_villages.init_weights() has to be called AFTER all village types and buildings have
-- been added using the functions above
dofile(mg_villages.modpath.."/init_weights.lua")

-- generate village names
dofile(mg_villages.modpath.."/name_gen.lua");

dofile(mg_villages.modpath.."/villages.lua")

-- determine type of work, name, age, bed position etc. for villagers (none included!)
dofile(mg_villages.modpath.."/inhabitants.lua")

-- provides some extra functionality for development of mob mods etc.;
-- contains some deprecated functions
dofile(mg_villages.modpath.."/extras_for_development.lua");
-- adds a command that allows to teleport to a known village
dofile(mg_villages.modpath.."/chat_commands.lua")
-- protect villages from griefing
dofile(mg_villages.modpath.."/protection.lua")
-- allows to buy/sell/restore/.. plots and their buildings
dofile(mg_villages.modpath.."/plotmarker_formspec.lua")
-- create and show a map of the world
dofile(mg_villages.modpath.."/map_of_world.lua")

-- grow some plants and farmland around the village
dofile(mg_villages.modpath.."/village_area_fill_with_plants.lua")

-- terrain blending for individual houses
dofile(mg_villages.modpath.."/terrain_blend.lua")
-- the interface for the mapgen;
-- also takes care of spawning the player
dofile(mg_villages.modpath.."/mapgen.lua")

dofile(mg_villages.modpath.."/spawn_player.lua")

-- reconstruct the connection of the roads inside a village
dofile(mg_villages.modpath.."/roads.lua")

-- add some nice villages and buildings;
dofile(mg_villages.modpath.."/add_default_village_types.lua")
-- if you DISABLE the default villages above and don't add houses to the
-- village type "single", then you need to disable lone houses here:
--mg_villages.INVERSE_HOUSE_DENSITY = 0
