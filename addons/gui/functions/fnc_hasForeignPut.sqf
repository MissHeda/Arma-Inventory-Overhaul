#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether another mod listens to the engine's "Put" event on a unit with a handler of its own
 * (addEventHandler) - a drone mod that deploys its drone from an item put on the ground does. This mod's own
 * handlers are CBA class handlers (XEH) and are not counted. Found by adding an empty handler for a moment and
 * asking the engine how many there are (getEventHandlerInfo: [exists, isLast, count]).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Another handler is there <BOOL>
 *
 * Example:
 * [player] call aio_gui_fnc_hasForeignPut;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

private _probe = _unit addEventHandler ["Put", {}];
private _info = getEventHandlerInfo [_unit, "Put", _probe];

_unit removeEventHandler ["Put", _probe];

private _total = _info param [2, 1];

if !(_total isEqualType 0) exitWith {false};

_total > 1
