#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Where a plain click on one of the soldier's slots takes the catalog: the group and category that slot is
 * browsed from, and for a weapon's part the slot of the weapon it has to fit.
 *
 * For an attachment's slot the third element is the weapon's slot ("primary"), for a magazine's the slot
 * itself ("primary_mag2": from the second magazine's only the second muzzle's magazines are listed). A
 * weapon the soldier does not have leaves it empty - the catalog then fits what it usually does.
 *
 * Arguments:
 * 0: Slot id, as in einv_storage_fnc_getSlot <STRING>
 *
 * Return Value:
 * [group, category, fits slot], [] for a slot with no category <ARRAY>
 *
 * Example:
 * ["primary_optic"] call einv_arsenal_fnc_categoryForSlot;
 *
 * Public: No
 */

params [["_slot", "", [""]]];

(_slot splitString "_") params [["_base", ""], ["_part", ""]];

private _id = "";
private _fits = "";

switch (true) do {
    case (_part isEqualTo "" && {_base isEqualTo "primary"}): {_id = "rifle"};
    case (_part isEqualTo "" && {_base in [
        "handgun", "launcher", "binocular", "headgear", "uniform", "vest", "backpack", "goggles", "nvg",
        "map", "compass", "watch", "radio", "gps"
    ]}): {_id = _base};
    case (_base in ["primary", "handgun", "launcher"] && {_part in ["optic", "rail", "muzzle", "bipod"]}): {
        _id = _part;
        _fits = _base;
    };
    case (_base in ["primary", "handgun", "launcher"] && {_part in ["mag", "mag2"]}): {
        _id = "magazine";
        _fits = _slot;
    };
    default {};
};

if (_id isEqualTo "") exitWith {[]};

// A weapon that is not there fits nothing to speak of.
if (_fits isNotEqualTo "" && {((([GVAR(center)] call EFUNC(storage,getEquipment)) getOrDefault [_base, []]) param [0, ""]) isEqualTo ""}) then {
    _fits = "";
};

private _index = (call FUNC(categories)) findIf {(_x select 0) isEqualTo _id};

if (_index < 0) exitWith {[]};

[((call FUNC(categories)) select _index) select 1, _id, _fits]
