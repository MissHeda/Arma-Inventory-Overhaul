#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a unit's hidden holder (fnc_hiddenLists) to the unit, public: einv_storage_hidden travels with the
 * unit to every machine - a looter's window, a Zeus taking it over, the server once its player left - and
 * to whoever joins later. Only the unit's owner writes it (the ops run there, fnc_execute). Empty, the
 * variable goes away.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: [lists, containers] as fnc_hiddenLists gives them <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _data] call einv_storage_fnc_hiddenWrite;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_data", [], [[]]]];

if (isNull _unit) exitWith {};

_data params [["_lists", [], [[]]], ["_containers", [], [[]]]];

if ((_lists findIf {_x isNotEqualTo []}) < 0) exitWith {
    if (!isNil {_unit getVariable QGVAR(hidden)}) then {
        _unit setVariable [QGVAR(hidden), nil, true];
    };
};

_unit setVariable [QGVAR(hidden), [_lists, _containers], true];
