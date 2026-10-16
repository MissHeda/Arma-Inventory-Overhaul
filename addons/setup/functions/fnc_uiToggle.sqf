#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a switch, Enhanced First Aid Kits' toggle (toggle_on_ca, toggle_off_ca): on the left of its box,
 * with an optional label beside it. The whole box takes the click, label included. The switch flips at
 * once; the code runs a moment later with the new state (fnc_defer).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group - the switch is as high as 0.62 of it <ARRAY>
 * 3: On <BOOL> (default: false)
 * 4: Theme <HASHMAP> (default: empty)
 * 5: Code, called with [new state, arguments] <CODE> (default: {})
 * 6: Arguments <ANY> (default: [])
 * 7: Enabled <BOOL> (default: true)
 * 8: Label, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.2, 0.03], true, _theme, {params ["_on"]; systemChat str _on}] call einv_setup_fnc_uiToggle;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_value", false, [false]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]], ["_label", "", [""]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _switchH = _height * 0.62;
private _switchW = SQUARE(_switchH * 2);
private _controls = [];

// The textures bring their own colours: accent when on, a grey track when off.
private _switch = [
    _display, _parent, [_left, _top + (_height - _switchH) / 2, _switchW, _switchH],
    [UI_TEX(toggle_off_ca), UI_TEX(toggle_on_ca)] select _value, [[1, 1, 1, 0.35], [1, 1, 1, 1]] select _enabled
] call EFUNC(gui,uiIcon);

_controls pushBack _switch;

if (_label isNotEqualTo "") then {
    private _font = _theme getOrDefault ["font", "PuristaMedium"];
    private _labelX = _left + _switchW + SQUARE(_height * 0.35);
    private _labelW = _left + _width - _labelX;

    _controls pushBack ([
        _display, _parent, [_labelX, _top, _labelW, _height], [_label, _labelW, _font, TEXT_BODY] call EFUNC(gui,fitText), TEXT_BODY,
        [DISABLED_INK, _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]]] select _enabled, _font, 0
    ] call EFUNC(gui,uiLabel));
};

private _hit = [_display, _parent, _rect, [], [], [], {}, [], _enabled, _label] call FUNC(uiHit);
_hit setVariable [QGVAR(toggle), [_switch, _value, _code, _arguments]];

if (_enabled) then {
    _hit ctrlAddEventHandler ["ButtonClick", {
        params ["_hit"];

        (_hit getVariable [QGVAR(toggle), [controlNull, false, {}, []]]) params ["_switch", "_value", "_code", "_arguments"];

        _value = !_value;
        _hit setVariable [QGVAR(toggle), [_switch, _value, _code, _arguments]];
        _switch ctrlSetText ([UI_TEX(toggle_off_ca), UI_TEX(toggle_on_ca)] select _value);

        [_code, [_value, _arguments]] call FUNC(defer);
    }];
};

_controls pushBack _hit;

_controls
