
-- reserve namespace for the villages
mg_villages = {}

mg_villages.all_villages  = {}
mg_villages.mg_generated_map = {}
mg_villages.anz_villages = 0;

mg_villages.modpath = minetest.get_modpath( "mg_villages");

dofile(mg_villages.modpath.."/save_restore.lua")
mg_villages.all_villages     = save_restore.restore_data( 'mg_all_villages.data' ); -- read mg_villages.all_villages data saved for this world from previous runs
mg_villages.mg_generated_map = save_restore.restore_data( 'mg_generated_map.data' );

dofile(mg_villages.modpath.."/config.lua")

dofile(mg_villages.modpath.."/we.lua")
dofile(mg_villages.modpath.."/rotate.lua")

-- read size from schematics files directly
-- analyze_mts_file.lua uses handle_schematics.* namespace
dofile(mg_villages.modpath.."/analyze_mts_file.lua") 

-- adds a special gravel node which will neither fall nor be griefed by mapgen
dofile(mg_villages.modpath.."/nodes.lua")

-- Note: the "buildings" talbe is not in the mg_villages.* namespace
dofile(mg_villages.modpath.."/buildings.lua")

-- replace some materials for entire villages randomly
dofile(mg_villages.modpath.."/replacements.lua")

-- generate village names
dofile(mg_villages.modpath.."/name_gen.lua");

dofile(mg_villages.modpath.."/place_buildings.lua")
dofile(mg_villages.modpath.."/villages.lua")

-- adds a command that allows to teleport to a known village
dofile(mg_villages.modpath.."/chat_commands.lua")
-- protect villages from griefing
dofile(mg_villages.modpath.."/protection.lua")
-- create and show a map of the world
dofile(mg_villages.modpath.."/map_of_world.lua")

dofile(mg_villages.modpath.."/fill_chest.lua")

-- terrain blending for individual houses
dofile(mg_villages.modpath.."/terrain_blend.lua")
-- the interface for the mapgen;
-- also takes care of spawning the player
dofile(mg_villages.modpath.."/mapgen.lua")

dofile(mg_villages.modpath.."/spawn_player.lua")
