#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Makes the locks the mission maker set in Eden ("Inventory locked to" and "Group callsign" in the
 * category Enhanced Inventory), on the server at the start, once every object has its own values (the
 * attribute expressions only queue the objects: einv_locks_edenQueue).
 *
 * A side or the admins lock at once. "One group": a callsign found among the groups becomes that group -
 * the lock then follows a rename -, one not found is matched by name from then on; without a callsign
 * the object is locked to the admins (closed rather than open: the mission maker meant it locked), with
 * a warning in the RPT. A callsign two groups share belongs to the first group found.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_locks_fnc_applyEden;
 *
 * Public: No
 */

if (!isServer) exitWith {};

private _sides = createHashMapFromArray [["west", west], ["east", east], ["independent", independent], ["civilian", civilian]];

{
    private _object = _x;

    if (isNull _object) then {continue};

    private _mode = _object getVariable [QGVAR(edenMode), ""];
    private _callsign = _object getVariable [QGVAR(edenGroup), ""];

    if (_mode in _sides) then {
        [_object, "side", _sides get _mode] call FUNC(setLock);
    };

    if (_mode isEqualTo "admins") then {
        [_object, "admins"] call FUNC(setLock);
    };

    if (_mode isEqualTo "group") then {
        if (_callsign isEqualTo "") then {
            // Without a callsign: closed rather than open.
            WARNING_1("%1 is locked to one group in Eden without a callsign - locked to admins instead.",_object);
            [_object, "admins"] call FUNC(setLock);
        } else {
            private _index = allGroups findIf {(groupId _x) == _callsign};

            if (_index < 0) then {
                WARNING_2("%1: no group with the callsign '%2' at the start - matched by callsign from now on.",_object,_callsign);
                [_object, "group", _callsign] call FUNC(setLock);
            } else {
                [_object, "group", allGroups select _index] call FUNC(setLock);
            };
        };
    };
} forEach GVAR(edenQueue);

GVAR(edenQueue) = [];
