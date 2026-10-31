#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The hidden holder of a unit, read and made well-formed: what the Strict setting keeps out of its uniform,
 * vest and backpack (fnc_opStrict). The holder is no object - it is the public variable einv_storage_hidden
 * on the unit, [[uniform list, vest list, backpack list], [uniform container, vest container, backpack
 * container]]: each list [[class, count, rounds], ...] with -1 rounds for an item that is no magazine, and
 * for each list the container object its things were taken out of (fnc_hiddenPut), so a container that was
 * swapped, dropped or replaced since is told from the one worn now.
 *
 * A copy: whoever changes it writes it back with fnc_hiddenWrite. Malformed entries are left out.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [[uniform, vest, backpack] lists, [uniform, vest, backpack] containers] <ARRAY>
 *
 * Example:
 * [player] call einv_storage_fnc_hiddenLists;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _empty = [[[], [], []], [objNull, objNull, objNull]];

if (isNull _unit) exitWith {_empty};

private _data = _unit getVariable [QGVAR(hidden), []];

if !(_data isEqualTypeArray [[], []]) exitWith {_empty};

_data params [["_lists", [], [[]]], ["_containers", [], [[]]]];

private _outLists = [0, 1, 2] apply {
    private _list = _lists param [_x, [], [[]]];

    (_list select {
        _x isEqualTypeArray ["", 0, 0] && {(_x select 0) isNotEqualTo ""} && {(_x select 1) > 0}
    }) apply {+_x}
};

private _outContainers = [0, 1, 2] apply {
    private _container = _containers param [_x, objNull];

    if (_container isEqualType objNull) then {_container} else {objNull}
};

[_outLists, _outContainers]
