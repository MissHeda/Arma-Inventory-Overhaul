#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens a kit's window on top of the others (aio_compat_efak_fnc_open, once the kit may open): beside
 * the tile it was opened from, fading in. Open already, it only comes to the top where it is. Only the
 * windows are drawn again (fnc_drawWindows): nothing in the columns appears, goes, moves or scrolls.
 *
 * Its key is all this window knows of the kit - what to draw comes from aio_compat_efak, which has to
 * know the kit as open already. With no inventory open only the order is noted.
 *
 * Arguments:
 * 0: The kit's key, "kit:" + its lowercase class <STRING>
 * 1: The tile it was opened from [x, y, w, h] on the screen (fnc_tileRect), [] for none <ARRAY>
 *    (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * ["kit:efak_ifak_7", [_grid, _tile] call aio_gui_fnc_tileRect] call aio_gui_fnc_openWindow;
 *
 * Public: No
 */

disableSerialization;

params [["_key", "", [""]], ["_anchor", [], [[]]]];

if (_key isEqualTo "") exitWith {};

private _index = GVAR(windowOrder) find _key;

if (_index >= 0) then {
    GVAR(windowOrder) deleteAt _index;
} else {
    // Opened again, it comes up beside its tile, not where it was last.
    GVAR(windowAnchor) set [_key, _anchor];
    GVAR(windowPos) deleteAt _key;
    GVAR(windowScroll) deleteAt _key;
    GVAR(windowFresh) pushBackUnique _key;
};

GVAR(windowOrder) pushBack _key;

// The windows are drawn once for a run of clicks (fnc_windowsSoon).
[] call FUNC(windowsSoon);
