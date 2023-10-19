#include <amxmodx>
#include <engine>
#include <reapi>
#include <orpheu>
#include <orpheu_memory>

#define PLUGIN	"Condition Zero Coop"
#define VERSION	"1.0"
#define AUTHOR	"MuLLlaH9!"

new OrpheuHook:HandleUTIL_CareerDPrintf

public plugin_init()
{
	// Register plugin
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Plugin commands
	register_concmd("player_kill","kill_all_players",ADMIN_RCON)
	register_concmd("spawn_info","spawn_count",ADMIN_RCON)
	
	// Only for Career Mode
	if (get_member_game(m_bInCareerGame))
	{
		// Plugin cvars
		register_cvar("bots_per_player", "2")
		register_cvar("motd_restart", "1")
		
		// Some tweaks and fixes
		server_cmd ("exec coop.cfg")
		
		// Hide match end message
		OrpheuMemorySet("SkipMatchHudMsgPatch1",1,0x0000B5E9)
		OrpheuMemorySet("SkipMatchHudMsgPatch2",1,0x00)
		// Skip round end message and restore later to show victory message
		OrpheuMemorySet("SkipRoundHudMsgPatch1",1,0x00008FE9)
		OrpheuMemorySet("SkipRoundHudMsgPatch2",1,0x9000)
		
		// Hook round give up function, to kill all players
		new OrpheuFunction:SV_Career_EndRound_f = OrpheuGetFunction("SV_Career_EndRound_f")
		OrpheuRegisterHook(SV_Career_EndRound_f, "OnSV_Career_EndRound_f")
		
		// Hook AreAllTasksComplete function, to force next round
		new OrpheuFunction:AreAllTasksComplete = OrpheuGetFunction("AreAllTasksComplete", "CCareerTaskManager")
		OrpheuRegisterHook(AreAllTasksComplete, "OnAreAllTasksComplete")
		
		// Hook end match to force restart and unhook later to prevent spam on victory
		new OrpheuFunction:UTIL_CareerDPrintf = OrpheuGetFunction("UTIL_CareerDPrintf")
		HandleUTIL_CareerDPrintf = OrpheuRegisterHook(UTIL_CareerDPrintf, "OnUTIL_CareerDPrintf")
		
		// Hook task manager event, to simplify survival and in-a-row tasks
		new OrpheuFunction:HandleEvent = OrpheuGetFunction("HandleEvent", "CCareerTaskManager")
		OrpheuRegisterHook(HandleEvent, "OnHandleEvent")
	}
}

public OnSV_Career_EndRound_f()
{
	// Kill all alive players
	kill_all_players()
}

public OnAreAllTasksComplete(...)
{
	// Force next round
	server_cmd("career_continue")
}

public OnUTIL_CareerDPrintf(pszMsg, ...)
{	
	// Get default team
	new team[64]
	get_pcvar_string(get_cvar_pointer("humans_join_team"), team, 63)
	// Get winner team
	new winteam[64]
	if (get_member_game(m_iNumCTWins) > get_member_game(m_iNumTerroristWins))
		winteam = "CT"
	else
		winteam = "T"
	// Check victory
	if (!strcmp(team,winteam))
	{
		// Restore match end message
		OrpheuMemorySet("SkipMatchHudMsgPatch1",1,0x006A006A)
		OrpheuMemorySet("SkipMatchHudMsgPatch2",1,0xFF)
		// Unhook to prevent spam
		OrpheuUnregisterHook(HandleUTIL_CareerDPrintf)
	}
	else
	{
		// Restart MotD or chat message
		if (get_cvar_num("motd_restart"))
			show_motd(0, "restart.html", "Mission Restart")
		else
			client_print_color(0, print_team_red, "^3Mission Failed! ^4Restarting...")
		// Force restart
		server_cmd("career_restart")
	}
}

public OnHandleEvent(pThisObject, event, pAttacker, pVictim)
{
	// Only for Career Mode
	if (get_member_game(m_bInCareerGame))
	{
		// If EVENT_DIE
		if (event == 49)
		{
			// Get alive players
			new players[32], players_alive
			get_players(players, players_alive, "ca")
			// Change event to skip task fail
			if (players_alive)
				OrpheuSetParam(2, 0)
		}
	}
}

public client_putinserver(id)
{
	// Only for Career Mode
	if (get_member_game(m_bInCareerGame))
	{
		// Forced scoring start
		set_member_game(m_bGameStarted, true)
		// Get player count
		new players[32], player_count
		get_players(players, player_count, "c")
		// Check client
		if (player_count > 1 && !is_user_bot(id))
		{
			// Get player name
			new name[64]
			get_user_name(id, name, 63)
			// Print player name
			client_print_color(0, print_team_default, "^3%s ^1joined the game", name)
			// Add extra bots
			new i = get_cvar_num("bots_per_player")
			if (i)
			{
				// Get default team
				new team[64]
				get_pcvar_string(get_cvar_pointer("humans_join_team"), team, 63)
				extra_bots_msg(get_cvar_num("bots_per_player"), get_cvar_num("bot_difficulty"))
				while (i)
				{
					// Add extra bots to opposite team
					if (!strcmp(team,"CT"))
						server_cmd("bot_add_t")
					else
						server_cmd("bot_add_ct")
					i--
				}
			}
		}
	}
}

public extra_bots_msg(count, difficulty)
{
	// Create bot message
	new s = ' '
	new skill[64]
	new botteam[64]
	new playerteam[64]
	// Get difficulty
	switch (difficulty)
	{
		case 0: skill = "Easy"
		case 1: skill = "Normal"
		case 2: skill = "Hard"
		case 3: skill = "Expert"
		default: skill = "Elite"
	}
	// Get team
	new color = 0
	get_pcvar_string(get_cvar_pointer("humans_join_team"), playerteam, 63)
	if (!strcmp(playerteam,"CT"))
	{
		botteam = "T"
		color = print_team_red
	}
	else
	{
		botteam = "CT"
		color = print_team_blue
	}
	// Count check
	if (count > 1)
		s = 's'
	// Print info
	client_print_color(0, color, "^4+%d ^3%s %s Bot%c", count, skill, botteam, s)
}

public kill_all_players()
{
	// Get alive players
	new players[32], players_alive
	get_players(players, players_alive, "ca")
	// Kill
	for (new i = 0; i < players_alive; i++)
		user_kill(players[i])
}

public spawn_count()
{
	// Get spawn points count
	new Tspawns = 0
	new CTspawns = 0
	new entity = 0
	// Count T spawn points
	Tspawns = 0
	while ((entity = find_ent_by_class(entity, "info_player_deathmatch")))
		Tspawns++
	// Count CT spawn points
	entity = 0
	CTspawns = 0
	while ((entity = find_ent_by_class(entity, "info_player_start")))
		CTspawns++
	// Get map name
	new map[64]
	get_mapname(map, sizeof (map))
	// Print spawns
	server_print("%s T:%i CT:%i", map, Tspawns, CTspawns)
}
