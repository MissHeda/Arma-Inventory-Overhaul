#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws every open kit's window anew - at the end of every build (fnc_build), and whenever a kit opens
 * or closes (fnc_openWindow, fnc_closeWindow). Only the windows: the columns under them stay as they are,
 * so opening or closing a kit moves nothing there and scrolls nothing.
 *
 * The open kits come from Enhanced First Aid Kits' addon (einv_compat_efak_fnc_getSections), found
 * anew among what the last build showed; without it there are none. Each keeps its place in the order
 * (GVAR(windowOrder), bottom first) and where it was put; one found nowhere any more - it left the
 * window's reach - goes, and a new one comes on top. Those opened just now fade in (GVAR(windowFresh)).
 * Each body is scrolled back on the next frame to where it was (fnc_onFrame).
 *
 * What floats over the windows is made again after them, so it stays on top (fnc_drawTopLayer).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_drawWindows;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

// A draw a click asked for (fnc_windowsSoon) and not yet done is this one.
["windows"] call FUNC(coalesceDrop);

call FUNC(clearWindows);

if (isNull _display) exitWith {};

// The column grids keep their places; the windows' come after them.
private _columnGrids = count (uiNamespace getVariable [QGVAR(grids), []]);

private _sections = [];

if (!isNil QEFUNC(compat_efak,getSections)) then {
    _sections = [
        GVAR(context) getOrDefault ["ownSections", []], GVAR(context) getOrDefault ["lootSections", []]
    ] call EFUNC(compat_efak,getSections);
};

private _byKey = createHashMap;

{
    private _key = _x getOrDefault ["key", ""];

    if (_key isNotEqualTo "" && {!(_key in _byKey)}) then {
        _byKey set [_key, _x];
    };
} forEach _sections;

// The order: windows of kits found no more go, new ones come on top in the order they were opened.
GVAR(windowOrder) = GVAR(windowOrder) select {_x in _byKey};

{
    private _key = _x getOrDefault ["key", ""];

    if (_key in _byKey && {!(_key in GVAR(windowOrder))}) then {
        GVAR(windowOrder) pushBack _key;
    };
} forEach _sections;

{
    private _kept = _x;

    {
        if !(_x in GVAR(windowOrder)) then {
            _kept deleteAt _x;
        };
    } forEach (keys _kept);
} forEach [GVAR(windowPos), GVAR(windowAnchor), GVAR(windowScroll)];

// Bottom first: what is made later lies on top.
{
    private _record = [_display, _byKey get _x, GVAR(theme), _x in GVAR(windowFresh)] call FUNC(drawWindow);

    (uiNamespace getVariable [QGVAR(windows), []]) pushBack _record;
} forEach GVAR(windowOrder);

GVAR(windowFresh) = [];

// A first click remembered on a window's tile is forgotten: whatever was drawn at that place in the list
// of grids now may be another tile.
if (((GVAR(lastClick) select 0) param [0, -1]) >= _columnGrids) then {
    GVAR(lastClick) = [[], -1];
};

[_display] call FUNC(drawTopLayer);
