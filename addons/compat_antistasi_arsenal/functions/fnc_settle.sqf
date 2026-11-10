#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The grid panel added or took something on JNA's arsenal: the difference between the two counts (fnc_census) goes to
 * JNA's stock with JNA's own functions - what came in is taken (jn_fnc_arsenal_removeItem), what went out is given back
 * (jn_fnc_arsenal_addItem). Both update the server's stock and every player with the arsenal open, as JNA's own "+" and
 * "-" do; moves between the soldier's containers and the staging space leave both counts alike and change nothing.
 *
 * Arguments:
 * 0: The count before <ARRAY>
 * 1: The count after <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_before, _after] call aio_compat_antistasi_arsenal_fnc_settle;
 *
 * Public: No
 */

params [["_before", [], [[]]], ["_after", [], [[]]]];

private _take = JNA_EMPTY;
private _give = JNA_EMPTY;
private _changed = [false, false];

for "_index" from 0 to (count _take) - 1 do {
    private _counts = createHashMap;

    {
        _x params [["_class", ""], ["_amount", 0]];

        if (_class isEqualType "" && {_amount isEqualType 0}) then {
            _counts set [_class, (_counts getOrDefault [_class, 0]) - _amount];
        };
    } forEach (_before param [_index, []]);

    {
        _x params [["_class", ""], ["_amount", 0]];

        if (_class isEqualType "" && {_amount isEqualType 0}) then {
            _counts set [_class, (_counts getOrDefault [_class, 0]) + _amount];
        };
    } forEach (_after param [_index, []]);

    {
        if (_y > 0) then {
            (_take select _index) pushBack [_x, _y];
            _changed set [0, true];
        };

        if (_y < 0) then {
            (_give select _index) pushBack [_x, -_y];
            _changed set [1, true];
        };
    } forEach _counts;
};

if (_changed select 0) then {
    TRACE_1("JNA stock taken",_take);
    _take call jn_fnc_arsenal_removeItem;
};

if (_changed select 1) then {
    TRACE_1("JNA stock given back",_give);
    _give call jn_fnc_arsenal_addItem;
};
