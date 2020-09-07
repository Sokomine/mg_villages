-- Intllib
local S = mg_villages.intllib

-- RealTest still hasn't moved to soil_wet
local farming_soil_wet_png = "farming_soil_wet.png";
local desert_sand_png = "default_desert_sand.png"
-- sounds are specific to some games
local sound_dirt   = nil
local sound_gravel = nil
if(minetest.registered_nodes['default:gravel']) then
	sound_gravel = minetest.registered_nodes['default:gravel'].sounds
end
if(minetest.registered_nodes['farming:soil_wet']) then
	sound_dirt   = minetest.registered_nodes['farming:soil_wet'].sounds
	sound_gravel = minetest.registered_nodes['default:gravel'].sounds
-- MineClone2 requires special handling
elseif(minetest.registered_nodes['mcl_farming:soil_wet']) then
	farming_soil_wet_png = "mcl_farming_farmland_wet.png"
	desert_sand_png = "default_dirt.png"
	sound_dirt   = minetest.registered_nodes['mcl_farming:soil_wet'].sounds
	sound_gravel = minetest.registered_nodes['mcl_core:gravel'].sounds
elseif(not(minetest.registered_nodes["farming:soil_wet"])) then
	farming_soil_wet_png = "farming_soil.png";
	sound_dirt   = minetest.registered_nodes['farming:soil'].sounds
end


-- slightly lower than a normal nodes for better look
minetest.register_node("mg_villages:road", {
	description = S("Village Road"),
	tiles = {"default_gravel.png", "default_dirt.png"},
        is_ground_content = false, -- will not be removed by the cave generator
        groups = {crumbly=2}, -- does not fall
        sounds = sound_gravel,
	paramtype  = "light",
	paramtype2 = "facedir",
	drawtype   = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { { -0.5, -0.5, -0.5, 0.5, 0.5-2/16, 0.5}, },
		},
})

mg_villages.road_node = minetest.get_content_id( 'mg_villages:road' );
-- do not drop snow on roads
if( minetest.get_modpath("moresnow")) then
	moresnow.snow_cover[ mg_villages.road_node ] = moresnow.c_air;
end


-- special soil that does not need abms/lbms or water
minetest.register_node("mg_villages:soil", {
	description = S("Soil found on a field"),
	tiles = {"default_dirt.png^"..farming_soil_wet_png, "default_dirt.png"},
	drop = "default:dirt",
	is_ground_content = true,
	groups = {crumbly=3, not_in_creative_inventory=1, grassland = 1, soil=3, wet=1},
	sounds = sound_dirt,
})

minetest.register_node("mg_villages:desert_sand_soil", {
	description = S("Desert Sand"),
	tiles = {desert_sand_png.."^"..farming_soil_wet_png, desert_sand_png},
	is_ground_content = true,
	drop   = "default:desert_sand",
	groups = {crumbly=3, not_in_creative_inventory = 1, sand=1, desert = 1, soil=3, wet=1},
	sounds = sound_dirt,
})


-- this non-snow-melting-torch is only needed if you use the old snow mod
if( mg_villages.USE_DEFAULT_3D_TORCHES == false ) then
	-- This torch is not hot. It will not melt snow and cause no floodings in villages.
	minetest.register_node("mg_villages:torch", {
		description = S("Torch"),
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
--		sounds = default.node_sound_defaults,
		drop   = "default:torch",
		is_ground_content = false,
	})
end


-- in RealTest, the node and texture come with an additional "s"
local plotmarker_texture = "default_stone_brick.png";
if(minetest.registered_nodes["default:stone_bricks"]) then
	plotmarker_texture = "default_stone_bricks.png";
end
-- get information about a plot, the building, its inhabitants; allow to buy the plot etc.
minetest.register_node("mg_villages:plotmarker", {
	description = S("Plot marker"),
	drawtype = "nodebox",
	tiles = {plotmarker_texture},
	is_ground_content = false,
	paramtype = "light",
	paramtype2 = "facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5+2/16, -0.5, -0.5+2/16,  0.5-2/16, -0.5+3/16, 0.5-2/16},
		},
	},
	groups = {cracky=3,stone=2},

	on_rightclick = function( pos, node, clicker, itemstack, pointed_thing)
		return mg_villages.plotmarker_formspec( pos, nil, {}, clicker )
	end,

	on_receive_fields = function(pos, formname, fields, sender)
		return mg_villages.plotmarker_formspec( pos, formname, fields, sender );
	end,

	-- protect against digging
	can_dig = function( pos, player )
			local meta = minetest.get_meta( pos );
			if( meta and meta:get_string( 'village_id' )~='' and meta:get_int( 'plot_nr' ) and meta:get_int( 'plot_nr' )>0) then
				return false;
			end
			return true;
		end
})


-- place this node where a mob that works in your building ought to stand
minetest.register_node("mg_villages:mob_workplace_marker", {
	description = "Place where a mob ought to work",
	drawtype = "nodebox",
	tiles = {"workplace_marker.png"},
	paramtype = "light",
	paramtype2 = "facedir",
	walkable = false,
	is_ground_content = false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5,  0.5, -0.5+1/16, 0.5},
		},
	},
	groups = {crumbly=3},
})

-- helper node for villager/mob mods that want to spawn npc
minetest.register_node("mg_villages:mob_spawner", {
	description = "Mob spawner",
	tiles = {"wool_cyan.png^beds_bed_fancy.png","wool_blue.png^doors_door_wood.png"},
	is_ground_content = false,
	groups = {not_in_creative_inventory = 1 }, -- cannot be digged by players
	on_rightclick = function( pos, node, clicker, itemstack, pointed_thing)
		return mg_villages.mob_spanwer_on_rightclick( pos, node, clicker, itemstack, pointed_thing);
	end
})


-- default to safe lava - prevent fire
if( not( mg_villages.use_normal_unsafe_lava )) then
	local lava = minetest.registered_nodes[ "default:lava_source"];
	if( lava ) then
		-- a deep copy for the table would be more helpful...but, well, ...
		local new_def = minetest.deserialize( minetest.serialize( lava ));
		-- this lava does not cause fire to spread
		new_def.name           = nil;
		new_def.groups.lava    = nil;
		new_def.groups.hot     = nil;
		new_def.groups.igniter = nil;
		new_def.groups.lava_tamed = 3;
		new_def.description = S("Lava Source (tame)");
		new_def.liquid_alternative_flowing = "mg_villages:lava_flowing_tamed";
		new_def.liquid_alternative_source = "mg_villages:lava_source_tamed";
		-- we create a NEW type of lava for this
		minetest.register_node( "mg_villages:lava_source_tamed", new_def );
	end
	
	-- take care of the flowing variant as well
	lava = minetest.registered_nodes[ "default:lava_flowing"];
	if( lava ) then
		-- a deep copy for the table would be more helpful...but, well, ...
		local new_def = minetest.deserialize( minetest.serialize( lava ));
		-- this lava does not cause fire to spread
		new_def.name           = nil;
		new_def.groups.lava    = nil;
		new_def.groups.hot     = nil;
		new_def.groups.igniter = nil;
		new_def.groups.lava_tamed = 3;
		new_def.description = S("Flowing Lava (tame)");
		new_def.liquid_alternative_flowing = "mg_villages:lava_flowing_tamed";
		new_def.liquid_alternative_source = "mg_villages:lava_source_tamed";
		-- and a NEW type of flowing lava...
		minetest.register_node( "mg_villages:lava_flowing_tamed", new_def );
	end
end
