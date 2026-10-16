#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Brings a kit's window to the top - any press on a window lying under another (fnc_onMouseButton). The
 * engine draws controls made later over earlier ones and has no other order, so that window alone is
 * made again, last, from what it was drawn from - nothing is read anew - and what floats over the
 * windows after it (fnc_drawTopLayer).
 *
 * Its new grids take the places its old ones had in the list of grids: no other grid's index changes,
 * so the press that follows, the hover and a remembered first click all still point where they did -
 * a press on a lower window's tile starts a drag at once, and a double click works. Its old group is
 * hidden at once and deleted on the next frame (fnc_onFrame): this runs inside that group's own event.
 *
 * Arguments:
 * 0: The kit's key <STRING>
 *
 * Return Value:
 * Raised - false for a window not open or on top already <BOOL>
 *
 * Example:
 * ["kit:efak_ifak_7"] call einv_gui_fnc_raiseWindow;
 *
 * Public: No
 */

disableSerialization;

params [["_key", "", [""]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _windows = uiNamespace getVariable [QGVAR(windows), []];
private _index = _windows findIf {(_x getOrDefault ["key", ""]) isEqualTo _key};

if (isNull _display || {_index < 0} || {_index == count _windows - 1}) exitWith {false};

private _record = _windows select _index;
private _group = _record getOrDefault ["group", controlNull];
private _old = _record getOrDefault ["grids", []];

// Its body is scrolled back to where it was, a frame later (fnc_drawWindow, fnc_onFrame). Until then the
// grids are found as if it were already (fnc_gridOrigin): the press that raised it is worked out right
// after this, on the new body, and must find the tile the player clicked.
GVAR(windowScroll) set [_key, [_record getOrDefault ["body", controlNull]] call FUNC(scrollPixels)];

if (!isNull _group) then {
    _group ctrlShow false;
    (uiNamespace getVariable [QGVAR(windowTrash), []]) pushBack _group;

    private _created = uiNamespace getVariable [QGVAR(created), []];
    private _at = _created find _group;

    if (_at >= 0) then {
        _created deleteAt _at;
    };
};

_windows deleteAt _index;

private _order = GVAR(windowOrder) find _key;

if (_order >= 0) then {
    GVAR(windowOrder) deleteAt _order;
};

GVAR(windowOrder) pushBack _key;

private _new = [_display, _record get "section", GVAR(theme), false] call FUNC(drawWindow);
private _made = _new getOrDefault ["grids", []];

_windows pushBack _new;

// The same section makes as many grids again; should it not, every window is drawn anew instead.
if (count _made != count _old) exitWith {
    [_display] call FUNC(drawWindows);

    if (GVAR(handQueue) isNotEqualTo []) then {
        [_display] call FUNC(drawQueue);
    };

    true
};

private _grids = uiNamespace getVariable [QGVAR(grids), []];

{
    _grids set [_x, _grids select (_made select _forEachIndex)];
} forEach _old;

// The new grids were added at the end of the list; they stand in the old ones' places now.
_grids resize (count _grids - count _made);
_new set ["grids", +_old];

[_display] call FUNC(drawTopLayer);

// The circles of the hands' queue (fnc_queueMoves) on its tiles, which are new controls.
if (GVAR(handQueue) isNotEqualTo []) then {
    [_display] call FUNC(drawQueue);
};

true
