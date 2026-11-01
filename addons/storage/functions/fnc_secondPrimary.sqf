#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The second primary weapon a unit carries on its back, as WebKnight's or KJW's Two Primary Weapons keeps it -
 * outside the loadout, in that mod's own variables and a holder hanging on the soldier. The window shows it as a
 * slot of its own, "primary2", next to the primary (fnc_getEquipment, fnc_getSlot).
 *
 * Asked of the compat addon of whichever of the two mods is loaded (GVAR(secondPrimaryMod), filled in its preInit);
 * with neither loaded no unit has the slot. A mod that knows the back weapon only of the player - KJW's - gives
 * every other unit none either.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [has the slot <BOOL>, weapon <ARRAY>] - the weapon as weaponsItems gives it, [class, muzzle, rail, optic,
 * [magazine, rounds] or [], [second magazine, rounds] or [], bipod], [] when the slot is empty
 *
 * Example:
 * [player] call aio_storage_fnc_secondPrimary;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

private _get = GVAR(secondPrimaryMod) getOrDefault ["get", {}];

if (isNull _unit || {_get isEqualTo {}}) exitWith {[false, []]};

private _answer = [_unit] call _get;

if (isNil "_answer" || {!(_answer isEqualType [])}) exitWith {[false, []]};

_answer params [["_has", false, [false]], ["_weapon", [], [[]]]];

if (!_has) exitWith {[false, []]};

// Anything that names no weapon is an empty slot.
if ((_weapon param [0, "", [""]]) isEqualTo "") exitWith {[true, []]};

// A weapon array always has its seven parts here, whatever form the mod wrote it in. WebKnight's writes the
// magazine of an empty weapon as [nil, 0]: a magazine that names no class is none.
_weapon = [_weapon] call FUNC(normalizeWeapon);

{
    private _part = _weapon select _x;

    if !(_part isEqualType [] && {(_part param [0, "", [""]]) isNotEqualTo ""}) then {
        _weapon set [_x, []];
    };
} forEach [4, 5];

{
    if !((_weapon select _x) isEqualType "") then {
        _weapon set [_x, ""];
    };
} forEach [1, 2, 3, 6];

[true, _weapon]
