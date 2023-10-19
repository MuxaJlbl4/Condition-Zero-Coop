# Counter-Strike: Condition Zero Cooperative Patch

Cooperative patches for **Counter-Strike: Condition Zero**. Enables cooperative play for **Tour of Duty** missions.

## Showcase

- Left side: **Admin** `192.168.124.1`
- Right side: **Player** `192.168.124.160`

## Features
- 🎮 Free server slots for extra players
- ➕ Extra bots for each joined player
- 🎫 Fixed restart/continue messages
- 🍰 Shared Survival/In-a-Row tasks
- 🧊 Decreased freeze time
- ☠️ Shared round give up
- 🔦 Enabled flashlights
- 🗝️ No passwords
- ⏳ No pauses

## Requirements
- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80) for all teammates
- **LAN connection** with your teammates (physical or VPN)

## Installation and Usage
- **Admin**: Unpack **Condition Zero Coop.exe** to folder with **hl.exe** and start any career mission
- **Teammates**: Connect to Admin by `connect <IP>` or `Find Servers -> Lan`

## Useful Commands
Adjust settings via **coop.cfg**:
- `bots_per_player 2` - Add enemy bots on player join
- `motd_restart 1`- Show MotD on round restart
- `pausable 0|1`, `pause` - For manual pauses
- `player_kill` - Kill all players
- `spawn_info` - Map spawn count info
- `sv_lan 0` - For compatibility with Hamachi, VPN hosting and unofficial clients

## Limitations
- Mission change still needs teammates reconnection
- Teammates still can't view tasks
- Player's team is limited by 6 participants
- Bot addition is limited by [map spawns](Spawns.md) and profile names

## Building
1. Install:
	- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80)
	- [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS/releases/latest)
	- [Metamod-P](https://github.com/Bots-United/metamod-p/releases/latest)
	- [AMX Mod X 1.10.0 (Base Package)](https://www.amxmodx.org/downloads-new.php?branch=master)
	- [ReAPI AMXX](https://github.com/s1lentq/reapi/releases/latest)
	- [Orpheu](https://github.com/Arkshine/Orpheu/releases/latest)
2. Replace `08 83 FE 01 7D 05 BE 01` to `08 EB 03 90 90 90 BE 20` in **hw.dll**
3. Copy with replace repository contents to your Half-Life folder
4. Launch `Half-Life\czero\addons\amxmodx\scripting\cz_coop.bat` to compile [amxx plugin](czero/addons/amxmodx/scripting/cz_coop.sma)
