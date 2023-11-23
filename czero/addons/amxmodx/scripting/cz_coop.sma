#include <amxmodx>
#include <engine>
#include <reapi>
#include <orpheu>
#include <orpheu_memory>
#include <orpheu_advanced>

#define PLUGIN	"Condition Zero Coop"
#define VERSION	"1.3"
#define AUTHOR	"MuLLlaH9!"

new OrpheuHook:HandleUTIL_CareerDPrintf
new WinMsg = 0

public plugin_init()
{
	// Register plugin
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Plugin commands
	register_concmd("player_kill", "kill_all_players", ADMIN_RCON)
	register_concmd("map_info", "spawn_count", ADMIN_RCON)
	
	// Only for Career Mode
	if (get_member_game(m_bInCareerGame))
	{
		// Plugin CVars
		register_cvar("bots_per_player_easy", "5")
		register_cvar("bots_per_player_normal", "4")
		register_cvar("bots_per_player_hard", "3")
		register_cvar("bots_per_player_expert", "2")
		register_cvar("motd_restart", "1")
		register_cvar("simple_survival", "1")
		
		// Hide match end message
		// push 0; push 0; push ?gmsgCZCareer@@3HA; -> jmp +B5
		OrpheuMemorySet("SkipMatchHudMsgPatch1", 1, 0x0000B5E9) // 6A 00 6A 00 -> E9 B5 00 00
		OrpheuMemorySet("SkipMatchHudMsgPatch2", 1, 0x00) // FF -> 00
		
		// Skip round end message and restore later to show victory message
		// call dword ptr [edx+144h] -> jmp +8F
		OrpheuMemorySet("SkipRoundHudMsgPatch1", 1, 0x00008FE9) // FF 92 44 01 -> E9 8F 00 00
		OrpheuMemorySet("SkipRoundHudMsgPatch2", 1, 0x9000) // 00 00 -> 00 90
		
		// Skip bot quota check to bypass 6 players limit
		// jle ... -> jmp ...
		OrpheuMemorySet("SkipBotQuotaPatch1", 1, 0xEB) // 7E -> EB
		OrpheuMemorySet("SkipBotQuotaPatch2", 1, 0xEB) // 7E -> EB
		
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
		
		// Get career difficulty
		set_cvar_num("bot_difficulty", get_career_difficulty())
		
		// Additional tweaks and fixes
		server_cmd("exec coop.cfg")
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
	if (!strcmp(team, winteam))
	{
		if (!WinMsg)
		{
			// Win message not received
			// Restore match end message
			// jmp +B5 -> push 0; push 0; push ?gmsgCZCareer@@3HA;
			OrpheuMemorySet("SkipMatchHudMsgPatch1", 1, 0x006A006A) // E9 B5 00 00 -> 6A 00 6A 00
			OrpheuMemorySet("SkipMatchHudMsgPatch2", 1, 0xFF) // 00 -> FF
			// Change hook behavior for next call
			WinMsg = 1
		}
		else
		{
			// Win message received
			// Hide match end message to prevent spam
			// push 0; push 0; push ?gmsgCZCareer@@3HA; -> jmp +B5
			OrpheuMemorySet("SkipMatchHudMsgPatch1", 1, 0x0000B5E9) // 6A 00 6A 00 -> E9 B5 00 00
			OrpheuMemorySet("SkipMatchHudMsgPatch2", 1, 0x00) // FF -> 00
			// Unhook function to prevent spam
			OrpheuUnregisterHook(HandleUTIL_CareerDPrintf)
		}
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
	if (get_member_game(m_bInCareerGame) && get_cvar_num("simple_survival"))
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
			new i = 0
			new difficulty = get_cvar_num("bot_difficulty")
			switch (difficulty)
			{
				case 0: i = get_cvar_num("bots_per_player_easy")
				case 1: i = get_cvar_num("bots_per_player_normal")
				case 2: i = get_cvar_num("bots_per_player_hard")
				case 3: i = get_cvar_num("bots_per_player_expert")
				default: i = 0
			}
			if (i)
			{
				// Get default team
				new team[64]
				get_pcvar_string(get_cvar_pointer("humans_join_team"), team, 63)
				extra_bots_msg(i, difficulty)
				while (i)
				{
					// Add extra bots to opposite team
					if (!strcmp(team, "CT"))
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
		default: skill = "Expert"
	}
	// Get team
	new color = 0
	get_pcvar_string(get_cvar_pointer("humans_join_team"), playerteam, 63)
	if (!strcmp(playerteam, "CT"))
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
	// Get map name
	new map[64]
	get_mapname(map, sizeof (map))
	// Print spawns
	server_print("%s T:%i CT:%i", map, get_member_game(m_iSpawnPointCount_Terrorist), get_member_game(m_iSpawnPointCount_CT))
}

public get_career_difficulty()
{
	// Get career difficulty from GameUI.dll
	new offsets[2] = {0x04, 0x18}
	return get_value_by_pointers(OrpheuMemoryGet("CareerDifficultyBase"), offsets, sizeof offsets)
}

public get_value_by_pointers(base, offsets[], size)
{
	new bytes[4] = {0x00, 0x00, 0x00, 0x00}
	for (new i = 0; i < size; i++)
	{
		// Get value from next pointer
		OrpheuGetBytesAtAddress(base + offsets[i], bytes, sizeof bytes)
		// Convert bytes to little-endian int
		base = bytes[0] + (bytes[1] << 8) + (bytes[2] << 16) + (bytes[3] << 24)
	}
	return base
}
