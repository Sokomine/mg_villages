
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
 other:
   bnr          index of this mob's bed in mg_villages.BUILDINGS[ this_building_type ].bed_list
            

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

-- in most cases this will be something like "John D.", "Martha A." etc.
mg_villages.inhabitants.mob_get_short_name = function( data )
	if( not( data ) or not( data.first_name )) then
		return "- unkown -";
	end
	local str = data.first_name;
	if( data.middle_name ) then
		str = str.." "..data.middle_name..".";
	end
	if( data.last_name ) then
		str = str.." "..data.last_name;
	end
	return str;
end


-- worker_data contains data about the father of the mob or about the mob him/herself
-- (needed for determining family relationship)
mg_villages.inhabitants.mob_get_full_name = function( data, worker_data )
	if( not( data ) or not( data.first_name )) then
		return "- unkown -";
	end
	local str = data.first_name;
--	if( data.mob_id ) then
--	   str = "["..data.mob_id.."] "..minetest.pos_to_string( data ).." "..data.first_name;
--	else
--	   str = " -no mob assigned - "..minetest.pos_to_string( data ).." "..data.first_name;
--	end

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
		elseif( data.title and (data.title == "servant" or data.title=="housemaid" or data.title=="guard" or data.title=="soldier")) then
			str = str..", a "..data.title;

		elseif( data.generation==2 and data.gender=="m" and data.title and data.uniq and data.uniq>1) then
			str = str..", a "..data.title; --", one of "..tostring( worker_data.uniq ).." "..worker_data.title.."s";
		-- if there is a job:   , the blacksmith
		elseif( data.generation==2 and data.gender=="m" and data.title) then
			str = str..", the "..data.title;
			-- if there is a job:   , blacksmith Fred's son   etc.
		elseif( worker_data.uniq and worker_data.uniq>1 ) then
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
-- bpos needs to contain at least { btype = building_type }
-- bpos is the building position data of one building each
-- Important: This function assigns a mob to each bed that was identified using path_info.
--            The real positions of the beds have to be calculated using
--               mg_villages.transform_coordinates( {p.x,p.y,p.z}, bpos )
--            with p beeing the corresponding entry from mg_villages.BUILDINGS[ bpos.btype ].bed_list
mg_villages.inhabitants.assign_mobs_to_beds = function( bpos, house_nr, village_to_add_data_bpos, village )

	if( not( bpos ) or not( bpos.btype )) then
		return bpos;
	end

	-- get data about the building
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];
	-- the building type determines which kind of mob will live there
	if( not( building_data ) or not( building_data.typ )
	   -- are there beds where the mob can sleep?
	   or not( building_data.bed_list ) or #building_data.bed_list < 1) then
		return bpos;
	end

	-- does the mob have a preferred spot where he likes to stand to receive customers/work?
	-- i.e. teacher, shop owner, priest,...
	-- this is the index of the mob's workplace in the building_data.workplace_list
	local workplace_index = 1;

	-- workplaces got assigned earlier on
	local works_at = nil;
	local title    = nil;
	local uniq     = nil;
	local not_uniq = 0;
	-- any other plots (sheds, wagons, fields, pastures) the worker here may own
	local owns = {};
	for nr, v in ipairs( village_to_add_data_bpos ) do
		-- have we found the workplace of this mob?
		if( v and v.worker and v.worker.lives_at and v.worker.lives_at == house_nr ) then
			works_at = nr;
			title    = v.worker.title;
			uniq     = v.worker.uniq;
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
			  and v.worker.title == title -- same profession
			  and village_to_add_data_bpos[ v.worker.lives_at ]
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds[1]
			  and village_to_add_data_bpos[ v.worker.lives_at ].beds[1].first_name ) then
				worker_names_with_same_profession[ village_to_add_data_bpos[ v.worker.lives_at ].beds[1].first_name ] = 1;
			end
		end
	end

	bpos.beds = {};
	-- make sure each bed is defined in the bpos.beds data structure, even if empty
	for i,bed in ipairs( building_data.bed_list ) do
		bpos.beds[i] = {};
		-- store the index for faster lookup
		bpos.beds[i].bnr = i;
		local p = mg_villages.transform_coordinates( {bed[1],bed[2],bed[3],bed[4]}, bpos )
		bpos.beds[i].x = p.x;
		bpos.beds[i].y = p.y;
		bpos.beds[i].z = p.z;
		bpos.beds[i].p2 =p.p2;
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
				v.uniq     = uniq;
				v.workplace= 1; -- gets the first available workplace there
				-- if he works at home, the first workplace there is taken
				if( works_at == house_nr ) then
					workplace_index = 2;
				end
			else
				v.title    = 'lumberjack';
				v.works_at = house_nr; -- works at home for now; TODO: ought to have a forrest
				v.uniq     = 99; -- one of many lumberjacks here
				-- give the next free workplace to the mob
				v.workplace= workplace_index;
				workplace_index = workplace_index+1;
			end
			if( owns and #owns>0 ) then
				v.owns     = owns;
			end
			worker_names_with_same_profession[ v.first_name ] = 1;
		end

	-- the castle-type buildings contain guards without family
	elseif( building_data.typ == "castle" ) then

		for i,v in ipairs( bpos.beds ) do
			v = mg_villages.inhabitants.get_new_inhabitant( v, "m", 2, worker_names_with_same_profession, nil, village );
			v.works_at = house_nr; -- they work in their castle
			v.title = "soldier";
			v.uniq  = 99; -- one of many guards here
			worker_names_with_same_profession[ v.first_name ] = 1;
			-- each soldier gets a workplace (provided one is available)
			v.workplace = workplace_index;
			workplace_index = workplace_index + 1;
		end

	-- normal house containing a family
	else
		-- the first inhabitant will be the male worker
		if( not( bpos.beds[1].first_name )) then
			bpos.beds[1] = mg_villages.inhabitants.get_new_inhabitant( bpos.beds[1], "m", 2, worker_names_with_same_profession, nil, village ); -- male of parent generation
			if( works_at ) then
				bpos.beds[1].works_at = works_at;
				bpos.beds[1].title    = title;
				bpos.beds[1].uniq     = uniq;
				bpos.beds[1].workplace= 1;
				-- if he works at home, the first workplace there is taken
				if( works_at == house_nr ) then
					workplace_index = 2;
				end
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
			-- no work or title assigned to the wife
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
					-- a chateau has servants instead of guests like a hotel
					if( building_data.typ == "chateau" ) then
						-- working generation (neither children nor grandparents)
						v = mg_villages.inhabitants.get_new_inhabitant( v, "r", 2, name_exclude, nil, village );
						if( v.gender == "m" ) then
							v.title = "servant";
						else
							v.title = "housemaid";
						end
						v.works_at = house_nr;
						v.uniq  = 99; -- one of many servants/housemaids here
						-- give the next free workplace to the mob
						v.workplace = workplace_index;
						workplace_index = workplace_index + 1;
					-- guest in a hotel
					else
						v = mg_villages.inhabitants.get_new_inhabitant( v, "r", math.random(3), name_exclude, nil, village ); -- get a random guest
						v.title = 'guest';
					end
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
		-- the grandfather (father's side) has to be old enough
		if( bpos.beds[1] and bpos.beds[grandfather_bed_id] and bpos.beds[grandfather_bed_id].first_name
		  and bpos.beds[1].age+18 > bpos.beds[grandfather_bed_id].age) then
			bpos.beds[grandfather_bed_id].age = bpos.beds[1].age+18;
		end
		-- ..and also the grandmother (father's side as well)
		if( bpos.beds[1] and bpos.beds[grandmother_bed_id] and bpos.beds[grandmother_bed_id].first_name
		  and bpos.beds[1].age+18 > bpos.beds[grandmother_bed_id].age) then
			bpos.beds[grandmother_bed_id].age = bpos.beds[1].age+18;
		end
	end
	return bpos;
end


-- helper function for listing the plots a mob/house owns (sheds, wagons, fields, ..)
mg_villages.inhabitants.print_plot_list = function(village_to_add_data_bpos, plotlist)
	local str = "";
	if( not( plotlist )) then
		return "";
	end
	for i,v in ipairs( plotlist ) do
		if( i>1 ) then
			str = str..", ";
		end
		local building_data = mg_villages.BUILDINGS[ village_to_add_data_bpos[v].btype ];
		str = str.."Nr. "..tostring( v ).." ("..building_data.typ..")";
	end
	-- the , in the list would disrupt formspecs
	return minetest.formspec_escape(str);
end

-- print information about which mobs "live" in a house
mg_villages.inhabitants.print_house_info = function( village_to_add_data_bpos, house_nr, village_id, pname )

	local bpos = village_to_add_data_bpos[ house_nr ];
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];

	if( not( building_data ) or not( building_data.typ )) then
		building_data = { typ = bpos.btype };
	end
	local str = "Plot Nr. "..tostring( house_nr ).." ["..tostring( building_data.typ or "-?-").."] ";
	local people_str = "";
	local add_str = "";
	if( bpos.road_nr ) then
		str = str.." at road nr. "..tostring( bpos.road_nr ).." ";
	end
	if( bpos.btype == "road" ) then
		str = str.."is a road.";

	-- wagon, shed, field and pasture
	elseif( bpos.belongs_to and village_to_add_data_bpos[ bpos.belongs_to ].beds) then
		local owner = village_to_add_data_bpos[ bpos.belongs_to ].beds[1];
		if( not( owner ) or not( owner.first_name )) then
			str = str.."WARNING: NO ONE owns this plot.";
		else
			str = str.."belongs to:";
			people_str = minetest.formspec_escape( mg_villages.inhabitants.mob_get_full_name( owner, owner ).." owns this plot");
		end

	elseif( (not( bpos.beds ) or #bpos.beds<1) and bpos.worker and bpos.worker.title) then
		if( not( bpos.worker.lives_at)) then
			str = str.."WARNING: NO WORKER assigned to this plot.";
		else
			local worker = village_to_add_data_bpos[ bpos.worker.lives_at ].beds[1];
			str = str.."provides work:";
			local btype2 = mg_villages.BUILDINGS[ village_to_add_data_bpos[ bpos.worker.lives_at ].btype];
			if( btype2 and btype2.typ ) then
				people_str = minetest.formspec_escape( mg_villages.inhabitants.mob_get_full_name( worker, worker ).." who lives at the "..tostring( btype2.typ ).." on plot "..tostring( bpos.worker.lives_at )..", works here");
			else
				people_str = "- unkown -";
			end
		end

	elseif( not( bpos.beds ) or not( bpos.beds[1])) then
		str = str.."provides neither work nor housing.";

	else
		str = str.."is inhabitated by ";
		if( #bpos.beds == 1 ) then
			str = str.."only one person:";
		elseif( #bpos.beds > 1 ) then
			str = str..tostring( #bpos.beds ).." people:";
		else
			str = str.."nobody:";
		end
		-- make sure all mobs living here are spawned
		mg_villages.inhabitants.spawn_mobs_for_one_house( bpos, nil, nil, village_id, house_nr );
		for i,v in ipairs( bpos.beds ) do
			if( v and v.first_name ) then
				local worker_data = bpos.beds[1]; -- the father has the job
				if( v and v.works_at ) then
					worker_data = v;
				end
				people_str = people_str..
					tostring( i )..". "..
					minetest.formspec_escape( mg_villages.inhabitants.mob_get_full_name( v, worker_data ));
				if(v and v.works_at and v.works_at==house_nr ) then
					people_str = people_str.." who lives and works here,";
				elseif( v and v.works_at ) then
					local works_at = bpos.beds[1].works_at;
					local btype2 = mg_villages.BUILDINGS[ village_to_add_data_bpos[ works_at ].btype];
					people_str = people_str.." who works at the "..tostring( btype2.typ ).." on plot "..tostring(works_at)..",";
				elseif( i ~= #bpos.beds ) then
					people_str = people_str..",";
				end
			end
		end
		-- other plots owned
		if( bpos.beds and bpos.beds[1] and bpos.beds[1].owns ) then
			add_str = "The family also owns the plot(s) "..
				mg_villages.inhabitants.print_plot_list(village_to_add_data_bpos, bpos.beds[1].owns)..".";
		end
	end
	-- which entrances/front doors does the building have?
	local front_doors = mg_villages.inhabitants.get_front_doors(bpos);
	local door_str = "Entrances: ";
	for i,p in ipairs( front_doors ) do
		door_str = door_str..minetest.pos_to_string( p ).." ";
	end
	if( not( front_doors ) or #front_doors<1) then
		door_str = door_str.."- unknown -";
	end

	if( people_str == "" ) then
		people_str = "- nobody lives or works here permanently -";
	end
	local link_teleport = "";
	if( pname and minetest.check_player_privs( pname, {teleport=true})) then
		-- teleport to the plotmarker and not somewhere where part of the house may stand
		link_teleport = 'button[8.0,0;1,0.5;teleport_to;Visit]'..
			"field[21,21;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string(
				handle_schematics.get_pos_in_front_of_house( bpos, 0 )).."]";
	end

	-- allow to click through the diffrent plots
	-- (a second back button doesn't hurt)
	local prev_next_button = "button[8.5,4.7;1,0.5;back_to_plotlist;Back]";
	if( house_nr > 1 ) then
		prev_next_button = prev_next_button..'button[9.5,4.7;1,0.5;prev;Prev]';
	end
	if( house_nr < #village_to_add_data_bpos ) then
		prev_next_button = prev_next_button..'button[10.5,4.7;1,0.5;next;Next]';
	end
	return 'size[12,5.0]'..
		'button_exit[4.0,0;2,0.5;quit;Exit]'..
		'button[9.5,0;2,0.5;back_to_plotlist;Back to plotlist]'..
		-- the back button needs to know which village we are in
		'field[20,20;0.1,0.1;village_id;VillageID;'..minetest.formspec_escape( village_id ).."]"..
		-- when a mob is selected we need to provide the plot nr of this plot
		'field[22,22;0.1,0.1;plot_nr;HouseNr;'..house_nr..']'..
		-- show where the plot is located
		'label[0.5,0;Location: '..minetest.formspec_escape( minetest.pos_to_string( bpos ))..']'..
		-- allow to teleport there (if the player has the teleport priv)
		link_teleport..
		-- allow to click through the plots
		prev_next_button..
		'label[0.5,0.5;'..minetest.formspec_escape(str)..']'..
		'label[0.5,4.1;'..add_str..']'..
		'label[0.5,4.6;'..minetest.formspec_escape(door_str)..']'..
		'tablecolumns[' ..
		'text,align=left]'..   -- name and description of inhabitant
		'table[0.1,1.0;11.4,3.0;mg_villages:formspec_list_inhabitants;'..people_str..']';
end


-- print information about a particular mob
mg_villages.inhabitants.print_mob_info = function( village_to_add_data_bpos, house_nr, village_id, bed_nr, pname )

	local bpos = village_to_add_data_bpos[ house_nr ];
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];

	if( not( building_data ) or not( building_data.typ )) then
		building_data = { typ = bpos.btype };
	end

	local this_mob_data = village_to_add_data_bpos[ house_nr ].beds[ bed_nr ];
	local gender = "male";
	if( this_mob_data.gender == "f" ) then
		gender = "female";
	end

	-- identify grandparents and children
	local list_of_children = "";
	local grandfather = -1;
	local grandmother = -1;
	for i,v in ipairs( bpos.beds ) do
		if(     not(v.title) and v.generation==3 and v.gender=="m") then
			grandfather = i;
		elseif( not(v.title) and v.generation==3 and v.gender=="f") then
			grandmother = i;
		elseif( not(v.title) and v.generation==1 ) then
			list_of_children = list_of_children..mg_villages.inhabitants.mob_get_short_name( v )..", ";
		end
	end
	if( list_of_children == "" ) then
		list_of_children = "- none -";
	end
	-- contains commata
	list_of_children = minetest.formspec_escape( string.sub( list_of_children, 1, -3));

	-- show family relationships (father, mother, grandfather, grandmother, children)
	local generation = "adult";
	if(     this_mob_data.generation == 1 ) then
		generation = "child";
		if( not( this_mob_data.title )) then -- no guest, servant, soldier, ...
			generation = generation..
				",Father:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[1] )..
				",Mother:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[2] )..
				",Grandfather:,"..mg_villages.inhabitants.mob_get_short_name(bpos.beds[grandfather])..
				",Grandmother:,"..mg_villages.inhabitants.mob_get_short_name(bpos.beds[grandmother]);
		end
	elseif( this_mob_data.generation == 3 ) then
		generation = "senior";
		if( not( this_mob_data.title )) then -- no guest, servant, soldier, ...
			if( this_mob_data.gender=="m" ) then
				generation = generation..
					",Father of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[1] )..
					",Grandfather of:,"..list_of_children;
			else
				generation = generation..
					",Mother of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[1] )..
					",Grandmother of:,"..list_of_children;
			end
		end
	elseif( this_mob_data.generation == 2 ) then
		if( this_mob_data.gender=="m" and bed_nr == 1) then
			generation = generation..
				",Father:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[grandfather] )..
				",Mother:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[grandmother] )..
				",Father of:,"..list_of_children;
		elseif( bed_nr == 2) then
			-- the grandparents belong to the man's side
			generation = generation..
				",Mother of:,"..list_of_children;
		end
	end
	-- the mob may have a wife or husband
	if(     this_mob_data.generation == 2 and this_mob_data.gender == "m" and bpos.beds[2] and not(bpos.beds[2].title)) then
		generation = generation..
			",Husband of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[2] );
	elseif( this_mob_data.generation == 2 and this_mob_data.gender == "f" and not(this_mob_data.title)) then
		generation = generation..
			",Wife of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[1] );
	elseif( this_mob_data.generation == 3 and this_mob_data.gender == "m" and not(this_mob_data.title)) then
		generation = generation..
			",Husband of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[grandmother] );
	elseif( this_mob_data.generation == 3 and this_mob_data.gender == "f" and not(this_mob_data.title)) then
		generation = generation..
			",Wife of:,"..mg_villages.inhabitants.mob_get_short_name( bpos.beds[grandfather] );
	end

	local lives_in = minetest.formspec_escape( building_data.typ.." on plot "..house_nr.." at "..
			minetest.pos_to_string( handle_schematics.get_pos_in_front_of_house( bpos, 0 )));
	local profession = "- none -";
	if( this_mob_data.title ) then
		profession = this_mob_data.title;
		if( this_mob_data and this_mob_data.title == "guest" ) then
			profession = profession..",,(just visiting)";
		elseif( not( this_mob_data.uniq ) or this_mob_data.uniq<1 ) then
			profession = profession..",,(the only one in this village)";
		else
			profession = profession..",,(one amongst several in this village)";
		end
	end
	local works_at = "-";
	local pref_workspace = "";
	if( this_mob_data.works_at ) then
		local bpos_work = village_to_add_data_bpos[ this_mob_data.works_at ];
		local building_data_work = mg_villages.BUILDINGS[ bpos_work.btype ];
		if( not( building_data_work )) then
			building_data_work = { typ = "unkown" };
		end
		works_at = minetest.formspec_escape( building_data_work.typ.." on plot "..this_mob_data.works_at..
			" at "..minetest.pos_to_string( handle_schematics.get_pos_in_front_of_house( bpos_work,0)));
		-- does this mob have a fixed workspace?
		if( building_data_work.workplace_list and this_mob_data.workplace) then
			if( building_data_work.workplace_list[ this_mob_data.workplace ] ) then
				pref_workspace = ",Preferred workplace:,"..
					minetest.formspec_escape(
						minetest.pos_to_string(
							mg_villages.transform_coordinates(
								building_data_work.workplace_list[ this_mob_data.workplace], bpos_work ))..
						" ["..tostring( this_mob_data.workplace ).."/"..
						tostring( #building_data_work.workplace_list ).."]");
			else
				pref_workspace = ",Preferred workplace:,no specific one";
			end
		end
	end
	local next_to_bed_str = "";
	if( this_mob_data.bnr and building_data.stand_next_to_bed_list[ this_mob_data.bnr ]) then
		next_to_bed_str = ",Gets up from bed to:,"..
			minetest.formspec_escape(
				minetest.pos_to_string(
					mg_villages.transform_coordinates(
						building_data.stand_next_to_bed_list[ this_mob_data.bnr], bpos)));
	end
	local text =
		 "First name:,"..(this_mob_data.first_name or '- ? -')..
		",Middle initial:,"..(this_mob_data.middle_name or '- ? -').."."..
		",Gender:,"..gender..
		",Age:,"..(this_mob_data.age or '- ? -')..
		",Generation:,"..generation..
		",Lives in:,"..lives_in..
		-- TODO: the bed position might be calculated (and be diffrent from this x,y,z here)
		-- TODO: the position next to the bed for getting up can be calculated as well
		",Sleeps in bed at:,"..minetest.formspec_escape( minetest.pos_to_string( this_mob_data )..
					", "..this_mob_data.p2.." ["..(this_mob_data.bnr or "-?-").."/"..
					(#building_data.bed_list or "-?-").."]")..
		-- place next to te bed where the mob can stand
		next_to_bed_str..
		-- position of the mob's mob spawner
		",Has a spawner at:,"..minetest.formspec_escape( minetest.pos_to_string(
					handle_schematics.get_pos_in_front_of_house( bpos, bed_nr)))..
		pref_workspace..
		",Profession:,"..profession..
		",Works at:,"..works_at;

	if( this_mob_data.owns ) then
		text = text..",Is owner of:,"..
			mg_villages.inhabitants.print_plot_list(village_to_add_data_bpos, this_mob_data.owns)..".";
	end

	for k,v in pairs( this_mob_data ) do
		if(   k~="first_name" and k~="middle_name" and k~="gender" and k~="age" and k~="generation"
		  and k~="x" and k~="y" and k~="z" and k~="p2" and k~="bnr"
		  and k~="title" and k~="works_at" and k~="owns" and k~="uniq" and k~="workplace"
		  and k~="typ" ) then -- typ: content_id of bed head node
			-- add those entries that have not been covered yet
			text = text..","..k..":,"..tostring(v);
		end
	end


	local link_teleport = "";
-- TODO: this ought to be a teleport-to-the-mob-button
	if( pname and minetest.check_player_privs( pname, {teleport=true})) then
		-- teleport to the plotmarker and not somewhere where part of the house may stand
		link_teleport = 'button[6.4,0;1,0.5;teleport_to;Visit]'..
			"field[21,21;0.1,0.1;pos2str;Pos;"..minetest.pos_to_string(
				handle_schematics.get_pos_in_front_of_house( bpos, 0 )).."]";
	end

	-- allow to click through the inhabitants
	-- (a second back button doesn't hurt)
	local prev_next_button = "button[8.5,7.2;1,0.5;back_to_houselist;Back]";
	if( bed_nr > 1 ) then
		prev_next_button = prev_next_button..'button[9.5,7.2;1,0.5;prev;Prev]';
	end
	if( bed_nr < #bpos.beds ) then
		prev_next_button = prev_next_button..'button[10.5,7.2;1,0.5;next;Next]';
	end
	return 'size[12,7.5]'..
		'button_exit[4.0,0;2,0.5;quit;Exit]'..
		'button[7.5,0;5,0.5;back_to_houselist;Back to all inhabitants of house]'..
		-- the back button needs to know which village we are in
		'field[20,20;0.1,0.1;village_id;VillageID;'..minetest.formspec_escape( village_id ).."]"..
		-- it also needs to know the plot number we might want to go back to
		'field[22,22;0.1,0.1;plot_nr;HouseNr;'..house_nr..']'..
		-- the prev/next buttons need information about the mob nr
		'field[23,23;0.1,0.1;bed_nr;BedNr;'..bed_nr..']'..
		-- show where the plot is located
		'label[0.5,0;Location: '..minetest.formspec_escape( minetest.pos_to_string( bpos ))..']'..
		-- allow to teleport there (if the player has the teleport priv)
		link_teleport..
		-- add prev/next buttons
		prev_next_button..
		'label[0.5,0.5;'..minetest.formspec_escape("Information about inhabitant nr. "..
				tostring( bed_nr )..": "..
				mg_villages.inhabitants.mob_get_short_name( this_mob_data )..
				" ("..( this_mob_data.title or "- no profession -").."):")..']'..
		'tablecolumns[' ..
		'text,align=left;'..
		'text,align=left]'..   -- name and description of inhabitant
		'table[0.1,1.0;11.4,6.0;mg_villages:formspec_list_one_mob;'..text..']';
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
mg_villages.inhabitants.jobs_in_buildings[ 'chateau'    ] = {'landlord'};
mg_villages.inhabitants.jobs_in_buildings[ 'sawmill'    ] = {'sawmill owner'};
mg_villages.inhabitants.jobs_in_buildings[ 'forrest'    ] = {'lumberjack'}; -- TODO: we don't have forrests yet
mg_villages.inhabitants.jobs_in_buildings['village_square']={'major'};
mg_villages.inhabitants.jobs_in_buildings[ 'townhall'   ] = {'major'};
mg_villages.inhabitants.jobs_in_buildings[ 'horsestable'] = {'horsekeeper'};



-- TODO pit - suitable for traders (they sell clay...)

mg_villages.inhabitants.assign_jobs_to_houses = function( village_to_add_data_bpos )

	local workers_required = {};	-- places that require a specific worker that lives elsewhere
	local found_farm_full  = {};	-- farmers (they like to work on fields and pastures)
	local found_hut        = {};	-- workers best fit for working in other buildings
	local found_house      = {};	-- workers which may either take a random job or work elsewhere
	local found_any_home   = {};    -- farm_full, hut or house (anything with beds in)
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
			table.insert( found_any_home, house_id );

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
		-- distribute sheds, wagons etc. equally on all places with beds
		if(     #found_any_home>0 ) then
			local nr = math.random( #found_any_home );
			village_to_add_data_bpos[ v ].belongs_to = found_any_home[ nr ];
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

	-- even though it should not happen there are still sometimes workers that work on
	-- another plot and wrongly get a random worker job in their house assigned as well;
	-- check for those and eliminiate them
	for house_nr,bpos in ipairs( village_to_add_data_bpos ) do
		if( bpos and bpos.worker and bpos.worker.lives_at and bpos.worker.lives_at ~= house_nr
			and village_to_add_data_bpos[ bpos.worker.lives_at ]
			and village_to_add_data_bpos[ bpos.worker.lives_at ].worker) then
			-- make sure the worker gets no other job or title from his house
			village_to_add_data_bpos[ bpos.worker.lives_at ].worker = nil;
		end
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


-- apply bpos.pos as offset and apply rotation
-- TODO: rotate param2 as well
mg_villages.transform_coordinates = function( pos, bpos )
	if( not( pos ) or not(pos[1]) or not(pos[2]) or not(pos[3])) then
		return nil;
	end
	-- start with the start position as stored in bpos
	local p = {x=bpos.x, y=bpos.y, z=bpos.z};

	local building_data = mg_villages.BUILDINGS[ bpos.btype ];

	-- the height is not affected by rotation
	-- the positions are stored as array
	p.y = p.y + building_data.yoff + pos[2] - 1;

	local rel = {x=pos[1], y=pos[2], z=pos[3]}; -- relative position (usually of entrance)

	-- all values start counting with index 1; we need to start with 0 for the offset
	local sx = bpos.bsizex-1;
	local sz = bpos.bsizez-1;
	rel.x = rel.x-1;
	rel.z = rel.z-1;

	if( bpos.mirror and bpos.btype ) then
		local o = building_data.orients[1];
		if(     (o == 0 or o == 2) and (bpos.brotate==0  or bpos.brotate==2)) then
			rel.z = sz - rel.z;
		elseif( (o == 0 or o == 2) and (bpos.brotate==1  or bpos.brotate==3)) then
			rel.z = sx - rel.z;

		elseif( (o == 1 or o == 3) and (bpos.brotate==0  or bpos.brotate==2)) then
			rel.x = sx - rel.x;
		elseif( (o == 1 or o == 3) and (bpos.brotate==1  or bpos.brotate==3)) then
			rel.x = sz - rel.x;
		end
	end

	if(     bpos.brotate==0 ) then
		p.x = p.x + rel.x;
		p.z = p.z + rel.z;
	elseif( bpos.brotate==1 ) then
		p.x = p.x + rel.z;
		p.z = p.z + sz - rel.x; -- bsizex and bsizez are swapped
	elseif( bpos.brotate==2 ) then
		p.x = p.x + sx - rel.x;
		p.z = p.z + sz - rel.z;
	elseif( bpos.brotate==3 ) then
		p.x = p.x + sx - rel.z; -- bsizex and bsizez are swapped
		p.z = p.z + rel.x;
	end

	-- param2 is rotated the same way as in handle_schematics.generate_building_what_to_place_here_and_how
	if( pos[4] ) then -- param2
		local mirror_x = false;
		local mirror_z = false;
		if( bpos.mirror ) then
			if( building_data.axis and building_data.axis == 1 ) then
				mirror_x = true;
				mirror_z = false;
			-- used for "restore original landscape"
			elseif( building_data.axis and building_data.axis == 3 ) then
				mirror_z = true;
				mirror_x = true;
			else
				mirror_x = false;
				mirror_z = true;
			end
		end
		if(     mirror_x ) then
			p.p2 = handle_schematics.rotation_table[ 'facedir' ][ pos[4]+1 ][ bpos.brotate+1 ][ 2 ];
		elseif( mirror_z ) then
			p.p2 = handle_schematics.rotation_table[ 'facedir' ][ pos[4]+1 ][ bpos.brotate+1 ][ 3 ];
		else
			p.p2 = handle_schematics.rotation_table[ 'facedir' ][ pos[4]+1 ][ bpos.brotate+1 ][ 1 ];
		end
	end

	return p;
end


mg_villages.get_plot_and_building_data = function( village_id, plot_nr )
	if(  not( mg_villages.all_villages[ village_id ])
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ] )) then
		return;
	end
	local bpos = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ];
	if( not( bpos ) or not( bpos.btype ) or not( mg_villages.BUILDINGS[ bpos.btype ])) then
		return;
	end
	return { bpos = bpos, building_data = mg_villages.BUILDINGS[ bpos.btype ]};
end


mg_villages.get_entrance_list = function( village_id, plot_nr )
	local res = mg_villages.get_plot_and_building_data( village_id, plot_nr );
	if( not( res ) or not( res.building_data ) or not(res.building_data.all_entrances )) then
		return {};
	end
	local entrance_list = {};
	for i,e in ipairs( res.building_data.all_entrances ) do
		table.insert( entrance_list, mg_villages.transform_coordinates( e, res.bpos ));
	end
	return entrance_list;
end


mg_villages.get_path_from_bed_to_outside = function( village_id, plot_nr, bed_nr, door_nr )
	local res = mg_villages.get_plot_and_building_data( village_id, plot_nr );
	if( not( res ) or not( res.building_data ) or not(res.building_data.short_file_name)
	  or not( mg_villages.path_info[ res.building_data.short_file_name ] )
	  or not( mg_villages.path_info[ res.building_data.short_file_name ][ door_nr ])
	  or not( mg_villages.path_info[ res.building_data.short_file_name ][ door_nr ][ bed_nr ])) then
		return;
	end
	local path = {};
	-- get the path from the bed to front door door_nr
	for i,p in ipairs( mg_villages.path_info[ res.building_data.short_file_name ][ door_nr ][ bed_nr ]) do
		table.insert( path, mg_villages.transform_coordinates( p, res.bpos ));
	end
	local rest_path_id = #mg_villages.path_info[ res.building_data.short_file_name ][ door_nr ];
	-- the last entrance is the common path for all beds from the front door door_nr to the outside
	if( rest_path_id == bed_nr ) then
		return path;
	end
	-- add the path from the front door to the front of the building
	for i,p in ipairs( mg_villages.path_info[ res.building_data.short_file_name ][ door_nr ][ rest_path_id ]) do
		table.insert( path, mg_villages.transform_coordinates( p, res.bpos ));
	end
	return path;
end


-- door_nr ought to be 1 in most cases (unless the mob is standing in front of another door)
mg_villages.get_path_from_outside_to_bed = function( village_id, plot_nr, bed_nr, door_nr )
	local path = mg_villages.get_path_from_bed_to_outside( village_id, plot_nr, bed_nr, door_nr );
	if( not( path )) then
		return path;
	end
	local reverse_path = {};
	for i = #path, 1, -1 do
		table.insert( reverse_path, path[i]);
	end
	return reverse_path;
end


-- get the information mg_villages has about a mob (useful for mg_villages:mob_spawner)
mg_villages.inhabitants.get_mob_data = function( village_id, plot_nr, bed_nr )
	if( not( village_id ) or not( plot_nr ) or not( bed_nr )
	  or not( mg_villages.all_villages[ village_id ] )
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ])
	  or not( mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ].beds )) then
		return;
	end
--[[
	-- TODO: mark entrances for manual inspection
	for i,p in ipairs( mg_villages.get_entrance_list( village_id, plot_nr )) do
		local bpos = mg_villages.all_villages[ village_id ].to_add_data.bpos[ plot_nr ];
		minetest.chat_send_player("singleplayer","door: "..minetest.pos_to_string( p )..
			" pos: "..minetest.pos_to_string( bpos )..
			" o: "..tostring( bpos.o ).." r: "..tostring( bpos.brotate ).." m: "..tostring( bpos.mirror));
		minetest.set_node( p, {name="wool:cyan",param2=0});
	end
--]]
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


-- calculate which mob works and lives where
mg_villages.inhabitants.assign_mobs = function( village, village_id, force_repopulate )
	-- make sure mobs get assigned only once (no point in doing this every time
	-- when part of a village spawned)
	if( village.mob_data_version and not(force_repopulate)) then
		return;
	end

	-- if force_repopulate is true: recalculate road network, discard all worker- and
	-- bed data and create new mobs
	if( force_repopulate ) then
		for plot_nr,bpos in ipairs(village.to_add_data.bpos) do
			-- delete information about who works here
			bpos.worker = nil;
			-- delete information about who lives here
			bpos.beds = nil;
			-- delete information about the interconnection of the road network
			bpos.xdir = nil;
			bpos.parent_road_plot = nil;
		end
	end

	-- analyze the road network
	mg_villages.get_road_list( village_id, true );

	-- some types of buildings require special workers
	village.to_add_data.bpos = mg_villages.inhabitants.assign_jobs_to_houses( village.to_add_data.bpos );

	-- for each building in the village
	for plot_nr,bpos in ipairs(village.to_add_data.bpos) do

		-- each bed gets a mob assigned
		bpos = mg_villages.inhabitants.assign_mobs_to_beds( bpos, plot_nr, village.to_add_data.bpos, village );
	end
	-- later versions may become incompatible
	village.mob_data_version = 1;
end


-- set metadata and/or infotexts for beds and workplace markers
mg_villages.inhabitants.prepare_metadata = function( village, village_id, minp, maxp )
	local bpos_list = village.to_add_data.bpos;
	for plot_nr,bpos in ipairs(bpos_list) do
		-- put labels on beds
		if( bpos.beds ) then
			for bed_nr, bed in ipairs( bpos.beds ) do
				-- if the bed is located withhin the given area OR no area is given
				-- (for manual calls later on, outside of mapgen)
				if( not( minp ) or not( maxp ) or (  minp.x <= bed.x and maxp.x >= bed.x
				    and minp.y <= bed.y and maxp.y >= bed.y
				    and minp.z <= bed.z and maxp.z >= bed.z)) then
					local meta = minetest.get_meta( bed );
					meta:set_string('infotext', 'Bed of '..
						mg_villages.inhabitants.mob_get_full_name( bed, bpos.beds[1] ));
					meta:set_string('village_id', village_id );
					meta:set_int(   'plot_nr',    plot_nr);
					meta:set_int(   'bed_nr',     bed_nr);
				end
				-- beds from the beds mod tend to have their foot as the selection box;
				-- we need to set the infotext for the bed's foot as well
				local p_foot = {x=bed.x,y=bed.y,z=bed.z};
				if(     bed.p2==0 ) then p_foot.z = p_foot.z-1;
				elseif( bed.p2==1 ) then p_foot.x = p_foot.x-1;
				elseif( bed.p2==2 ) then p_foot.z = p_foot.z+1;
				elseif( bed.p2==3 ) then p_foot.x = p_foot.x+1;
				end
				if( not( minp ) or not( maxp )
				  or (  minp.x <= p_foot.x and maxp.x >= p_foot.x
				    and minp.y <= p_foot.y and maxp.y >= p_foot.y
				    and minp.z <= p_foot.z and maxp.z >= p_foot.z)) then
					local meta = minetest.get_meta( p_foot );
					-- setting the infotext is enough here
					meta:set_string('infotext', 'Bed of '..
						mg_villages.inhabitants.mob_get_full_name( bed, bpos.beds[1] ));
				end
				-- there might be a workplace belonging to the bed/mob
				if( bed.works_at and bed.workplace
				  and bed.workplace>0
				  and bpos_list[ bed.works_at ]
				  and bpos_list[ bed.works_at ].btype
				  and mg_villages.BUILDINGS[ bpos_list[ bed.works_at ].btype ]
				  and mg_villages.BUILDINGS[ bpos_list[ bed.works_at ].btype ].workplace_list
				  and #mg_villages.BUILDINGS[ bpos_list[ bed.works_at ].btype ].workplace_list >= bed.workplace ) then
					local p = mg_villages.BUILDINGS[ bpos_list[ bed.works_at ].btype ].workplace_list[ bed.workplace ];
					local bpos_work = bpos_list[ bed.works_at ];
					local p_akt = mg_villages.transform_coordinates( {p[1],p[2],p[3]}, bpos_work);
					if( not( minp ) or not( maxp )
					  or (  minp.x <= p_akt.x and maxp.x >= bed.x
					    and minp.y <= p_akt.y and maxp.y >= p_akt.y
					    and minp.z <= p_akt.z and maxp.z >= p_akt.z)) then
						local meta = minetest.get_meta( p_akt );
						meta:set_string('infotext', 'Workplace of '..
							mg_villages.inhabitants.mob_get_full_name( bed, bed ));
						meta:set_string('village_id', village_id );
						-- data about the workplace itshelf
						meta:set_int(   'plot_nr',      bed.works_at );
						meta:set_int(   'workplace_nr', bed.workplace );
						-- the data of the *mob* might be more relevant for spawning
						meta:set_int(   'lives_at',     plot_nr );
						meta:set_int(   'bed_nr',       bed_nr );
					end
				end
			end
		end
	end
end


-- determine positions of front doors from stored pathinfo data and building_data.front_door_list
mg_villages.inhabitants.get_front_doors = function( bpos )
	if( not( bpos ) or not( bpos.btype ) or not( mg_villages.BUILDINGS[ bpos.btype ] )) then
		return {};
	end
	local building_data = mg_villages.BUILDINGS[ bpos.btype ];
	if( not( building_data ) or not( building_data.front_door_list )) then
		return {};
	end
	local door_list = {};
	for i,d in ipairs( building_data.front_door_list ) do
		door_list[i] = mg_villages.transform_coordinates( {d[1],d[2],d[3]}, bpos);
	end
	return door_list;
end


-- spawn mobs in villages
mg_villages.inhabitants.part_of_village_spawned = function( village, minp, maxp, data, param2_data, a, cid )
	-- for each building in the village
	for plot_nr,bpos in ipairs(village.to_add_data.bpos) do
		-- actually spawn the mobs
		local village_id = tostring( village.vx )..':'..tostring( village.vz );
		mg_villages.inhabitants.spawn_mobs_for_one_house( bpos, minp, maxp, village_id, plot_nr );
	end
end


--[[ deprecated
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
					minetest.chat_send_player( name, mg_villages.inhabitants.print_house_info( v.to_add_data.bpos, house_nr, v.nr, name ));
				end
				return;
			end
		end
		-- no village found
		minetest.chat_send_player( name, "There is no village with the number "..tostring( param ).." (yet?).");
	end
});

--]]
