#include <amxmodx> 
#include <reapi>
#include <engine>
#include <fakemeta>

enum Cvars{
	CVAR_ASP_TT_SPAWNS,					// необходимое количество спавнов ТТ
	CVAR_ASP_CT_SPAWNS,					// необходимое количество спавнов ТТ
	Float:CVAR_ASP_CHECK_HEIGHT,		// максимальная высота спавна над поверхностью
	Float:CVAR_ASP_CHECK_RADIUS,		// радиус проверки
	Float:CVAR_ASP_SEARCH_RADIUS,		// радиус поиска
	CVAR_ASP_REPAIR,					// удалять плохие спавны?
	CVAR_ASP_DEBUG_INFO					// включить доп инфо?
	//CVAR_ASP_SAVE_ORIGINS				// Нет в планах
}

new g_eCvar[Cvars]; 					// Квары
new Array:g_TTSpawn;					// info_player_deathmatch entities ID
new Array:g_CTSpawn;					// info_player_start entities ID
new g_iLastSpawnId[3];					// ID последнего занятого спавна (спасибо fl0wer)

new const Float:pointXY[8][2] = {{0.0, -1.0}, 	
								{1.0, -1.0}, 	
								{1.0, 0.0},		
								{1.0, 1.0}, 	
								{0.0, 1.0},
								{-1.0, 1.0}, 
								{0.0, -1.0},
								{-1.0, -1.0}};
new const Float:pointZ[] = {0.0, -48.0, -36.0, -18.0, 18.0, 36.0, 48.0};							

public plugin_init(){
	register_plugin("ASP", "1.0.2", "iPlague");

	CreateCvars();
	AutoExecConfig(true, "asp");

	g_TTSpawn = ArrayCreate(1, 0);
	g_CTSpawn = ArrayCreate(1, 0);

	register_clcmd("asp_status", "show_asp_status");
	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "@CSGameRules_GetPlayerSpawnSpot_Pre", false); // prevent spawning if place isn't vacant
	RegisterHookChain(RG_CSGameRules_RestartRound, "@CSGameRules_RestartRound_Post", true); // reset iSpawnPointCount
	
	get_spawns_num();
}

public show_asp_status(id){
server_print("===============================================^n^nAUTO SPAWN POINTS^nENT NUM: %d | SPAWN POINTS NUM: %d^nENT NUM: %d | SPAWN POINTS NUM: %d^n===============================================^n^n",
ArraySize(g_TTSpawn),get_member_game(m_iSpawnPointCount_Terrorist), ArraySize(g_CTSpawn),get_member_game(m_iSpawnPointCount_CT));
client_print(id, print_console,"===============================================^n^nAUTO SPAWN POINTS^nENT NUM: %d | SPAWN POINTS NUM: %d^nENT NUM: %d | SPAWN POINTS NUM: %d^n===============================================^n^n",  
ArraySize(g_TTSpawn),get_member_game(m_iSpawnPointCount_Terrorist), ArraySize(g_CTSpawn),get_member_game(m_iSpawnPointCount_CT));
}

public get_spawns_num(){
	new SpawnEnt = NULLENT, Float:fOrigin[3];
	while ((SpawnEnt = rg_find_ent_by_class(SpawnEnt, "info_player_deathmatch")) != 0){
		if(g_eCvar[CVAR_ASP_REPAIR] == 1){
			get_entvar(SpawnEnt, var_origin, fOrigin);
			engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, HULL_HUMAN, 0, 0);
			if(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen)){
				set_entvar(SpawnEnt, var_flags, FL_KILLME);
				continue;
			}
		}
		
		if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
			server_print("%d. TT ENTITY %d", ArraySize(g_TTSpawn), SpawnEnt);
		
		ArrayPushCell(g_TTSpawn, SpawnEnt);
	}

	SpawnEnt = NULLENT;
	while ((SpawnEnt = rg_find_ent_by_class(SpawnEnt, "info_player_start"))!= 0){
		if(g_eCvar[CVAR_ASP_REPAIR] == 1){
			get_entvar(SpawnEnt, var_origin, fOrigin);
			engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, HULL_HUMAN, 0, 0);
			if(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen)){
				set_entvar(SpawnEnt, var_flags, FL_KILLME);
				continue;
			}
		}
		
		if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
			server_print("%d. TT ENTITY %d", ArraySize(g_CTSpawn), SpawnEnt);
		
		ArrayPushCell(g_CTSpawn, SpawnEnt);
	}

	if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
		server_print("= = = = = = = = = = =^nOLD RESULT: %d TTs AND %d CTs SPAWNS", ArraySize(g_TTSpawn), ArraySize(g_CTSpawn));

	make_new_spawns();
}

