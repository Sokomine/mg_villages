
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
