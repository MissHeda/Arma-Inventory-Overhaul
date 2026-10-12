#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Plays the sound of an answer that is finished (fnc_afterAction): of the first item that really moved,
 * and only one per answer - a group dragged, Take all and a whole crate sound like their first item, each
 * chunk of BATCH_MAX moves once. Nothing when all of it was refused (the hint says why) or nothing was
 * asked for a sound.
 *
 * A magazine loaded into the weapon in the hands first tries that weapon's own reload (fnc_playReload,
 * with its gesture) and stops there when it played; else the generic sound of the action
 * (fnc_playSound). A suppressor put on or taken off the weapon in the hands also does the mount gesture
 * (fnc_gesture); the other attachments have none, as Arma's own are long full-body moves.
 *
 * Arguments:
 * 0: How the moves of the answer sound, [[action, class, holder, slot, unit], ...] - fnc_feelFor, in the order
 *    of the moves <ARRAY>
 * 1: How many item moves of the answer ended well <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_feels, 1] call einv_gui_fnc_feelAnswer;
 *
 * Public: No
 */

params [["_feels", [], [[]]], ["_moved", 0, [0]]];

if (_moved < 1 || {_feels isEqualTo []}) exitWith {};

(_feels select 0) params [["_action", "", [""]], ["_class", "", [""]], ["_holder", objNull, [objNull]], ["_slot", "", [""]], ["_unit", objNull, [objNull]]];

if (_action isEqualTo "") exitWith {};

// A magazine into the weapon in the hands: that weapon's own reload.
if (_action in ["loadMag", "loadMagHandgun", "loadMagLauncher", "loadMagUgl"] && {[_unit, _slot] call FUNC(playReload)}) exitWith {};

[_action, _class, _holder] call FUNC(playSound);

// A suppressor screwed on or off the weapon in the hands.
if (_action in ["attach", "detach"] && {((_slot splitString "_") param [1, ""]) isEqualTo "muzzle"}) then {
    private _weapon = switch ((_slot splitString "_") param [0, ""]) do {
        case "primary": {primaryWeapon _unit};
        case "handgun": {handgunWeapon _unit};
        case "launcher": {secondaryWeapon _unit};
        default {""};
    };

    if (_weapon isNotEqualTo "" && {currentWeapon _unit isEqualTo _weapon}) then {
        [_unit, ["GestureDismountMuzzle", "GestureMountMuzzle"] select (_action isEqualTo "attach")] call FUNC(gesture);
    };
};
