#include "script_component.hpp"

// Mavic 3 (Improved) turns its item into a drone from the player's "Put" event: the item lands on a plain
// GroundWeaponHolder and its function Mavic_fnc_createMavicOnItemCheck removes it and creates the drone. This
// window puts things on the ground through the storage (a scripted pile, no engine "Put"), so the storage's
// event is answered here instead: raised where the pile is made (the server), the item taken out of the pile
// there and the drone deployed by the mod's own function on the machine of the unit that dropped it - the
// machine the mod runs it on.
[QEGVAR(storage,groundPut), {_this call FUNC(onGroundPut)}] call CBA_fnc_addEventHandler;

// On the unit's machine: the drone is deployed.
[QGVAR(deploy), {_this call FUNC(deploy)}] call CBA_fnc_addEventHandler;
