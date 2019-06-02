-- Intllib
local S = mg_villages.intllib

namegen = {};

namegen.prefixes = {'ac','ast','lang','pen','shep','ship'}
namegen.suffixes = {'beck','ey','ay','bury','burgh','brough','by','by','caster',
	'cester','cum','den','don','field','firth','ford','ham','ham','ham',
	'hope','ing','kirk','hill','law','leigh','mouth','ness','pool','shaw',
	'stead','ster','tun','ton','ton','ton','ton','wold','worth','worthy',
	'ville','river','forrest','lake'}

-- people/environmental features





namegen.silben = { 'a', 'an', 'ab', 'ac', 'am', 
	'be', 'ba', 'bi', 'bl', 'bm', 'bn', 'bo', 'br', 'bst', 'bu', 
	'ca', 'ce', 'ch', 'ci', 'ck', 'cl', 'cm', 'cn', 'co', 'cv', 
	'da', 'de', 'df', 'di', 'dl', 'dm', 'dn', 'do', 'dr', 'ds', 'dt', 'du', 'dv',
	'do','ren','nav','ben','ada','min','org','san','pa','re','ne','en','er','ich',
	'the','and','tha','ent','ing','ion','tio','for','nde',
	'has','nce','edt','tis','oft','sth','mem',
	'ich','ein','und','der','nde','sch','die','den','end','cht',
	'the','and','tha','ent','ing','ion','for','de',
	'has','ce','ed','is','ft','sth','mem',
	'ch','ei','un','der','ie','den','end',
	'do','ren','nav','ben','ada','min','org','san','pa','re','ne','en','er','ich',
	'ta','bek','nik','le','lan','nem',
	'bal','cir','da','en','fan','fir','fern','fa','oak','nut','gen','ga','hu','hi','hal',
	'in','ig','ir','im','ja','je','jo','kla','kon','ker','log','lag','leg','lil',
	'lon','las','leve','lere','mes','mir','mon','mm','mer','mig',	
	'na','nn','nerv','neu','oto','on','opt','oll','ome','ott',
	'pen','par','pi','pa','po','pel','pig','qu','ren','rig','raf','res','ring',
	'rib','rast','rost','ru','rum','rem','sem','sim','su','spring',
	'cotton','cot','wood','palm',
	'do','na','ik','ke','gen','bra','bn','lla','lle','st','aa','kir',
	'nn','en','fo','fn','gi','ja','jn','ke','kr','kon','lis','on','ok','or','op',
	'pp','p','qu','re','ra','rn','ri','so','sn','se','ti','tu',
	'a','e','i','o','u',
	're','ro','pe','pn','ci','co','cl',
	'no','en','wi','we','er','en','ba','ki','nn','va','wu','x','tel','or',
	'so','me','mi','em','en','eg','ge','kn'};


namegen.generate_village_name = function( pr )
	local anz_silben = pr:next(2,5);
	local name = '';
	local prefix  = '';
	local postfix = '';
	if( pr:next(1,8)==1) then
		prefix = namegen.prefixes[ #namegen.prefixes ];
		anz_silben = anz_silben -1;
	end
	if( pr:next(1,4)==1) then
		postfix = name..namegen.suffixes[ #namegen.suffixes ];
		anz_silben = anz_silben -2;
	end
	if( anz_silben < 2 ) then
		anz_silben = 2;
	end
	for i = 1, anz_silben do
		name = name..namegen.silben[ pr:next( 1, #namegen.silben )];
	end
	name = prefix..name..postfix;
	name = string.upper( string.sub( name, 1, 1 ) )..string.sub( name, 2 );
	return name;
end


namegen.generate_village_name_with_prefix = function( pr, village )

	local name = namegen.generate_village_name( pr );

	-- if a village consists of a single house, it gets a prefix depending on the house type
	if( village.is_single_house and village.to_add_data and village.to_add_data.bpos ) then
		-- the building got removed from mg_villages.BUILDINGS in the meantime
		if( not( mg_villages.BUILDINGS[ village.to_add_data.bpos[1].btype] )) then
			return S("Abandoned building");
		end
		local btyp = mg_villages.BUILDINGS[ village.to_add_data.bpos[1].btype].typ;
		local bdata = mg_villages.village_type_data[ btyp ];
		if( bdata and (bdata.name_prefix or bdata.name_postfix )) then
			name = (bdata.name_prefix or '')..name..(bdata.name_postfix or '');
		else			
			name = S("House")..' '..name;
		end
	end
	return name;
end
