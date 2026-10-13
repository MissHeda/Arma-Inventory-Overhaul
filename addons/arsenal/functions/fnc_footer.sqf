#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The panel's hint line (the "footer" hook), in place of the inventory's footer, which would lie over ACE's
 * menu bar: a strip of the theme's glass under the grid (fnc_layout) with the engine's hint in it - what the
 * mouse is on, what a drag would do, why something did not go (einv_gui_fnc_updateHover,
 * einv_gui_fnc_flashHint). With no panel drawn there is no hint either.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_arsenal_fnc_footer;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]]];

uiNamespace setVariable [QEGVAR(gui,hint), controlNull];

if (GVAR(hintRect) isEqualTo []) exitWith {};

GVAR(hintRect) params ["_left", "_top", "_width", "_height"];

[
    _display, controlNull, GVAR(hintRect), _theme getOrDefault ["panel", []],
    (_theme getOrDefault ["radius", 0]) min (_height / 2)
] call EFUNC(gui,uiPanel);

// In the inventory's footer size, two lines of it: the panel is narrow, and a longer hint wraps rather
// than being cut off.
private _size = UNIT * 0.558;
private _padX = SQUARE(UNIT * 0.4);
private _padY = (_height - _size * 2.6) / 2;

uiNamespace setVariable [QEGVAR(gui,hint), [
    _display, "EINV_FooterHint", controlNull,
    [_left + _padX, _top + _padY, _width - _padX * 2, _size * 2.6]
] call EFUNC(gui,uiCreate)];