public make_new_spawns(){
	new iTTSpawnsNum = ArraySize(g_TTSpawn);
	new iCTSpawnsNum = ArraySize(g_CTSpawn);

	new iNeedTTSpawns = max(g_eCvar[CVAR_ASP_TT_SPAWNS] - iTTSpawnsNum, 0);
	new iNeedCTSpawns = max(g_eCvar[CVAR_ASP_CT_SPAWNS] - iCTSpawnsNum, 0);

	new iSpawn, Float:fOrigin[3], Float:fNewOrigin[3];
	
	if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
		server_print("NEED: %d TT^n= = = = = = = = =^nSTART SEARCH TT SPAWNS^n", iNeedTTSpawns);

	if(iNeedTTSpawns > 0){
		for(new i = 0; i < iTTSpawnsNum; i++){
			if(iNeedTTSpawns <= 0)
				break;
				
			iSpawn = ArrayGetCell(g_TTSpawn, i);
			get_entvar(iSpawn , var_origin, fOrigin);

			for(new j = 0; j < sizeof pointXY; j++){
				if(iNeedTTSpawns <= 0)
					break;
				fNewOrigin[0] = (fOrigin[0] + g_eCvar[CVAR_ASP_SEARCH_RADIUS] * pointXY[j][0]);
				fNewOrigin[1] = (fOrigin[1] + g_eCvar[CVAR_ASP_SEARCH_RADIUS] * pointXY[j][1]);
				
				for( new z = 0; z < sizeof pointZ; z++){
					if(iNeedTTSpawns <= 0)
						break;
					fNewOrigin[2] = (fOrigin[2] + pointZ[z]);
					
					if(is_place_ok(fNewOrigin, g_eCvar[CVAR_ASP_CHECK_RADIUS])){
						new iNewSpawn = rg_create_entity("info_player_deathmatch", true);
						if(!is_nullent(iNewSpawn)){
							engfunc(EngFunc_SetOrigin, iNewSpawn, fNewOrigin);
							ArrayPushCell(g_TTSpawn, iNewSpawn);
							if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
								server_print("+++++++++++ADD SPAWN ENTITY %d (j %d)", iNewSpawn, j);
							
							iNeedTTSpawns--;
							iTTSpawnsNum++;
							if(z == 0)
								break;
						}
					}
				}
			}
		}
	}
	if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
		server_print("NEED: %d CT^n= = = = = = = = =^nSTART SEARCH CT SPAWNS^n", iNeedCTSpawns);
	
	if(iNeedCTSpawns > 0){
		for(new i = 0; i < iCTSpawnsNum; i++){
			if(iNeedCTSpawns  <= 0)
				break;

			iSpawn = ArrayGetCell(g_CTSpawn, i);
			get_entvar(iSpawn , var_origin, fOrigin);

			for(new j = 0; j < sizeof pointXY; j++){
				if(iNeedCTSpawns <= 0)
					break;
				fNewOrigin[0] = (fOrigin[0] + g_eCvar[CVAR_ASP_SEARCH_RADIUS] * pointXY[j][0]);
				fNewOrigin[1] = (fOrigin[1] + g_eCvar[CVAR_ASP_SEARCH_RADIUS] * pointXY[j][1]);
				
				for(new z = 0; z < sizeof pointZ; z++){
					if(iNeedCTSpawns <= 0)
						break;
					fNewOrigin[2] = (fOrigin[2] + pointZ[z]);
					
					if(is_place_ok(fNewOrigin, g_eCvar[CVAR_ASP_CHECK_RADIUS])){
						new iNewSpawn = rg_create_entity("info_player_start", true);
						if(!is_nullent(iNewSpawn)){
							engfunc(EngFunc_SetOrigin, iNewSpawn, fNewOrigin);
							ArrayPushCell(g_CTSpawn, iNewSpawn);
							if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
								server_print("+++++++++++ADD SPAWN ENTITY %d (j %d)", iNewSpawn, j);
							
							iNeedCTSpawns--;
							iCTSpawnsNum++;
							if(z == 0)
								break;
						}
					}
				}
			}
		}
	}
	if(g_eCvar[CVAR_ASP_DEBUG_INFO] == 1)
		server_print("NEW RESULT: %d TTs AND %d CTs SPAWNS", ArraySize(g_TTSpawn), ArraySize(g_CTSpawn));

	reset_spawns_num();
}

