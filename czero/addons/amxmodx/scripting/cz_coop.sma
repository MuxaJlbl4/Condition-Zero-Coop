#include <amxmodx>
#include <engine>
#include <reapi>
#include <orpheu>
#include <orpheu_memory>
#include <orpheu_advanced>

#define PLUGIN	"Condition Zero Coop"
#define VERSION	"2.7"
#define AUTHOR	"MuLLlaH9!"

new OrpheuHook:HandleUTIL_CareerDPrintf
new WinMsg = 0
new default_team[64] = ""
new BotRejoin = 0
#define TASK	0.5

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
		register_cvar("bots_custom_ai", "0")
		register_cvar("bots_per_player", "3")
		register_cvar("motd_restart", "1")
		register_cvar("simple_hostages", "1")
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
		
		// Hook bot addition
		new OrpheuFunction:BotAddCommand = OrpheuGetFunction("BotAddCommand", "CCSBotManager")
		OrpheuRegisterHook(BotAddCommand, "OnBotAddCommand")
		
		// Hook HandleEnemyKill
		new OrpheuFunction:HandleEnemyKill = OrpheuGetFunction("HandleEnemyKill", "CCareerTaskManager")
		OrpheuRegisterHook(HandleEnemyKill, "OnHandleEnemyKill")
		
		// Hook HandleEnemyInjury
		new OrpheuFunction:HandleEnemyInjury = OrpheuGetFunction("HandleEnemyInjury", "CCareerTaskManager")
		OrpheuRegisterHook(HandleEnemyInjury, "OnHandleEnemyInjury")
		
		// Hook MakeBomber
		if (get_member_game(m_bMapHasBombTarget))
			RegisterHookChain(RG_CBasePlayer_MakeBomber, "CBasePlayer_MakeBomber")
		
		// Get career difficulty
		set_cvar_num("bot_difficulty", get_career_difficulty())
		
		// Additional cmd tweaks and fixes for carrer mode
		server_cmd("exec carrer.cfg")
		
		// Load custom cvar values
		server_cmd("exec coop.cfg")
	}
}

public OrpheuHookReturn:OnBotAddCommand(pThisObject, team, isFromConsole)
{
	if (get_cvar_num("bots_custom_ai"))
	{
		// Create YaPB bot
		server_cmd("yb add %i", get_cvar_num("bot_difficulty"))
		
		// Get bot team
		new bot_team[64]
		if (team)
			bot_team = "CT"
		else
			bot_team = "T"
		
		// If bot team is NOT default
		if (strcmp(get_default_team_str(), bot_team))
			BotRejoin++
		
		OrpheuSetReturn(true)
		return OrpheuSupercede
	}
	return OrpheuIgnored
}

public OrpheuHookReturn:OnHandleEnemyKill(pThisObject, wasBlind, weaponName, headshot, killerHasShield, pAttacker, pVictim)
{
	// Exclude YaPB bots (pVictim is pAttacker)
	if (is_user_bot(pVictim))
		return OrpheuSupercede
	// Flash task fix for YaPB (pAttacker is pVictim)
	if (Float:get_member(pAttacker, m_blindStartTime) + Float:get_member(pAttacker, m_blindFadeTime) - 6.0 > get_gametime())
		OrpheuSetParam(2, true)
	return OrpheuIgnored
}

public OrpheuHookReturn:OnHandleEnemyInjury(pThisObject, weaponName, attackerHasShield, pAttacker)
{
	// Exclude YaPB bots
	if (is_user_bot(pAttacker))
		return OrpheuSupercede
	return OrpheuIgnored
}

public OnSV_Career_EndRound_f()
{
	// Kill default team
	for (new i = 0; i < MaxClients; i++)
		if (is_user_alive(i) && get_member(i, m_iTeam) == get_default_team())
			user_kill(i)
}

public OnAreAllTasksComplete(...)
{
	// Force next round
	server_cmd("career_continue")
}

