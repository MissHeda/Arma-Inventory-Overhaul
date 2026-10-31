#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The locked object a container belongs to: itself when it is locked, the object it is attached to when
 * that is locked (ACE cargo hangs a loaded crate under its vehicle), or the locked crate or vehicle it
 * lies in, a few containers deep - a backpack in a locked crate.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * The locked object, objNull when none <OBJECT>
 *
 * Example:
 * [_backpackContainer] call aio_locks_fnc_lockHolder;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container) exitWith {objNull};
if ((_container getVariable [QGVAR(lock), []]) isNotEqualTo []) exitWith {_container};

// Attached to a locked object counts as in it.
private _carrier = attachedTo _container;

if (!isNull _carrier && {(_carrier getVariable [QGVAR(lock), []]) isNotEqualTo []}) exitWith {_carrier};

private _objects = missionNamespace getVariable [QGVAR(objects), []];

if (_objects isEqualTo []) exitWith {objNull};

// Lying inside a locked one: whether `_container` is among the containers within `_outer`, to MAX_DEPTH.
private _fnc_inside = {
    params ["_outer", "_depth"];

    (everyContainer _outer) findIf {
        private _inner = _x select 1;

        _inner isEqualTo _container || {_depth < MAX_DEPTH && {[_inner, _depth + 1] call _fnc_inside}}
    } >= 0
};

// The inner call reads `_x` only through `_inner`, taken first - the outer record is never needed after it.
private _index = _objects findIf {!isNull _x && {[_x, 1] call _fnc_inside}};

if (_index < 0) exitWith {objNull};

_objects select _index
