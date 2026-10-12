#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where the soldier is left when the window closes: the plain state of the stance he had when it opened,
 * with the weapon in his hands now - AmovP<stance>MstpS<low|ras|non>W<rfl|pst|lnr|non>Dnon. The lowered
 * state first, as he stood bent over his gear, then the raised one; a launcher has only the raised one,
 * empty hands the plain one.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The stance - "STAND", "CROUCH" or "PRONE" <STRING>
 *
 * Return Value:
 * The animation state, "" when there is none for this <STRING>
 *
 * Example:
 * [player, "CROUCH"] call einv_gui_fnc_restState;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_stance", "STAND", [""]]];

private _posture = switch (_stance) do {
    case "STAND": {"Perc"};
    case "CROUCH": {"Pknl"};
    case "PRONE": {"Ppne"};
    default {""};
};

private _weapon = currentWeapon _unit;

if (_posture isEqualTo "" || {_weapon isNotEqualTo "" && {_weapon isEqualTo binocular _unit}}) exitWith {""};

// The ways the hands can be, lowered first.
private _hands = switch (true) do {
    case (_weapon isEqualTo ""): {["SnonWnon"]};
    case (_weapon isEqualTo primaryWeapon _unit): {["SlowWrfl", "SrasWrfl"]};
    case (_weapon isEqualTo handgunWeapon _unit): {["SlowWpst", "SrasWpst"]};
    case (_weapon isEqualTo secondaryWeapon _unit): {["SlowWlnr", "SrasWlnr"]};
    default {["SnonWnon"]};
};

private _found = "";

{
    private _state = format ["Amov%1Mstp%2Dnon", _posture, _x];

    if (isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _state)) exitWith {
        _found = _state;
    };
} forEach _hands;

_found