public reset_spawns_num(){
	if(ArraySize(g_TTSpawn))
		set_member_game(m_iSpawnPointCount_Terrorist, ArraySize(g_TTSpawn));
	
	if(ArraySize(g_CTSpawn))
		set_member_game(m_iSpawnPointCount_CT, ArraySize(g_CTSpawn));

	set_member_game(m_bLevelInitialized, true);
}


@CSGameRules_RestartRound_Post()
	reset_spawns_num();

@CSGameRules_GetPlayerSpawnSpot_Pre(id){
	new TeamName:team = get_member(id, m_iTeam);
	if (team != TEAM_TERRORIST && team != TEAM_CT)
		return HC_CONTINUE;

	new spot = EntSelectSpawnPoint(id, team);

	if (is_nullent(spot))
		return HC_CONTINUE;

	new Float:vecOrigin[3];	get_entvar(spot, var_origin, vecOrigin);
	new Float:vecAngles[3];	get_entvar(spot, var_angles, vecAngles);

	vecOrigin[2] += 1.0;

	set_entvar(id, var_origin, vecOrigin);
	set_entvar(id, var_v_angle, NULL_VECTOR);
	set_entvar(id, var_velocity, NULL_VECTOR);
	set_entvar(id, var_angles, vecAngles);
	set_entvar(id, var_punchangle, NULL_VECTOR);
	set_entvar(id, var_fixangle, 1);

	SetHookChainReturn(ATYPE_INTEGER, spot);
	return HC_SUPERCEDE;
}

EntSelectSpawnPoint(id, TeamName:team){
	new spotId = g_iLastSpawnId[_:team],spot,Float:vecOrigin[3];
	do{
		if (++spotId >= ArraySize(_:team == 1 ? g_TTSpawn : g_CTSpawn))
			spotId = 0;

		switch(team){
			case TEAM_TERRORIST: spot = ArrayGetCell(g_TTSpawn, spotId);
			case TEAM_CT: spot = ArrayGetCell(g_CTSpawn, spotId);
		}
		if (is_nullent(spot))
			continue;
		get_entvar(spot, var_origin, vecOrigin);
		if (!IsHullVacant(id, vecOrigin, HULL_HUMAN))
			continue;
		break;
	}
	while (spotId != g_iLastSpawnId[_:team]);
	if (is_nullent(spot))
		return 0;
	g_iLastSpawnId[_:team] = spotId;
	return spot;
}

