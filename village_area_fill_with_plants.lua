
-- places trees and plants at empty spaces
mg_villages.village_area_fill_with_plants = function( village_area, villages, minp, maxp, data, param2_data, a, cid, trees_to_grow_via_voxelmanip )
	-- do not place any plants if we are working on the mapchunk above
	if( minp.y > 0 ) then
		return;
	end
	-- TODO: replacements depend on the actual village...
	local replacements = {};
	-- add farmland
	cid.c_wheat           = handle_schematics.get_content_id_replaced( 'farming:wheat_8', replacements );
	cid.c_cotton          = handle_schematics.get_content_id_replaced( 'farming:cotton_8', replacements );
	cid.c_shrub           = handle_schematics.get_content_id_replaced( 'default:dry_shrub', replacements);
	-- these extra nodes are used in order to avoid abms on the huge fields around the villages
	cid.c_soil_wet        = handle_schematics.get_content_id_replaced( 'mg_villages:soil', replacements ); --'farming:soil_wet' );
	cid.c_soil_sand       = handle_schematics.get_content_id_replaced( 'mg_villages:desert_sand_soil', replacements); --'farming:desert_sand_soil_wet' );

	if( mg_villages.realtest_trees ) then
		cid.c_soil_wet        = handle_schematics.get_content_id_replaced( 'farming:soil', replacements ); -- TODO: the one from mg_villages would be better...but that one lacks textures
		cid.c_soil_sand       = handle_schematics.get_content_id_replaced( 'farming:soil', replacements ); -- TODO: the one from mg_villages would be better...but that one lacks textures
		cid.c_wheat           = handle_schematics.get_content_id_replaced( 'farming:spelt_4', replacements );
		cid.c_cotton          = handle_schematics.get_content_id_replaced( 'farming:flax_4', replacements );
--		cid.c_shrub           = handle_schematics.get_content_id_replaced( 'default:dry_shrub', replacements);
	end

	local pr = PseudoRandom(mg_villages.get_bseed(minp));
	for x = minp.x, maxp.x do
		for z = minp.z, maxp.z do
			-- turn unused land (which is either dirt or desert sand) into a field that grows wheat
			if( village_area[ x ][ z ][ 2 ]==1 
			 or village_area[ x ][ z ][ 2 ]==6) then

				local village_nr = village_area[ x ][ z ][ 1 ];
				local village    = villages[ village_nr ];
				local h = village.vh;
				local g = data[a:index( x, h, z )];

				-- choose a plant/tree with a certain chance
				-- Note: There are no checks weather the tree/plant will actually grow there or not;
				--       Tree type is derived from wood type used in the village
				local plant_id = data[a:index( x, h+1, z)];
				local on_soil  = false;
				local plant_selected = false;
				local has_snow_cover = false;
				for _,v in ipairs( village.to_add_data.plantlist ) do
					if( plant_id == cid.c_snow or g==cid.c_dirt_with_snow or g==cid.c_snowblock) then
						has_snow_cover = true;
					end
					-- select the first plant that fits; if the node is not air, keep what is currently inside
					if( (plant_id==cid.c_air or plant_id==cid.c_snow) and (( v.p == 1 or pr:next( 1, v.p )==1 ))) then
						-- TODO: check if the plant grows on that soil
						plant_id = v.id;
						plant_selected = true;
					end
					-- wheat and cotton require soil
					if( plant_id == cid.c_wheat or plant_id == cid.c_cotton ) then
						on_soil = true;
					end
				end

				local pos = {x=x, y=h+1, z=z};
				if( not( plant_selected )) then -- in case there is something there already (usually a tree trunk)
					has_snow_cover = nil;

				elseif( mg_villages.grow_a_tree( pos, plant_id, minp, maxp, data, a, cid, pr, has_snow_cover, trees_to_grow_via_voxelmanip )) then
					param2_data[a:index( x, h+1, z)] = 0; -- make sure the tree trunk is not rotated
					has_snow_cover = nil; -- else the sapling might not grow
					-- nothing to do; the function has grown the tree already
	
				-- grow wheat and cotton on normal wet soil (and re-plant if it had been removed by mudslide)
				elseif( on_soil and (g==cid.c_dirt_with_grass or g==cid.c_soil_wet or g==cid.c_dirt_with_snow)) then	
					-- wheat needs another option there
					if( plant_id == cid.c_wheat ) then
						param2_data[a:index( x, h+1, z)] = 0;
					else
						param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					end
					data[a:index( x,  h,   z)] = cid.c_soil_wet;
					-- no plants in winter
					if( has_snow_cover and mg_villages.use_soil_snow) then
						data[a:index( x,  h+1, z)] = cid.c_msnow_soil;
						has_snow_cover = nil;
					else
						data[a:index( x,  h+1, z)] = plant_id;
					end

				-- grow wheat and cotton on desert sand soil - or on soil previously placed (before mudslide overflew it; same as above)
				elseif( on_soil and (g==cid.c_desert_sand or g==cid.c_soil_sand) and cid.c_soil_sand and cid.c_soil_sand > 0) then
					-- wheat needs another option there
					if( plant_id == cid.c_wheat ) then
						param2_data[a:index( x, h+1, z)] = 0;
					else
						param2_data[a:index( x, h+1, z)] = math.random( 1, 179 );
					end
					data[a:index( x,  h,   z)] = cid.c_soil_sand;
					-- no plants in winter
					if( has_snow_cover and mg_villages.use_soil_snow) then
						data[a:index( x,  h+1, z)] = cid.c_msnow_soil;
						has_snow_cover = nil;
					else
						data[a:index( x,  h+1, z)] = plant_id;
					end

				elseif( on_soil ) then
					if( math.random(1,5)==1 ) then
						data[a:index( pos.x,  pos.y, pos.z)] = cid.c_shrub;
					end

				-- do not place any RealTest saplings again after the tree has been grown
				elseif( plant_id and not(mg_villages.sapling_to_tree_realtest[plant_id])) then -- place the sapling or plant (moretrees uses spawn_tree)
					data[a:index( pos.x,  pos.y, pos.z)] = plant_id;
				end

				-- put a snow cover on plants where needed
				if( has_snow_cover and cid.c_msnow_1 ~= cid.c_ignore and cid.c_msnow_1 ~= cid.c_air) then
					data[a:index( x,  h+2, z)] = cid.c_msnow_1;
				end

				-- place a water source now and then so that the fake soil can later be turned into real soil if needed
				if( mg_villages.PLACE_WATER_FOR_FARMING and on_soil and x%3==0 and z%3==0 and h>minp.y) then
					data[a:index( x, h-1, z)] = cid.c_water;
				end
			end
		end
	end
end
