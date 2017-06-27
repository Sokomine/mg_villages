
--[[
 Data about mobs is stored for each plot in the array beds.

 Each entry in the beds table may have the following entries:
   x, y, z      position of the bed; set automaticly by handle_schematics.
                This is the position of the node containing the head of the bed.
                Supported beds are normal bed, fancy bed and the bed from cottages.
   p2           param2 of the node that contains the head of the bed; set
                automaticly by handle_schematics.
   first_name   the first name of a mob; all mobs with the same profession in the
                same village have diffrent first names; also family members have
                uniq first names (inside each village; not globally)
   middle_name  random middle initial (just one letter)
   gender       m or f (male/female)
   generation   1 for children, 2 for parents (=workers), 3 for workers parents
   age          age of the mob in years
 optional entries:
   works_at     plot_nr of the place where this mob works (may be the same as the
                current one if he works at home)
   title        profession of the mob; see worker.title; also acts as a family name
                to some degree
   belongs_to   some plots are neither workplaces nor places where mobs may live;
                it is assumed that other mobs will "own" these places and work there
                aside from their main job; this includes sheds, meadows, pastures
                and wagons
   owns         array containing the ids of plots which belong_to this plot here
            

 Apart from the beds array, there may also be a worker array. It contains information
 about the mob that *works* at this place. Each entry in the worker table contains
 the following information:
   works_as     general job description name (i.e. "shopkeeper")
   title        more specific job description (i.e. "flower seller");
                also used for the name of the mob and to some degree as a family name
   lives_at     plot_nr of the house where the worker lives
   uniq         counts how many other mobs in the village have the same profession
                (=worker.title); also determines weather the mob will be called i.e.
                "the flower seller" (if there is only one in this village) or "a
                flower seller" (if there are several)

 Important: In order to *really* spawn a mob, you need to override the function
 mg_villages.inhabitants.spawn_one_mob (see mobf_trader for an example).
--]]



mg_villages.inhabitants = {}

mg_villages.inhabitants.names_male = { "John", "James", "Charles", "Robert", "Joseph",
	"Richard", "David", "Michael", "Christopher", "Jason", "Matthew",
	"Joshua", "Daniel","Andrew", "Tyler", "Jakob", "Nicholas", "Ethan",
	"Alexander", "Jayden", "Mason", "Liam", "Oliver", "Jack", "Harry",
	"George", "Charlie", "Jacob", "Thomas", "Noah", "Wiliam", "Oscar",
	"Clement", "August", "Peter", "Edgar", "Calvin", "Francis", "Frank",
	"Eli", "Adam", "Samuel", "Bartholomew", "Edward", "Roger", "Albert",
	"Carl", "Alfred", "Emmett", "Eric", "Henry", "Casimir", "Alan",
	"Brian", "Logan", "Stephen", "Alexander", "Gregory", "Timothy",
	"Theodore", "Marcus", "Justin", "Julius", "Felix", "Pascal", "Jim",
	"Ben", "Zach", "Tom" };

mg_villages.inhabitants.names_female = { "Amelia", "Isla", "Ella", "Poppy", "Mia", "Mary",
	"Anna", "Emma", "Elizabeth", "Minnie", "Margret", "Ruth", "Helen",
	"Dorothy", "Betty", "Barbara", "Joan", "Shirley", "Patricia", "Judith",
	"Carol", "Linda", "Sandra", "Susan", "Deborah", "Debra", "Karen", "Donna",
	"Lisa", "Kimberly", "Michelle", "Jennifer", "Melissa", "Amy", "Heather",
	"Angela", "Jessica", "Amanda", "Sarah", "Ashley", "Brittany", "Samatha",
	"Emily", "Hannah", "Alexis", "Madison", "Olivia", "Abigail", "Isabella",
	"Ava", "Sophia", "Martha", "Rosalind", "Matilda", "Birgid", "Jennifer",
	"Chloe", "Katherine", "Penelope", "Laura", "Victoria", "Cecila", "Julia",
	"Rose", "Violet", "Jasmine", "Beth", "Stephanie", "Jane", "Jacqueline",
	"Josephine", "Danielle", "Paula", "Pauline", "Patricia", "Francesca"}

