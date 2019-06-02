--  scm="bla"		Name of the file that holds the buildings' schematic. Supported types: .we and .mts (omit the extension!)
--  sizex, sizez, ysize: obsolete
--  yoff=0		how deep is the building burried?
--  pervillage=1	Never generate more than this amount of this building and this type (if set) of building per village.
--  axis=1		Building needs to be mirrored along the x-axis instead of the z-axis because it is initially rotated
--  inh=2  		maximum amount of inhabitants the building may hold (usually amount of beds present)
--			if set to i.e. -1, this indicates that a mob is WORKING, but not LIVING here 
--   we_origin		Only needed for very old .we files (savefile format version 3) which do not start at 0,0,0 but have an offset.
--  price               Stack that has to be paid in order to become owner of the plot the building stands on and the building;
--                      overrides mg_villages.prices[ building_typ ].
--  guests		Negative value, i.e. -2: 2 of the beds will belong to the family working here; the rest will be guests.
--                      For building type "chateau", guest names the number of servants/housemaids instead of guests.

-- Intllib
local S = mg_villages.intllib

mg_villages.all_buildings_list = {}

local buildings = {

-- the houses the mod came with
	{yoff= 0, scm="house_1_0",                          typ='house',    weight={nore=1,   single=2   }, inh=4},
	{yoff= 0, scm="wheat_field",                        typ='field',    weight={nore=1   }, inh=-1},
	{yoff= 0, scm="cotton_field",                       typ='field',    weight={nore=1   }, inh=-1},
	{yoff= 1, scm="lamp", no_rotate=true,               typ='lamp',     weight={nore=1/5 }},
	{yoff=-5, scm="well", no_rotate=true, pervillage=1, typ='well',     weight={nore=1   }},
	{yoff= 0, scm="fountain", pervillage=3,             typ='fountain', weight={nore=1/4 },             axis=1},
	{yoff= 0, scm="small_house_1_0",                    typ='house',    weight={nore=1,   single=2   }, inh=2},
	{yoff= 0, scm="house_with_garden_1_0",              typ='house',    weight={nore=1,   single=2   }, inh=3},
	{yoff= 0, scm="church_1_0",           pervillage=1, typ='church',   weight={nore=1   },             inh=-1},
	{yoff= 0, scm="tower_1_0",                          typ='tower',    weight={nore=1/7, single=1   }, inh=-1},
	{yoff= 0, scm="forge_1_0",            pervillage=2, typ='forge',    weight={nore=1,   single=1/3 }, inh=-1},
	{yoff= 0, scm="library_1_0",          pervillage=2, typ='library',  weight={nore=1               }, inh=-1},
	{yoff= 0, scm="inn_1_0",              pervillage=4, typ='inn',      weight={nore=1/2, single=1/3 }, inh=-1, guests=-2}, -- has room for 4 guests
	{yoff= 0, scm="pub_1_0",              pervillage=2, typ='tavern',   weight={nore=1/3, single=1/3 }, inh=-1},


-- log cabins by Sokomine (requiring cottages, glasspanes)
	{yoff= 0, scm="logcabin1",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin2",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin3",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=3, typ='hut'},
	{yoff= 0, scm="logcabin4",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=3, typ='hut'},
	{yoff= 0, scm="logcabin5",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin6",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin7",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin8",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=2, typ='hut'},
	{yoff= 0, scm="logcabin9",    orients={1}, weight={logcabin=1,   single=1}, axis=1, inh=1, typ='hut'},
	{yoff= 0, scm="logcabin10",   orients={2}, weight={logcabin=1,   single=1},         inh=3, typ='hut'},
	{yoff= 0, scm="logcabin11",   orients={1}, weight={logcabin=1,   single=1},         inh=6, typ='hut'},
	{yoff= 0, scm="logcabinpub1", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=1, guests=-2}, -- +5 guests
	{yoff= 0, scm="logcabinpub2", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=2, guests=-3}, -- +8 guests
	{yoff= 0, scm="logcabinpub3", orients={1}, weight={logcabin=1/6, single=1}, pervillage=1, typ='tavern', axis=1, inh=2, guests=-4}, -- +12 guest

-- grass huts (requiring cottages, dryplants, cavestuff/undergrowth, plantlife)
	{yoff= 0, scm="grasshut1_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut2_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='townhall'}, -- community hut for meetings
	{yoff= 0, scm="grasshut3_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut4_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut5_1_90", weight={grasshut=1, single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshut6_1_90", weight={            single=1}, nomirror=1, typ='hut'},
	{yoff= 0, scm="grasshutcenter_1_90", pervillage=1, weight={grasshut=2}, nomirror=1, typ = 'tavern'}, -- open meeting place

-- for the buildings below, sizex, sizez and ysize are read from the file directly;

-- schematics from Sokomines villages mod (requires cottages)
	{scm="church_1",        yoff= 0, orients={0}, farming_plus=0, avoid='', typ='church',    weight={medieval=4            }, pervillage=1,   inh=-1},    
--	{scm="church_2_twoelk", yoff= 0, orients={0}, farming_plus=0, avoid='', typ='church',    weight={medieval=4}, pervillage=1},    
	{scm="forge_1",         yoff= 0, orients={0}, farming_plus=0, avoid='', typ='forge',     weight={medieval=2,   single=1/2}, pervillage=1,   inh=-1},
	{scm="mill_1",          yoff= 0, orients={0}, farming_plus=0, avoid='', typ='mill',      weight={medieval=2            }, pervillage=1,   inh=-1},
	{scm="watermill_1",     yoff=-3, orients={1}, farming_plus=0, avoid='', typ='mill',      weight={medieval=2            }, pervillage=1,   inh=-2},
	{scm="hut_1",           yoff= 0, orients={0}, farming_plus=0, avoid='', typ='hut',       weight={medieval=1,   single=1  },                 inh=1},
	{scm="hut_2",           yoff= 0, orients={0}, farming_plus=0, avoid='', typ='hut',       weight={medieval=1,   single=1  },                 inh=2},
	{scm="farm_full_1",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=2},
	{scm="farm_full_2",     yoff= 0, orients={1}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_3",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_4",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=8},
	{scm="farm_full_5",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_full_6",     yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  },               inh=5},
	{scm="farm_tiny_1",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=2},
	{scm="farm_tiny_2",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=6},
	{scm="farm_tiny_3",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_4",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_5",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_6",     yoff= 0, orients={0}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=4},
	{scm="farm_tiny_7",     yoff= 0, orients={3}, farming_plus=1, avoid='', typ='farm_tiny', weight={medieval=1,   single=1  },                 inh=7},
	{scm="taverne_1",       yoff= 0, orients={0}, farming_plus=1, avoid='', typ='tavern',    weight={medieval=1/2, single=1  }, pervillage=1, inh=6, guests=-3},  -- 19 beds: 10 guest, 3 worker, 6 family
	{scm="taverne_2",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=2},  -- no guests
	{scm="taverne_3",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=2},  -- no guests
	{scm="taverne_4",       yoff= 0, orients={0}, farming_plus=0, avoid='', typ='tavern',    weight={medieval=1/2, single=1/3}, pervillage=1, inh=1},  -- no guests

	{scm="well_1",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_2",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_3",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_4",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_5",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_6",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_7",          yoff= -1, orients={0}, farming_plus=0, avoid='well', typ='well', weight={medieval=1/12, single=1/2}, pervillage=4},
	{scm="well_8",          yoff= 0, orients={0}, farming_plus=0, avoid='well', typ='well',  weight={medieval=1/12, single=1/2}, pervillage=4},

	{scm="allmende_3_90",   yoff=-2, orients={0}, farming_plus=0, avoid='', typ='allmende',  weight={medieval=3,taoki=3,nore=3,logcabin=1,grasshut=1}, pervillage=1},

	{scm="tree_place_1",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_2",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_3",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_4",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_5",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_6",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_7",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_8",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_9",    yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},
	{scm="tree_place_10",   yoff= 1, orients={0}, farming_plus=0, avoid='', typ='village_square', weight={medieval=1/12}, pervillage=1},

	{scm="wagon_1",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_2",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_3",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_4",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_5",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_6",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_7",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_8",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_9",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_10",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_11",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},
	{scm="wagon_12",        yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='wagon',  weight={medieval=1/12,tent=1/3}, axis=1},

	{scm="bench_1",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_2",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_3",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},
	{scm="bench_4",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='bench',  weight={medieval=1/12}, nomirror=1},

	{scm="shed_1",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_2",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_3",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_5",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_6",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_7",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_8",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_9",          yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_10",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_11",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='shed',  weight={medieval=1/10}},
	{scm="shed_12",         yoff= 0, orients={0,1,2}, farming_plus=0, avoid='', typ='stable',  weight={medieval=1/10}},

	{scm="weide_1",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_2",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_3",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_4",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_5",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},
	{scm="weide_6",         yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='pasture', typ='pasture',  weight={medieval=1/6}, pervillage=8},

	{scm="field_1",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_2",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_3",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},
	{scm="field_4",         yoff=-2, orients={0,1,2,3}, farming_plus=0, avoid='field',   typ='field',    weight={medieval=1/6}, pervillage=8},

	-- hut and hills for charachoal burners; perhaps they could live together with lumberjacks?
	{scm="charachoal_hut",  yoff= 0, orients={0,1,2},   farming_plus=0, avoid='', typ='hut',  weight={charachoal=1, single=5}, inh=2, nomirror=1},
	{scm="charachoal_hill", yoff= 0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='hut',  weight={charachoal=2          }, inh=-1, nomirror=1},

	-- lumberjacks; they require the cottages mod
	{scm="lumberjack_1",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_2",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=4},
	{scm="lumberjack_3",        yoff= 1, orients={1,2,3}, avoid='', typ='lumberjack', weight={lumberjack=1, single=3},         inh=3},
	{scm="lumberjack_4",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=4},
	{scm="lumberjack_5",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=9},
	{scm="lumberjack_6",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_7",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_8",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=9},
	{scm="lumberjack_9",        yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=5},
	{scm="lumberjack_10",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_11",       yoff= 0, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_12",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_13",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=3},
	{scm="lumberjack_14",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_15",       yoff= 1, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_16",       yoff= 0, orients={1},     avoid='', typ='lumberjack', weight={lumberjack=1, single=3}, axis=1, inh=2},
	{scm="lumberjack_school",   yoff= 1, orients={1},     avoid='', typ='school',     weight={lumberjack=2          }, axis=1, inh=1},
	{scm="lumberjack_stable",   yoff= 0, orients={3},     avoid='', typ='horsestable',     weight={lumberjack=1, single=3}, axis=1, inh=-1},
	{scm="lumberjack_pub_1",    yoff= 1, orients={1},     avoid='', typ='tavern',     weight={lumberjack=3, single=1}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_church_1", yoff= 1, orients={1},     avoid='', typ='church',     weight={lumberjack=3}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_hotel_1",  yoff= 1, orients={0},     avoid='', typ='inn',        weight={lumberjack=1, single=1}, axis=1,               inh=16, guests=-1}, -- all but one of the 16 are guests
	{scm="lumberjack_shop_1",   yoff= 1, orients={1},     avoid='', typ='shop',       weight={lumberjack=1}, pervillage=1, axis=1, inh=-1},
	{scm="lumberjack_sawmill_1",yoff=-7, orients={1},     avoid='', typ='sawmill',    weight={lumberjack=2, single=1}, pervillage=1, axis=1, inh=-1},


--	{scm="cow_trader_1",    yoff= 0, orients={4}, avoid='', typ='trader',     weight={lumberjack=1}},

	-- clay traders depend on cottages as well
	{scm="trader_clay_1",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=1}, -- poor guy who has to live in that small thing
	{scm="trader_clay_2",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=1}, -- not that he'll live very comftable there...
	{scm="trader_clay_3",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3},         inh=2},
	{scm="trader_clay_4",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3},         inh=2},
	{scm="trader_clay_5",   yoff= 1, orients={1}, avoid='', typ='trader',     weight={claytrader=3, single=3}, axis=1, inh=2},

	{scm="clay_pit_1",      yoff=-3, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_2",      yoff=-1, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_3",      yoff=-6, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_4",      yoff= 0, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},
	{scm="clay_pit_5",      yoff= 1, orients={0,1,2,3}, avoid='', typ='pit',        weight={claytrader=1}},


   -- Houses from Taokis Structure I/O Mod (see https://forum.minetest.net/viewtopic.php?id=5524)
	{scm="default_town_farm",          yoff= -1, orients={1}, farming_plus=0, avoid='',     typ='field',  weight={taoki=1,   single=1}, axis=1},
	{scm="default_town_house_large_1", yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/4, single=1}, axis=1, inh=10},
	{scm="default_town_house_large_2", yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/4, single=1}, axis=1, inh=8},
	{scm="default_town_house_medium",  yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/2, single=1}, axis=1, inh=6},
	{scm="default_town_house_small",   yoff= -4, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=4},
	{scm="default_town_house_tiny_1",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=3},
	{scm="default_town_house_tiny_2",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=3},
	{scm="default_town_house_tiny_3",  yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1,   single=1},   axis=1, inh=2},
	{scm="default_town_park",          yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='park',   weight={taoki=1            },   axis=1},
	{scm="default_town_tower",         yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='tower',  weight={taoki=1/6, single=1}, axis=1, inh=-1},
	{scm="default_town_well",          yoff= -6, orients={1}, farming_plus=0, avoid='',     typ='well',   weight={taoki=1/4          }, axis=1},
	{scm="default_town_fountain",      yoff=  1, orients={1}, farming_plus=0, avoid='',     typ='fountain',weight={taoki=1/4          }, axis=1},
	-- the hotel seems to be only the middle section of the building; it's build for another spawning algorithm
--	{scm="default_town_hotel",         yoff= -1, orients={1}, farming_plus=0, avoid='',     typ='house',  weight={taoki=1/5}},

	{scm="tent_tiny_1",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=1},
	{scm="tent_tiny_2",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=1},
	{scm="tent_big_1",                 yoff=0, orients={1}, farming_plus=0, avoid='',        typ='shop',    weight={tent=1,   single=1}},           -- no sleeping place
	{scm="tent_big_2",                 yoff=0, orients={3}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1,   single=1},   inh=2},
	{scm="tent_medium_1",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_2",              yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shed',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_3",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_medium_4",              yoff=0, orients={1}, farming_plus=0, avoid='',        typ='tent',    weight={tent=1/2, single=1}, inh=3},
	{scm="tent_open_1",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='pub',    weight={tent=1/5}},
	{scm="tent_open_2",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shed',    weight={tent=1/5}},
	{scm="tent_open_3",                yoff=0, orients={3}, farming_plus=0, avoid='',        typ='shop',    weight={tent=1/5}},
	{scm="tent_open_big_1",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='pub',     weight={tent=1/5}},
	{scm="tent_open_big_2",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='church',  weight={tent=1/5}},
	{scm="tent_open_big_3",            yoff=0, orients={3}, farming_plus=0, avoid='',        typ='townhall',    weight={tent=5}, pervillage=1},

	{scm="hochsitz_1",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_2",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_3",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},
	{scm="hochsitz_4",                 yoff=0, orients={0,1,2,3}, farming_plus=0, avoid='', typ='tower',    weight={tower=1, single=1/3}, nomirror=1},

	{scm="chateau_without_garden",     yoff=-1,orients={0,1,2,3}, farming_plus=0, avoid='', typ='chateau',  weight={chateau=1,single=8}, pervillage=1, inh=8, guests=-6}, -- 6 family members of the landlord's family; rest are servants

	{scm="baking_house_1",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_2",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_3",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},
	{scm="baking_house_4",             yoff=0, orients={0}, farming_plus=0, avoid='', typ='bakery', weight={medieval=1/4}, pervillage=1, inh=-1},

	{scm="empty_1", yoff=0, typ='empty', inh=0, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_2", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_3", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_4", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},
	{scm="empty_5", yoff=0, typ='empty', inh=1, pervillage=4,
			weight={nore=1,taoki=1,medieval=1,charachoal=1,lumberjack=1,claytrader=1,logcabin=1,canadian=1,grasshut=1,tent=1}},

	{scm="house_medieval_fancy_1_90", yoff= 0, orients={0}, farming_plus=0, avoid='', typ='farm_full', weight={medieval=1/4, single=1  }, inh=6},
	{scm="cow_shed_1_270",            yoff= 0, orients={0}, farming_plus=0, avoid='', typ='stable',      weight={medieval=1/4, single=1  }, inh=-1},
	{scm="shed_with_forge_v2_1_0",    yoff= 0, orients={0}, farming_plus=0, avoid='', typ='forge',     weight={medieval=1,single=1/2}, inh=1},

	{scm="empty_16x32_2_90", typ='empty', inh=1, pervillage=4,
			weight={nore=2,taoki=2,medieval=2,charachoal=2,lumberjack=2,claytrader=2,logcabin=2,canadian=2,grasshut=2,tent=2}},
	{scm="empty_32x32_2_90", typ='empty', inh=1, pervillage=4,
			weight={nore=2,taoki=2,medieval=2,charachoal=2,lumberjack=2,claytrader=2,logcabin=2,canadian=2,grasshut=2,tent=2}},

	-- some new grasshut variants
	{scm="grasshut7_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut8_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut9_1_90",      weight={grasshut=1,   single=1}, nomirror=1, typ='hut'},
	{scm="grasshut_pub_1_90",   weight={grasshut=1/4, single=1}, nomirror=1, typ='pub'},
	{scm="grasshut_hotel_1_90", weight={grasshut=1/4, single=1}, nomirror=1, typ='inn'},
	{scm="grasshut_shop_1_90",  weight={grasshut=1,   single=1}, nomirror=1, typ='shop'},
	{scm="grasshutwell_8_90",   weight={grasshut=1,   single=1}, nomirror=1, typ='well'},
}


-- read the data files and fill in information like size and nodes that need on_construct to be called after placing;
-- skip buildings that cannot be used due to missing mods
mg_villages.add_building = function( building_data )

	local file_name = building_data.mts_path .. building_data.scm;
	-- a building will only be used if it is used by at least one supported village type (=mods required for that village type are installed)
	local is_used = false;
	for typ,weight in pairs( building_data.weight ) do
		if( typ and weight and typ ~= 'single' and mg_villages.village_type_data[ typ ] and mg_villages.village_type_data[ typ ].supported ) then
			is_used = true;
		end
		-- add the building to the menu list for the build chest ("single" would be too many houses)
		-- the empty plots are added to each village and of no intrest here
		if( build_chest and build_chest.add_entry and typ and typ ~= 'single' and (not( building_data.typ ) or building_data.typ ~= 'empty')) then
			build_chest.add_entry( {'main','mg_villages', typ, building_data.scm, file_name });
		end
	end
	-- buildings as such may have a type as well
	if( build_chest and build_chest.add_entry and building_data.typ ) then
		build_chest.add_entry( {'main','mg_villages', building_data.typ, building_data.scm, file_name });
	end


	if( not( is_used )) then
		-- do nothing; skip this file
		mg_villages.print(mg_villages.DEBUG_LEVEL_INFO, S("SKIPPING").." "..tostring( building_data.scm )..' '..S("due to village type not supported."));
		-- building cannot be used
		building_data.not_available = 1;
		return false;
	end


	-- read the size of the building;
	-- convert to .mts for later usage if necessary
	-- true: no entry in the build_chest (we did that manually already)
	local res  = handle_schematics.analyze_file( file_name, building_data.we_origin, building_data.mts_path .. building_data.scm, building_data, true );

	if( not( res )) then
		mg_villages.print(mg_villages.DEBUG_LEVEL_WARNING, S("SKIPPING").." "..tostring( building_data.scm ).." "..S("due to import failure."));
		building_data.not_available = 1;
		return false;
	-- provided the file could be analyzed successfully (now covers both .mts and .we files)
	elseif( res and res.size and res.size.x ) then

		building_data = res;
		-- identify front doors, calculate paths from beds/workplaces to front of house
		building_data = mg_villages.analyze_building_for_mobs( building_data, file_name, mg_villages.path_info);

	-- missing data regarding building size - do not use this building for anything
	elseif( not( building_data.sizex )    or not( building_data.sizez )
		or   building_data.sizex == 0 or      building_data.sizez==0) then

		-- no village will use it
		mg_villages.print( mg_villages.DEBUG_LEVEL_INFO, S("No schematic found for building \'@1\'. Will not use that building.", tostring( building_data.scm )));
		building_data.weight = {};
		building_data.not_available = 1;
		return false;

	else
		-- the file has to be handled by worldedit; it is no .mts file
		building_data.is_mts = 0;
	end


	if( not( building_data.weight ) or type( building_data.weight ) ~= 'table' ) then
		mg_villages.print( mg_villages.DEBUG_LEVEL_WARNING, S("SKIPPING").." "..tostring( building_data.scm ).." "..S("due to missing weight information."));
		building_data.not_available = 1;
		return false;
	end


	-- handle duplicates; make sure buildings always get the same number;
	-- check if the building has been used in previous runs and got an ID there

	-- create a not very unique, but for this case sufficient "id";
	-- (buildings with the same size and name are considered to be drop-in-replacements
	local building_id = building_data.sizex..'x'..building_data.sizez..'_'..building_data.scm;
	-- if the building is new, it will get the next free id
	local building_nr = #mg_villages.all_buildings_list + 1;
	for i,v in ipairs( mg_villages.all_buildings_list ) do
		if( v==building_id ) then
			-- we found the building
			building_nr = i;
		end
	end

	-- if it is a new building, then save the list
	if( building_nr == #mg_villages.all_buildings_list+1 ) then
		mg_villages.all_buildings_list[ building_nr ] = building_id;
		-- save information about previously imported buildings
		save_restore.save_data( 'mg_villages_all_buildings_list.data', mg_villages.all_buildings_list );
	end

	-- determine the internal number for the building; this number is used as a key and can be found in the mg_all_villages.data file
	if( not( mg_villages.BUILDINGS )) then
		mg_villages.BUILDINGS = {};
	end
	-- actually store the building data
	mg_villages.BUILDINGS[ building_nr ] = minetest.deserialize( minetest.serialize( building_data ));


	-- create lists for all village types containing the buildings which may be used for that village
	for typ, data in pairs( mg_villages.village_type_data ) do
		local total_weight = 0;
		if( not( data.building_list ) or not( data.max_weight_list )) then
			data.building_list   = {};
			data.max_weight_list = {};
		elseif( #data.max_weight_list > 0 ) then
			-- get the last entry - that one will determine the current total_weight
			total_weight = data.max_weight_list[ #data.max_weight_list ];
		end

		if( building_data.weight[ typ ] and building_data.weight[ typ ] > 0 ) then
			local index = #data.building_list+1;
			data.building_list[   index ] = building_nr; 
			data.max_weight_list[ index ] = total_weight + building_data.weight[ typ ];
		end
	end

	-- print it for debugging usage
 	--print( building_data.scm .. ': '..tostring(building_data.sizex)..' x '..tostring(building_data.sizez)..' x '..tostring(building_data.ysize)..' h');
	return true;
end


-- this list contains some information about previously imported buildings so that they will get the same id
mg_villages.all_buildings_list =  save_restore.restore_data( 'mg_villages_all_buildings_list.data' );

-- information about beds, positions to stand next to the beds, paths to the doors, and doors
--mg_villages.path_info = {};
--mg_villages.path_info =  save_restore.restore_data( 'mg_villages_path_info.data' );

mg_villages.file_name_offset = string.len( minetest.get_modpath( "mg_villages" ))-11+1;

-- import all the buildings
mg_villages.BUILDINGS = {};
local mts_path = mg_villages.modpath.."/schems/";
-- determine the size of the given houses and other necessary values
for i,v in ipairs( buildings ) do
	v.mts_path = mts_path;
	mg_villages.add_building( v, i );
end
buildings = nil;

-- roads are built in a diffrent way
mg_villages.BUILDINGS["road"] = {yoff = 0, ysize = 2, scm = {}}

-- save the path data; wait a bit so that all mods may have registered their buildings
-- Note: uncomment the following line if you have added a larger amount of new buildings; then, after
--       WORLDNAME/mg_villages_path_info.data has been written, copy that file over to your
--       mods/mg_villages/ folder and replace the old one. Add
--           mg_villages.path_info = ..
--       at the start of the table so that a dofile can execute it.
--minetest.after( 10, save_restore.save_data, 'mg_villages_path_info.data', mg_villages.path_info );
