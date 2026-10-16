#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a text field on a film, like the inventory's search field: a placeholder while it is empty, and
 * a click anywhere on the film puts the cursor in it.
 *
 * One line (EINV_Edit) - Return hands the text in (read on the key's release: the field swallows the
 * press). Several lines (EINV_EditArea) - for rules text: in a scrolling group of its own that grows with
 * the text (fnc_fitEditArea), Return starts a new line. Disabled, several lines can still be selected and
 * copied (Ctrl+A, Ctrl+C) - only typing is refused; one line is greyed out - unless it is "selectable": then
 * it is a read-only field (EINV_EditReadOnly) that is drawn as any other and can be selected and copied, a
 * texture path say. Ctrl+C or Return in it gives the cursor back to the wizard (the sink, fnc_onLoad), so the
 * wizard's own keys work again.
 *
 * The code runs a moment later (fnc_defer) with [text, submitted, arguments]: on every change with
 * submitted false, on Return with true.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Text <STRING> (default: "")
 * 4: Placeholder, shown while it is empty <STRING> (default: "")
 * 5: Theme <HASHMAP> (default: empty)
 * 6: Code, called with [text, submitted, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Several lines <BOOL> (default: false)
 * 9: Enabled <BOOL> (default: true)
 * 10: Selectable, with Enabled false and one line: read only but not greyed out, the code is never called <BOOL> (default: false)
 *
 * Return Value:
 * The controls, the field last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.2, 0.03], "", "Name", _theme, {params ["_text", "_submitted"]}] call einv_setup_fnc_uiEdit;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_text", "", [""]], ["_placeholder", "", [""]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_multiLine", false, [false]], ["_enabled", true, [true]],
    ["_selectable", false, [false]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _muted = _theme getOrDefault ["muted", [0.56, 0.56, 0.56, 1]];
private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 2);

if (_multiLine) then {
    _radius = (_theme getOrDefault ["radius", 0]) min (UNIT * 0.3);
};

private _controls = [_display, _parent, _rect, _theme getOrDefault ["button", [1, 1, 1, 0.08]], _radius] call EFUNC(gui,uiPanel);
private _padY = [_height * 0.2, UNIT * 0.3] select _multiLine;
private _padX = [_height * 0.3, UNIT * 0.3] select _multiLine;
_padX = SQUARE(_padX);
private _size = [_height * 0.5, UNIT * 0.56] select _multiLine;

private _placeholderCtrl = [
    _display, _parent, [_left + _padX, _top + ([0, _padY] select _multiLine), _width - _padX * 2, [_height, _size * 1.4] select _multiLine],
    _placeholder, _size * ([1, 1.1] select _multiLine), _muted, _font, 0
] call EFUNC(gui,uiLabel);

_placeholderCtrl ctrlShow (_text isEqualTo "");
_controls pushBack _placeholderCtrl;

// A click anywhere on the film puts the cursor in the field.
private _hit = [_display, "EINV_Hitbox", _parent, _rect] call EFUNC(gui,uiCreate);
_controls pushBack _hit;

private _edit = controlNull;

if (_multiLine) then {
    // Its own scrolling group, and the field as high as its text: the group scrolls, the field never
    // has to. The scroll bar keeps clear of the text.
    private _group = [_display, "EINV_ScrollGroup", _parent, [_left + _padX, _top + _padY, _width - _padX - pixelW * 2, _height - _padY * 2]] call EFUNC(gui,uiCreate);
    (ctrlPosition _group) params ["", "", "_groupW", "_groupH"];

    _edit = [_display, ["EINV_EditAreaReadOnly", "EINV_EditArea"] select _enabled, _group, [0, 0, _groupW - SCROLL_W - pixelW * 2, _groupH]] call EFUNC(gui,uiCreate);
    _edit ctrlSetFontHeight _size;
    _edit setVariable [QGVAR(lineH), _size * 1.2];

    _controls pushBack _group;

    (uiNamespace getVariable [QGVAR(editAreas), []]) pushBack _edit;
    uiNamespace setVariable [QGVAR(editAreas), (uiNamespace getVariable [QGVAR(editAreas), []]) select {!isNull _x}];
} else {
    private _class = ["EINV_Edit", "EINV_EditReadOnly"] select (_selectable && {!_enabled});

    _edit = [_display, _class, _parent, [_left + _padX, _top + (_height - _size * 1.4) / 2, _width - _padX * 2, _size * 1.4]] call EFUNC(gui,uiCreate);
    _edit ctrlSetFont _font;
    _edit ctrlSetFontHeight _size;
    _edit ctrlEnable (_enabled || _selectable);
};

_edit ctrlSetTextColor (_theme getOrDefault ["text", [1, 1, 1, 1]]);
_edit ctrlSetText _text;
_edit setVariable [QGVAR(edit), [_placeholderCtrl, _code, _arguments, _multiLine, _enabled, _text]];
_edit setVariable [QGVAR(selectable), _selectable && {!_multiLine} && {!_enabled}];

_hit setVariable [QGVAR(edit), _edit];
_hit ctrlAddEventHandler ["ButtonClick", {
    ctrlSetFocus ((_this select 0) getVariable [QGVAR(edit), controlNull]);
}];

if (_multiLine) then {
    [_edit] call FUNC(fitEditArea);
};

_edit ctrlAddEventHandler ["EditChanged", {
    params ["_edit", "_text"];

    (_edit getVariable [QGVAR(edit), []]) params [["_placeholder", controlNull], ["_code", {}], ["_arguments", []], ["_multiLine", false], ["_enabled", true], ["_original", ""]];

    // Not to be typed into: whatever got typed is put back. Selecting and copying change nothing.
    if (!_enabled) exitWith {
        if (_text isNotEqualTo _original) then {
            _edit ctrlSetText _original;
        };
    };

    _placeholder ctrlShow (_text isEqualTo "");

    if (_multiLine) then {
        [_edit] call FUNC(fitEditArea);
    };

    [_code, [_text, false, _arguments]] call FUNC(defer);
}];

_edit ctrlAddEventHandler ["KeyUp", {
    params ["_edit", "_key", "", "_ctrl"];

    (_edit getVariable [QGVAR(edit), []]) params ["", ["_code", {}], ["_arguments", []], ["_multiLine", false], ["_enabled", true]];

    // A path to copy: once it is copied (or Return), the wizard has its keys back.
    if (_edit getVariable [QGVAR(selectable), false]) exitWith {
        if (_key in [DIK_RETURN, DIK_NUMPADENTER] || {_key == DIK_C && {_ctrl}}) then {
            ctrlSetFocus (uiNamespace getVariable [QGVAR(sink), controlNull]);
        };

        false
    };

    if (_multiLine || {!_enabled} || {!(_key in [DIK_RETURN, DIK_NUMPADENTER])}) exitWith {false};

    [_code, [ctrlText _edit, true, _arguments]] call FUNC(defer);

    false
}];

_controls pushBack _edit;

_controls
