
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


-- This torch is not hot. It will not melt snow and cause no floodings in villages.
minetest.register_node("mg_villages:torch", {
	description = "Torch",
	drawtype = "torchlike",
	--tiles = {"default_torch_on_floor.png", "default_torch_on_ceiling.png", "default_torch.png"},
	tiles = {
		{name="default_torch_on_floor_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=3.0}},
		{name="default_torch_on_ceiling_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=3.0}},
		{name="default_torch_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=3.0}}
	},
	inventory_image = "default_torch_on_floor.png",
	wield_image = "default_torch_on_floor.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	light_source = LIGHT_MAX-1,
	selection_box = {
		type = "wallmounted",
		wall_top = {-0.1, 0.5-0.6, -0.1, 0.1, 0.5, 0.1},
		wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.5+0.6, 0.1},
		wall_side = {-0.5, -0.3, -0.1, -0.5+0.3, 0.3, 0.1},
	},
	groups = {choppy=2,dig_immediate=3,flammable=1,attached_node=1},
	legacy_wallmounted = true,
	sounds = default.node_sound_defaults(),
})

