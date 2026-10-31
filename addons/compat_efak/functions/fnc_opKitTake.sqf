#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "kitTake": what a tile of a kit stands for out of the kit, at the kit's authority - the machine
 * where the phase's root is local (aio_storage_fnc_execute, which checked the kit lies under that root
 * first, fnc_holderVerify). All or nothing: the kit must hold that many with those rounds, else "Gone"
 * - somebody was quicker (fnc_takeFromKit). The payload goes on to the move's next op, or is settled
 * back into the kit (its "put", fnc_opKitPut). A whole tile's record leaves the kit's places; an
 * emptied kit goes when its type says so (fnc_removeIfEmpty).
 *
 * Arguments:
 * 0: Args, [kit holder "kit:" + lowercase class, entry array (aio_storage_fnc_entryToArray), how many
 *    - -1 for the whole tile] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (aio_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" taken; "Gone", "Moved" (no longer under the root), "Failed", or why not in words
 *              (that mod's contents have not reached this machine yet)
 *   produced - [payload] when taken (aio_storage_fnc_removeEntry's shapes)
 *   extra    - [kit removed when emptied BOOL] when taken, else []
 *
 * Example:
 * [["kit:efak_ifak_7", _entryArray, 1], _context] call aio_compat_efak_fnc_opKitTake;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];
_args params [["_holder", "", [""]], ["_entryArray", [], [[]]], ["_count", -1, [0]]];

if ((_holder select [0, 4]) isNotEqualTo "kit:" || {_entryArray isEqualTo []}) exitWith {["Failed", [], []]};

// That mod's contents are one table for every machine, tied to no place: only a kit that lies under
// this phase's root is this machine's to write.
if !([_holder, _context getOrDefault ["root", objNull]] call FUNC(holderVerify)) exitWith {["Moved", [], []]};

private _kit = _holder select [4];

([_kit, [_entryArray] call EFUNC(storage,entryFromArray), _count] call FUNC(takeFromKit)) params ["_status", "_payload"];

if (_status isNotEqualTo "") exitWith {[_status, [], []]};

private _removed = [_kit, _context getOrDefault ["root", objNull]] call FUNC(removeIfEmpty);

["", [_payload], [_removed]]
