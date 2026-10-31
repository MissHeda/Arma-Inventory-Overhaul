#define COMPONENT locks
#define COMPONENT_BEAUTIFIED EINV - Locks
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// How often a client looks again whether the player may open each locked object, in seconds - side,
// group, admin login, Zeus and respawn have no event of their own (fnc_refreshAll).
#define LOCK_RECHECK 1

// How deep a container may lie inside a locked one and still count as locked (fnc_lockHolder).
#define MAX_DEPTH 3
