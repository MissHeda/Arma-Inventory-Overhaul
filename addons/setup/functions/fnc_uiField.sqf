#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A text box for one line that is kept, not applied key by key: typing changes nothing until Return or until the
 * cursor leaves the box (fnc_uiEdit on a film, as fnc_uiNumber does for numbers) - a step that drew itself again on
 * every key would take the cursor away. The code runs a moment later (fnc_defer) with [text, arguments] - once
 * for a Return and the leaving that follows it, and not at all for a text that is the one the box already had.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Text <STRING>
 * 4: Placeholder, shown while it is empty <STRING> (default: "")
 * 5: Theme <HASHMAP> (default: empty)
 * 6: Code, called with [new text, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Tooltip, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The controls, the field last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.2, 0.03], "Closed", "Message", _theme, {params ["_text"]}] call einv_setup_fnc_uiField;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_text", "", [""]], ["_placeholder", "", [""]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_tooltip", "", [""]]
];

// What the box is for, shared by Return and by leaving the box: done once, so the redraw that follows a new text
// does not read the box a second time as the old control goes.
private _state = createHashMapFromArray [["text", _text], ["code", _code], ["arguments", _arguments], ["done", false]];

private _controls = [
    _display, _parent, _rect, _text, _placeholder, _theme, {
        params ["_new", "_submitted", "_state"];

        if (_submitted && {!(_state get "done")} && {_new isNotEqualTo (_state get "text")}) then {
            _state set ["done", true];

            [_new, _state get "arguments"] call (_state get "code");
        };
    }, _state
] call FUNC(uiEdit);

private _edit = _controls select (count _controls - 1);

_edit setVariable [QGVAR(field), _state];

if (_tooltip isNotEqualTo "") then {
    _edit ctrlSetTooltip _tooltip;
};

// Leaving the box reads it too - a click on another control, Tab -, a moment later like everything here.
_edit ctrlAddEventHandler ["KillFocus", {
    params ["_edit"];

    private _state = _edit getVariable [QGVAR(field), createHashMap];

    if (_state getOrDefault ["done", true] || {(ctrlText _edit) isEqualTo (_state getOrDefault ["text", ""])}) exitWith {};

    [{
        params ["_text", "_state"];

        if (_state get "done") exitWith {};

        _state set ["done", true];

        [_text, _state get "arguments"] call (_state get "code");
    }, [ctrlText _edit, _state]] call FUNC(defer);
}];

_controls
