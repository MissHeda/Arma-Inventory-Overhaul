#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives a unit's hidden holder back to its containers at once, outside any transaction, where the unit is
 * local: everything, or the lists of the kinds named. Each list goes into the unit's container of its kind,
 * raw - whatever the settings say (fnc_addPayload with raw) -, verified by counting; a kind the unit has no
 * container of goes into another of its containers, and with none at all onto a fresh pile at its feet
 * (fnc_getGroundHolder). What the engine would not take stays in the holder. The holder is written after
 * each kind, so a script error cannot bring anything back twice, and public at the end (fnc_hiddenWrite).
 *
 * For the moments the ops cannot wait for: a death (the body's containers hold everything, so its looters
 * find it; XEH_postInit), a uniform, vest or backpack about to come off (fnc_takeOff: the snapshot then
 * carries the things along, into the dropped backpack), an arsenal opening on this machine (the arsenal and
 * the loadouts saved there see the real gear). Anything else is fnc_opStrict's, as an op of a transaction.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Kinds, any of "uniform", "vest", "backpack" - one of them as a string -, [] for all <ARRAY or STRING>
 *    (default: [])
 *
 * Return Value:
 * How many entries of the holder were put back, whole or in part <NUMBER>
 *
 * Example:
 * [player, "backpack"] call aio_storage_fnc_hiddenReturn;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_kinds", [], [[], ""]]];

if (_kinds isEqualType "") then {
    _kinds = [_kinds];
};

if (isNull _unit || {!local _unit} || {isNil {_unit getVariable QGVAR(hidden)}}) exitWith {0};

([_unit] call FUNC(hiddenLists)) params ["_lists", "_containers"];

if ((_lists findIf {_x isNotEqualTo []}) < 0) exitWith {
    [_unit, [_lists, _containers]] call FUNC(hiddenWrite);
    0
};

private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _returned = 0;
private _pile = objNull;

{
    private _index = _forEachIndex;
    private _list = _x;

    if (_list isEqualTo [] || {_kinds isNotEqualTo [] && {!((USE_KINDS select _index) in _kinds)}}) then {continue};

    // Its own container, else another of the unit's, else a pile at its feet - never nowhere.
    private _target = _own select _index;

    if (isNull _target) then {
        _target = (_own select {!isNull _x}) param [0, objNull];
    };

    if (isNull _target) then {
        if (isNull _pile) then {
            _pile = [_unit, objNull, true] call FUNC(getGroundHolder);
        };

        _target = _pile;
    };

    if (isNull _target) then {
        WARNING_2("Nothing to give the hidden %1 things of %2 back into - they stay in the holder.",USE_KINDS select _index,_unit);
        continue;
    };

    private _left = [];

    {
        _x params ["_class", "_count", "_ammo"];

        private _rest = [_target, [_class, _count, _ammo] call FUNC(hiddenPayload), true] call FUNC(addPayload);

        if (_rest isNotEqualTo []) then {
            private _n = if ((_rest select 0) isEqualTo "magazine") then {count (_rest select 2)} else {_rest param [2, 0]};

            if (_n > 0) then {
                _left pushBack [_class, _n, _ammo];
            };
        };

        _returned = _returned + 1;
    } forEach _list;

    _lists set [_index, _left];

    if (_left isEqualTo []) then {
        _containers set [_index, objNull];
    };

    _unit setVariable [QGVAR(hidden), [_lists, _containers]];
} forEach _lists;

[_unit, [_lists, _containers]] call FUNC(hiddenWrite);

if (!isNull _pile) then {
    [_pile] call FUNC(pruneScriptedPile);
};

_returned
