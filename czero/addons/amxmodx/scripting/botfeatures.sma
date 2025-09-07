// Copyright © 2017 Vaqtincha
// Fix смены ников новых игроков на ники Ботов+Взятых Ботов от juice (2019)
//	по заказу от SNauPeRа

// Fix2 проверка на взятие VIP-бота на as_ карте от AlexandrFiner (2020)
// по заказу от SNauPeRа

// Lite удалён функционал замены скина и чата, перевод сообщений на английский (2024)
// по заказу от MuLLlaH9!

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG START ■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#define BACK_ITEMS_ON_RESTARTROUND					// Вернуть боту оружия и предметов при новом раунде

#define INFO_HUD_POSITION		-1.0, 0.60			// Позиция худ информера
#define INFO_HUD_COLOR			25, 200, 20			// Цвет худ информера

// #define KILL_REWARD				100				// Сколько давать деньги игроку за килл
// #define KILL_FRAGS				1				// Сколько давать фраги игроку за килл
// #define MAX_USE_PER_ROUND		2				// Сколько раз можно использовать бота за раунд

// #define PL_DEBUG									// Включить отладочную информацию

/**■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ CONFIG END ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#define PL_VERSION 		"0.0.3fix2-lite"

#if AMXX_VERSION_NUM < 183
	#define client_disconnected 		client_disconnect
	#include <colorchat>
#endif


#define IsPlayer(%1)					(1 <= %1 <= g_iMaxPlayers)
#define IsBot(%1)						(g_aPlayerData[%1][szBotName][0])

#define SET_ORIGIN(%1,%2) 				engfunc(EngFunc_SetOrigin, %1, %2)
#define SET_SIZE(%1,%2,%3) 				engfunc(EngFunc_SetSize, %1, %2, %3)

#define VECTOR_ZERO 					Float:{0.0, 0.0, 0.0}

const MAX_NAME_LENGHT =	32
const INVALID_WEAPONS_BS = ((1 << any:WEAPON_NONE)|(1 << any:WEAPON_GLOCK)|(1 << any:WEAPON_KNIFE))
const USEFUL_WEAPON_SLOTS_BS = ((1 << any:PRIMARY_WEAPON_SLOT)|(1 << any:PISTOL_SLOT)/* |(1 << any:GRENADE_SLOT) */)
const ALLOWED_OBS_MODE_BS = ((1 << OBS_IN_EYE)|(1 << OBS_CHASE_FREE))

enum coord_e { Float:X, Float:Y, Float:Z }
enum { SpecHealth2_Health = 1, SpecHealth2_Target }

enum player_s
{
	pBotIndex,		// last bot index
	szBotName[32],
	iUsedCount
}

new g_aPlayerData[MAX_CLIENTS + 1][player_s]

new bool:g_bMapHasBombTarget, bool:g_bRoundEnded, g_iMaxPlayers, g_iHudSync
new HookChain:g_hGetPlayerSpawnSpot, HamHook:g_hUseWeaponStrip
/*
new const g_szBotChatMsg[][] = {
	"Смотри и не подведи меня!",
	"Надеюсь ты не зря убил меня",
	"Думаешь играешь лучше чем я ? Посмотрим..",
	"Б*я человечки не дают играть",
	"Решил играть за меня ? Только береги мое оружие.",
	"Во блин. Так несправедливо",
	"Зарабатывай деньги и фраги. Я БУДУ РАД."
}

new const g_szDefModelNames[MODEL_AUTO][] = { 
	"", "urban", "terror", "leet", "arctic", "gsg9",
	"gign", "sas", "guerilla", "vip", "militia", "spetsnaz" 
}
*/

