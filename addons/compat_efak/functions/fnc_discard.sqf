#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes things out of a kit and away, in the ACE Arsenal: a tile of the kit's grid in the panel dragged out
 * onto ACE's list, Ctrl+wheel down over it (einv_arsenal_fnc_remove). The counterpart of fnc_packNew: the kit
 * type's Arsenal setting must allow a change (efak_core_fnc_canPackInto with the Arsenal), the kit must lie
 * under a root whose phases run on this machine (einv_storage_fnc_isLocalRoot, fnc_holderVerify), and the
 * tile is taken out as a window's take-out does (fnc_takeFromKit: all or nothing, the tile's record leaving
 * the kit's places), outside any phase, so the one writer of the kit is this machine. The window is built
 * again (fnc_requestRebuild). An emptied kit stays where it is.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: The tile, as the grid shows it <HASHMAP>
 * 2: How many of it, -1 for the whole tile <NUMBER> (default: -1)
 * 3: Root of what the kit lies in <OBJECT> (default: objNull)
 *
 * Return Value:
 * [how many were taken out - 0 or the count the tile held, why not - "" when it went] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", _tile, 1, player] call einv_compat_efak_fnc_discard;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_entry", createHashMap, [createHashMap]], ["_count", -1, [0]], ["_root", objNull, [objNull]]];

if (
    _kit isEqualTo "" || {count _entry == 0} || {isNull _root}
    || {!([_root] call EFUNC(storage,isLocalRoot))} || {!(["kit:" + toLowerANSI _kit, _root] call FUNC(holderVerify))}
) exitWith {[0, "Failed"]};

private _wait = [] call FUNC(notReady);

if (_wait isNotEqualTo "") exitWith {[0, _wait]};

if (!isNil QEFAKFUNC(core,canPackInto) && {!([_kit, true] call EFAKFUNC(core,canPackInto))}) exitWith {
    [0, LLSTRING(ArsenalReadOnly)]
};

([_kit, _entry, _count] call FUNC(takeFromKit)) params ["_status"];

if (_status isNotEqualTo "") exitWith {[0, _status]};

[] call FUNC(requestRebuild);

[[_count, _entry getOrDefault ["count", 1]] select (_count < 1), ""]
