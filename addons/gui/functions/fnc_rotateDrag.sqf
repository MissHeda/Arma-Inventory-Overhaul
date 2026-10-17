#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * R while dragging: turns what is held a quarter round - its width becomes its height. It is held by its
 * middle (fnc_startDrag), so it stays under the mouse and the footprint shows where it lands now. It
 * turns clockwise from upright and back the other way, as a shaped item's cells do (size=xx/x-,
 * einv_items_fnc_turnMask) - so the cell held is still a cell of it. Its picture is not turned: it is drawn upright,
 * fitted into the turned footprint (fnc_uiItemPicture).
 * It is put down turned (einv_storage_fnc_setPlace keeps the size it lies in). A tick sounds for the looter
 * alone, lower for a bigger item (fnc_playSound "rotate").
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * Turned <BOOL>
 *
 * Example:
 * [_display] call einv_gui_fnc_rotateDrag;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

if (!GVAR(dragging)) exitWith {false};

GVAR(dragSize) params ["_w", "_h"];

// A square rectangle looks the same either way; a shape in a square box turns when turned it takes other
// cells (an L) - which way round goes with it (GVAR(dragRot), the 7th element of its place record).
private _info = [(uiNamespace getVariable [QGVAR(dragEntry), createHashMap]) getOrDefault ["class", ""]] call EFUNC(items,getInfo);

if (_w == _h && {((_info getOrDefault ["footprint", [1, 1, []]]) param [2, []]) isEqualTo ((_info getOrDefault ["footprintTurned", [1, 1, []]]) param [2, []])}) exitWith {false};

GVAR(dragSize) = [_h, _w];

// Upright now: the cell in column c, row r goes to column h - 1 - r, row c; turned, the way back.
private _upright = GVAR(dragRot) == 0;

GVAR(dragRot) = 1 - GVAR(dragRot);

// Held by its middle, turned: the middle cell of the new shape.
GVAR(press) set [3, [floor (_h / 2), floor (_w / 2)]];

[_display] call FUNC(makeGhost);
[_display, getMousePosition] call FUNC(updateDrag);

// A tick, lower for a bigger item, for the looter alone (fnc_playSound).
["rotate", (uiNamespace getVariable [QGVAR(dragEntry), createHashMap]) getOrDefault ["class", ""], objNull, false] call FUNC(playSound);

true