public plugin_init()
{
	register_plugin("Bot Features", PL_VERSION, "Vaqtincha")
	if(!cvar_exists("bot_zombie"))
	{
		pause("ad")
		return 
	}
	
	register_clcmd("nightvision", "ClCmd_ControlBot")
	register_clcmd("rr", "ClCmd_ControlBot")
	register_event("SpecHealth2", "Event_SpecHealth2", "bd", "1>0" /*, "2!0" */)

	RegisterHookChain(RG_RoundEnd, "RoundEnd", .post = true)
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", .post = false)
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "CSGameRules_PlayerKilled", .post = false)

	DisableHookChain(g_hGetPlayerSpawnSpot = RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "CSGameRules_GetPlayerSpawnSpot", .post = false))
	
	if(rg_find_ent_by_class(NULLENT, "player_weaponstrip", true) > 0) {
		DisableHamForward(g_hUseWeaponStrip = RegisterHam(Ham_Use, "player_weaponstrip", "CStripWeapons_Use", .Post = false))
	}
	
	g_bMapHasBombTarget = bool:get_member_game(m_bMapHasBombTarget)
	g_iMaxPlayers = get_maxplayers()
	g_iHudSync = CreateHudSyncObj()	

	register_forward(FM_ClientDisconnect, "OnClientDisconnect_Post", 1)
}

public OnClientDisconnect_Post(pClient)
{
	set_entvar(pClient, var_netname, "^0")
}

public client_putinserver(pClient) 
{
	g_aPlayerData[pClient][szBotName][0] = g_aPlayerData[pClient][iUsedCount] = g_aPlayerData[pClient][pBotIndex] = 0

	if(is_user_bot(pClient)) {
		get_user_name(pClient, g_aPlayerData[pClient][szBotName], MAX_NAME_LENGHT - 1)
	}
}

public client_disconnected(pClient) 
{
	new pBot
	if(IsBot(pClient))
	{
		new aPlayers[32], iCount, pPlayer
		get_players(aPlayers, iCount, "ch")		// skip bot's & hltv

		for(--iCount; iCount >= 0; iCount--)
		{
			pPlayer = aPlayers[iCount]
			if(g_aPlayerData[pPlayer][pBotIndex] == pClient) {
				FullResetPlayer(pPlayer)
			}
		}
	}
	else if((pBot = g_aPlayerData[pClient][pBotIndex]) > 0) {
		SetBotName(pBot, g_aPlayerData[pBot][szBotName])
	}
	
	g_aPlayerData[pClient][iUsedCount] = g_aPlayerData[pClient][pBotIndex] = 0
}

