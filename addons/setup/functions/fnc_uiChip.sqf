#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a chip: a pill with a label that is on or off - a filter, a choice among several that may all
 * be on. On, it is filled with the accent. A click runs the code a moment later with the state it
 * switches to (fnc_defer); the caller draws it again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Label <STRING>
 * 4: On <BOOL>
 * 5: Theme <HASHMAP>
 * 6: Code, called with [new state, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Enabled <BOOL> (default: true)
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.06, 0.025], "Weapons", true, _theme, {params ["_on"]}] call einv_setup_fnc_uiChip;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_label", "", [""]], ["_active", false, [false]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _fill = [_theme getOrDefault ["button", [1, 1, 1, 0.08]], _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] select _active;
private _hover = [_theme getOrDefault ["buttonHover", [1, 1, 1, 0.12]], ACCENT_HOVER] select _active;
private _ink = [_theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]]] select _active;

if (!_enabled) then {
    _fill = DISABLED_FILL;
    _hover = _fill;
    _ink = DISABLED_INK;
};

private _font = _theme getOrDefault [["font", "fontBold"] select _active, "PuristaMedium"];
private _size = _height * 0.52;
private _pad = SQUARE(_height * 0.45);
private _controls = [_display, _parent, _rect, _fill, _height / 2] call EFUNC(gui,uiPanel);
private _surface = +_controls;

_controls pushBack ([
    _display, _parent, [_left + _pad, _top, _width - _pad * 2, _height],
    [_label, _width - _pad * 2, _font, _size] call EFUNC(gui,fitText), _size, _ink, _font, 2
] call EFUNC(gui,uiLabel));

_controls pushBack ([_display, _parent, _rect, _surface, _fill, _hover, {
    params ["_code", "_state", "_arguments"];

    [_state, _arguments] call _code;
}, [_code, !_active, _arguments], _enabled] call FUNC(uiHit));

_controls
