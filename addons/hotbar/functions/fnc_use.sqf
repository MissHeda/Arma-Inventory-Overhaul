#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Uses what lies on a slot, as its key does (fnc_onKey a frame after the press): a bandage on the part that
 * bleeds most, a grenade into the hand, a magazine into the weapon, a kit opened. What the class does is
 * fnc_useOf's answer, and each kind has a function of its own that answers [done, text]: fnc_useThrowable,
 * fnc_useMedical, fnc_useConsumable, fnc_useMagazine and fnc_useKit. A class that does nothing, or none
 * left, is refused here. A refusal shows on the bar as a line over the boxes, with the slot's box lit.
 *
 * A throwable in the hand (ACE's advanced throwing) is put away first for anything that needs the hands
 * - unless it is primed, which has to be thrown first.
 *
 * Arguments:
 * 0: Slot index, 0 to 6 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [2] call einv_hotbar_fnc_use;
 *
 * Public: Yes
 */

params [["_index", -1, [0]]];

if (_index < 0 || {_index >= SLOT_COUNT} || {!(call FUNC(isActive))}) exitWith {};

private _unit = ACE_player;
private _class = GVAR(slots) param [_index, ""];

if (_class isEqualTo "" || {!alive _unit}) exitWith {};

([_class] call FUNC(useOf)) params ["_kind"];

// Shown whatever happens: the player pressed a key and looks for the answer.
call FUNC(hudPing);

if (_kind isEqualTo "") exitWith {
    [_index, LLSTRING(Reason_NoUse), "warning"] call FUNC(flash);
};

if (([_class] call FUNC(count)) == 0) exitWith {
    [_index, LLSTRING(Reason_NoneLeft), "warning"] call FUNC(flash);
};

// What needs the hands puts a throwable away first.
if (_kind in ["medical", "consume", "reload"] && {_unit getVariable ["ace_advanced_throwing_inHand", false]}) then {
    if (_unit getVariable ["ace_advanced_throwing_primed", false]) exitWith {
        [_index, LLSTRING(Reason_Primed), "warning"] call FUNC(flash);
        _kind = "";
    };

    if (!isNil "ace_advanced_throwing_fnc_exitThrowMode") then {
        [_unit, "einv hotbar"] call ace_advanced_throwing_fnc_exitThrowMode;
    };
};

// Refused above, and said.
if (_kind isEqualTo "") exitWith {};

private _result = switch (_kind) do {
    case "throw": {[_unit, _class, _index] call FUNC(useThrowable)};
    case "medical": {[_unit, _class, _index] call FUNC(useMedical)};
    case "consume": {[_unit, _class, _index] call FUNC(useConsumable)};
    case "reload": {[_unit, _class, _index] call FUNC(useMagazine)};
    case "kit": {[_unit, _class, _index] call FUNC(useKit)};
    default {[false, LLSTRING(Reason_NoUse)]};
};

_result params [["_done", false], ["_text", ""]];

if (!_done) exitWith {
    [_index, _text, "warning"] call FUNC(flash);
};

// ACE's progress bar takes over for these; the bar mirrors it.
if (_kind in ["medical", "consume"]) then {
    GVAR(busy) = [_index, diag_tickTime];
};

if (_text isNotEqualTo "") then {
    [_index, _text, "text"] call FUNC(flash);
};
