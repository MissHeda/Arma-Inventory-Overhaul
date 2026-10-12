#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a requester can still reach a root, asked by the machine that executes (fnc_execute): always
 * for a requester who left (null), for the requester's own unit and for work of the server's own
 * (objNull); else the distance to the root - to what it hangs under when attached, as ACE cargo hangs
 * loaded objects under their vehicle - within the reach (einv_storage_nearbyRange, 3 m where it is not
 * set) plus REACH_SLACK plus half the root's size.
 *
 * Arguments:
 * 0: Requester <OBJECT>
 * 1: Root <OBJECT>
 *
 * Return Value:
 * In reach <BOOL>
 *
 * Example:
 * [player, cursorObject] call einv_storage_fnc_inReach;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_root", objNull, [objNull]]];

// A requester who left: what they started goes on to the end. Their own gear, and the server's own
// ground work, are nothing to reach for.
if (isNull _unit || {isNull _root} || {_unit isEqualTo _root}) exitWith {true};

// ACE cargo hangs a loaded crate under its vehicle - the vehicle is where it is.
private _target = attachedTo _root;

if (isNull _target) then {
    _target = _root;
};

// The reach setting arrives with the nearby boxes; until then, and should a mission break it, 3 m.
private _range = missionNamespace getVariable [QGVAR(nearbyRange), 3];

if !(_range isEqualType 0) then {
    _range = 3;
};

// Half the diagonal of its box: a truck is reached at its side, not at its middle. Positions reach the
// executing machine late, which REACH_SLACK covers.
(boundingBoxReal _target) params [["_min", [0, 0, 0], [[]]], ["_max", [0, 0, 0], [[]]]];

(_unit distance _target) <= _range + REACH_SLACK + (_min distance _max) / 2
