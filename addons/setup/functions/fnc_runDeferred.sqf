#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Runs what fnc_defer queued and whose time has come, in the order it was queued. The queue is taken
 * first: code that queues more - a redraw whose new buttons are clicked at once - starts a queue of its
 * own rather than running inside this one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_setup_fnc_runDeferred;
 *
 * Public: No
 */

private _queue = uiNamespace getVariable [QGVAR(deferred), []];

if (_queue isEqualTo []) exitWith {};

private _now = diag_tickTime;
private _due = _queue select {(_x select 2) <= _now};

if (_due isEqualTo []) exitWith {};

uiNamespace setVariable [QGVAR(deferred), _queue select {(_x select 2) > _now}];

{
    _x params ["_code", "_arguments"];

    _arguments call _code;
} forEach _due;
