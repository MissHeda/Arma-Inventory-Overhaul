#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item just found: on its tile, built anew without its "?", the picture, name and count fade in,
 * and a flash in the accent colour dies away over it (fnc_flashTile). Only ctrlCommit times it -
 * nothing waits on it, and a rebuild meanwhile simply ends it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The item, as it stood in the search queue (fnc_markHidden) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _head] call aio_gui_fnc_revealFx;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_item"];

// A found item simply appears: no flash and no fade (both were tiring to watch). The tile is built shown already.