public ClCmd_ControlBot(const pPlayer)
{
	if(is_user_alive(pPlayer))
		return PLUGIN_CONTINUE

	new pBot = get_entvar(pPlayer, var_iuser2)
	if(pBot <= 0 || pBot == pPlayer || !IsBot(pBot) || !is_user_alive(pBot))
		return PLUGIN_HANDLED
	
	if(!(ALLOWED_OBS_MODE_BS & (1 << get_entvar(pPlayer, var_iuser1))))
		return PLUGIN_HANDLED
	
	new TeamName:iTeam = get_member(pPlayer, m_iTeam)
	if(!(TEAM_TERRORIST <= iTeam <= TEAM_CT))
	{
		client_print(pPlayer, print_center, "Not available for spectators")
		return PLUGIN_HANDLED
	}
	if(get_member(pBot, m_bIsVIP)) {
		client_print(pPlayer, print_center, "Can't pick VIP bot")
		return PLUGIN_HANDLED
	}
#if !defined PL_DEBUG		// ignore the team on debug mode (not recommended!)
	if(iTeam != get_member(pBot, m_iTeam))
	{
		client_print(pPlayer, print_center, "You can pick only teammate bots!")
		return PLUGIN_HANDLED
	}
#endif
#if defined MAX_USE_PER_ROUND
	if(MAX_USE_PER_ROUND > 0 && g_aPlayerData[pPlayer][iUsedCount] >= MAX_USE_PER_ROUND)
	{
		client_print(pPlayer, print_center, "Can be used %i times per round!", MAX_USE_PER_ROUND)
		return PLUGIN_HANDLED
	}
#endif
	if(g_bRoundEnded) // (get_member_game(m_bRoundTerminating) || get_member_game(m_bCompleteReset))
	{
		client_print(pPlayer, print_center, "Round ended!")
		return PLUGIN_HANDLED
	}

	//rg_set_user_model(pPlayer, g_szDefModelNames[get_member(pBot, m_iModelName)], true)
#if defined PL_DEBUG
	set_member(pPlayer, m_iTeam, get_member(pBot, m_iTeam))
#endif

	set_user_info(pPlayer, "*bot", "1")		 // lol

	g_aPlayerData[pPlayer][pBotIndex] = pBot
	g_aPlayerData[pPlayer][iUsedCount]++

	set_member(pPlayer, m_bNotKilled, true)	// HACK: ignore default items

	if(g_hUseWeaponStrip > any:0) {			// map has weapon stipper ?
		EnableHamForward(g_hUseWeaponStrip)
	}

	EnableHookChain(g_hGetPlayerSpawnSpot)
	
	rg_round_respawn(pPlayer)
	ScenarioIcon(pPlayer)
	
	new szName[MAX_NAME_LENGHT], szFakeName[MAX_NAME_LENGHT]
	get_user_name(pPlayer, szName, charsmax(szName))
	PrintChatAll(pPlayer, szName, g_aPlayerData[pBot][szBotName])

	formatex(szFakeName, charsmax(szFakeName), "[%s] %s", szName, g_aPlayerData[pBot][szBotName])
	SetBotName(pBot, szFakeName)

	//client_print_color(pPlayer, print_team_default, "^3%s ^1: %s", g_aPlayerData[pBot][szBotName], g_szBotChatMsg[random(sizeof(g_szBotChatMsg))])

	return PLUGIN_HANDLED
}

public Event_SpecHealth2(const pPlayer)
{
	new pTarget = read_data(SpecHealth2_Target)
	if(pTarget > 0 && IsBot(pTarget) && (ALLOWED_OBS_MODE_BS & (1 << get_entvar(pPlayer, var_iuser1)))
		&& get_member(pPlayer, m_iTeam) == get_member(pTarget, m_iTeam))
	{
		set_hudmessage(INFO_HUD_COLOR, INFO_HUD_POSITION, .holdtime = 1.5, .fadeintime = 0.5, .fadeouttime = 0.5)
		ShowSyncHudMsg(pPlayer, g_iHudSync, "Press ^"N^" to play as: %s", g_aPlayerData[pTarget][szBotName])
	}
	else {
		ClearSyncHud(pPlayer, g_iHudSync)
	}
}

public CStripWeapons_Use(const pStripEntity, const pActivator, const pCaller, const useType, const Float:value)
{
	DisableHamForward(g_hUseWeaponStrip)
	return (IsPlayer(pActivator) && g_aPlayerData[pActivator][pBotIndex] > 0) ? HAM_SUPERCEDE : HAM_IGNORED
}

public RoundEnd(const WinStatus:status, const ScenarioEventEndRound:event, const Float:tmDelay) {
	g_bRoundEnded = true
}


public CSGameRules_RestartRound()
{
	new aPlayers[32], iCount, pPlayer, pBot, bool:bRestart = bool:get_member_game(m_bCompleteReset)
	get_players(aPlayers, iCount, "ch") 	// skip bot's & hltv

	g_bRoundEnded = false

	for(--iCount; iCount >= 0; iCount--)
	{
		pPlayer = aPlayers[iCount]
		if(!bRestart && (pBot = g_aPlayerData[pPlayer][pBotIndex]) > 0)
		{
			if(!is_nullent(pBot))
			{
#if defined BACK_ITEMS_ON_RESTARTROUND
				// player has a useful weapon ?
				if(TransferItems(pPlayer, pBot, true) & USEFUL_WEAPON_SLOTS_BS) {
					set_member(pBot, m_bNotKilled, true) 	// HACK: ignore default items
				}
#endif
				SetBotName(pBot, g_aPlayerData[pBot][szBotName])
			}
#if defined BACK_ITEMS_ON_RESTARTROUND
			set_member(pPlayer, m_bNotKilled, false)	// HACK: give default items
#endif
		}

		if(g_aPlayerData[pPlayer][iUsedCount] > 0) {
			FullResetPlayer(pPlayer)
		}
	}
}

