#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Packs new items straight into a kit, in the ACE Arsenal: dragged out of ACE's list or the kits tab's list onto
 * the kit's grid or tile in the panel (einv_arsenal_fnc_onDrop), Ctrl and the wheel up over its tile
 * (einv_arsenal_fnc_onWheel). What the kits tab still has staged is written first (fnc_arsenalFlush), so the kit
 * is asked as that tab shows it. As many as the kit takes (fnc_canPackNew: the kit type's
 * Arsenal setting, that mod's rules, and its room - its capacity, or the free cells of a grid a rule or
 * its config gives it, fnc_roomMode), made from nothing (einv_storage_fnc_makePayload) and written into
 * the kit (fnc_putIntoKit, which asks the kit once more and ends in that mod's setContents); the tile's
 * record goes on the cell asked for when that is free, else where the kit's layout puts it.
 *
 * One writer per kit: it writes where it is called, outside any phase, and only for a root whose
 * transactions run on this machine (einv_storage_fnc_isLocalRoot) with the kit really under it
 * (fnc_holderVerify) - the soldier's own gear in the Arsenal, or its staging space -, as
 * einv_storage_fnc_addNew does for a container. The window is built again (fnc_requestRebuild).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Item class <STRING>
 * 2: How many <NUMBER> (default: 1)
 * 3: Cell [col, row, compartment, w, h, rot] in the kit's grid, [] for where its layout puts it
 *    <ARRAY> (default: [])
 * 4: Root of what the kit lies in <OBJECT> (default: objNull)
 *
 * Return Value:
 * [how many went in, why not all - "" when all did, a reason or words otherwise, the cell it landed on
 *  [col, row, compartment, w, h, rot] - [] when unknown] <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7", "ACE_fieldDressing", 5, [], player] call einv_compat_efak_fnc_packNew;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_class", "", [""]], ["_count", 1, [0]], ["_cell", [], [[]]], ["_root", objNull, [objNull]]];

if (
    _kit isEqualTo "" || {_class isEqualTo ""} || {_count < 1} || {isNull _root}
    || {!([_root] call EFUNC(storage,isLocalRoot))} || {!(["kit:" + toLowerANSI _kit, _root] call FUNC(holderVerify))}
) exitWith {[0, "Failed", []]};

[] call FUNC(arsenalFlush);

([_kit, _class, _count] call FUNC(canPackNew)) params ["_n", "_why"];

if (_n < 1) exitWith {[0, [_why, "Failed"] select (_why isEqualTo ""), []]};

private _payload = [_class, _n] call EFUNC(storage,makePayload);

([_kit, _payload, _cell] call FUNC(putIntoKit)) params ["_refused", "_landed"];

if (_refused isNotEqualTo "") exitWith {[0, _refused, []]};

[] call FUNC(requestRebuild);

[_n, ["", format [LLSTRING(SomeFit), _n, _count]] select (_n < _count), _landed]
