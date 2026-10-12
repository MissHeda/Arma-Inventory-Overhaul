#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Why no kit may change through the window yet - asked before every move into or out of a kit, by the
 * kit ops where they run, and shown in an open kit's window in place of its grid. Enhanced First Aid
 * Kits' contents have to have reached this machine, or each kit would look empty.
 *
 * Whether the server takes what leaves the player's gear is no longer asked here: every move goes
 * through the storage's transactions, and the window hands nothing to the server's hub before the
 * server answered with this very version (einv_storage_fnc_hubReady, einv_gui_fnc_sendMoves).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * "" when kits may change, else why not, in words <STRING>
 *
 * Example:
 * call einv_compat_efak_fnc_notReady;
 *
 * Public: No
 */

["", LLSTRING(Loading)] select !(missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true])
