#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a slot (fnc_drawSlot) is on the screen right now, cut to what its group shows. The area a slot
 * registers is where it was drawn - before fnc_build scrolls its column back to where it stood - so it
 * is only right for a slot outside any group. A slot that also registered where it lies in its group
 * (its anchor, with "rel" and "parent") is placed through that group's scroll (fnc_gridOrigin).
 *
 * Arguments:
 * 0: Slot, as registered in uiNamespace QGVAR(slots) <ARRAY>
 *
 * Return Value:
 * [x, y, w, h] on the screen, [] when it is scrolled out of view <ARRAY>
 *
 * Example:
 * [(uiNamespace getVariable [QGVAR(slots), []]) select 0] call einv_gui_fnc_slotRect;
 *
 * Public: No
 */

disableSerialization;

params ["_slot"];
_slot params [["_rect", [0, 0, 0, 0]], "", "", ["_anchor", createHashMap]];

if !(_anchor isEqualType createHashMap && {"parent" in _anchor} && {"rel" in _anchor}) exitWith {_rect};

private _parent = _anchor get "parent";

if (isNull _parent) exitWith {_rect};

([_anchor] call FUNC(gridOrigin)) params ["_left", "_top"];
(ctrlPosition _parent) params ["_groupX", "_groupY", "_groupW", "_groupH"];

private _outer = createHashMapFromArray [["rel", [_groupX, _groupY]], ["parent", ctrlParentControlsGroup _parent]];
([_outer] call FUNC(gridOrigin)) params ["_boxX", "_boxY"];

private _x0 = _left max _boxX;
private _y0 = _top max _boxY;
private _x1 = (_left + (_rect select 2)) min (_boxX + _groupW);
private _y1 = (_top + (_rect select 3)) min (_boxY + _groupH);

if (_x1 <= _x0 || {_y1 <= _y0}) exitWith {[]};

[_x0, _y0, _x1 - _x0, _y1 - _y0]
