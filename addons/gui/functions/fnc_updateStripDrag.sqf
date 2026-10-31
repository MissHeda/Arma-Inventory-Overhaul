#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A frame of a hotbar slot's binding being dragged (fnc_startStripDrag): the ghost follows the mouse, the
 * slot under it lights up as it does for any hover (fnc_updateHover), and the hint says what letting go
 * does here - move the binding to that slot, leave it where it is (on the strip between its slots), or
 * remove it (anywhere else). The ghost fades where it would be removed.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * What letting go does here: "move", "stay" or "remove" <STRING>
 *
 * Example:
 * [_display, getMousePosition] call aio_gui_fnc_updateStripDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_mouse"];

if (GVAR(stripDrag) isEqualTo []) exitWith {"stay"};

GVAR(stripDrag) params ["_index", "_ghost", "_box", "_offset", "_size"];
_mouse params ["_mouseX", "_mouseY"];

_ghost ctrlSetPosition [_mouseX - (_size select 0) / 2 + (_offset select 0), _mouseY - (_size select 1) / 2 + (_offset select 1)];
_ghost ctrlCommit 0;

[_display, _mouse] call FUNC(updateHover);

private _result = [_index, _mouse] call FUNC(stripTarget);
private _which = ["stay", "move", "remove"] find _result;

_ghost ctrlSetFade ([0, 0.45] select (_result isEqualTo "remove"));
_ghost ctrlCommit 0;

[[[
    [LLSTRING(Hint_StripStay), LLSTRING(Hint_StripMove), LLSTRING(Hint_StripRemove)] select _which,
    ["text2", "accent", "warn"] select _which
]]] call FUNC(dragHint);

_result
