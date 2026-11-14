#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Why moves that need the server's hub may not be sent yet (fnc_hubReady), so the window can say it (aio_gui_fnc_notReadyText):
 * the server answered with another version of this mod ("mismatch"), has not answered for HUB_SILENT seconds - most likely it
 * does not run this mod at all - ("silent"), or has just not answered yet, as in the first seconds after joining ("waiting").
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [state, server's version, this machine's version] - state "ready", "waiting", "silent" or "mismatch"; the server's version
 * "" until it answered <ARRAY>
 *
 * Example:
 * call aio_storage_fnc_hubState;
 *
 * Public: No
 */

// As long as fnc_greetServer asks every 5 seconds before it warns in the RPT.
#define HUB_SILENT 60

private _own = QUOTE(VERSION_STR);
private _server = missionNamespace getVariable [QGVAR(serverVersion), ""];

if (call FUNC(hubReady)) exitWith {["ready", _server, _own]};
if (_server isNotEqualTo "") exitWith {["mismatch", _server, _own]};

// Counted from the first greeting; none sent yet - CBA's client id has not arrived - is waiting still.
private _since = missionNamespace getVariable [QGVAR(greetedAt), -1];

[["waiting", "silent"] select (_since >= 0 && {diag_tickTime - _since > HUB_SILENT}), _server, _own]
