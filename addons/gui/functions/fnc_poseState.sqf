#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The state of Arma's own inventory pose for a stance and the weapon in the hands: the engine's "Gear"
 * targets of CfgMovesMaleSdr, AinvP<stance>MstpS<ras|non>W<rfl|pst|lnr|non>Dnon, with the weapon lowered.
 * A rifle in the hands gives the rifle pose, a pistol the pistol pose, a launcher the launcher pose (none
 * lying down), no weapon the empty-handed one; the binocular has none.
 *
 * Arguments:
 * 0: The unit <OBJECT>
 * 1: The stance - "STAND", "CROUCH" or "PRONE" <STRING>
 *
 * Return Value:
 * The animation state, "" when there is none for this <STRING>
 *
 * Example:
 * [player, "CROUCH"] call einv_gui_fnc_poseState;
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

private _hands = switch (true) do {
    case (_weapon isEqualTo ""): {"SnonWnon"};
    case (_weapon isEqualTo primaryWeapon _unit): {"SrasWrfl"};
    case (_weapon isEqualTo handgunWeapon _unit): {"SrasWpst"};
    case (_weapon isEqualTo secondaryWeapon _unit): {"SrasWlnr"};
    default {"SnonWnon"};
};

private _state = format ["Ainv%1Mstp%2Dnon", _posture, _hands];

["", _state] select (isClass (configFile >> "CfgMovesMaleSdr" >> "States" >> _state))
