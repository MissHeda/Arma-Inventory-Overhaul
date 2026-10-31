#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a segmented switch: one film split into equal parts, one of them picked and filled with the
 * accent - for a choice of a few that excludes the others. A click on another part runs the code a
 * moment later with its index (fnc_defer); the caller draws it again.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Labels <ARRAY>
 * 4: Index of the part picked <NUMBER>
 * 5: Theme <HASHMAP>
 * 6: Code, called with [new index, arguments] <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Enabled <BOOL> (default: true)
 *
 * Return Value:
 * The controls, the last part's hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.2, 0.025], ["Own", "Full", "CBA line"], 0, _theme, {params ["_index"]}] call aio_setup_fnc_uiSegmented;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_labels", [], [[]]], ["_index", 0, [0]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _radius = (_theme getOrDefault ["radius", 0]) min (_height / 2);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _controls = [_display, _parent, _rect, [DISABLED_FILL, _theme getOrDefault ["button", [1, 1, 1, 0.08]]] select _enabled, _radius] call EFUNC(gui,uiPanel);
private _partW = _width / ((count _labels) max 1);

// The picked part sits inside the film, two pixels in, so the film shows round it.
private _insetX = pixelW * 2;
private _insetY = pixelH * 2;

{
    private _current = _forEachIndex == _index;
    private _partX = _left + _forEachIndex * _partW;
    private _fill = [[0, 0, 0, 0], _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]] select _current;
    private _ink = [_theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]], _theme getOrDefault ["onAccent", [0.05, 0.05, 0.05, 1]]] select _current;

    if (!_enabled) then {
        _fill = [[0, 0, 0, 0], DISABLED_FILL] select _current;
        _ink = DISABLED_INK;
    };

    private _surface = [
        _display, _parent, [_partX + _insetX, _top + _insetY, _partW - _insetX * 2, _height - _insetY * 2], _fill,
        (_radius - _insetY) max 0
    ] call EFUNC(gui,uiPanel);

    private _partFont = [_font, _fontBold] select _current;
    private _size = _height * 0.5;

    _controls append _surface;
    _controls pushBack ([
        _display, _parent, [_partX, _top, _partW, _height],
        [_x, _partW * 0.9, _partFont, _size] call EFUNC(gui,fitText), _size, _ink, _partFont, 2
    ] call EFUNC(gui,uiLabel));

    _controls pushBack ([_display, _parent, [_partX, _top, _partW, _height], _surface, _fill, [_fill, [1, 1, 1, 0.06]] select !_current, {
        params ["_code", "_index", "_arguments"];

        [_index, _arguments] call _code;
    }, [_code, _forEachIndex, _arguments], _enabled && {!_current}] call FUNC(uiHit));
} forEach _labels;

_controls
