#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * This machine's id on the network: CBA_clientID once the server sent it, else clientOwner. CBA:
 * clientOwner is unreliable in saved games, and CBA_clientID is -1 until the server's value arrived and
 * in Eden.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Machine id <NUMBER>
 *
 * Example:
 * call aio_storage_fnc_machineId;
 *
 * Public: No
 */

// Read with a default: Eden and the very start of a mission may not have it yet.
private _cba = missionNamespace getVariable ["CBA_clientID", -1];

if (_cba isEqualType 0 && {_cba >= 0}) exitWith {_cba};

clientOwner
