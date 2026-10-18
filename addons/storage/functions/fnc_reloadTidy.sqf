#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * After a reload by the engine's action (fnc_loadMagazine) with the "Use items from ..." settings active: the
 * magazine the game put away may have landed in a container the settings close. It is moved to the container
 * the new magazine came from - where a cell was freed - when that has room for it. Nothing is moved when it
 * landed in a usable container, when the source is gone or full, or when the game did not change the counts.
 * Once per reload; nothing repeats.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The magazine the weapon had, [class, rounds] <ARRAY>
 * 2: The kind the new magazine came from - "uniform", "vest" or "backpack" <STRING>
 * 3: How many magazines of that class and rounds each container held before, [uniform, vest, backpack] <ARRAY>
 *
 * Return Value:
 * It was moved <BOOL>
 *
 * Example:
 * [player, ["30Rnd_65x39_caseless_mag", 30], "vest", [0, 1, 0]] call einv_storage_fnc_reloadTidy;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_old", [], [[]]], ["_kind", "", [""]], ["_before", [], [[]]]];

_old params [["_class", "", [""]], ["_rounds", 0, [0]]];

if (isNull _unit || {!alive _unit} || {_class isEqualTo ""} || {count _before < 3} || {!(missionNamespace getVariable [QGVAR(useActive), false])}) exitWith {false};

private _containers = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _toAt = USE_KINDS find (toLowerANSI _kind);

if (_toAt < 0) exitWith {false};

private _to = _containers select _toAt;

if (isNull _to) exitWith {false};

private _fnc_count = {
    params [["_box", objNull, [objNull]]];

    if (isNull _box) exitWith {0};

    {(_x select 0) == _class && {(_x select 1) == _rounds}} count (magazinesAmmoCargo _box)
};

// The container the old magazine was put into: one that holds more of it than before.
private _at = _containers findIf {(([_x] call _fnc_count) > (_before select (_containers find _x))) && {!isNull _x}};

if (_at < 0) exitWith {false};

private _from = _containers select _at;

// Already where the new one came from, or in a container that may be used.
if (_from isEqualTo _to || {([_class, USE_KINDS select _at] call FUNC(useState)) isNotEqualTo "blocked"}) exitWith {false};

private _capacity = getNumber (configFile >> "CfgMagazines" >> _class >> "count");
private _probe = createHashMapFromArray [
    ["class", _class], ["count", 1], ["ammo", _rounds], ["capacity", _capacity], ["attachments", []], ["container", objNull]
];

if !([_to, _probe] call FUNC(hasSpace)) exitWith {false};

private _had = [_to] call _fnc_count;

_from addMagazineAmmoCargo [_class, -1, _rounds];
_to addMagazineAmmoCargo [_class, 1, _rounds];

// The source would not take it: back where the game had put it.
if (([_to] call _fnc_count) <= _had) exitWith {
    _from addMagazineAmmoCargo [_class, 1, _rounds];

    false
};

[_unit] call FUNC(queueMigrate);
[_unit] call FUNC(useTrack);

true