-- get a middle name for the mob
mg_villages.inhabitants.get_random_letter = function()
	return string.char( string.byte( "A") + math.random( string.byte("Z") - string.byte( "A")));
end

-- this is for medieval villages
mg_villages.inhabitants.get_family_function_str = function( data )
	if(     data.generation == 2 and data.gender=="m") then
		return "worker";
	elseif( data.generation == 2 and data.gender=="f") then
		return "wife";
	elseif( data.generation == 3 and data.gender=="m") then
		return "father";
	elseif( data.generation == 3 and data.gender=="f") then
		return "mother";
	elseif( data.generation == 1 and data.gender=="m") then
		return "son";
	elseif( data.generation == 1 and data.gender=="f") then
		return "daughter";
	else
		return "unkown";
	end
end

mg_villages.inhabitants.mob_get_full_name = function( data, worker_data )
	if( not( data ) or not( data.first_name )) then
		return;
	end
	local str = data.first_name;
	if( data.mob_id ) then
	   str = "["..data.mob_id.."] "..minetest.pos_to_string( data ).." "..data.first_name;
	else
	   str = " -no mob assigned - "..minetest.pos_to_string( data ).." "..data.first_name;
	end

	if( data.middle_name ) then
		str = str.." "..data.middle_name..".";
	end
	if( data.last_name ) then
		str = str.." "..data.last_name;
	end
	if( data.age ) then
		str = str..", age "..data.age;
	end

	if( worker_data and worker_data.title and worker_data.title ~= "" ) then
		if( data.title and data.title == 'guest' ) then
			str = str..", a guest staying at "..worker_data.title.." "..worker_data.first_name.."'s house";
		elseif( data.generation==2 and data.gender=="m" and data.title and data.uniq>1) then
			str = str..", a "..data.title; --", one of "..tostring( worker_data.uniq ).." "..worker_data.title.."s";
		-- if there is a job:   , the blacksmith
		elseif( data.generation==2 and data.gender=="m" and data.title) then
			str = str..", the "..data.title;
			-- if there is a job:   , blacksmith Fred's son   etc.
		elseif( worker_data.uniq>1 ) then
			str = str..", "..worker_data.title.." "..worker_data.first_name.."'s "..mg_villages.inhabitants.get_family_function_str( data );
		else
			str = str..", the "..worker_data.title.."'s "..mg_villages.inhabitants.get_family_function_str( data );
		end
	-- else something like i.e. (son)
	elseif( data.generation and data.gender ) then
		str = str.." ("..mg_villages.inhabitants.get_family_function_str( data )..")";
	end
	return str;
end


-- override this function if you want more specific names (regional, age based, ..)
-- usually just "gender" is of intrest
-- name_exclude will be evaluated in get_new_inhabitant
-- village contains the village data of the entire village
mg_villages.inhabitants.get_names_list_full = function( data, gender, generation, name_exclude, min_age, village)
	if( gender=="f") then
		return mg_villages.inhabitants.names_female;
	else -- if( gender=="m" ) then
		return mg_villages.inhabitants.names_male;
	end
end


