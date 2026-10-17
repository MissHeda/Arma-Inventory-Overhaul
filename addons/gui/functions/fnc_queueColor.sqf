#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The colour of a tile's surface while it waits in the hands' queue (fnc_drawQueue): its own colour a good way towards the
 * theme's accent, and never fainter than half - a tile that waits has to read as something else than one that was not
 * searched (hatched, fnc_createTile) and than one the mouse lights up. The mouse's light, and a redraw that puts the
 * colour back, ask for it too (fnc_updateHover, fnc_drawTiles).
 *
 * Arguments:
 * 0: The tile's own colour <ARRAY>
 *
 * Return Value:
 * The colour it has while it waits <ARRAY>
 *
 * Example:
 * [[1, 1, 1, 0.075]] call einv_gui_fnc_queueColor;
 *
 * Public: No
 */

params [["_color", [1, 1, 1, 0.075], [[]]]];

private _accent = GVAR(theme) getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];

[
    (_color param [0, 1]) * 0.45 + (_accent select 0) * 0.55,
    (_color param [1, 1]) * 0.45 + (_accent select 1) * 0.55,
    (_color param [2, 1]) * 0.45 + (_accent select 2) * 0.55,
    ((_color param [3, 0.1]) max 0.5) min 0.7
]
