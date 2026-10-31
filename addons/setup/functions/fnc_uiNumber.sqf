#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A small text box for one whole number, to type an exact value where a stepper would take many clicks
 * (fnc_uiEdit on a film). Nothing happens while typing: Return or leaving the box (the cursor goes
 * elsewhere) reads it. A number is taken as far as the range allows - 500 in a box up to 400 is 400 -; text
 * that is no number, or the number the box already had, is put back as it was.
 *
 * It reads digits with an optional minus and a percent sign or spaces around them ("-20", "150 %", "12,5"
 * rounds to 13). The code runs a moment later (fnc_defer) with [number, arguments], as a stepper's does, so
 * the same code can serve both.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Value <NUMBER>
 * 4: [lowest, highest] <ARRAY>
 * 5: Theme <HASHMAP>
 * 6: Code, called with [new value, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Tooltip, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The controls, the field last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.05, 0.03], 100, [25, 400], _theme, {params ["_zoom"]}] call aio_setup_fnc_uiNumber;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_value", 0, [0]], ["_range", [0, 100], [[]]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_tooltip", "", [""]]
];
_range params [["_min", 0, [0]], ["_max", 100, [0]]];

_value = round _value;

// What the box is for, shared by Return and by leaving the box: done once, so the redraw that follows a new
// number does not read the box a second time as the old control goes.
private _state = createHashMapFromArray [
    ["value", _value], ["min", _min], ["max", _max], ["code", _code], ["arguments", _arguments], ["done", false], ["edit", controlNull]
];

_state set ["apply", {
    params ["_text", "_state"];

    if (_state get "done") exitWith {};

    private _edit = _state get "edit";

    if (isNull _edit) exitWith {};

    private _value = _state get "value";
    private _clean = ((_text splitString "% ") joinString "") regexReplace [",", "."];
    private _new = _value;

    if (_clean regexMatch "^-?[0-9]+([.][0-9]*)?$") then {
        _new = (((round (parseNumber _clean)) max (_state get "min")) min (_state get "max"));
    };

    // The box shows what is in force, a number that was cut to the range included.
    if (_new == _value) exitWith {
        if (ctrlText _edit isNotEqualTo str _value) then {
            _edit ctrlSetText str _value;
        };
    };

    _state set ["done", true];

    [_new, _state get "arguments"] call (_state get "code");
}];

private _controls = [
    _display, _parent, _rect, str _value, "", _theme, {
        params ["_text", "_submitted", "_state"];

        if (_submitted) then {
            [_text, _state] call (_state get "apply");
        };
    }, _state
] call FUNC(uiEdit);

private _edit = _controls select (count _controls - 1);

_state set ["edit", _edit];
_edit setVariable [QGVAR(number), _state];

if (_tooltip isNotEqualTo "") then {
    _edit ctrlSetTooltip _tooltip;
};

// Leaving the box reads it too - a click on another control, Tab -, a moment later like everything here.
_edit ctrlAddEventHandler ["KillFocus", {
    params ["_edit"];

    private _state = _edit getVariable [QGVAR(number), createHashMap];

    if (_state getOrDefault ["done", true]) exitWith {};

    [{
        params ["_text", "_state"];

        [_text, _state] call (_state get "apply");
    }, [ctrlText _edit, _state]] call FUNC(defer);
}];

_controls
