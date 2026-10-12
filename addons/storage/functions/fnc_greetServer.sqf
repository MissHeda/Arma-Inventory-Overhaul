#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Asks the server which version of the hub it runs (einv_storage_hello [machine id, version]) as soon as
 * CBA's client id arrived (fnc_machineId; after 10 seconds without it, with clientOwner). The answer
 * (einv_storage_welcome) is kept in GVAR(serverVersion) (XEH_postInit). A server without the hub's
 * events, or with another version of them, would drop what this machine already took out: until it
 * answered with this very version nothing goes through it (fnc_hubReady).
 *
 * Asked again every 5 seconds until an answer came - a greeting sent before the server's event handler
 * was there, or an answer that came before this machine's, is simply lost -, after a minute every 30
 * seconds, with one RPT warning. Nothing on the server itself, nor in single player.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_storage_fnc_greetServer;
 *
 * Public: No
 */

if (isServer || {!isMultiplayer}) exitWith {};

private _fnc_greet = {
    params ["_fnc_greet", "_tries"];

    // Answered - with this version or another one: fnc_hubReady compares.
    if (GVAR(serverVersion) isNotEqualTo "") exitWith {};

    [QGVAR(hello), [call FUNC(machineId), QUOTE(VERSION_STR)]] call CBA_fnc_serverEvent;
    GVAR(greeted) = diag_tickTime;

    // A minute of 5 s tries: the server most likely runs no Enhanced Inventory at all.
    if (_tries == 12) then {
        WARNING("The server has not answered for a minute - moves through the server stay off until it does.");
    };

    [_fnc_greet, [_fnc_greet, _tries + 1], [5, 30] select (_tries >= 12)] call CBA_fnc_waitAndExecute;
};

[{CBA_clientID >= 0}, _fnc_greet, [_fnc_greet, 0], 10, _fnc_greet] call CBA_fnc_waitUntilAndExecute;
