#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes an item off a unit's slot into a holder or onto the ground: off where the unit is local - the
 * player's own here, a body or a living person on their machine -, in where the target's root is local
 * (fnc_sendMoves). The window follows the answer (fnc_afterAction).
 *
 * Checked here first, so the hint says at once what this machine can tell: a living person's gear as
 * the settings say and while in reach (fnc_checkTouch) - their machine asks again -, a uniform, vest or
 * backpack never into itself or into anything lying in it, room for its load (einv_storage_fnc_roomByWeight;
 * a refusal for weight says how much is missing). The radio slot ACRE2 keeps for itself comes off never
 * (einv_compat_acre_fnc_isFixedSlot - only when that addon is loaded).
 *
 * "ground" is the surface under the feet, or the vehicle's cargo while seated. A ground pile the window
 * does not show, or none at all, stands for the ground as well (einv_storage_fnc_getGroundHolder, as
 * callers used to ask it).
 *
 * Arguments:
 * 0: Whose slot it is <OBJECT>
 * 1: Slot id <STRING>
 * 2: Holder it goes to - a container, a key like "kit:..." - or "ground" <OBJECT or STRING>
 * 3: Cell [col, row, compartment] - with [.., width, height] when it lies turned there - or [] to let
 *    the layout find one <ARRAY> (default: [])
 *
 * Return Value:
 * Asked for <BOOL>
 *
 * Example:
 * [player, "headgear", backpackContainer player, []] call einv_gui_fnc_doUnequip;
 *
 * Public: No
 */

params ["_unit", "_slot", "_to", ["_cell", []]];

// ACRE2's dummy radio stays where it is.
if (!isNil QEFUNC(compat_acre,isFixedSlot) && {[_unit, _slot] call EFUNC(compat_acre,isFixedSlot)}) exitWith {false};

private _entry = [_unit, _slot] call EFUNC(storage,getSlot);

if (count _entry == 0) exitWith {false};

if (
    _to isEqualType objNull
    && {
        isNull _to
        || {[_to] call EFUNC(storage,isGroundHolder) && {(uiNamespace getVariable [QGVAR(grids), []]) findIf {(_x getOrDefault ["container", objNull]) isEqualTo _to} < 0}}
    }
) then {
    _to = "ground";
};

private _why = [_unit, "worn"] call FUNC(checkTouch);
private _details = [];

if (_why isEqualTo "" && {_to isEqualType objNull}) then {
    _why = [_to, "items"] call FUNC(checkTouch);
};

if (_why isNotEqualTo "") exitWith {
    [_why] call FUNC(flashHint);
    false
};

if (_to isEqualType objNull) then {
    // Not into what comes off with it: a vest lying in the uniform taken off would be gone with it.
    private _inside = _entry getOrDefault ["container", objNull];

    if (!isNull _inside && {_to isEqualTo _inside || {[_to, _inside] call EFUNC(storage,liesIn)}}) exitWith {
        _why = "IntoItself";
    };

    // Too heavy says by how much, a backpack into a backpack says that.
    private _room = [_to, _entry] call EFUNC(storage,roomByWeight);

    if !(_room get "fits") then {
        _why = _room get "reason";

        if (_why isEqualTo "TooHeavy") then {
            _details = [_to, [_entry] call EFUNC(storage,entryToArray), 1];
        };
    };
};

if (_why isNotEqualTo "") exitWith {
    [_why, _details] call FUNC(flashHint);
    false
};

[[createHashMapFromArray [
    ["kind", "unequip"], ["unit", _unit], ["slot", _slot], ["to", _to], ["cell", _cell]
]]] call FUNC(sendMoves)
