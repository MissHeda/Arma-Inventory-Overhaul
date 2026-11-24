#define COMPONENT compat_antistasi
#define COMPONENT_BEAUTIFIED AIO - Antistasi Ultimate
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// Antistasi's own files this addon runs, changed or wrapped (config.cpp, fnc_patched).
#define A3A_FILE_GATHERLOOT "\x\A3A\addons\scrt\Loot\fn_loot_gatherLoot.sqf"
#define A3A_FILE_PARADROP "\x\A3A\addons\scrt\Paradrop\fn_paradrop_jump.sqf"
#define A3A_FILE_MINESWEEP "\x\A3A\addons\core\functions\AI\fn_mineSweep.sqf"
#define A3A_FILE_USEMAGITEM "\x\A3A\addons\ultimate\functions\Utility\fn_useMagazineItem.sqf"
#define A3A_FILE_CANADDITEM "\x\A3A\addons\hals\Addons\store\functions\system\fn_canAddItem.sqf"
#define A3A_FILE_STOREMAIN "\x\A3A\addons\hals\Addons\store\functions\client\ui\fn_main.sqf"
#define A3A_FILE_RECEIVEITEMS "\x\A3A\addons\bazaar\functions\fn_receiveItems.sqf"

// Antistasi's plugin events for a player's own save data (core\Includes\cba_events.hpp): raised on the client, with
// the hash map to fill or the one saved.
#define A3A_EVENT_PLAYER_SAVE "A3A_event_clientPlayerSave"
#define A3A_EVENT_PLAYER_LOAD "A3A_event_clientPlayerLoad"

// After Antistasi's load event: its loadout is set by the server and has to arrive here first.
#define LOAD_DELAY 2

// How often Mag Repack's functions are looked at - they are made anew when its script runs again (a respawn).
#define MAGREPACK_TICK 5

// The arsenals, as aio_storage's ARSENAL_OPEN: nothing is turned into money while one is open.
#define ARSENAL_OPEN (!isNull (findDisplay 1127001) || {!isNull (uiNamespace getVariable ["RscDisplayArsenal", displayNull])})
