#include "script_component.hpp"

if (!hasInterface) exitWith {};

// Ravage defines its search action (fnc_lootSearchAction) when its loot module runs - for a player who joins later,
// or after a respawn, again. Made over every time it is new (fnc_patchAction).
[{call FUNC(patchAction)}, 1] call CBA_fnc_addPerFrameHandler;
