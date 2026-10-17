#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives the pieces of a surface another colour - a tile lit by the mouse or put back (fnc_updateHover, fnc_drawTiles). A
 * rectangle takes it as its background, a round corner (fnc_uiSurface) as its picture's colour.
 *
 * Arguments:
 * 0: The controls of the surface <ARRAY>
 * 1: Colour <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_tile get "backgrounds", [1, 1, 1, 0.2]] call einv_gui_fnc_paintSurface;
 *
 * Public: No
 */

params [["_controls", [], [[]]], ["_color", [], [[]]]];

{
    if (ctrlClassName _x isEqualTo "EINV_PanelCorner") then {
        _x ctrlSetTextColor _color;
    } else {
        _x ctrlSetBackgroundColor _color;
    };
} forEach _controls;
