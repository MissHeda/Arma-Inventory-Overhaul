#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a unit wears, slot by slot, read from its loadout - which works the same for the living and the
 * dead, and gives every weapon with its attachments and loaded magazines in one go.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * The equipment <HASHMAP>
 *   "primary", "launcher", "handgun", "binocular" - [class, muzzle, rail, optic, [magazine, rounds] or [],
 *       [second magazine, rounds] or [], bipod], [] when the slot is empty <ARRAY>
 *   "uniform", "vest", "backpack", "headgear", "goggles", "map", "gps", "radio", "compass", "watch",
 *       "nvg" - class name, "" when the slot is empty <STRING>
 *   "primary2" - the second primary on the back, as the weapons, [] when empty - only on a unit that has
 *       that slot: with WebKnight's or KJW's Two Primary Weapons loaded (fnc_secondPrimary) <ARRAY>
 *
 * Example:
 * [player] call aio_storage_fnc_getEquipment;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

private _loadout = [];

if (!isNull _unit) then {
    _loadout = getUnitLoadout _unit;
};

if (isNil "_loadout" || {!(_loadout isEqualType [])}) then {_loadout = []};

_loadout params [
    ["_primary", [], [[]]],
    ["_launcher", [], [[]]],
    ["_handgun", [], [[]]],
    ["_uniform", [], [[]]],
    ["_vest", [], [[]]],
    ["_backpack", [], [[]]],
    ["_headgear", "", [""]],
    ["_goggles", "", [""]],
    ["_binocular", [], [[]]],
    ["_assigned", [], [[]]]
];

// The assigned items always come in this order, "" where one is missing.
_assigned params [
    ["_map", "", [""]],
    ["_gps", "", [""]],
    ["_radio", "", [""]],
    ["_compass", "", [""]],
    ["_watch", "", [""]],
    ["_nvg", "", [""]]
];

private _equipment = createHashMapFromArray [
    ["primary", _primary],
    ["launcher", _launcher],
    ["handgun", _handgun],
    ["binocular", _binocular],
    ["uniform", _uniform param [0, "", [""]]],
    ["vest", _vest param [0, "", [""]]],
    ["backpack", _backpack param [0, "", [""]]],
    ["headgear", _headgear],
    ["goggles", _goggles],
    ["map", _map],
    ["gps", _gps],
    ["radio", _radio],
    ["compass", _compass],
    ["watch", _watch],
    ["nvg", _nvg]
];

// The weapon on the back that one of the two-primary mods keeps outside the loadout - a slot of its own.
([_unit] call FUNC(secondPrimary)) params ["_hasSecond", "_second"];

if (_hasSecond) then {
    _equipment set ["primary2", _second];
};

_equipment