CreateCvars(){
	bind_pcvar_num(create_cvar(
		"asp_tt_spawns", "24", FCVAR_SERVER,
		.description = "Необходимое количество спавнов ТТ.",
		.has_min = true, .min_val = 1.0,
		.has_max = true, .max_val = 128.0
	),g_eCvar[CVAR_ASP_TT_SPAWNS]);

	bind_pcvar_num(create_cvar(
		"asp_ct_spawns", "24", FCVAR_SERVER,
		.description = "Необходимое количество спавнов СТ.",
		.has_min = true, .min_val = 1.0,
		.has_max = true, .max_val = 128.0
	),g_eCvar[CVAR_ASP_CT_SPAWNS]);

	bind_pcvar_float(create_cvar(
		"asp_check_height", "64.0", FCVAR_SERVER,
		.description = "Максимальная высота над землёй, на которой может быть создан спавн.",
		.has_min = true, .min_val = 10.0,
		.has_max = true, .max_val = 128.0
	),g_eCvar[CVAR_ASP_CHECK_HEIGHT]);

	bind_pcvar_float(create_cvar(
		"asp_check_radius", "72.0", FCVAR_SERVER,
		.description = "Радиус проверки на наличие существующих спавнов вокруг точки.",
		.has_min = true, .min_val = 48.0,
		.has_max = true, .max_val = 256.0
	),g_eCvar[CVAR_ASP_CHECK_RADIUS]);

	bind_pcvar_float(create_cvar(
		"asp_search_radius", "96.0", FCVAR_SERVER,
		.description = "Рекомендованное расстояние между двумя спавнами.",
		.has_min = true, .min_val = 48.0,
		.has_max = true, .max_val = 256.0
	),g_eCvar[CVAR_ASP_SEARCH_RADIUS]);

	bind_pcvar_num(create_cvar(
		"asp_repair", "1", FCVAR_SERVER,
		.description = "Удалить плохие спавны (игроки могут застрять) [0 - off / 1 - on]."
	),g_eCvar[CVAR_ASP_REPAIR]);

	bind_pcvar_num(create_cvar(
		"asp_debug_info", "0", FCVAR_SERVER,
		.description = "Включить вывод информации в консоль сервера	[0 - off / 1 - on]."
	),g_eCvar[CVAR_ASP_DEBUG_INFO]);

}

//						iSpawn		fOldOrigin		fNewOrigin		fSearchRadius
stock bool:is_place_ok(Float:forigin[3],   Float:radius){
	// First check
	engfunc(EngFunc_TraceHull, forigin,  forigin, 0, HULL_HUMAN, 0, 0);
	if(get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen)){
		return false;
	}
	// Second check	if any info_player_* or func_wall or other entities..
 	new Ent = NULLENT;
	while((Ent = find_ent_in_sphere(Ent, forigin, radius)) != 0){
		new szClassname[32]; get_entvar(Ent, var_classname, szClassname, 31);
		if(	equal(szClassname, "func_buyzone") || equal(szClassname, "func_hostage_rescue") || 
			equal(szClassname, "env_sprite") || equal(szClassname, "armoury_entity") ||
			equal(szClassname, "func_water"))
			continue;
		return false;
	}
	// Third check	if this point is too high over ground (f.e. tt spawns on cs_assault) 
	if(distance_to_ground(forigin) > g_eCvar[CVAR_ASP_CHECK_HEIGHT])
		return false;
	
	// 4th check if spawn out of map
	if(engfunc(EngFunc_PointContents , forigin) == CONTENTS_SOLID)
		return false;
	
	// 5th check if spawn out of map
	if(engfunc(EngFunc_PointContents , forigin) == CONTENTS_SKY)
		return false;

	return true;	
}

stock Float:distance_to_ground(Float:start[3]){ 
    new Float:end[3]; 
  
    end[0] = start[0]; 
    end[1] = start[1]; 
    end[2] = start[2] - 9999.0; 
    
    new ptr = create_tr2(); 
    engfunc(EngFunc_TraceHull, start, end, IGNORE_MONSTERS, HULL_HUMAN, 0, ptr); 
    new Float:distance; 
    get_tr2(ptr, TR_flFraction, distance); 
    free_tr2(ptr); 
    distance *= 9999.0; 
    return distance;
}

bool:IsHullVacant(id, Float:vecOrigin[3], hull){
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, 0, hull, id, 0);
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return false;
	return true;
}