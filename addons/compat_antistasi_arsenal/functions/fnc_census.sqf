#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the containers hold, counted the way JNA counts a crate it is filled from (jn_fnc_arsenal_cargoToArray): one list
 * per tab of [class, amount], magazines in rounds (loaded ones in weapons too), weapons as their base weapon, the
 * attachments on a weapon apart, and the contents of a uniform, vest or backpack inside another.
 *
 * Arguments:
 * 0: The containers <ARRAY of OBJECTs>
 *
 * Return Value:
 * One list per tab <ARRAY>
 *
 * Example:
 * [[uniformContainer player]] call aio_compat_antistasi_arsenal_fnc_census;
 *
 * Public: No
 */

params [["_containers", [], [[]]]];

private _all = JNA_EMPTY;

{
    if (isNull _x) then {continue};

    {
        if (_x isNotEqualTo []) then {
            _all set [_forEachIndex, [_all select _forEachIndex, _x] call jn_fnc_arsenal_addToArray];
        };
    } forEach ([_x] call jn_fnc_arsenal_cargoToArray);
} forEach _containers;

_all
