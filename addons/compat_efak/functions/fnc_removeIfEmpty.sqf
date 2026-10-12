#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Enhanced First Aid Kits' "remove when empty": a kit emptied through the window goes, where its type's
 * setting says so (off unless the mission sets it), and its id is handed back to that mod
 * (efak_core_fnc_freeInstance). Its window closes when the kit windows are next drawn - the kit is found
 * nowhere (fnc_getSections, einv_gui_fnc_drawWindows).
 *
 * Only inside a kit op, on the machine where the kit's root is local - the op that emptied it
 * (fnc_opKitTake, fnc_opKitMove) or "kitRemoveIfEmpty" (fnc_opKitRemoveIfEmpty): where it lies is read
 * off the real cargo under that root (fnc_locate), never from a window. Out of exactly the container it
 * lies in - nested ones too - with the storage's verified removal (einv_storage_fnc_removeEntry), its
 * record with it; a kit packed in another kit leaves that one's contents, a write of that kit. Done
 * here rather than by that mod's removeKit, which only knows its holder's top-level cargo.
 *
 * Its places go as well (einv_storage_fnc_dropPlaces) - first, while it still lies under the root, as
 * an empty kit has nothing on them to keep: that mod hands its class to the next kit of the type, which
 * must start unsorted instead of inheriting the arrangement.
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: Root of the phase it runs in <OBJECT>
 *
 * Return Value:
 * Removed <BOOL>
 *
 * Example:
 * ["efak_ifak_7", player] call einv_compat_efak_fnc_removeIfEmpty;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_root", objNull, [objNull]]];

if (
    _kit isEqualTo ""
    || {isNull _root}
    || {([_kit] call EFAKFUNC(core,getContents)) isNotEqualTo []}
    || {!([_kit, "removeWhenEmpty", false] call EFAKFUNC(core,getKitSetting))}
) exitWith {false};

([_kit, [], _root] call FUNC(locate)) params ["_holder", "_top"];

// Found nowhere under the root: somebody took it meanwhile - it is not this phase's to remove.
if (isNull _top) exitWith {false};

_holder params [["_container", objNull, [objNull]], ["_parent", "", [""]]];

private _kitKey = "kit:" + toLowerANSI _kit;

[_kitKey] call EFUNC(storage,dropPlaces);
EGVAR(storage,cache) deleteAt _kitKey;

// Packed in another kit: out of that one's contents, its tile's record with it.
if (_parent isNotEqualTo "") exitWith {
    private _view = [_parent, true] call FUNC(getEntries);
    private _index = _view findIf {(_x getOrDefault ["class", ""]) == _kit};

    if !([_parent, _kit, -1] call FUNC(changeKit)) exitWith {false};

    private _parentKey = "kit:" + toLowerANSI _parent;

    if (_index >= 0) then {
        [_parentKey, _view select _index, []] call EFUNC(storage,setPlace);
    };

    EGVAR(storage,cache) deleteAt _parentKey;

    if (!isNil QEFAKFUNC(core,freeInstance)) then {
        [_kit] call EFAKFUNC(core,freeInstance);
    };

    true
};

// In a container: its tile there, where it lies - the record is found by its cell.
private _entries = ([_container, [_container] call EFUNC(storage,getContents)] call EFUNC(storage,getLayout)) getOrDefault ["entries", []];
private _index = _entries findIf {(_x getOrDefault ["class", ""]) == _kit};

if (_index < 0) exitWith {false};

private _tile = _entries select _index;
private _payload = [_container, _tile, 1] call EFUNC(storage,removeEntry);

// Verified: only what really left. Should it not have, it stays where it is - empty, nothing lost.
if (_payload isEqualTo []) exitWith {false};

[_container, _tile, []] call EFUNC(storage,setPlace);
EGVAR(storage,cache) deleteAt (netId _container);

// That mod's own (Public: No) - should it ever be missing, the kit keeps its id until the pool comes
// round to it again.
if (!isNil QEFAKFUNC(core,freeInstance)) then {
    [_kit] call EFAKFUNC(core,freeInstance);
};

true
