-- this code is taken from https://github.com/VanessaE/dreambuilder_game/blob/master/mods/default/trees.lua
-- The code is adjusted where needed. It handles tree growing for default (Minetest Game).

local c_air = minetest.get_content_id("air")
local c_ignore = minetest.get_content_id("ignore")

local c_msnow_top = minetest.get_content_id( 'air' );
if(minetest.registered_nodes["moresnow:snow_top"]) then
	c_msnow_top = minetest.get_content_id( 'moresnow:snow_top' );
end

-- not all games come with the default leaves
local leaves_name = 'default:leaves'
if(not(minetest.registered_nodes[ leaves_name ])) then
	leaves_name = 'air'
end
local c_msnow_leaves1 = minetest.get_content_id( leaves_name );
local c_msnow_leaves2 = minetest.get_content_id( leaves_name );
if( minetest.registered_nodes[ 'moresnow:autumnleaves_tree' ] ) then
	c_msnow_leaves1 = minetest.get_content_id( 'moresnow:autumnleaves_tree' );
end
if( minetest.registered_nodes[ 'moresnow:winterleaves_tree' ] ) then
	c_msnow_leaves2 = minetest.get_content_id( 'moresnow:winterleaves_tree' );
end

mg_villages.grow_tree = function(data, a, pos, is_apple_tree, seed, snow)
        --[[
                NOTE: Tree-placing code is currently duplicated in the engine
                and in games that have saplings; both are deprecated but not
                replaced yet
        ]]--
    local c_leaves = minetest.get_content_id("default:leaves")
    local c_sapling = minetest.get_content_id("default:sapling");
    local c_tree = minetest.get_content_id("default:tree")
    local c_snow = minetest.get_content_id("default:snow");

    local leaves_type = c_leaves;
    if(  snow
      or data[ a:index(pos.x, pos.y,   pos.z) ] == c_snow
      or data[ a:index(pos.x, pos.y+1, pos.z) ] == c_snow ) then
       leaves_type = c_msnow_leaves2; 
    end

    local hight = math.random(4, 5)
    for x_area = -2, 2 do
    for y_area = -1, 2 do
    for z_area = -2, 2 do
        if math.random(1,30) < 23 then  --randomize leaves
            local area_l = a:index(pos.x+x_area, pos.y+hight+y_area-1, pos.z+z_area)  --sets area for leaves
            if data[area_l] == c_air or data[area_l] == c_ignore or data[area_l]== c_snow then    --sets if it's air or ignore 
		if( snow and c_msnow_leaves1 and math.random( 1,5 )==1) then
			data[area_l] = c_msnow_leaves1;
		else
	                data[area_l] = leaves_type    --add leaves now
		end
            end
            -- put a snow top on some leaves
            if ( snow and math.random(1,3)==1 )then
               mg_villages.trees_add_snow(data, a:index(pos.x+x_area, pos.y+hight+y_area, pos.z+z_area), c_air, c_ignore, c_snow)
            end
         end       
    end
    end
    end
    for tree_h = 0, hight-1 do  -- add the trunk
        local area_t = a:index(pos.x, pos.y+tree_h, pos.z)  --set area for tree
        if data[area_t] == c_air or data[area_t] == c_leaves or data[area_t] == c_sapling or data[area_t] == c_snow or data[area_t] == c_msnow_top or data[area_t] == c_msnow_leaves1 or data[area_t] == c_msnow_leaves2 then    --sets if air
            data[area_t] = c_tree    --add tree now
        end
    end
end


mg_villages.grow_jungletree = function(data, a, pos, seed, snow)
        --[[
                NOTE: Tree-placing code is currently duplicated in the engine
                and in games that have saplings; both are deprecated but not
                replaced yet
        ]]--
    local c_junglesapling = minetest.get_content_id("default:junglesapling");
    local c_jungletree = minetest.get_content_id("default:jungletree")
    local c_jungleleaves = minetest.get_content_id("default:jungleleaves")
    local c_snow = minetest.get_content_id("default:snow");

    local leaves_type = c_jungleleaves;
    if(  snow
      or data[ a:index(pos.x, pos.y,   pos.z) ] == c_snow
      or data[ a:index(pos.x, pos.y+1, pos.z) ] == c_snow ) then
       leaves_type = c_msnow_leaves1;
    end

    local hight = math.random(8, 12)
    for x_area = -3, 3 do
    for y_area = -2, 2 do
    for z_area = -3, 3 do
        if math.random(1,30) < 23 then  --randomize leaves
            local area_l = a:index(pos.x+x_area, pos.y+hight+y_area-1, pos.z+z_area)  --sets area for leaves
            if data[area_l] == c_air or data[area_l] == c_ignore then    --sets if it's air or ignore
                data[area_l] = leaves_type    --add leaves now
            end
         end       
    end
    end
    end
    for tree_h = 0, hight-1 do  -- add the trunk
        local area_t = a:index(pos.x, pos.y+tree_h, pos.z)  --set area for tree
        if data[area_t] == c_air or data[area_t] == c_jungleleaves or data[area_t] == c_junglesapling or data[area_t] == c_snow or data[area_t] == c_msnow_top then    --sets if air
            data[area_t] = c_jungletree    --add tree now
        end
    end
    for roots_x = -1, 1 do
    for roots_z = -1, 1 do
        if math.random(1, 3) >= 2 then  --randomize roots
            if a:contains(pos.x+roots_x, pos.y-1, pos.z+roots_z) and data[a:index(pos.x+roots_x, pos.y-1, pos.z+roots_z)] == c_air then
                data[a:index(pos.x+roots_x, pos.y-1, pos.z+roots_z)] = c_jungletree
            elseif a:contains(pos.x+roots_x, pos.y, pos.z+roots_z) and data[a:index(pos.x+roots_x, pos.y, pos.z+roots_z)] == c_air then
                data[a:index(pos.x+roots_x, pos.y, pos.z+roots_z)] = c_jungletree
            end
        end
    end
    end
