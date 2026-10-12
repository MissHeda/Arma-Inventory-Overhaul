#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The mouse wheel turned (the "wheel" hook): over the catalog it steps one row of cards, in the free middle
 * it zooms - the distance changes by a tenth of a metre a step as ACE's does, within ACE's limits raised by
 * how close the soldier may come and stay in the middle (fnc_cameraRect).
 *
 * Arguments:
 * 0: Scroll <NUMBER>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [1, getMousePosition] call einv_arsenal_fnc_onWheel;
 *
 * Public: No
 */

params [["_scroll", 0, [0]], ["_mouse", [], [[]]]];

if (_scroll == 0 || {count _mouse < 2}) exitWith {false};

// The catalog's pool first: it knows where it is (and is away while the panels are hidden).
if (!GVAR(hidden) && {[_scroll, _mouse] call FUNC(catalogWheel)}) exitWith {true};

private _unit = GVAR(center);

if (isNull GVAR(camera) || {isNull _unit}) exitWith {false};

// Only in the middle, and only where nothing floats: the same test as the turning.
if !([0, _mouse, false, false, false, true] call FUNC(onMouseDown)) exitWith {false};

(boundingBoxReal _unit) params ["_low", "_high"];

private _diagonal = (_low vectorDistance _high) * 1.5;
private _maximum = _diagonal max GVAR(cameraMinDistance);
private _minimum = (_diagonal * 0.15) max GVAR(cameraMinDistance);

GVAR(cameraPosition) set [0, ((GVAR(cameraPosition) select 0) - _scroll / 10) max _minimum min _maximum];

true