public CSGameRules_PlayerKilled(const pVictim, const pevKiller, const pevInflictor)
{
	new pKillerBot, pVictimBot
	if((pVictimBot = g_aPlayerData[pVictim][pBotIndex]) > 0)
	{
		set_user_info(pVictim, "*bot", "0")
		SetBotName(pVictimBot, g_aPlayerData[pVictimBot][szBotName])
		g_aPlayerData[pVictim][pBotIndex] = 0
	}

	if(pVictim == pevKiller)
		return HC_CONTINUE

	if(pVictimBot > 0) {
		SetHookChainArg(1, ATYPE_INTEGER, pVictimBot)
	}

	if(IsPlayer(pevKiller) && (pKillerBot = g_aPlayerData[pevKiller][pBotIndex]) > 0)
	{
		SetHookChainArg(2, ATYPE_INTEGER, pKillerBot)
		
		if(pevKiller == pevInflictor) {
			SetHookChainArg(3, ATYPE_INTEGER, get_member(pevKiller, m_pActiveItem))
		}
#if defined KILL_REWARD 
		rg_add_account(pevKiller, KILL_REWARD)
#endif
#if defined KILL_FRAGS
		ExecuteHam(Ham_AddPoints, pevKiller, KILL_FRAGS, false)
#endif
	}

	return HC_CONTINUE
}

