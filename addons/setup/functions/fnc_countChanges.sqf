#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many changes the draft holds against what was last saved or loaded - the rows of the change list
 * (fnc_changeRows "saved"), so the header's "4 changes" and that list always agree: the cell size, the switch to
 * force it over the mission, each server setting, and each group or rule added, changed or taken away. And
 * which steps they belong to, for the dots on the steps: General for the settings, the cell size, the kinds of
 * container and any rule that is not for one class, Items and Containers for the rules of one class
 * (fnc_ruleStep).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [all changes, the ids of the steps that hold some] <ARRAY>
 *
 * Example:
 * (call aio_setup_fnc_countChanges) select 0;
 *
 * Public: No
 */

private _rows = ["saved", false] call FUNC(changeRows);
private _steps = [];

{
    _x params ["_kind", "", "", "", "", "", "", "_statement"];

    if (_kind isEqualTo "rule") then {
        _steps pushBackUnique (([_statement] call FUNC(ruleStep)) select 0);
    } else {
        _steps pushBackUnique "general";
    };
} forEach _rows;

[count _rows, _steps]
