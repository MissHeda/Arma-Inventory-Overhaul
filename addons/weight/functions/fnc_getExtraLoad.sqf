#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the weight overrides of the rules add to everything a unit carries, in config mass: for every
 * item, its weight by the rules less its weight by config, times how many of it the unit carries.
 * Below zero when the rules make things lighter, 0 when nothing carried has an override.
 *
 * Everything the unit carries counts: what it wears (uniform, vest, backpack, headgear, goggles, NVG,
 * binocular and the assigned items), its weapons with their attachments and loaded magazines, and
 * everything in its uniform, vest and backpack - weapons in there with their attachments and
 * magazines too, and uniforms, vests and backpacks lying in there with whatever they hold.
 *
 * The weights come from einv_items_fnc_getInfo: "mass" is the weight by the rules, "configMass" the
 * config's. An item without "configMass" has no override.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Extra load, in tenths of a pound like config mass <NUMBER>
 *
 * Example:
 * [player] call einv_weight_fnc_getExtraLoad;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {0};

// How many of each class the unit carries, lowercase class -> count. Counted first and weighed once
// per class afterwards: a rifleman carries a dozen of the same magazine.
private _carried = createHashMap;

private _fnc_count = {
    params ["_class", ["_count", 1]];

    if (!(_class isEqualType "") || {_class isEqualTo ""}) exitWith {};

    private _key = toLowerANSI _class;
    _carried set [_key, (_carried getOrDefault [_key, 0]) + _count];
};

// [weapon, muzzle, rail, optic, [magazine, rounds] or [], [second magazine, rounds] or [], bipod] -
// a weapon's shape in a loadout and in weaponsItemsCargo alike. Empty parts are "" or [].
private _fnc_countWeapon = {
    {
        if (_x isEqualType "") then {[_x] call _fnc_count};
        if (_x isEqualType [] && {_x isNotEqualTo []}) then {[_x select 0] call _fnc_count};
    } forEach _this;
};

// A uniform's, vest's or backpack's container object, and whatever lies inside it.
private _fnc_countContainer = {
    params ["_container", "_depth"];

    if (isNull _container || {_depth > MAX_DEPTH}) exitWith {};

    private _weapons = weaponsItemsCargo _container;

    if (isNil "_weapons") then {_weapons = []};

    {
        _x call _fnc_countWeapon;
    } forEach _weapons;

    // [[classes], [counts]] each. A uniform or vest lying in here is one of the items, a backpack one
    // of the backpacks.
    {
        _x params [["_classes", [], [[]]], ["_counts", [], [[]]]];

        {
            [_x, _counts param [_forEachIndex, 1]] call _fnc_count;
        } forEach _classes;
    } forEach [getMagazineCargo _container, getItemCargo _container, getBackpackCargo _container];

    // What those uniforms, vests and backpacks hold is in none of this container's lists - only in
    // their own.
    {
        [_x select 1, _depth + 1] call _fnc_countContainer;
    } forEach (everyContainer _container);
};

// What the unit wears, read from its loadout. Its contents lists are left alone: they do not see into
// a uniform, vest or backpack lying inside, the container objects below do.
private _loadout = getUnitLoadout _unit;

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

// Weapons with their attachments and loaded magazines - a laser designator's battery among them.
{
    _x call _fnc_countWeapon;
} forEach [_primary, _launcher, _handgun, _binocular];

// The uniform, vest and backpack themselves.
{
    [_x param [0, ""]] call _fnc_count;
} forEach [_uniform, _vest, _backpack];

// Headgear and goggles, then map, GPS, radio, compass, watch and NVG.
{
    [_x] call _fnc_count;
} forEach ([_headgear, _goggles] + _assigned);

// And everything packed into the uniform, vest and backpack.
{
    [_x, 0] call _fnc_countContainer;
} forEach [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

private _load = 0;

{
    private _info = [_x] call EFUNC(items,getInfo);
    private _mass = _info getOrDefault ["mass", 0];

    _load = _load + (_mass - (_info getOrDefault ["configMass", _mass])) * _y;
} forEach _carried;

// Strict mode's hidden holder (einv_storage_fnc_opStrict): what it keeps out of the uniform, vest and
// backpack is in no cargo the engine weighs, so its whole mass - the rules' - is added, not only the
// override's difference. [[uniform, vest, backpack] lists of [class, count, rounds], containers].
private _hidden = _unit getVariable [QEGVAR(storage,hidden), []];

if (_hidden isEqualTypeArray [[], []]) then {
    {
        {
            if (_x isEqualTypeArray ["", 0, 0]) then {
                _x params ["_class", "_count"];

                _load = _load + (([_class] call EFUNC(items,getInfo)) getOrDefault ["mass", 0]) * _count;
            };
        } forEach _x;
    } forEach (_hidden select 0);
};

_load
