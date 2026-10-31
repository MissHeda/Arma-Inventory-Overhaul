#include "script_component.hpp"

// WebKnight's Two Primary Weapons keeps the weapon on the back in a box hanging on the soldier (DummyWeapon_Wbk,
// its inventory locked) and the weapon itself in his variable WBK_SecondWeapon. The box is never loot here: the
// nearby list and the ground leave out whatever hangs on someone (einv_storage_fnc_getNearby, fnc_getGroundHolder).
//
// Its "Put" handler brings the weapon on the back into the hands when the primary weapon was put away and the hands
// are empty. This window moves things without the engine's "Put", so the same is done here when a move of the window
// leaves the primary slot empty.
if (!hasInterface) exitWith {};

["loadout", {_this call FUNC(onLoadout)}] call CBA_fnc_addPlayerEventHandler;
