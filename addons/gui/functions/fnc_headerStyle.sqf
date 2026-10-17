#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The colours of a button in the header (fnc_drawHeader): the header lies on the world, so its buttons
 * need a surface that stands out of the window's glass at a glance - the theme's lit button colour, much
 * stronger than a button inside a column, and lighter again under the mouse. A button that is on (the camera,
 * the speaker's dropdown while it is open) takes the accent. The search field's frame uses the plain one.
 *
 * Arguments:
 * 0: Theme <HASHMAP>
 * 1: The button is on <BOOL> (default: false)
 *
 * Return Value:
 * [surface, surface under the mouse, ink] <ARRAY>
 *
 * Example:
 * ([_theme, true] call einv_gui_fnc_headerStyle) params ["_fill", "_hover", "_ink"];
 *
 * Public: No
 */

params ["_theme", ["_on", false, [false]]];

private _ink = _theme getOrDefault ["buttonText", [0.88, 0.88, 0.88, 1]];

if (_on) exitWith {
    private _fill = +(_theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]);
    private _hover = +_fill;

    _fill set [3, 0.42];
    _hover set [3, 0.62];

    [_fill, _hover, _theme getOrDefault ["text", [1, 1, 1, 1]]]
};

private _fill = +(_theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]]);
private _hover = +_fill;

_fill set [3, ((_fill select 3) * 1.3) max 0.2];
_hover set [3, ((_hover select 3) * 2.4) max 0.36];

[_fill, _hover, _ink]
