#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The wheel over the catalog's pool: it moves the first visible row by one for every turn, the sign of the
 * event. The catalog's frame sets the pool's scroll to exactly that.
 *
 * Arguments:
 * 0: Scroll <NUMBER>
 * 1: Mouse position [x, y] <ARRAY>
 *
 * Return Value:
 * The wheel was over the pool and stepped it <BOOL>
 *
 * Example:
 * [1, getMousePosition] call einv_arsenal_fnc_catalogWheel;
 *
 * Public: No
 */

params [["_scroll", 0, [0]], ["_mouse", [], [[]]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _pool = _column getOrDefault ["pool", controlNull];

if (isNull _pool || {_scroll == 0} || {count _mouse < 2}) exitWith {false};

// Where the pool is on the screen now.
(ctrlPosition _pool) params ["_poolX", "_poolY", "_poolW", "_poolH"];
([createHashMapFromArray [["rel", [_poolX, _poolY]], ["parent", ctrlParentControlsGroup _pool]]] call EFUNC(gui,gridOrigin)) params ["_left", "_top"];
_mouse params ["_mouseX", "_mouseY"];

if (_mouseX < _left || {_mouseX >= _left + _poolW} || {_mouseY < _top} || {_mouseY >= _top + _poolH}) exitWith {false};

// A turn up goes up the list.
_column set ["wheel", (_column getOrDefault ["wheel", 0]) + ([1, -1] select (_scroll > 0))];

true
