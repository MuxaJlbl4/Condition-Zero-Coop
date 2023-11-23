# Counter-Strike: Condition Zero Cooperative Patch

Cooperative patches for **Counter-Strike: Condition Zero**. Enables cooperative play for **Tour of Duty** missions.

https://github.com/MuxaJlbl4/Condition-Zero-Coop/assets/20092823/f141a596-781c-4f08-8b7b-f7462a6a2d7a

- Left side: **Admin** `192.168.124.1`
- Right side: **Player** `192.168.124.160`
  
Automatically added 2 easy bots (CVar `bots_per_player_easy 2`)

## Features
- 🎮 Maximum slots and spawns for extra players
- ➕ Extra bots addition for each joined player
- 🍰 Simplified survival and in-a-row tasks
- 🎫 Fixed restart and continue messages
- 🧊 Decreased freeze time
- ☠️ Shared round give up
- 🔦 Enabled flashlights
- 🗝️ No passwords
- ⏳ No pauses

## Requirements
- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80) for all teammates
- **LAN connection** with your teammates (physical or VPN)

## Installation and Usage
- **Admin**: Install [Condition-Zero-Coop.exe](https://github.com/MuxaJlbl4/Condition-Zero-Coop/releases/latest) to your **Half-Life** folder and start any career mission
- **Teammates**: Connect to Admin by `connect <IP>` or `Find Servers -> Lan`

## CVars
| CVar | Default Value | Description |
| ---- | ------------- | ----------- |
| bots_per_player_easy | 5 | Extra bots on player join (for **easy** campaign) |
| bots_per_player_normal | 4 | Extra bots on player join (for **normal** campaign) |
| bots_per_player_hard | 3 | Extra bots on player join (for **hard** campaign) |
| bots_per_player_expert | 2 | Extra bots on player join (for **expert** campaign) |
| motd_restart | 1 | Show MotD on mission restart (**1** - **on**; **0** - **off**) |
| simple_survival | 1 | Simplified survival and in-a-row tasks. Task fails when: <br>**1** - **all** players are dead; **0** - **any** player is dead |

## Commands
| Command | Description |
| ------- | ----------- |
| map_info | Show map name and spawn count |
| player_kill | Kill all players (non-bots) |

## Note from Valve
Many GoldSrc mods, Counter-Strike included, may still have compatibility issues with the [updated version of the Half-Life engine](https://half-life.com/en/halflife25). While we work on improving mod support it is advisable to install the beta "steam_legacy" build of Half-Life (which can be selected in the game's properties page) when playing mods.

## Notes
- 📝 Adjust settings and difficulty balance via [coop.cfg](czero/coop.cfg)
- 🪟 Tested with Windows [Aug 2020 Steam version](https://steamcommunity.com/games/80/announcements/detail/2773608655118460844)
- 🍌 More missions: [gamebanana.com](https://gamebanana.com/mods/cats/2547?_sSort=Generic_MostLiked)
- 🟣 Steam guides: [Eng](https://steamcommunity.com/sharedfiles/filedetails/?id=3059078485); [Rus](https://steamcommunity.com/sharedfiles/filedetails/?id=3059084601)

## Limitations
- 🔄 Mission change requires teammates reconnection
- 👀 Teammates can't view tasks
- 👯‍♀ Max players = 32

## Building
1. Install:
	- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80)
	- [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS/releases/latest)
	- [Metamod-P](https://github.com/Bots-United/metamod-p/releases/latest)
	- [AMX Mod X 1.10.0 (Base Package)](https://www.amxmodx.org/downloads-new.php?branch=master)
	- [ReAPI AMXX](https://github.com/s1lentq/reapi/releases/latest)
	- [Orpheu](https://github.com/Arkshine/Orpheu/releases/latest)
2. Copy (with replace) repository content to your `Half-Life` folder
3. Replace hex bytes `08 83 FE 01 7D 05 BE 01` to `08 EB 03 90 90 90 BE 20` in your `Half-Life\hw.dll` file
4. Launch `Half-Life\czero\addons\amxmodx\scripting\autospawnpoints.bat` to compile [Autospawnpoints](https://dev-cs.ru/resources/1253) plugin
5. Launch `Half-Life\czero\addons\amxmodx\scripting\cz_coop.bat` to compile [Condition Zero Coop](czero/addons/amxmodx/scripting/cz_coop.sma) plugin
6. Compile `Half-Life\Condition-Zero-Coop.iss` with [Inno Setup](https://jrsoftware.org/isinfo.php)

## Special Thanks
[Arkshine](https://github.com/Arkshine) · [dystopm](https://github.com/dystopm) · [fl0werD](https://github.com/fl0werD) · [iPlague](https://roadtoglory.ru/profile?id=1) · [jkivilin](https://github.com/jkivilin) · [LunaTheReborn](https://forums.alliedmods.net/member.php?u=297878) · [s1lentq](https://github.com/s1lentq) · [Vaqtincha](https://github.com/Vaqtincha) · [wopox1337](https://github.com/wopox1337)
