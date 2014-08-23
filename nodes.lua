
minetest.register_node("mg_villages:road", {
	description = "village road",
	tiles = {"default_gravel.png", "default_dirt.png"},
        is_ground_content = false, -- will not be removed by the cave generator
        groups = {crumbly=2}, -- does not fall
        sounds = default.node_sound_dirt_defaults({
                footstep = {name="default_gravel_footstep", gain=0.5},
                dug = {name="default_gravel_footstep", gain=1.0},
        }),
})

mg_villages.road_node = minetest.get_content_id( 'mg_villages:road' );


minetest.register_node("mg_villages:soil", {
	description = "Soil found on a field",
	tiles = {"farming_soil_wet.png", "farming_soil_wet_side.png"},
	drop = "default:dirt",
	is_ground_content = true,
	groups = {crumbly=3, not_in_creative_inventory=1, grassland = 1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("mg_villages:desert_sand_soil", {
	description = "Desert Sand",
	tiles = {"farming_desert_sand_soil_wet.png", "default_desert_sand.png"},
	is_ground_content = true,
	groups = {crumbly=3, not_in_creative_inventory = 1, sand=1, desert = 1},
	sounds = default.node_sound_sand_defaults(),
})
