#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The words for a move the server's hub did not take ("NotReady", fnc_flashHint): which of the three reasons it is
 * (aio_storage_fnc_hubState) - the server runs another version of this mod, with both versions named; the server has not
 * answered for a minute, so it most likely does not run this mod; or it has just not answered yet. One line said the same
 * for all three before (Steam report, 0.7.2: "waiting for server" on some sessions and not on others).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * call aio_gui_fnc_notReadyText;
 *
 * Public: No
 */

(call EFUNC(storage,hubState)) params ["_state", "_server", "_own"];

switch (_state) do {
    case "mismatch": {format [LLSTRING(Hint_ServerVersion), _server, _own]};
    case "silent": {LLSTRING(Hint_ServerSilent)};
    default {LLSTRING(Hint_NotReady)};
}
