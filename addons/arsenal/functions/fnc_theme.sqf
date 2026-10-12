#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The Arsenal's colours (the "theme" hook): the dim layer is nearly clear, and the glass of its panels a
 * little more see-through than the inventory's (PANEL_ALPHA), so a soldier who slips behind one is still
 * seen.
 *
 * Arguments:
 * 0: The theme, changed in place <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_theme] call einv_arsenal_fnc_theme;
 *
 * Public: No
 */

params [["_theme", createHashMap, [createHashMap]]];

// The world shows through: the layer over it is almost clear, with the camera and without.
_theme set ["dim", [0, 0, 0, 0.12]];
_theme set ["dimCamera", [0, 0, 0, 0.12]];

// A copy: the colour in the theme may be shared.
private _panel = +(_theme getOrDefault ["panel", [0.04, 0.045, 0.055, 0.85]]);

_panel set [3, PANEL_ALPHA];
_theme set ["panel", _panel];
