#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The modding view's point or box under a place on the screen (fnc_drawHotspots) - one that shows. Where a part let
 * go over the inspect card goes (fnc_updateDrag, fnc_onMouseButton).
 *
 * Arguments:
 * 0: Place on the screen [x, y] <ARRAY>
 *
 * Return Value:
 * The point, see fnc_drawHotspots - an empty HashMap when there is none <HASHMAP>
 *
 * Example:
 * [getMousePosition] call aio_gui_fnc_hotspotAt;
 *
 * Public: No
 */

disableSerialization;

params [["_point", [], [[]]]];

private _spots = uiNamespace getVariable [QGVAR(hotspots), []];
private _group = uiNamespace getVariable [QGVAR(inspectGroup), controlNull];

if (_spots isEqualTo [] || {isNull _group} || {count _point < 2}) exitWith {createHashMap};

_point params ["_pointX", "_pointY"];
(ctrlPosition _group) params ["_cardX", "_cardY"];

// The points over the picture first: they lie over it, the row beside it.
private _ordered = (_spots select {_x get "floating"}) + (_spots select {!(_x get "floating")});
private _index = _ordered findIf {
    (_x get "rel") params ["_relX", "_relY", "_relW", "_relH"];

    ctrlShown (_x get "ctrl")
    && {_pointX >= _cardX + _relX} && {_pointX < _cardX + _relX + _relW}
    && {_pointY >= _cardY + _relY} && {_pointY < _cardY + _relY + _relH}
};

if (_index < 0) exitWith {createHashMap};

_ordered select _index
