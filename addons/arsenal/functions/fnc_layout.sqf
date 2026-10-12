#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The layout of the window (the "layout" hook): the inventory's glass layout with the catalog in the place
 * of the loot column, which grows on a wide screen (einv_gui_fnc_layoutGlass). In the Items view the
 * catalog's source grid and the give-back zone are registered, in the Loadouts view only the soldier's
 * zone, so a drop on the loadouts does nothing. The column itself is made once and kept across builds
 * (fnc_drawColumn); a build only registers it again.
 *
 * Zones are told apart by their id, the second element: "soldier" (where the camera shows him) and
 * "giveBack" (the catalog's column).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 * 2: Context <HASHMAP>
 *
 * Return Value:
 * Where the soldier stands [x, y, w, h], [] when there is no room <ARRAY>
 *
 * Example:
 * [_display, _theme, _context] call einv_arsenal_fnc_layout;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_theme", createHashMap, [createHashMap]], ["_context", createHashMap, [createHashMap]]];

// The catalog stands where the loot column would: reserved and allowed to grow, but nothing is looted here
// (what lies in containers opened inside the soldier's is in the storage column already).
_context set ["rightColumn", true];
_context set ["rightGrow", RIGHT_GROW];
_context set ["rightKeep", RIGHT_KEEP];
_context set ["looting", false];

private _rect = [_display, _theme, _context] call EFUNC(gui,layoutGlass);
private _right = _context getOrDefault ["rightRect", []];

// No column (a narrow screen): hidden panels still give the camera the whole screen.
if (_right isEqualTo []) exitWith {[_rect, [safeZoneX, safeZoneY, safeZoneW, safeZoneH]] select GVAR(hidden)};

EGVAR(gui,panels) pushBack _right;

// The column is made when there is none for this display, or it lies elsewhere now.
private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _group = _column getOrDefault ["group", controlNull];

if (isNull _group || {(_column getOrDefault ["rect", []]) isNotEqualTo _right} || {(_column getOrDefault ["display", displayNull]) isNotEqualTo _display}) then {
    [_display, _right, _theme] call FUNC(drawColumn);
};

// Kept across builds, so it comes back by itself after the panels were hidden (fnc_afterBuild hid it).
if (!GVAR(hidden)) then {
    (_column getOrDefault ["group", controlNull]) ctrlShow true;
};

private _zones = uiNamespace getVariable [QEGVAR(gui,zones), []];

// Where the camera shows him: a thing dropped there is put on.
if (_rect isNotEqualTo []) then {
    _zones pushBack [_rect, "soldier"];
};

// The Items view: the cards are a place things come from, and the column takes things back.
if (GVAR(view) isEqualTo "items") then {
    private _grid = _column getOrDefault ["grid", createHashMap];

    if (count _grid > 0) then {
        (uiNamespace getVariable [QEGVAR(gui,grids), []]) pushBack _grid;
    };

    _zones pushBack [_right, "giveBack"];
};

uiNamespace setVariable [QEGVAR(gui,zones), _zones];

// Hidden panels give the camera the whole screen.
if (GVAR(hidden)) exitWith {
    [safeZoneX, safeZoneY, safeZoneW, safeZoneH]
};

_rect
