#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "fit": puts a part on a weapon that was taken out of a container, or takes one off - nothing in the world changes here, the
 * weapon and the part are payloads in hand (the takes before it), and what it produces goes back by the puts after it
 * (aio_gui_fnc_doFit). Produced: [the weapon with its new part, what was on that part before] - only the weapon when nothing was.
 * A part that does not fit (fnc_partFits) is "Failed", and both come back as they were, so they settle back where they came
 * from. A magazine goes on with its rounds; one taken off comes off with its rounds.
 *
 * Arguments:
 * 0: Args, [weapon payload, part payload or [] to take the part off, part - "muzzle", "optic", "rail", "bipod", "mag", "mag2"]
 *    <ARRAY>
 * 1: Context (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *
 * Example:
 * [[_weaponPayload, _opticPayload, "optic"], _context] call aio_storage_fnc_opFit;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];

_args params [["_weapon", [], [[]]], ["_payload", [], [[]]], ["_part", "", [""]]];

private _inputs = [_weapon, _payload] select {_x isNotEqualTo []};
private _index = ["", "muzzle", "rail", "optic", "mag", "mag2", "bipod"] find _part;

if ((_weapon param [0, ""]) isNotEqualTo "weapon" || {_index < 1}) exitWith {["Failed", _inputs, []]};

private _array = +(_weapon param [1, []]);
private _class = _array param [0, "", [""]];

if (_class isEqualTo "") exitWith {["Failed", _inputs, []]};

private _magazine = _index in [4, 5];

// The new part: an item of one, or a magazine with its rounds.
private _new = ["", []] select _magazine;

if (_payload isNotEqualTo []) then {
    _payload params [["_type", ""], ["_newClass", "", [""]], ["_third", []]];

    if (_magazine) then {
        if (_type isEqualTo "magazine") then {
            _new = [_newClass, (_third param [0, getNumber (configFile >> "CfgMagazines" >> _newClass >> "count")]) max 0];
        };
    } else {
        if (_type isEqualTo "item" && {_third isEqualTo 1 || {_third isEqualType 0 && {_third <= 1}}}) then {
            _new = _newClass;
        };
    };
};

private _newClass = [_new, _new param [0, ""]] select _magazine;

if (_payload isNotEqualTo [] && {_newClass isEqualTo "" || {!([_class, _part, _newClass] call FUNC(partFits))}}) exitWith {
    ["Failed", _inputs, []]
};

// What was on the part, as a payload of its own.
private _old = _array param [_index, ["", []] select _magazine];
private _oldPayload = [];

if (_magazine) then {
    if (_old isEqualType [] && {(_old param [0, ""]) isNotEqualTo ""}) then {
        _oldPayload = ["magazine", _old select 0, [_old param [1, 0]]];
    };
} else {
    if (_old isEqualType "" && {_old isNotEqualTo ""}) then {
        _oldPayload = ["item", _old, 1, []];
    };
};

_array set [_index, _new];

["", [["weapon", _array]] + ([[_oldPayload], []] select (_oldPayload isEqualTo [])), []]