end

-- taken from minetest_game/mods/default/trees.lua
mg_villages.trees_add_pine_needles = function(data, vi, c_air, c_ignore, c_snow, c_pine_needles)
	if data[vi] == c_air or data[vi] == c_ignore or data[vi] == c_snow then
		data[vi] = c_pine_needles
	end
end

mg_villages.trees_add_snow = function(data, vi, c_air, c_ignore, c_snow)
	if data[vi] == c_air or data[vi] == c_ignore then
		data[vi] = c_snow
	end
end

mg_villages.grow_pinetree = function(data, a, pos, snow)
	local x, y, z = pos.x, pos.y, pos.z
	local maxy = y + math.random(9, 13) -- Trunk top

	local c_air = minetest.get_content_id("air")
	local c_ignore = minetest.get_content_id("ignore")
	local c_pinetree = minetest.get_content_id("default:pine_tree")
	local c_pine_needles  = minetest.get_content_id("default:pine_needles")
	local c_snow = minetest.get_content_id("default:snow")
	local c_snowblock = minetest.get_content_id("default:snowblock")
	local c_dirtsnow = minetest.get_content_id("default:dirt_with_snow")

	-- Scan for snow nodes near sapling
--	local snow = false
	for yy = y - 1, y + 1 do
	for zz = z - 1, z + 1 do
		local vi  = a:index(x - 1, yy, zz)
		for xx = x - 1, x + 1 do
			local nodid = data[vi]
			if nodid == c_snow
			or nodid == c_snowblock
			or nodid == c_dirtsnow then
				snow = true
			end
			vi  = vi + 1
		end
	end
	end

	-- Upper branches layer
	local dev = 3
	for yy = maxy - 1, maxy + 1 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			local via = a:index(x - dev, yy + 1, zz)
			for xx = x - dev, x + dev do
				if math.random() < 0.95 - dev * 0.05 then
					mg_villages.trees_add_pine_needles(data, vi, c_air, c_ignore, c_snow,
							c_pine_needles)
					if snow then
						mg_villages.trees_add_snow(data, via, c_air, c_ignore, c_snow)
					end
				end
				vi  = vi + 1
				via = via + 1
			end
		end
		dev = dev - 1
	end

	-- Centre top nodes
	mg_villages.trees_add_pine_needles(data, a:index(x, maxy + 1, z), c_air, c_ignore, c_snow,
			c_pine_needles)
	mg_villages.trees_add_pine_needles(data, a:index(x, maxy + 2, z), c_air, c_ignore, c_snow,
			c_pine_needles) -- Paramat added a pointy top node
	if snow then
		mg_villages.trees_add_snow(data, a:index(x, maxy + 3, z), c_air, c_ignore, c_snow)
	end

	-- Lower branches layer
	local my = 0
	for i = 1, 20 do -- Random 2x2 squares of needles
		local xi = x + math.random(-3, 2)
		local yy = maxy + math.random(-6, -5)
		local zi = z + math.random(-3, 2)
		if yy > my then
			my = yy
		end
		for zz = zi, zi+1 do
			local vi = a:index(xi, yy, zz)
			local via = a:index(xi, yy + 1, zz)
			for xx = xi, xi + 1 do
				mg_villages.trees_add_pine_needles(data, vi, c_air, c_ignore, c_snow,
						c_pine_needles)
				if snow then
					mg_villages.trees_add_snow(data, via, c_air, c_ignore, c_snow)
				end
				vi  = vi + 1
				via = via + 1
			end
		end
	end

	local dev = 2
	for yy = my + 1, my + 2 do
		for zz = z - dev, z + dev do
			local vi = a:index(x - dev, yy, zz)
			local via = a:index(x - dev, yy + 1, zz)
			for xx = x - dev, x + dev do
				if math.random() < 0.95 - dev * 0.05 then
					mg_villages.trees_add_pine_needles(data, vi, c_air, c_ignore, c_snow,
							c_pine_needles)
					if snow then
						mg_villages.trees_add_snow(data, via, c_air, c_ignore, c_snow)
					end
				end
				vi  = vi + 1
				via = via + 1
			end
		end
		dev = dev - 1
	end

	-- Trunk
	for yy = y, maxy do
		local vi = a:index(x, yy, z)
		data[vi] = c_pinetree
	end

end

