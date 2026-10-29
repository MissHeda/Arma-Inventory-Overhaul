#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The colours of a button in the header (fnc_drawHeader): the dark of the inventory's panels. The window's glass
 * lies under every button and the theme's button film goes over it, so a button is the panel colour one step
 * lighter, as the buttons in the columns are; under the mouse it is one step lighter again. Nothing is filled with
 * the accent: a button that is on (the speaker or the palette while its dropdown is open) keeps the same surface and
 * shows it by its icon, tinted with the accent (and a thin accent line under it, fnc_drawHeader). The search
 * field's frame uses the plain one.
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

private _fill = +(_theme getOrDefault ["button", [1, 1, 1, 0.07]]);
private _hover = +(_theme getOrDefault ["buttonHover", [1, 1, 1, 0.16]]);

// One step lighter than the surface, not the column buttons' brighter light.
_hover set [3, ((_hover select 3) * 0.75) max ((_fill select 3) + 0.04)];

private _ink = _theme getOrDefault ["buttonText", [0.88, 0.88, 0.88, 1]];

if (_on) then {
    _ink = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
};

[_fill, _hover, _ink]