-- configure a new inhabitant
-- 	gender		can be "m" or "f"
--	generation	2 for parent-generation, 1 for children, 3 for grandparents
--	name_exlcude	names the npc is not allowed to carry (=avoid duplicates)
--			(not a list but a hash table)
-- there can only be one mob with the same first name and the same profession per village
mg_villages.inhabitants.get_new_inhabitant = function( data, gender, generation, name_exclude, min_age, village )
	-- only create a new inhabitant if this one has not yet been configured
	if( not( data ) or data.first_name ) then
		return data;
	end

	-- the gender of children is random
	if( gender=="r" ) then
		if( math.random(2)==1 ) then
			gender = "m";
		else
			gender = "f";
		end
	end

	local name_list = mg_villages.inhabitants.get_names_list_full( data, gender, generation, name_exclude, min_age, village );
	if( gender=="f") then
		data.gender     = "f";   -- female
	else -- if( gender=="m" ) then
		data.gender     = "m";   -- male
	end
	local name_list_tmp = {};
	for i,v in ipairs( name_list ) do
		if( not( name_exclude[ v ])) then
			table.insert( name_list_tmp, v );
		end
	end
	data.first_name = name_list_tmp[ math.random(#name_list_tmp)];
	-- middle name as used in the english speaking world (might help to distinguish mobs with the same first name)
	data.middle_name = mg_villages.inhabitants.get_random_letter();

	data.generation = generation; -- 2: parent generation; 1: child; 3: grandparents
	if(     data.generation == 1 ) then
		data.age =      math.random( 18 ); -- a child
	elseif( data.generation == 2 ) then
		data.age = 18 + math.random( 30 ); -- a parent
	elseif( data.generation == 3 ) then
		data.age = 48 + math.random( 50 ); -- a grandparent
	end
	if( min_age ) then
		data.age = min_age + math.random( 12 );
	end
	return data;
end


-- assign inhabitants to bed positions; create families;
-- bpos needs to contain at least { beds = {list_of_bed_positions}, btype = building_type}
-- bpos is the building position data of one building each
mg_villages.inhabitants.assign_mobs_to_beds = function( bpos, house_nr, village_to_add_data_bpos, village )

	if( not( bpos ) or not( bpos.btype ) or not( bpos.beds)) then
		return bpos;
	end

	-- make sure no duplicates exist
	local check_duplicates = {};
	local new_table = {};
	for i,v in ipairs( bpos.beds ) do
		local str = minetest.pos_to_string( v );
		if( not(check_duplicates[ str ])) then
			table.insert( new_table, v );
		end
		check_duplicates[ str ] = 1;
	end
	bpos.beds = new_table;

	-- workplaces got assigned earlier on
	local works_at = nil;
	local title    = nil;
	local not_uniq = 0;
	-- any other plots (sheds, wagons, fields, pastures) the worker here may own
	local owns = {};
	for nr, v in ipairs( village_to_add_data_bpos ) do
		-- have we found the workplace of this mob?
		if( v and v.worker and v.worker.lives_at and v.worker.lives_at == house_nr ) then
			works_at = nr;
			title    = v.worker.title;
			if( v.worker.uniq ) then
				not_uniq = v.worker.uniq;
			end
		end
		-- ..or another plot that the mob might own?
		if( v and v.belongs_to and v.belongs_to == house_nr ) then
			table.insert( owns, nr );
		end
	end

	local worker_names_with_same_profession = {};
	-- if the profession of this mob is not uniq then at least make sure that he does not share a name with a mob with the same profession
	if( not_uniq > 1 ) then
		for nr, v in ipairs( village_to_add_data_bpos ) do
			if( v and v.worker and v.worker.lives_at
			  and village_to_add_data_bpos[ v.worker.lives_at ]
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds[1]
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds[1].first_name ) then
				table.insert( worker_names_with_same_profession, village_to_add_data_bpos[ v.worker.lives_at ].beds[1].first_name );
			end
		end
	end


	-- get data about the building
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];
	-- the building type determines which kind of mob will live there
	if( not( building_data ) or not( building_data.typ )
	   -- are there beds where the mob can sleep?
	   or not( bpos.beds ) or table.getn( bpos.beds ) < 1) then
		return bpos;
	end

	-- lumberjack home
	if( building_data.typ == "lumberjack" ) then

		for i,v in ipairs( bpos.beds ) do
			-- lumberjacks do not have families and are all male
			v = mg_villages.inhabitants.get_new_inhabitant( v, "m", 2, worker_names_with_same_profession, nil, village );
			-- the first worker in a lumberjack hut can get work assigned and own other plots
			if( works_at and i==1) then
				v.works_at = works_at;
				v.title    = title;
				v.uniq     = not_uniq;
			else
				v.title    = 'lumberjack';
				v.uniq     = 99; -- one of many lumberjacks here
			end
			if( owns and #owns>0 ) then
				v.owns     = owns;
			end
		end

	-- normal house containing a family
	else
		-- the first inhabitant will be the male worker
		if( not( bpos.beds[1].first_name )) then
			bpos.beds[1] = mg_villages.inhabitants.get_new_inhabitant( bpos.beds[1], "m", 2, worker_names_with_same_profession, nil, village ); -- male of parent generation
			if( works_at ) then
				bpos.beds[1].works_at = works_at;
				bpos.beds[1].title    = title;
				bpos.beds[1].uniq     = not_uniq;
			end
			if( owns and #owns>0 ) then
				bpos.beds[1].owns     = owns;
			end
		end

		local name_exclude = {};
		-- the second inhabitant will be the wife of the male worker
		if( bpos.beds[2] and not( bpos.beds[2].first_name )) then
			bpos.beds[2] = mg_villages.inhabitants.get_new_inhabitant( bpos.beds[2], "f", 2, {}, nil, village ); -- female of parent generation
			-- first names ought to be uniq withhin a family
			name_exclude[ bpos.beds[2].first_name ] = 1;
		end

		-- not all houses will have grandparents
		local grandmother_bed_id = 2+math.random(5);
		local grandfather_bed_id = 2+math.random(5);
		-- some houses have guests
		local guest_id = 99;
		-- all but the given number are guests
		if( building_data.guests ) then
			guest_id = building_data.guests * -1;
		end
		-- a child of 18 with a parent of 19 would be...usually impossible unless adopted
		local oldest_child = 0;

		-- the third and subsequent inhabitants will ether be children or grandparents
		for i,v in ipairs( bpos.beds ) do
			if(     v and v.first_name and v.generation == 3 and v.gender=="f" ) then
				grandmother_bed_id = i;
			elseif( v and v.first_name and v.generation == 3 and v.gender=="m" ) then
				grandfather_bed_id = i;

			-- at max 7 npc per house (taverns may have more beds than that)
			elseif( v and not( v.first_name )) then
				if( i>guest_id ) then
					v = mg_villages.inhabitants.get_new_inhabitant( v, "r", math.random(3), name_exclude, nil, village ); -- get a random guest
					v.title = 'guest';
				elseif( i==grandmother_bed_id ) then
					v = mg_villages.inhabitants.get_new_inhabitant( v, "f", 3, name_exclude, bpos.beds[1].age+18, village ); -- get the grandmother
				elseif( i==grandfather_bed_id ) then
					v = mg_villages.inhabitants.get_new_inhabitant( v, "m", 3, name_exclude, bpos.beds[1].age+18, village ); -- get the grandfather
				else
					v = mg_villages.inhabitants.get_new_inhabitant( v, "r", 1, name_exclude, nil, village ); -- get a child of random gender
					-- find out how old the oldest child is
					if( v.age > oldest_child ) then
						oldest_child = v.age;
					end
				end
				-- children and grandparents need uniq names withhin a family
				name_exclude[ v.first_name ] = 1;
			end
		end
		-- the father has to be old enough for his children
		if( bpos.beds[1] and oldest_child + 18 > bpos.beds[1].age ) then
			bpos.beds[1].age = oldest_child + 18 + math.random( 10 );
		end
		-- the mother also has to be old enough as well
		if( bpos.beds[2] and oldest_child + 18 > bpos.beds[2].age ) then
			bpos.beds[2].age = oldest_child + 18 + math.random( 10 );
		end
	end

	return bpos;
end


-- print information about which mobs "live" in a house
mg_villages.inhabitants.print_house_info = function( village_to_add_data_bpos, house_nr, village_id )

	local bpos = village_to_add_data_bpos[ house_nr ];
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];

	if( not( building_data ) or not( building_data.typ )) then
		building_data = { typ = bpos.btype };
	end
	local str = "Plot Nr. "..tostring( house_nr ).." ["..tostring( building_data.typ or "-?-").."] ";
	if( bpos.btype == "road" ) then
		str = str.."is a road.\n";

	-- wagon, shed, field and pasture
	elseif( bpos.belongs_to and village_to_add_data_bpos[ bpos.belongs_to ].beds) then
		local owner = village_to_add_data_bpos[ bpos.belongs_to ].beds[1];
		if( not( owner ) or not( owner.first_name )) then
			str = str.."WARNING: NO ONE owns this plot.\n";
		else
			str = str.."belongs to: "..mg_villages.inhabitants.mob_get_full_name( owner, owner ).."\n";
		end

	elseif( not( bpos.beds ) or #bpos.beds<1 and bpos.worker and bpos.worker.title) then
		if( not( bpos.worker.lives_at)) then
			str = str.."WARNING: NO WORKER assigned to this plot.\n";
		else
			local worker = village_to_add_data_bpos[ bpos.worker.lives_at ].beds[1];
			str = str..mg_villages.inhabitants.mob_get_full_name( worker, worker ).." works here.\n";
		end

	elseif( not( bpos.beds ) or not( bpos.beds[1])) then
		str = str.."provides neither work nor housing.\n";

	else
		str = str.."is inhabitated by:\n";
		-- make sure all mobs living here are spawned
		mg_villages.inhabitants.spawn_mobs_for_one_house( bpos, nil, nil, village_id, house_nr );
		for i,v in ipairs( bpos.beds ) do
			if( v and v.first_name ) then
				str = str.."  "..mg_villages.inhabitants.mob_get_full_name( v, bpos.beds[1] );
				if( i==1 and bpos.beds[1] and bpos.beds[1].works_at and bpos.beds[1].works_at==house_nr ) then
					str = str.." who lives and works here\n";
				elseif( i==1 ) then
					local works_at = bpos.beds[1].works_at;
					local btype2 = mg_villages.BUILDINGS[ village_to_add_data_bpos[ works_at ].btype];
					str = str.." who works at the "..tostring( btype2.typ ).." on plot "..tostring(works_at).."\n";
				else
					str = str.."\n";
				end
			end
		end
		-- other plots owned
		if( bpos.beds and bpos.beds[1] and bpos.beds[1].owns ) then
			str = str.."The family also owns the plot(s) ";
			for i,v in ipairs( bpos.beds[1].owns ) do
				if( i>1 ) then
					str = str..", ";
				end
				local building_data = mg_villages.BUILDINGS[ village_to_add_data_bpos[v].btype ];
				str = str.."Nr. "..tostring( v ).." ("..building_data.typ..")";
			end
			str = str.."\n";
		end
	end
	return str;
end



-- some building types will determine the name of the job
mg_villages.inhabitants.jobs_in_buildings = {};
mg_villages.inhabitants.jobs_in_buildings[ 'mill'       ] = {'miller'};
mg_villages.inhabitants.jobs_in_buildings[ 'bakery'     ] = {'baker'};
mg_villages.inhabitants.jobs_in_buildings[ 'church'     ] = {'priest'};
mg_villages.inhabitants.jobs_in_buildings[ 'tower'      ] = {'guard'};
mg_villages.inhabitants.jobs_in_buildings[ 'school'     ] = {'schoolteacher'};
mg_villages.inhabitants.jobs_in_buildings[ 'library'    ] = {'librarian'};
mg_villages.inhabitants.jobs_in_buildings[ 'tavern'     ] = {'barkeeper'};
mg_villages.inhabitants.jobs_in_buildings[ 'pub'        ] = {'barkeeper'};
mg_villages.inhabitants.jobs_in_buildings[ 'inn'        ] = {'innkeeper'};
mg_villages.inhabitants.jobs_in_buildings[ 'hotel'      ] = {'innkeeper'};
mg_villages.inhabitants.jobs_in_buildings[ 'forge'      ] = {'smith',
		-- bronzesmith, bladesmith, locksmith etc. may be of little use in our MT worlds;
		-- the blacksmith is the most common one, followed by the coppersmith
		{'blacksmith','blacksmith', 'blacksmith',  'coppersmith','coppersmith',
		 'tinsmith', 'goldsmith'}};
mg_villages.inhabitants.jobs_in_buildings[ 'shop'       ] = {'shopkeeper',
		-- the shopkeeper is the most common; however, there can be more specialized sellers
		{'shopkeeper', 'shopkeeper', 'shopkeeper', 'seed seller', 'flower seller', 'ore seller', 'fruit trader', 'wood trader'}};
mg_villages.inhabitants.jobs_in_buildings[ 'charachoal' ] = {'charachoal burner'};
mg_villages.inhabitants.jobs_in_buildings[ 'trader'     ] = {'trader'}; -- TODO: currently only used for clay traders
mg_villages.inhabitants.jobs_in_buildings[ 'chateau'    ] = {'servant'};
mg_villages.inhabitants.jobs_in_buildings[ 'sawmill'    ] = {'sawmill owner'};
mg_villages.inhabitants.jobs_in_buildings[ 'forrest'    ] = {'lumberjack'}; -- TODO: we don't have forrests yet
mg_villages.inhabitants.jobs_in_buildings['village_square']={'major'};
mg_villages.inhabitants.jobs_in_buildings[ 'horsestable'] = {'horsekeeper'};



-- TODO pit - suitable for traders (they sell clay...)

mg_villages.inhabitants.assign_jobs_to_houses = function( village_to_add_data_bpos )

	local workers_required = {};	-- places that require a specific worker that lives elsewhere
	local found_farm_full  = {};	-- farmers (they like to work on fields and pastures)
	local found_hut        = {};	-- workers best fit for working in other buildings
	local found_house      = {};	-- workers which may either take a random job or work elsewhere
	local suggests_worker  = {};	-- sheds and wagons can support workers with a random job
	local suggests_farmer  = {};	-- fields and pastures are ideal for farmers
	-- find out which jobs need to get taken
	for house_id,bpos in ipairs(village_to_add_data_bpos) do
		-- get data about the building
		local building_data = mg_villages.BUILDINGS[ bpos.btype ];
		-- the building type determines which kind of mobs will live there;

		-- nothing gets assigned if we don't have data
		if( not( building_data ) or not( building_data.typ )
		-- or if a mob is assigned already
		   or bpos.worker) then

		-- some buildings require a specific worker
		elseif( mg_villages.inhabitants.jobs_in_buildings[ building_data.typ ] ) then
			local worker_data = mg_villages.inhabitants.jobs_in_buildings[ building_data.typ ];
			bpos.worker = {};
			bpos.worker.works_as =  worker_data[1];
			-- the worker might be specialized
			if( worker_data[2] ) then
				bpos.worker.title = worker_data[2][ math.random( #worker_data[2])];
			-- otherwise his title is the same as his job name
			else
				bpos.worker.title = bpos.worker.works_as;
			end
			-- can the worker sleep there or does he require a house elsewhere?
			if( building_data.bed_count and building_data.bed_count > 0 ) then
				bpos.worker.lives_at = house_id;
			else
				table.insert( workers_required, house_id );
			end

		-- we have found a place with a bed that does not reuiqre a worker directly
		elseif( building_data.bed_count and building_data.bed_count > 0 ) then

			-- mobs having to take care of a full farm (=farm where the farmer's main income is
			-- gained from farming) are less likely to have time for other jobs
			if(     building_data.typ=='farm_full' ) then
				table.insert( found_farm_full, house_id );
			-- mobs living in a hut are the best candidates for jobs in other buildings
			elseif( building_data.typ=='hut' ) then
				table.insert( found_hut,       house_id );
			-- other mobs may either take on a random job or work in other buildings
			else
				table.insert( found_house,     house_id );
			end

		-- sheds and wagons are useful for random jobs but do not really require a worker
		elseif( building_data.typ == 'shed'
		     or building_data.typ == 'wagon' ) then

			table.insert( suggests_worker, house_id );

		-- fields and pastures are places where full farmers are best at
		elseif( building_data.typ == 'field'
		     or building_data.typ == 'pasture' ) then

			table.insert( suggests_farmer, house_id );
		end
	end

	-- these are only additional; they do not require a worker as such
	-- assign sheds and wagons randomly to suitable houses
	for i,v in ipairs( suggests_worker ) do
		-- order: found_house, found_hut, found_farm_full
		if(     #found_house>0 ) then
			local nr = math.random( #found_house );
			village_to_add_data_bpos[ v ].belongs_to = found_house[ nr ];
		elseif( #found_hut  >0 ) then
			local nr = math.random( #found_hut   );
			village_to_add_data_bpos[ v ].belongs_to = found_hut[ nr ];
		elseif( #found_farm_full>0 ) then
			local nr = math.random( #found_farm_full );
			village_to_add_data_bpos[ v ].belongs_to = found_farm_full[ nr ];
		else
		-- print("NOT ASSIGNING work PLOT Nr. "..tostring(v).." to anything (nothing suitable found)");
		end
	end

	-- assign fields and pastures randomly to suitable houses
	for i,v in ipairs( suggests_farmer ) do
		-- order: found_farm_full, found_house, found_hut
		if(     #found_farm_full>0 ) then
			local nr = math.random( #found_farm_full );
			village_to_add_data_bpos[ v ].belongs_to = found_farm_full[ nr ];
		elseif( #found_house>0 ) then
			local nr = math.random( #found_house );
			village_to_add_data_bpos[ v ].belongs_to = found_house[ nr ];
		elseif( #found_hut  >0 ) then
			local nr = math.random( #found_hut   );
			village_to_add_data_bpos[ v ].belongs_to = found_hut[ nr ];
		else
		-- print("NOT ASSIGNING farm PLOT Nr. "..tostring(v).." to anything (nothing suitable found)");
		end
	end

	-- find workers for jobs that require workes who live elsewhere
	for i,v in ipairs( workers_required ) do
		-- huts are ideal
		if(     #found_hut>0 ) then
			local nr = math.random( #found_hut );
			village_to_add_data_bpos[ v ].worker.lives_at = found_hut[ nr ];
			table.remove( found_hut, nr );
		-- but workers may also be gained from other houses where workers may live
		elseif( #found_house > 0 ) then
			local nr = math.random( #found_house );
			village_to_add_data_bpos[ v ].worker.lives_at = found_house[ nr ];
			table.remove( found_house, nr );
		-- if all else fails try to get a worker from a full farm
		elseif( #found_farm_full > 0 ) then
			local nr = math.random( #found_farm_full );
			village_to_add_data_bpos[ v ].worker.lives_at = found_farm_full[ nr ];
			table.remove( found_farm_full, nr );
		-- we ran out of potential workers...
		else
			-- no suitable worker found
			--local building_data = mg_villages.BUILDINGS[ village_to_add_data_bpos[v].btype ];
			--print("NO WORKER FOUND FOR Nr. "..tostring(v).." "..tostring( building_data.typ )..": "..minetest.serialize( village_to_add_data_bpos[v].worker ));
		end
	end

	-- other owners of farm_full buildings become farmers
	for i,v in ipairs( found_farm_full ) do
		village_to_add_data_bpos[ v ].worker = {};
		village_to_add_data_bpos[ v ].worker.works_as = "farmer";
		village_to_add_data_bpos[ v ].worker.title    = "farmer";
		village_to_add_data_bpos[ v ].worker.lives_at = v; -- house number
	end


	-- add random jobs to the leftover houses
	local random_jobs = { 'stonemason', 'stoneminer', 'carpenter', 'toolmaker',
			'doormaker', 'furnituremaker', 'stairmaker', 'cooper', 'wheelwright',
			'saddler', 'roofer', 'iceman', 'potterer', 'bricklayer', 'dyemaker',
			'glassmaker' };
	for i,v in ipairs( found_house ) do
		local job = random_jobs[ math.random(#random_jobs)];
		village_to_add_data_bpos[ v ].worker = {};
		village_to_add_data_bpos[ v ].worker.works_as = job;
		village_to_add_data_bpos[ v ].worker.title    = job;
		village_to_add_data_bpos[ v ].worker.lives_at = v; -- house number
	end
	for i,v in ipairs( found_hut ) do
		local job = random_jobs[ math.random(#random_jobs)];
		village_to_add_data_bpos[ v ].worker = {};
		village_to_add_data_bpos[ v ].worker.works_as = job;
		village_to_add_data_bpos[ v ].worker.title    = job;
		village_to_add_data_bpos[ v ].worker.lives_at = v; -- house number
	end

	-- find out if there are any duplicate professions
	local professions = {};
	for house_nr,bpos in ipairs( village_to_add_data_bpos ) do
		if( bpos.worker and bpos.worker.title ) then
			if( not( professions[ bpos.worker.title ])) then
				professions[ bpos.worker.title ] = 1;
			else
				professions[ bpos.worker.title ] = professions[ bpos.worker.title ] + 1;
			end
		end
	end
	-- mark all those workers who share the same profession as "not_uniq"
	for house_nr,bpos in ipairs( village_to_add_data_bpos ) do
		if( bpos.worker and bpos.worker.title and professions[ bpos.worker.title ]>1) then
			bpos.worker.uniq = professions[ bpos.worker.title ];
		end
	end
	return village_to_add_data_bpos;
end


-- get the information mg_villages has about a mob (useful for mg_villages:mob_spawner)
mg_villages.inhabitants.get_mob_data = function( village_id, plot_nr, bed_nr )
	if( not( village_id ) or not( plot_nr ) or not( bed_nr )
	  or not( mg_villages.all_villages[ village_id ] )
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ])
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].beds )) then
		return;
	end
	return mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].beds[ bed_nr ];
end


-- mob mods are expected to override this function! mobf_trader mobs are supported directly
mg_villages.inhabitants.spawn_one_mob = function( bed, village_id, plot_nr, bed_nr, bpos )

	--print("NPC spawned in village "..tostring( village_id ).." on plot "..tostring(plot_nr)..", sleeping in bed nr. "..tostring( bed_nr ));
	if( minetest.get_modpath("mobf_trader") and mobf_trader and mobf_trader.spawn_one_trader) then
		return mobf_trader.spawn_one_trader( bed, village_id, plot_nr, bed_nr, bpos );
	end
end

mg_villages.inhabitants.spawn_mobs_for_one_house = function( bpos, minp, maxp, village_id, plot_nr )
	if( not( bpos ) or not( bpos.beds )) then
		return;
	end
	for bed_nr,bed in ipairs( bpos.beds ) do
		-- only for beds that exist, have a mob assigned and fit into minp/maxp
		if( bed
		  and bed.first_name
		  and (not( minp )
		    or (   bed.x>=minp.x and bed.x<=maxp.x
		       and bed.y>=minp.y and bed.y<=maxp.y
		       and bed.z>=minp.z and bed.z<=maxp.z))) then

			bed.mob_id = mg_villages.inhabitants.spawn_one_mob( bed, village_id, plot_nr, bed_nr, bpos );
		end
	end
end


-- spawn mobs in villages
mg_villages.inhabitants.part_of_village_spawned = function( village, minp, maxp, data, param2_data, a, cid )

	-- some types of buildings require special workers
	village.to_add_data.bpos = mg_villages.inhabitants.assign_jobs_to_houses( village.to_add_data.bpos );

	-- for each building in the village
	for plot_nr,bpos in ipairs(village.to_add_data.bpos) do

		-- each bed gets a mob assigned
		bpos = mg_villages.inhabitants.assign_mobs_to_beds( bpos, plot_nr, village.to_add_data.bpos, village );

		-- actually spawn the mobs
		local village_id = tostring( village.vx )..':'..tostring( village.vz );
		mg_villages.inhabitants.spawn_mobs_for_one_house( bpos, minp, maxp, village_id, plot_nr );
	end
end



-- command for debugging all inhabitants of a village (useful for debugging only)
minetest.register_chatcommand( 'inhabitants', {
	description = "Prints out a list of inhabitants of a village plus their professions.",
	params = "<village number>",
	privs = {},
	func = function(name, param)


		if( not( param ) or param == "" ) then
			minetest.chat_send_player( name, "List the inhabitants of which village? Please provide the village number!");
			return;
		end

		local nr = tonumber( param );
		for id, v in pairs( mg_villages.all_villages ) do
			-- we have found the village
			if( v and v.nr == nr ) then

				minetest.chat_send_player( name, "Printing information about inhabitants of village no. "..tostring( v.nr )..", called "..( tostring( v.name or 'unknown')).." to console.");
				-- actually print it
				for house_nr = 1,#v.to_add_data.bpos do
					minetest.chat_send_player( name, mg_villages.inhabitants.print_house_info( v.to_add_data.bpos, house_nr, v.nr ));
				end
				return;
			end
		end
		-- no village found
		minetest.chat_send_player( name, "There is no village with the number "..tostring( param ).." (yet?).");
	end
});

