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

// Off is the grey track texture; on is a white track tinted with the player's accent and a white knob over it,
// so the switch follows the Arma colour the player picked rather than a fixed orange.
private _switchRect = [_left, _top + (_height - _switchH) / 2, _switchW, _switchH];
private _alpha = [0.35, 1] select _enabled;
private _accent = +(_theme getOrDefault ["accent", [1, 1, 1, 1]]);
_accent set [3, _alpha];

private _switch = [_display, _parent, _switchRect, UI_TEX(toggle_off_ca), [1, 1, 1, _alpha]] call EFUNC(gui,uiIcon);
private _track = [_display, _parent, _switchRect, UI_TEX(toggle_track_ca), _accent] call EFUNC(gui,uiIcon);
private _knob = [_display, _parent, _switchRect, UI_TEX(toggle_knob_ca), [1, 1, 1, _alpha]] call EFUNC(gui,uiIcon);

_switch ctrlShow !_value;
_track ctrlShow _value;
_knob ctrlShow _value;
_controls append [_track, _knob];
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
_hit setVariable [QGVAR(toggle), [_switch, _value, _code, _arguments, _track, _knob]];

if (_enabled) then {
    _hit ctrlAddEventHandler ["ButtonClick", {
        params ["_hit"];

        (_hit getVariable [QGVAR(toggle), [controlNull, false, {}, [], controlNull, controlNull]]) params ["_switch", "_value", "_code", "_arguments", "_track", "_knob"];

        _value = !_value;
        _hit setVariable [QGVAR(toggle), [_switch, _value, _code, _arguments, _track, _knob]];
        _switch ctrlShow !_value;
        _track ctrlShow _value;
        _knob ctrlShow _value;

        [_code, [_value, _arguments]] call FUNC(defer);
    }];
};

_controls pushBack _hit;

_controls
