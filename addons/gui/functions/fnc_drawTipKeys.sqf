#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the key hints that hang under the name at the mouse (fnc_hoverKeys): a small card of the tooltip's
 * glass with a key badge and its words for each, in the footer's style (fnc_uiKeyHint). It is one controls
 * group, kept in uiNamespace tipKeys with its width and height, hidden at [-10, -10] until fnc_onFrame puts it
 * under the name (or the comparison card) - and hides it whenever that goes. The one of the last hover goes in
 * any case - unless it shows the same keys already (then it is kept, and not made again, which is every hover
 * change on a row of identical tiles). Made after the name, so that it lies over it: fnc_raiseTooltip makes it again whenever the name
 * is made again.
 *
 * Arguments:
 * 0: Key hints [[key, text], ...], [] for none <ARRAY> (default: [])
 * 1: Make it again even if it shows these keys: it must lie over something made after it <BOOL> (default: false)
 *
 * Return Value:
 * The group, controlNull for none <CONTROL>
 *
 * Example:
 * [[["G", "Drop"], ["Right click", "Options"]]] call einv_gui_fnc_drawTipKeys;
 *
 * Public: No
 */

disableSerialization;

params [["_keys", [], [[]]], ["_force", false]];

private _old = uiNamespace getVariable [QGVAR(tipKeys), controlNull];

if (!_force && {!isNull _old} && {_keys isNotEqualTo []} && {(_old getVariable [QGVAR(source), []]) isEqualTo _keys}) exitWith {_old};

ctrlDelete _old;
uiNamespace setVariable [QGVAR(tipKeys), controlNull];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display || {_keys isEqualTo []}) exitWith {controlNull};

private _theme = GVAR(theme);
private _keyH = UNIT * 0.72;
private _padX = SQUARE(UNIT * 0.3);
private _padY = UNIT * 0.2;

// The width of the row: what each hint takes, less the space after the last one.
private _width = _padX * 2 - SQUARE(_keyH * 0.9);

{
    _width = _width + ([_display, controlNull, [0, 0], _x select 0, _x select 1, _theme, _keyH, true] call FUNC(uiKeyHint));
} forEach _keys;

private _height = _keyH + _padY * 2;
private _group = [_display, "EINV_Group", controlNull, [-10, -10, _width + pixelW * 2, _height + pixelH * 2]] call FUNC(uiCreate);

[_display, _group, [0, 0, _width, _height], _theme getOrDefault ["tooltipBg", [0.03, 0.03, 0.03, 0.96]], (_theme getOrDefault ["radius", 0]) * 0.5] call FUNC(uiPanel);

private _cursor = _padX;

{
    private _taken = [_display, _group, [_cursor, _padY], _x select 0, _x select 1, _theme, _keyH] call FUNC(uiKeyHint);

    _cursor = _cursor + _taken;
} forEach _keys;

_group setVariable [QGVAR(width), _width];
_group setVariable [QGVAR(height), _height];

// What it was made from, to make it again over something made after it (fnc_raiseTooltip).
_group setVariable [QGVAR(source), _keys];

_group ctrlShow false;

uiNamespace setVariable [QGVAR(tipKeys), _group];

_group
