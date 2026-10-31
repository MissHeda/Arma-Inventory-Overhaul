#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sets one server setting in the draft, or takes it back to its default (fnc_commitSettings): what a control
 * of the General step does with a click, and what the small reset button beside it does.
 *
 * Arguments:
 * 0: The setting's name, the variable it sets (aio_gui_searchTime) <STRING>
 * 1: Its new value, as the variable holds it; nothing for the default <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["aio_gui_searchTime", 0.8] call aio_setup_fnc_setSetting;
 * ["aio_gui_searchTime"] call aio_setup_fnc_setSetting;
 *
 * Public: No
 */

params [["_name", "", [""]], "_value"];

private _values = +GVAR(draftSettings);

if (isNil "_value") then {
    _values deleteAt _name;
} else {
    _values set [_name, _value];
};

[_values] call FUNC(commitSettings);
