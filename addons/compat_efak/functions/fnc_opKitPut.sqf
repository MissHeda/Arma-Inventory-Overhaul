#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Op "kitPut": a payload into a kit, at the kit's authority - the machine where the phase's root is
 * local (einv_storage_fnc_execute, which checked the kit lies under that root first,
 * fnc_holderVerify). Asked against what the kit holds now (fnc_putIntoKit, fnc_canPack): turned down -
 * by that mod's rules, its capacity, an empty magazine, a uniform, vest or backpack with something in
 * it - the payload is handed back, "Bounced", and settled where it came from, else into the vehicle or
 * onto the ground (einv_storage_fnc_settle). Else the kit is written and the record lies on the cell
 * asked for, or - taken by now - on the first free one ("put elsewhere"). Settlement puts payloads back
 * into a kit with this op too (einv_storage_holderTypes "kit" "put").
 *
 * Arguments:
 * 0: Args, [kit holder "kit:" + lowercase class, payload (a ref filled in by einv_storage_fnc_execute),
 *    cell [col, row, compartment, w, h] - [] for the first free one (default: [])] <ARRAY>
 * 1: Context - "requester", "where", "txId", "root", "settlement" (einv_storage_fnc_execute) <HASHMAP>
 *
 * Return Value:
 * [status, produced, extra] <ARRAY>
 *   status   - "" written; "Bounced" when the kit turned it down (the payload counts as consumed and is
 *              handed on); "Moved" when the kit no longer lies under the root and "Skipped" with no
 *              payload (it is not consumed - the storage settles it); "Failed" for no kit
 *   produced - [payload] when it bounced, else []
 *   extra    - [landed cell [col, row, compartment, w, h] or [], put elsewhere than asked BOOL, why the
 *              kit turned it down - "" when it did not]
 *
 * Example:
 * [["kit:efak_ifak_7", ["item", "ACE_fieldDressing", 3, []], [2, 0, 0, 1, 1]], _context] call einv_compat_efak_fnc_opKitPut;
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_context", createHashMap, [createHashMap]]];
_args params [["_holder", "", [""]], ["_payload", [], [[]]], ["_cell", [], [[]]]];

if ((_holder select [0, 4]) isNotEqualTo "kit:") exitWith {["Failed", [], []]};

// Nothing to put: the op that was to hand it on never did (a ref einv_storage_fnc_execute could not
// fill).
if (_payload isEqualTo [] || {(_payload select 0) isEqualTo "#ref"}) exitWith {["Skipped", [], []]};

// That mod's contents are one table for every machine, tied to no place: only a kit that lies under
// this phase's root is this machine's to write. Moved away meanwhile, the payload is not consumed - the
// storage settles it (einv_storage_fnc_settle).
if !([_holder, _context getOrDefault ["root", objNull]] call FUNC(holderVerify)) exitWith {["Moved", [], []]};

([_holder select [4], _payload, _cell] call FUNC(putIntoKit)) params ["_why", "_landed", "_elsewhere"];

if (_why isNotEqualTo "") exitWith {["Bounced", [+_payload], [[], false, _why]]};

["", [], [_landed, _elsewhere, ""]]
