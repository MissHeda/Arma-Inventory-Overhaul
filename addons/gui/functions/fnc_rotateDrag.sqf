#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * R while dragging: turns what is held a quarter round - its width becomes its height. The grabbed
 * cell turns along, so the item stays under the mouse, and the footprint shows where it lands now.
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

// A square item looks the same either way.
if (_w == _h) exitWith {false};

GVAR(dragSize) = [_h, _w];

(GVAR(press) param [3, [0, 0]]) params ["_grabCol", "_grabRow"];
GVAR(press) set [3, [_grabRow min (_h - 1), _grabCol min (_w - 1)]];

[_display] call FUNC(makeGhost);
[_display, getMousePosition] call FUNC(updateDrag);

// A tick, lower for a bigger item, for the looter alone (fnc_playSound).
["rotate", (uiNamespace getVariable [QGVAR(dragEntry), createHashMap]) getOrDefault ["class", ""], objNull, false] call FUNC(playSound);

true
