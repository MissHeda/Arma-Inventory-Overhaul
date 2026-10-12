#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * For missions: puts an item from a container on a unit, into one of its equipment slots (ids as in
 * fnc_getSlot), as a transaction (fnc_request): taken out where it lies ("take", or a kit's own op),
 * put on ("putOn", where the unit is local), and whatever was in the slot put where the item lay - a
 * swap; with no room there it settles like anything else that found no place. The window no longer
 * calls this.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Slot id <STRING>
 * 2: Holder the item lies in - a container, or a kit's key <OBJECT or STRING>
 * 3: Entry <HASHMAP>
 *
 * Return Value:
 * "" when it was put on here and then, "Requested" when it went to the server and is put on shortly,
 * else why not ("NoFit", "Gone", "OutOfReach", "Moved", "NotReady", "Bounced" - it went back -,
 * "Failed") <STRING>
 *
 * Example:
 * [player, "primary_optic", backpackContainer player, _entry] call einv_storage_fnc_equip;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_slotId", "", [""]],
    ["_from", objNull, [objNull, ""]],
    ["_entry", createHashMap, [createHashMap]]
];

if (isNull _unit || {count _entry == 0}) exitWith {"Failed"};
if (if (_from isEqualType "") then {_from isEqualTo ""} else {isNull _from}) exitWith {"Failed"};
if !([_unit, _slotId, _entry getOrDefault ["class", ""]] call FUNC(slotAccepts)) exitWith {"NoFit"};

// The op of a holder's type: storage's own for a container, the type's for a kit.
private _fnc_op = {
    params ["_holder", "_op"];

    if (_holder isEqualType "") then {
        (GVAR(holderTypes) getOrDefault [(_holder splitString ":") param [0, ""], createHashMap]) getOrDefault [_op, ""]
    } else {
        _op
    }
};

private _fromRoot = [_from] call FUNC(rootOf);
private _take = [_from, "take"] call _fnc_op;
private _put = [_from, "put"] call _fnc_op;

if (isNull _fromRoot || {_take isEqualTo ""} || {_put isEqualTo ""}) exitWith {"Failed"};

private _entryArray = [_entry] call FUNC(entryToArray);

// The old item goes where the new one lay - free once a whole tile left -, else the first free spot.
private _former = [];

if ((_entry getOrDefault ["col", -1]) >= 0 && {(_entry getOrDefault ["block", -1]) >= 0}) then {
    _former = [_entry get "col", _entry get "row", _entry get "block"];
};

private _fnc_putOld = {
    params ["_ref"];

    [_put, [[_from, _ref, _former, false], [_from, _ref, _former]] select (_from isEqualType "")]
};

// One root: one phase. Else the item travels to the unit's machine and the old item back.
private _phases = if (_fromRoot isEqualTo _unit) then {
    [[_unit, [
        [_take, [_from, _entryArray, 1]],
        ["putOn", [_unit, _slotId, ["#ref", 0, 0, 0]]],
        [["#ref", 0, 1, 0]] call _fnc_putOld
    ]]]
} else {
    [
        [_fromRoot, [[_take, [_from, _entryArray, 1]]]],
        [_unit, [["putOn", [_unit, _slotId, ["#ref", 0, 0, 0]]]]],
        [_fromRoot, [[["#ref", 1, 0, 0]] call _fnc_putOld]]
    ]
};

// Taking out and putting on decide; where the old item went does not.
private _decisive = if (_fromRoot isEqualTo _unit) then {[[0, 0], [0, 1]]} else {[[0, 0], [1, 0]]};
private _answers = [];
private _id = [_phases, {(_this select 3) pushBack (_this select 1)}, _answers, false, _unit] call FUNC(request);

if (_id isEqualTo "") exitWith {"Failed"};
if (_answers isEqualTo []) exitWith {"Requested"};

private _perPhase = (_answers select 0) param [0, []];
private _status = "";

{
    _x params ["_phase", "_op"];

    private _said = ((_perPhase param [_phase, []]) param [_op, []]) param [0, "Failed"];

    if (_said isNotEqualTo "") exitWith {
        _status = _said;
    };
} forEach _decisive;

_status
