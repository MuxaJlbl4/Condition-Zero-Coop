# Counter-Strike: Condition Zero Cooperative Patch

Cooperative patches for **Counter-Strike: Condition Zero**. Enables cooperative play for **Tour of Duty** missions.

https://github.com/MuxaJlbl4/Condition-Zero-Coop/assets/20092823/f141a596-781c-4f08-8b7b-f7462a6a2d7a

- Left side: **Admin** `192.168.124.1`
- Right side: **Player** `192.168.124.160`

## Features
- 🎮 Maximum slots and spawns for extra players
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
- **Admin**: Unpack [Condition-Zero-Coop.exe](/releases/latest) to folder with **hl.exe** and start any career mission
- **Teammates**: Connect to Admin by `connect <IP>` or `Find Servers -> Lan`

## CVars
| CVar | Default Value | Description |
| ---- | ------------- | ----------- |
| bots_per_player_easy | 5 | Add enemy bots on player join (easy campaign) |
| bots_per_player_normal | 4 | Add enemy bots on player join (normal campaign) |
| bots_per_player_hard | 3 | Add enemy bots on player join (hard campaign) |
| bots_per_player_expert | 2 | Add enemy bots on player join (expert campaign) |
| motd_restart | 1 | Show MotD on round restart (1 - on; 0 - off) |

## Commands
| Command | Description |
| ------- | ----------- |
| map_info | Show map name and spawn count |
| player_kill | Kill all players |

## Notes
- Adjust settings and difficulty balance via [coop.cfg](czero/coop.cfg)
- Mission change still needs teammates reconnection
- Teammates still can't view tasks
- Max players = 32 (GoldSrc limit)

## Building
1. Install:
	- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80)
	- [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS/releases/latest)
	- [Metamod-P](https://github.com/Bots-United/metamod-p/releases/latest)
	- [AMX Mod X 1.10.0 (Base Package)](https://www.amxmodx.org/downloads-new.php?branch=master)
	- [ReAPI AMXX](https://github.com/s1lentq/reapi/releases/latest)
	- [Orpheu](https://github.com/Arkshine/Orpheu/releases/latest)
2. Replace `08 83 FE 01 7D 05 BE 01` to `08 EB 03 90 90 90 BE 20` in **hw.dll**
3. Copy (with replace) repository content to your Half-Life folder
4. Launch `Half-Life\czero\addons\amxmodx\scripting\autospawnpoints.bat` to compile [Autospawnpoints](https://dev-cs.ru/resources/1253) plugin
5. Launch `Half-Life\czero\addons\amxmodx\scripting\cz_coop.bat` to compile [Condition Zero Coop](czero/addons/amxmodx/scripting/cz_coop.sma) plugin

## Other Links
- [Steam Guide (En)](https://steamcommunity.com/sharedfiles/filedetails/?id=3059078485)
- [Steam Guide (Ru)](https://steamcommunity.com/sharedfiles/filedetails/?id=3059084601)

## Special Thanks
- [Arkshine](https://github.com/Arkshine)
- [dystopm](https://github.com/dystopm)
- [fl0werD](https://github.com/fl0werD)
- [iPlague](https://roadtoglory.ru/profile?id=1)
- [jkivilin](https://github.com/jkivilin)
- [LunaTheReborn](https://forums.alliedmods.net/member.php?u=297878)
- [s1lentq](https://github.com/s1lentq)
- [Vaqtincha](https://github.com/Vaqtincha)
- [wopox1337](https://github.com/wopox1337)
