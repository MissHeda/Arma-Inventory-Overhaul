#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes every open kit's window off the screen before they are drawn again (fnc_drawWindows) or the
 * whole window is built anew (fnc_build). How far each one's body was scrolled is kept
 * (GVAR(windowScroll)), and so is everything else about them: their order, where they were put.
 *
 * A window's group is hidden at once but deleted only on the next frame (fnc_onFrame): this runs inside
 * the window's own events too - a double click on a tile in it that opens or closes a kit - and a
 * control must not be deleted inside its own event. Its grids leave the list of grids now; the columns'
 * grids come first in it and keep their places. A press or the hover on one of its tiles is forgotten,
 * on a column's tile both stay.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_gui_fnc_clearWindows;
 *
 * Public: No
 */

disableSerialization;

private _trash = uiNamespace getVariable [QGVAR(windowTrash), []];
private _created = uiNamespace getVariable [QGVAR(created), []];

{
    private _group = _x getOrDefault ["group", controlNull];

    GVAR(windowScroll) set [_x getOrDefault ["key", ""], [_x getOrDefault ["body", controlNull]] call FUNC(scrollPixels)];

    if (!isNull _group) then {
        _group ctrlShow false;
        _trash pushBack _group;

        private _at = _created find _group;

        if (_at >= 0) then {
            _created deleteAt _at;
        };
    };
} forEach (uiNamespace getVariable [QGVAR(windows), []]);

uiNamespace setVariable [QGVAR(windowTrash), _trash];
uiNamespace setVariable [QGVAR(windows), []];

private _grids = uiNamespace getVariable [QGVAR(grids), []];
private _kept = _grids select {(_x getOrDefault ["window", ""]) isEqualTo ""};

// A press on a tile of a window that goes, or the mouse on one, would point at whatever is drawn in its
// place. On a column's tile both stay: its grid keeps its place, and the hover lights it down again.
if (!GVAR(dragging) && {(GVAR(press) param [0, -1]) >= count _kept}) then {
    GVAR(press) = [];
};

if ((GVAR(hover) param [0, ""]) isEqualTo "tile" && {(GVAR(hover) param [1, -1]) >= count _kept}) then {
    GVAR(hover) = [];
};

uiNamespace setVariable [QGVAR(grids), _kept];