public CSGameRules_GetPlayerSpawnSpot(const pPlayer)
{
	DisableHookChain(g_hGetPlayerSpawnSpot)

	new pBot = g_aPlayerData[pPlayer][pBotIndex]
	if(pBot > 0 && !is_nullent(pBot))
	{
		new Float:vecOrigin[coord_e], Float:vecVAngles[coord_e], Float:vecMins[coord_e], Float:vecMaxs[coord_e]

		get_entvar(pBot, var_origin, vecOrigin)
		get_entvar(pBot, var_v_angle, vecVAngles)	// note: v_angle
		get_entvar(pBot, var_mins, vecMins)
		get_entvar(pBot, var_maxs, vecMaxs)

		TransferItems(pBot, pPlayer)
		KillBot(pBot, vecOrigin)

		if(SetPlayerPosition(pPlayer, vecOrigin, vecVAngles, vecMins, vecMaxs, (get_entvar(pBot, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN))
		{
			SetHookChainReturn(ATYPE_INTEGER, pPlayer)
			return HC_SUPERCEDE
		}
	}

	return HC_CONTINUE
}

TransferItems(const pPlayer, const pReceiver, bool:bBackToBot = false)
{
	if(!bBackToBot) {
		set_entvar(pReceiver, var_health, Float:get_entvar(pPlayer, var_health))
	}

	new bitWeaponSlots, ArmorType:iArmortype, iArmorVal
	if((iArmorVal = rg_get_user_armor(pPlayer, iArmortype)) > 0 && iArmortype != ARMOR_NONE) {
		rg_set_user_armor(pReceiver, iArmorVal, iArmortype)
	}

	if(get_member(pPlayer, m_bHasNightVision)) {
		set_member(pReceiver, m_bHasNightVision, true)
	}
	// if(get_member(pPlayer, m_fLongJump)) {
		// set_member(pReceiver, m_fLongJump, true)
	// }
	
	if(g_bMapHasBombTarget)
	{
		if(!bBackToBot && get_member(pPlayer, m_bHasC4)) {
			rg_transfer_c4(pPlayer, pReceiver)
		}
		if(get_member(pPlayer, m_bHasDefuser))
		{
			rg_give_defusekit(pReceiver)
			rg_remove_item(pPlayer, "item_thighpack")
		}
	}

	new pActiveItem = get_member(pPlayer, m_pActiveItem)
	for(new WeaponIdType:iId, iBpAmmo, pItem, pNextItem, Float:flReleaseThrow, 
		InventorySlotType:iSlot = PRIMARY_WEAPON_SLOT; iSlot <= GRENADE_SLOT; iSlot++
	)
	{
		pItem = get_member(pPlayer, m_rgpPlayerItems, iSlot)
		while(pItem > 0 && !is_nullent(pItem))
		{
			pNextItem = get_member(pItem, m_pNext)
			if(iSlot == GRENADE_SLOT && pActiveItem == pItem)
			{
				flReleaseThrow = Float:get_member(pActiveItem, m_flReleaseThrow)
				if(flReleaseThrow == 0.0)   // ready to launch nade (get_entvar(pPlayer, var_button) & IN_ATTACK)
				{
					ExecuteHam(Ham_Item_Holster, pActiveItem, 1)	// reset: m_flStartThrow & m_flReleaseThrow
					set_entvar(pPlayer, var_button, get_entvar(pPlayer, var_button) &~ IN_ATTACK)	// old ReGameDLL support
				}
				else if(flReleaseThrow > 0.0) 	// grenade throwed
				{
					ExecuteHam(Ham_Weapon_RetireWeapon, pActiveItem) 	// force switch to best weapon
					pActiveItem = get_member(pPlayer, m_pActiveItem)	// update active weapon
					pItem = pNextItem
					continue											// skip it
				}
			}

			if(iSlot != KNIFE_SLOT && !(INVALID_WEAPONS_BS & (1 << any:(iId = get_member(pItem, m_iId))))) {
				iBpAmmo = rg_get_user_bpammo(pPlayer, iId)
			}

			if(!ExecuteHam(Ham_RemovePlayerItem, pPlayer, pItem)) // Removes an item to the player inventory (is failed ?).
			{
				pItem = pNextItem
				continue
			}
			
			if(!ExecuteHam(Ham_AddPlayerItem, pReceiver, pItem)) // Add a weapon to the player inventory (is failed ?).
			{
				pItem = pNextItem
				continue
			}
	
			ExecuteHam(Ham_Item_AttachToPlayer, pItem, pReceiver)

			if(iBpAmmo > 0) {
				rg_set_user_bpammo(pReceiver, iId, iBpAmmo)
			}

			bitWeaponSlots |= (1 << any:iSlot)
			pItem = pNextItem
		}
	}
	
	if(pActiveItem > 0 && !is_nullent(pActiveItem)) 
	{
		rg_switch_weapon(pReceiver, pActiveItem)

		if(get_member(pPlayer, m_bOwnsShield)) 
		{
			rg_give_shield(pReceiver)
			if(!IsBot(pReceiver) && get_member(pPlayer, m_bShieldDrawn)) {	// get_member(pActiveItem, m_Weapon_iWeaponState) & WPNSTATE_SHIELD_DRAWN
				ExecuteHam(Ham_Weapon_SecondaryAttack, pActiveItem)
			}
			rg_remove_item(pPlayer, "weapon_shield")
		}
	}

	return bitWeaponSlots
}

bool:SetPlayerPosition(const pPlayer, Float:vecOrigin[coord_e], Float:vecAngles[coord_e], Float:vecMins[coord_e], Float:vecMaxs[coord_e], const iHullNumber)
{
	static const Float:vecMove[][coord_e] = { { 1.0, 1.0, 0.0 }, { 1.0, -1.0, 0.0 }, { -1.0, -1.0, 0.0 }, { -1.0, 1.0, 0.0 } }
	new i

	do
	{
		if(IsFreeSpace(vecOrigin, iHullNumber))
		{
			if(iHullNumber == HULL_HEAD)
			{
				set_entvar(pPlayer, var_flags, get_entvar(pPlayer, var_flags) | FL_DUCKING)
				set_entvar(pPlayer, var_button, get_entvar(pPlayer, var_button) | IN_DUCK)
			}
	
			SET_SIZE(pPlayer, vecMins, vecMaxs)
			SET_ORIGIN(pPlayer, vecOrigin)
			set_entvar(pPlayer, var_velocity, VECTOR_ZERO)
			// set_entvar(pPlayer, var_basevelocity, VECTOR_ZERO)
			set_entvar(pPlayer, var_v_angle, VECTOR_ZERO)
			set_entvar(pPlayer, var_angles, vecAngles)
			set_entvar(pPlayer, var_punchangle, VECTOR_ZERO)
			set_entvar(pPlayer, var_fixangle, 1) 	// const FORCE_VIEW_ANGLES = 1

			return true
		}
		else
		{
			vecOrigin[X] = (vecOrigin[X] - vecMins[X] * vecMove[i][X])
			vecOrigin[Y] = (vecOrigin[Y] - vecMins[Y] * vecMove[i][Y])
			i++
		}

		// server_print("Attemps: %i", i)
	} while (i < sizeof(vecMove))

	return false
}

KillBot(const pBot, Float:vecOrigin[coord_e])
{
	set_member(pBot, m_vBlastVector, vecOrigin)		// FIX: "PM Got a NaN velocity"
	set_member(pBot, m_bKilledByBomb, true)			// HACK: block sending "DeathMsg" & frag loses
	set_entvar(pBot, var_effects, EF_NODRAW)		// hide corpse
	// SET_ORIGIN(pBot, VECTOR_ZERO)  				// FIX: panic bot's
	dllfunc(DLLFunc_ClientKill, pBot)
}

FullResetPlayer(const pPlayer)
{
	set_user_info(pPlayer, "*bot", "0")
	//rg_reset_user_model(pPlayer, true)
	g_aPlayerData[pPlayer][pBotIndex] = g_aPlayerData[pPlayer][iUsedCount] = 0
}

PrintChatAll(const pPlayer, const szName[], const szNameBot[])
{
	new aPlayers[32], iCount, pReceiver
	get_players(aPlayers, iCount, "ch")		// skip bot's & hltv

	for(--iCount; iCount >= 0; iCount--)
	{
		pReceiver = aPlayers[iCount]
		if(pPlayer != pReceiver) {
			client_print_color(pReceiver, pPlayer, "^4* ^1Bot ^3%s ^1replaced with ^3%s", szNameBot, szName)
		}
	}
}

SetBotName(const pBot, const szName[])
{
	if(szName[0])
	{
		set_user_info(pBot, "name", szName)
		set_entvar(pBot, var_netname, szName)
	}
}

// checks if a space is vacant, by VEN
stock bool:IsFreeSpace(Float:vecOrigin[coord_e], const iHullNumber, const pSkipEnt = 0) 
{
	const pTR = 0 		// Global traceresult handle
	engfunc(EngFunc_TraceHull, vecOrigin, vecOrigin, DONT_IGNORE_MONSTERS, iHullNumber, pSkipEnt, pTR)

	return bool:(!get_tr2(pTR, TR_StartSolid) && !get_tr2(pTR, TR_AllSolid) && get_tr2(pTR, TR_InOpen))
}

stock ScenarioIcon(const pPlayer, const iStatus = 1)
{
	static iMsgIdScenario
	if(iMsgIdScenario > 0 || (iMsgIdScenario = get_user_msgid("Scenario")))
	{
		message_begin(MSG_ONE_UNRELIABLE, iMsgIdScenario, .player = pPlayer)
		write_byte(iStatus)
		write_string("hostage1")
		write_byte(150)
		message_end()
	}
}



