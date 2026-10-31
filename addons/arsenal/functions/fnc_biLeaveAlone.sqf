#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * With the setting on "leave it alone": notes the unit when the vanilla arsenal is about to open and, after
 * it closed, passes what does not fit the grid on to the unit's next container with room and reports what
 * has nowhere to go (fnc_reportOverflow). Nothing is removed - the mission chose the vanilla arsenal.
 *
 * The vanilla arsenal forgets its unit before it says it closed, so the unit is kept from the opening. The
 * Virtual Garage raises no opening, so it never reports. The Eden editor never reports: the unit there is
 * a temporary copy.
 *
 * Arguments:
 * 0: "open" before the vanilla arsenal opens, "closed" after it <STRING>
 * 1: Unit <OBJECT> (default: objNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["open", player] call aio_arsenal_fnc_biLeaveAlone;
 *
 * Public: No
 */

params [["_when", "", [""]], ["_unit", objNull, [objNull]]];

if (is3DEN) exitWith {};

if (_when isEqualTo "open") exitWith {
    GVAR(biLeave) = [_unit];
};

if (_when isNotEqualTo "closed" || {GVAR(biLeave) isEqualTo []}) exitWith {};

private _center = GVAR(biLeave) select 0;
GVAR(biLeave) = [];

if (isNull _center) exitWith {};

// A frame later: the vanilla arsenal is gone, the unit's gear is as it left it. What it holds beyond the grid
// moves on to the next container with room first (aio_storage op "migrate", nothing moves under an open
// arsenal), then what has nowhere to go is reported.
[{
    params ["_center"];

    [_center] call EFUNC(storage,requestMigrate);
    [_center, displayNull] call FUNC(reportOverflow);
}, [_center]] call CBA_fnc_execNextFrame;