public OnUTIL_CareerDPrintf(...)
{	
	// Get default team
	new team[64]
	get_pcvar_string(get_cvar_pointer("humans_join_team"), team, charsmax(team))
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

public OrpheuHookReturn:OnHandleEvent(pThisObject, event, pAttacker, pVictim)
{
	// Simple hostages
	if (get_cvar_num("simple_hostages"))
	{
		// If EVENT_HOSTAGE_RESCUED or EVENT_ALL_HOSTAGES_RESCUED
		if (event == 32 || event == 33)
			return OrpheuIgnored
	}
	
	// Exclude YaPB bots
	if (is_user_bot(pAttacker))
		return OrpheuSupercede
	
	// Simple survival
	if (get_cvar_num("simple_survival"))
	{
		// If EVENT_DIE
		if (event == 49)
		{
			// Get alive players
			new players[32], players_alive
			get_players(players, players_alive, "ca")
			// Change event to skip task fail
			if (players_alive)
				return OrpheuSupercede
		}
	}
	return OrpheuIgnored
}

public CBasePlayer_MakeBomber()
{
	// Exclude YaPB bombers
	if (get_default_team() == TEAM_TERRORIST && get_cvar_num("bots_custom_ai"))
	{
		// Get players
		new players[32], player_count
		get_players(players, player_count, "c")
		SetHookChainArg(1, ATYPE_INTEGER, players[random(player_count)])
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
			// Check default team
			if (get_default_team() != get_member(id, m_iTeam))
				rg_join_team(id, get_default_team())
			// Print joined player name
			new name[64]
			get_user_name(id, name, charsmax(name))
			client_print_color(0, print_team_default, "^3%s ^1joined the game", name)
			// Add extra bots
			new addbots = get_cvar_num("bots_per_player")
			for (new i = 0; i < addbots; i++)
			{
				// Add extra bots to opposite team
				if (get_default_team() == TEAM_CT)
					server_cmd("bot_add_t")
				else
					server_cmd("bot_add_ct")
			}
			if (addbots)
				extra_bots_msg(addbots, get_cvar_num("bot_difficulty"))
		}
		// Balance task for YaPB
		if (get_cvar_num("bots_custom_ai") && is_user_bot(id) && BotRejoin)
			set_task (TASK, "BotRejoinTeam")
	}
}

public BotRejoinTeam()
{
	// Get bots
	new bots[32], bot_count
	get_players(bots, bot_count, "d")
	for (new i = 0; i < bot_count; i++)
	{
		// Check availability after task delay
		if (BotRejoin && is_user_connected(bots[i]) && get_default_team() == get_member(bots[i], m_iTeam))
		{
			// Change bot team
			if (get_default_team() == TEAM_CT)
				rg_join_team(bots[i], TEAM_TERRORIST)
			else
				rg_join_team(bots[i], TEAM_CT)
			BotRejoin--
			return
		}
	}
}

public extra_bots_msg(count, difficulty)
{
	// Create bot message
	new s = ' '
	new ai[64]
	new skill[64]
	new botteam[64]
	// Get difficulty
	if (get_cvar_num("bots_custom_ai"))
		switch (difficulty)
		{
			case 0: skill = "Newbie"
			case 1: skill = "Average"
			case 2: skill = "Normal"
			case 3: skill = "Professional"
			default: skill = "Godlike"
		}
	else
		switch (difficulty)
		{
			case 0: skill = "Easy"
			case 1: skill = "Normal"
			case 2: skill = "Hard"
			default: skill = "Expert"
		}
	// Get team
	new color = 0
	if (get_default_team() == TEAM_CT)
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
	// Get AI
	if (get_cvar_num("bots_custom_ai"))
		ai = "YaPB"
	else
		ai = "zBot"
	// Print info
	client_print_color(0, color, "^4+%d ^3%s %s Bot%c ^1[%s]", count, skill, botteam, s, ai)
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
	get_mapname(map, sizeof map)
	// Print spawns
	server_print("%s T:%i CT:%i", map, get_member_game(m_iSpawnPointCount_Terrorist), get_member_game(m_iSpawnPointCount_CT))
}

public TeamName:get_default_team()
{
	if (!strcmp(get_default_team_str(), "T"))
		return TEAM_TERRORIST
	else
		return TEAM_CT
	
}

public get_default_team_str()
{
	// Update humans_join_team (too early for init)
	if (!strcmp(default_team, ""))
		get_pcvar_string(get_cvar_pointer("humans_join_team"), default_team, charsmax(default_team))
	return default_team
}

public get_career_difficulty()
{
	// Get career difficulty from GameUI.dll (cl_carrer_difficulty)
	new offsets[1] = {0xF0}
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
