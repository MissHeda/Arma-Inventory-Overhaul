#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "kitRemoveIfEmpty": Enhanced First Aid Kits' "remove when empty", at the kit's authority - an
 * emptied kit whose type says so taken out of the container or kit it lies in under the phase's root,
 * its instance freed and its places dropped (fnc_removeIfEmpty). The kit ops that empty a kit do this
 * themselves (fnc_opKitTake, fnc_opKitMove); this is for a phase that names it on its own. Where the
 * kit lies is read off the cargo under the root: the holder the window found is only what it saw then.
 *
 * Arguments:
 * 0: Args, [kit holder "kit:" + lowercase class, where the window found it [container, kit it is packed
 *    in] (default: [])] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" - a kit that is not empty, or whose type keeps it, simply stays; "Failed" for no kit
 *   produced - []
 *   extra    - [removed BOOL]
 *
 * Example:
 * [["kit:efak_ifak_7", [_container, ""]], _context] call aio_compat_efak_fnc_opKitRemoveIfEmpty;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];
_args params [["_holder", "", [""]]];

if ((_holder select [0, 4]) isNotEqualTo "kit:") exitWith {["Failed", [], []]};

["", [], [[_holder select [4], _context getOrDefault ["root", objNull]] call FUNC(removeIfEmpty)]]
