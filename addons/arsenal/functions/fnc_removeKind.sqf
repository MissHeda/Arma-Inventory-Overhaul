#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes every one of a class out of the open uniform, vest or backpack ("Remove all" in a tile's menu):
 * tile after tile, each record first, through the storage (einv_storage_fnc_removeEntry) - read again
 * after each, as taking a weapon out puts its siblings back as new objects. ACE hears of it as of its own
 * removals (fnc_tellAce). Out of the staging space (fnc_staging) the same way, and ACE is not told -
 * only the panel is built again.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The staging crate to take it out of, objNull for the open container <OBJECT> (default: objNull)
 *
 * Return Value:
 * Something was taken out <BOOL>
 *
 * Example:
 * ["ACE_fieldDressing"] call einv_arsenal_fnc_removeKind;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_from", objNull, [objNull]]];

(call FUNC(selected)) params ["", "_container"];

// Apart from ACE's list: the staging space or another worn container.
private _staged = !isNull _from && {_from isNotEqualTo _container};

if (_staged) then {
    _container = _from;
};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];

if (_class isEqualTo "" || {isNull _container} || {!local _center}) exitWith {false};

private _key = toLowerANSI _class;
private _before = [_container, _class] call EFUNC(storage,countClass);

// One tile a turn, at most as many turns as there are things of the class: a tile that will not come out
// cannot hold this up.
for "_i" from 1 to _before do {
    // Laid out, so each knows the cell its record is found by (einv_storage_fnc_setPlace).
    private _contents = [_container] call EFUNC(storage,getContents);
    [_container, _contents] call EFUNC(storage,getLayout);

    private _entries = _contents select {toLowerANSI (_x getOrDefault ["class", ""]) isEqualTo _key};

    if (_entries isEqualTo []) exitWith {};

    private _entry = _entries select 0;

    [_container, _entry, []] call EFUNC(storage,setPlace);

    if (([_container, _entry, -1] call EFUNC(storage,removeEntry)) isEqualTo []) exitWith {};
};

private _after = [_container, _class] call EFUNC(storage,countClass);

if (_after == _before) exitWith {
    ["Failed"] call EFUNC(gui,flashHint);
    false
};

["giveBack", _class, objNull, false] call EFUNC(gui,playSound);

// Kits taken away for good: their instances back to that mod's pool (einv_compat_efak_fnc_arsenalFree).
if (!isNil QEFUNC(compat_efak,arsenalFree)) then {
    [[_class], [uniformContainer _center, vestContainer _center, backpackContainer _center, GVAR(staging)]] call EFUNC(compat_efak,arsenalFree);
};

if (_staged) exitWith {
    [] call FUNC(settle);
    true
};

[_class, _before, _after] call FUNC(tellAce);

true
