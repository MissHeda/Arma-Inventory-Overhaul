#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Adds another mod's reason to keep a unit out of a container, asked by fnc_canReach on every machine -
 * the window, the engine's inventory gate and the guard on every op. The code gets the unit and the
 * container at the top of the chain (the crate or vehicle, never a backpack opened inside it) and answers
 * the text that names the reason, or "" when the unit may. Everything it reads must be the same on
 * every machine: the guard asks it where the op runs.
 * (einv_compat_ace_vehiclelock adds ACE's vehicle lock this way.)
 *
 * Arguments:
 * 0: Provider, given [unit, container] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_unit", "_container"]; ["", "No key"] select (locked _container == 2)}] call einv_locks_fnc_addProvider;
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (_code isEqualTo {}) exitWith {};

GVAR(providers) pushBackUnique _code;
