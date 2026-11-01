#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A size of the size popover (fnc_sizeDefs) as it is now, between its slider's two ends: the setting's value in the mission
 * namespace, where CBA puts it and the popover's sliders set it while they are dragged (fnc_sizeSet). The rows per page at 0 -
 * no pages, as at MAX_ROWS - are the slider's right end; anything that is no number is the default.
 *
 * Arguments:
 * 0: Which size: an index of fnc_sizeDefs <NUMBER>
 *
 * Return Value:
 * The value <NUMBER>
 *
 * Example:
 * [1] call aio_gui_fnc_sizeValue;
 *
 * Public: No
 */

params [["_index", 0, [0]]];

((call FUNC(sizeDefs)) param [_index, []]) params [["_setting", ""], "", "", ["_least", 0], ["_most", 1], "", ["_default", 1]];

private _value = missionNamespace getVariable [_setting, _default];

if !(_value isEqualType 0) then {
    _value = _default;
};

if (_setting isEqualTo QGVAR(pageRows) && {_value <= 0}) then {
    _value = _most;
};

(_value max _least) min _most
