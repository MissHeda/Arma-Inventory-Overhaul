#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * One kit as a section of the window's kind (see fnc_getSections): the kit's picture and name, how full
 * it is, and what it holds - for a kit window (fnc_getSections) and for a kit unfolded in the ACE Arsenal's
 * panel (aio_arsenal_fnc_layout, fnc_arsenalKit).
 *
 * Arguments:
 * 0: Kit class <STRING>
 * 1: The container its tile lies in, objNull when it lies in another kit <OBJECT>
 * 2: The class of the kit it is packed in, "" when it lies in a container <STRING>
 * 3: The container the outermost kit lies in - whose root runs its ops, objNull when not known <OBJECT>
 *
 * Return Value:
 * The section, with the keys fnc_getSections lists <HASHMAP>
 *
 * Example:
 * ["efak_IFAK_7", backpackContainer player, "", backpackContainer player] call aio_compat_efak_fnc_kitSection;
 *
 * Public: No
 */

params [["_kit", "", [""]], ["_container", objNull, [objNull]], ["_parentKit", "", [""]], ["_top", objNull, [objNull]]];

private _key = "kit:" + toLowerANSI _kit;
private _title = [_kit] call FUNC(getName);

if (_title isEqualTo "") then {
    _title = ([_kit] call EFUNC(items,getInfo)) getOrDefault ["name", _kit];
};

private _synced = missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true];

// Why no kit may change yet, shown in place of the grid, so nothing can be dropped there (fnc_notReady).
private _wait = call FUNC(notReady);

// How full: that mod's mass against its capacity, or the cells of a grid of its own.
([_kit] call FUNC(fillState)) params ["_load", "_over"];

createHashMapFromArray [
    ["id", "kit"],
    ["title", _title],
    ["class", _kit],
    ["container", objNull],
    ["entries", if (_synced) then {[_kit] call FUNC(getEntries)} else {[]}],
    ["virtual", false],
    ["kit", _kit],
    ["key", _key],
    ["layoutKey", _key],
    ["holder", _key],
    ["root", if (isNull _top) then {objNull} else {[_top] call EFUNC(storage,rootOf)}],
    ["parent", if (_parentKit isEqualTo "") then {_container} else {"kit:" + toLowerANSI _parentKit}],
    ["load", _load],
    ["loadOver", _over],
    ["notice", _wait]
]
