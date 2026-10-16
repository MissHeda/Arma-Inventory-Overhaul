#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The small reset button beside a setting, as CBA puts one beside each of its rows: an icon of the turning
 * arrow in a square, shown only where the value is not the default (the caller decides - nothing is drawn for a
 * value that is). A click runs the code a moment later (fnc_uiAction) and the step draws itself again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Theme <HASHMAP>
 * 4: Code, called with the arguments as _this <CODE>
 * 5: Arguments <ANY> (default: [])
 * 6: Tooltip <STRING> (default: "Back to the default")
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0.4, 0.1, 0.03, 0.03], _theme, {["einv_gui_searchTime"] call einv_setup_fnc_setSetting}] call einv_setup_fnc_uiReset;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_theme", createHashMap, [createHashMap]], ["_code", {}, [{}]], ["_arguments", []],
    ["_tooltip", "", [""]]
];

if (_tooltip isEqualTo "") then {
    _tooltip = LLSTRING(Reset_Field);
};

[_display, _parent, _rect, "", ICON(icon_reset_ca,icon_auto_ca), _theme, _code, _arguments, true, "ghost", _tooltip] call FUNC(uiAction)
