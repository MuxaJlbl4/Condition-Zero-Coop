![Header](Header.png)

# Counter-Strike: Condition Zero Cooperative Patch

Cooperative patches for **Counter-Strike: Condition Zero**. Enables cooperative play for **Tour of Duty** missions and allows to play with **Yet Another POD-Bots**.

https://github.com/MuxaJlbl4/Condition-Zero-Coop/assets/20092823/f141a596-781c-4f08-8b7b-f7462a6a2d7a

- Left side: **Admin** `192.168.124.1`
- Right side: **Player** `192.168.124.160`
- Added extra enemy bots on **Player** join

## Features
- 🏃‍♀️ Compatibility with [Yet Another POD-Bot (YaPB)](https://yapb.readthedocs.io/en/latest/index.html)
- 🎁 [25th Anniversary](https://half-life.com/en/halflife25) and [Legacy](https://steamdb.info/app/80/depots/?branch=steam_legacy) versions support
- 🎮 Maximum slots and spawns for extra players
- 😎 Singleplayer and custom campaign support
- ➕ Extra bots addition for each joined player
- 🍰 Simplified survival and in-a-row tasks
- 🎫 Fixed restart and continue messages
- ♟️ Play as bot after death
- 🧊 Decreased freeze time
- 🔦 Custom game config
- 🦘 No jump slowdown
- 🗝️ No passwords
- ⏳ No pauses

## Requirements
- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80) for every participant
- **LAN connection** with your teammates (physical or virtual)

## Installation and Usage
- **Admin**: Install [Condition-Zero-Coop.exe](https://github.com/MuxaJlbl4/Condition-Zero-Coop/releases/latest) to your **Half-Life** folder and start any career mission
- **Teammates**: Connect to Admin by `connect <IP>` or `Find Servers -> Lan`

## CVars
All plugin settings should be configured via [coop.cfg](czero/coop.cfg) file:

### Variables
| CVar | Default Value | Description |
| ---- | :-----------: | ----------- |
| `bots_custom_ai` | 0 | Custom bots AI:<br>**1** - **YaPB**; **0** - **zBot** (default AI) |
| `bots_per_player` | 3 | Extra bots on player join<br>Adds the specified number of enemy bots with campaign difficulty skill |
| `motd_restart` | 1 | Show MotD on mission restart:<br>**1** - **on**; **0** - **off** |
| `simple_hostages` | 1 | Hostage tasks can be completed by:<br>**1** - **players & YaPB** bots; **0** - **players** only |
| `simple_survival` | 1 | Simplified survival and in-a-row tasks. Task fails when:<br>**1** - **all** players are dead; **0** - **any** player is dead |

### Auxiliary
| CVar | Description |
| ---- | ----------- |
| `bot_difficulty` | Extra bots and YaPB difficulty:<br>**0** - **Easy/Newbie**; **1** - **Medium/Average**; **2** - **Hard/Normal**;<br>**3** - **Expert/Professional**; **4** - **Expert/Godlike (YaPB)** |
| `mp_friendlyfire` | Allow friendly fire:<br>**1** - **on**; **0** - **off** |

### Commands
| Command | Description |
| ------- | ----------- |
| `map_info` | Show map name and spawn count |
| `player_kill` | Kill all players (non-bots) |

## Notes
- ⚙️ Additional settings should be configured via [coop.cfg](czero/coop.cfg) and [game.cfg](czero/game.cfg)
- ⚡ To play as a bot: switch to spectating for your bot and press **`N`**
- 🪟 For latest [25th Anniversary Update](https://half-life.com/en/halflife25) - Choose **Steam** installation
- ⏳ For [Pre-25th Anniversary](https://steamdb.info/app/80/depots/?branch=steam_legacy) - Choose **Steam Legacy** installation
- 🍌 More missions: [gamebanana.com](https://gamebanana.com/mods/cats/2547?_sSort=Generic_MostLiked)
- 🟣 Steam guides: [Eng](https://steamcommunity.com/sharedfiles/filedetails/?id=3059078485); [Rus](https://steamcommunity.com/sharedfiles/filedetails/?id=3059084601)

## Limitations
- 🔄 Mission change requires teammates reconnection
- 👀 Teammates can't view current tasks
- 👯‍♀ Max players = 32

## Manual Building
1. Install:
	- [Counter-Strike: Condition Zero](https://store.steampowered.com/app/80)
	- [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS)
	- [Metamod-R](https://github.com/theAsmodai/metamod-r)
	- [AMX Mod X](https://www.amxmodx.org/downloads-new.php?branch=master) - Base Package + Counter-Strike
	- [Orpheu](https://github.com/Arkshine/Orpheu)
	- [ReAPI](https://github.com/rehlds/ReAPI)
	- [YaPB](https://github.com/yapb/yapb)
	
 	For [ReGameDLL_CS](https://github.com/s1lentq/ReGameDLL_CS) build **Release Play** version with **Visual Studio 2015 Update 3** and modified line in [`regamedll\dlls\hostage\hostage.cpp`](https://github.com/rehlds/ReGameDLL_CS/blob/master/regamedll/dlls/hostage/hostage.cpp#L31):
 
	```cpp
	cvar_t cv_hostage_ai_enable = { "hostage_ai_enable", "1", 0, 1.0f, nullptr };
	```
 
2. Copy (with replace) repository content to your `Half-Life` folder
3. For **maxplayers** patch, replace hex bytes in your `Half-Life\hw.dll` file and update corresponding [dlls](dlls):
	- `3B F0 0F 4C F0 A1` to `BE 20 00 00 00 A1` for [25th Anniversary](https://half-life.com/en/halflife25) version
	- `08 83 FE 01 7D 05 BE 01` to `08 EB 03 90 90 90 BE 20` for [Pre-25th Anniversary](https://steamdb.info/app/80/depots/?branch=steam_legacy) version
4. Build plugins:
	- [Condition Zero Coop](czero/addons/amxmodx/scripting/cz_coop.sma) with [cz_coop.bat](czero/addons/amxmodx/scripting/cz_coop.bat)
	- [Autospawnpoints](https://dev-cs.ru/resources/1253) with [autospawnpoints.bat](czero/addons/amxmodx/scripting/autospawnpoints.bat)
	- [Bot Features](https://dev-cs.ru/resources/44/) with [botfeatures.bat](czero/addons/amxmodx/scripting/botfeatures.bat)
	- [No Slow Down](https://dev-cs.ru/threads/4088/page-2#post-95000) with [noslowdown.bat](czero/addons/amxmodx/scripting/noslowdown.bat)
5. Check `mp.dll` with [Signatures.asm](Signatures.asm) and edit [Orpheu config files](czero/addons/amxmodx/configs/orpheu) if it's required
6. Build [Condition-Zero-Coop.iss](Condition-Zero-Coop.iss) with [Inno Setup](https://jrsoftware.org/isinfo.php) to make the installer

## Special Thanks
- [Arkshine](https://github.com/Arkshine)
- [dystopm](https://github.com/dystopm)
- [fl0werD](https://github.com/fl0werD)
- [iPlague](https://roadtoglory.ru/profile?id=1)
- [jeefo](https://github.com/jeefo)
- [jkivilin](https://github.com/jkivilin)
- [LunaTheReborn](https://forums.alliedmods.net/member.php?u=297878)
- [s1lentq](https://github.com/s1lentq)
- [SSX](https://dev-cs.ru/members/228)
- [theAsmodai](https://github.com/theAsmodai)
- [Vaqtincha](https://github.com/Vaqtincha)
- [wopox1337](https://github.com/wopox1337)
