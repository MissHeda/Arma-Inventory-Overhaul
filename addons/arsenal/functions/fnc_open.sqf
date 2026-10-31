#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the arsenal of a box, from the inventory window's context menu. The inventory closes first and
 * the arsenal opens a frame later: two dialogs on top of each other would fight over the keys, closing it
 * stops its camera before the arsenal brings its own, and the grid panel can only move into ACE's window
 * once the inventory has let go of the engine (fnc_onOpened). An ACE box opens ACE Arsenal (openBox); a
 * box that is only a vanilla one goes through the vanilla arsenal's function, which lands in the mode the
 * server chose (fnc_handleBIOpen) - by default ACE Arsenal with the same items.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Box <OBJECT>
 *
 * Return Value:
 * Opening <BOOL>
 *
 * Example:
 * [player, cursorObject] call aio_arsenal_fnc_open;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_box", objNull, [objNull]]];

// The menu was opened a moment ago; things may have changed since.
if !([_unit, _box] call FUNC(canOpen)) exitWith {false};

private _isAceBox = !isNil {_box getVariable QACEGVAR(arsenal,virtualItems)};

(uiNamespace getVariable [QEGVAR(gui,display), displayNull]) closeDisplay 2;

[{
    params ["_unit", "_box", "_isAceBox"];

    if (_isAceBox) exitWith {
        [_box, _unit] call ACEFUNC(arsenal,openBox);
    };

    ["Open", [false, _box, _unit]] call BIS_fnc_arsenal;
}, [_unit, _box, _isAceBox]] call CBA_fnc_execNextFrame;

true
