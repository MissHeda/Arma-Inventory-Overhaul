#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether moves that need the server's hub may be sent: in single player and in Eden, on the server,
 * and on a client whose greeting the server answered with this very version (GVAR(serverVersion),
 * fnc_greetServer). The window refuses such moves before that ("NotReady"): a server without the hub's
 * events, or with others, would drop what this machine already took out.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Ready <BOOL>
 *
 * Example:
 * call einv_storage_fnc_hubReady;
 *
 * Public: No
 */

!isMultiplayer || {isServer} || {(missionNamespace getVariable [QGVAR(serverVersion), ""]) isEqualTo QUOTE(VERSION_STR)}
