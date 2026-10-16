#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What an item is in config, before any rule: its kind, category, mass, rounds and load, the classes
 * it is built on and the addon that brought it in - everything the rules ask about - plus its names,
 * description and picture, and what its own mod says about its size, stack, grid, weight, name and how
 * its picture is drawn: einv_size, einv_stack, einv_grid, einv_weight, einv_name, einv_icon
 * (fnc_readConfigKeys), and the older
 * einv_gridSize[], einv_stackSize, einv_grids[], einv_slots, which still work. A subclass has what
 * its parent has, as everything in config does. fnc_getInfo puts the rules on top of this.
 *
 * Config does not change while the game runs, so this is read once per class and kept in uiNamespace:
 * not saved with the game (a setup wizard reading thousands of classes must not bloat save games),
 * and still there in the next mission.
 *
 * A class no config knows - a mod that is not loaded, or "" - still comes back, as kind "unknown"
 * under its own name, so nothing that shows an item has to check first.
 *
 * Kinds: rifle, handgun, launcher, binocular, muzzle, optic, rail, bipod, headgear, nvg, vest,
 * uniform, map, gps, radio, compass, watch, item (any other CfgWeapons class, CBA's and ACE's misc
 * items among them), magazine, grenade (one round and light), backpack, goggles, vehicle (CfgVehicles,
 * of AllVehicles), crate (any other CfgVehicles class), kit, unknown.
 *
 * A kit is an item that Enhanced First Aid Kits registers as one of its kits (its config EFAK_Kits) - a
 * pouch of Enhanced Utility Pouches as well: the type's own class (the prototype, "efak_IFAK") and the
 * instance classes that mod makes of it, "efak_IFAK_1" up to as many as the type has. The same list
 * that mod reads for its own efak_core_fnc_isKit, read here from config, so the kind is known in the
 * editor and the main menu too, where none of that mod's functions run. Its load is the capacity that
 * config gives the type - a mission's setting for it is that mod's business (einv_compat_efak). To the
 * rules' kind= it is an item as well (KINDS_AS_ITEM): kind=item sizes and stacks it as before, kind=kit
 * reaches only kits.
 *
 * Arguments:
 * 0: Class name <STRING>
 *
 * Return Value:
 * The item's facts, shared by every caller - do not change them <HASHMAP>
 *   "class"       - configName, or the class as given when no config knows it <STRING>
 *   "lc"          - the class in lowercase <STRING>
 *   "root"        - "CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses" or "" <STRING>
 *   "kind"        - see above <STRING>
 *   "category"    - CATEGORY_* <NUMBER>
 *   "mass"        - config mass, in tenths of a pound <NUMBER>
 *   "rounds"      - count of a CfgMagazines class (grenades too), 0 for everything else <NUMBER>
 *   "capacity"    - a magazine's rounds, 0 for everything else (grenades too) <NUMBER>
 *   "maxLoad"     - what a uniform, vest, backpack, crate or vehicle holds, a kit's capacity, 0 for
 *                   everything else <NUMBER>
 *   "lineage"     - lowercase classes from the class itself up to the topmost it is built on <ARRAY>
 *   "addon"       - the CfgPatches class that defined it, lowercase, "" if none <STRING>
 *   "mod"         - what its own config says, only the keys it sets and that can be used: "size"
 *                   [w, h, holes] or "mass", "stack" NUMBER, "grid" spec (fnc_parseGrid), "weight"
 *                   kg NUMBER, "name" STRING and "icon" [scale, across, down] (einv_size ... einv_icon),
 *                   and the older "gridSize"
 *                   [w, h], "stackSize" NUMBER, "grids" [[cols, rows], ...], "slots" NUMBER
 *                   <HASHMAP>
 *   "name"        - displayName, or the class when it has none <STRING>
 *   "short"       - displayNameShort, or else the name <STRING>
 *   "description" - descriptionShort, may contain <br/>, "" if none <STRING>
 *   "picture"     - "" if none <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call einv_items_fnc_getFacts;
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

private _cache = uiNamespace getVariable QGVAR(facts);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(facts), _cache];
};

private _key = toLowerANSI _class;
private _cached = _cache get _key;

if (!isNil "_cached") exitWith {_cached};

private _config = configNull;
private _root = "";

if (_class isNotEqualTo "") then {
    {
        private _candidate = configFile >> _x >> _class;

        if (isClass _candidate) exitWith {
            _config = _candidate;
            _root = _x;
        };
    } forEach ["CfgWeapons", "CfgMagazines", "CfgVehicles", "CfgGlasses"];
};

private _itemType = getNumber (_config >> "ItemInfo" >> "type");

private _kind = switch (_root) do {
    case "CfgWeapons": {
        private _type = getNumber (_config >> "type");
        private _simulation = ["itemmap", "itemgps", "itemradio", "itemcompass", "itemwatch"] find (toLowerANSI (getText (_config >> "simulation")));

        switch (true) do {
            // NVGs come from the binoculars in config and keep their weapon type - only the slot their
            // ItemInfo names tells them apart.
            case (_itemType == 616): {"nvg"};
            case (_type == 1): {"rifle"};
            case (_type == 2): {"handgun"};
            case (_type == 4): {"launcher"};
            case (_type == 4096): {"binocular"};
            case (_itemType == 101): {"muzzle"};
            case (_itemType == 201): {"optic"};
            case (_itemType == 301): {"rail"};
            // CBA gives its misc items the bipod's ItemInfo type 302 too (CBA_MiscItem_ItemInfo), and
            // ACE_ItemCore comes from CBA_MiscItem - so every ACE item has it: bandages, morphine, cable
            // ties, earplugs. Those are plain items; only a type 302 from elsewhere is a bipod. CBA is
            // always loaded, the isClass only keeps this safe should its base class ever go missing.
            case (_itemType == 302): {
                private _cfgWeapons = configFile >> "CfgWeapons";
                private _isMiscItem = isClass (_cfgWeapons >> "CBA_MiscItem") && {(configName _config) isKindOf ["CBA_MiscItem", _cfgWeapons]};

                ["bipod", "item"] select _isMiscItem
            };
            case (_itemType == 605): {"headgear"};
            case (_itemType == 701): {"vest"};
            case (_itemType == 801): {"uniform"};
            case (_simulation >= 0): {["map", "gps", "radio", "compass", "watch"] select _simulation};
            // UAV terminals sit in the GPS slot.
            case (_itemType == 621): {"gps"};
            default {"item"};
        };
    };
    // Hand grenades, smokes, chemlights and 40 mm shells: one round and light. A rocket is one round
    // too, but heavy - it stays a magazine.
    case "CfgMagazines": {
        ["magazine", "grenade"] select (getNumber (_config >> "count") == 1 && {getNumber (_config >> "mass") <= 15})
    };
    // What is no backpack is a container of another kind - a crate, or a vehicle with a cargo space.
    // The rules give both a grid (@crate in the default preset).
    case "CfgVehicles": {
        switch (true) do {
            case (getNumber (_config >> "isBackpack") == 1): {"backpack"};
            case ((configName _config) isKindOf "AllVehicles"): {"vehicle"};
            default {"crate"};
        };
    };
    case "CfgGlasses": {"goggles"};
    default {"unknown"};
};

// A kit of Enhanced First Aid Kits, by that mod's registry (fnc_kitOf): the type's own class or one of
// its instances. Only an item: a kit is no weapon, vest or uniform.
private _kitType = [];

if (_kind isEqualTo "item") then {
    _kitType = [_key] call FUNC(kitOf);

    if (_kitType isNotEqualTo []) then {
        _kind = "kit";
    };
};

private _category = switch (true) do {
    case (getNumber (_config >> "ACE_isMedicalItem") == 1): {CATEGORY_MEDICAL};
    // The vanilla first aid kit and medikit.
    case (_itemType in [401, 619]): {CATEGORY_MEDICAL};
    case (_kind in ["rifle", "handgun", "launcher"]): {CATEGORY_WEAPON};
    case (_kind in ["magazine", "grenade"]): {CATEGORY_AMMO};
    case (_kind in ["uniform", "vest", "headgear", "goggles", "nvg", "binocular", "backpack"]): {CATEGORY_GEAR};
    default {CATEGORY_MISC};
};

// Weapons keep their mass with their attachment slots, everything else in CfgWeapons with its item
// info. Binoculars are weapons in config, but a mod may well have put theirs in the item info.
private _mass = if (_root == "CfgWeapons") then {
    private _itemMass = getNumber (_config >> "ItemInfo" >> "mass");

    if (_kind in ["rifle", "handgun", "launcher", "binocular"]) then {
        private _weaponMass = getNumber (_config >> "WeaponSlotsInfo" >> "mass");
        [_weaponMass, _itemMass] select (_weaponMass == 0)
    } else {
        _itemMass
    };
} else {
    getNumber (_config >> "mass")
};

// A uniform or vest is only the item; what it holds is the container class it brings along.
private _maxLoad = switch (_kind) do {
    case "uniform";
    case "vest": {
        private _containerClass = getText (_config >> "ItemInfo" >> "containerClass");

        if (_containerClass isEqualTo "") then {
            0
        } else {
            getNumber (configFile >> "CfgVehicles" >> _containerClass >> "maximumLoad")
        };
    };
    case "backpack";
    case "crate";
    case "vehicle": {getNumber (_config >> "maximumLoad")};
    // What its type holds by that mod's config: a grid by load (grid=auto, a share of it) is laid out
    // from it.
    case "kit": {_kitType select 3};
    default {0};
};

private _rounds = [0, getNumber (_config >> "count")] select (_root == "CfgMagazines");

// The class and every class it is built on, for class=X+ in the rules: one rule for a base class
// covers all its variants, the unique classes TFAR, ACRE and EFAK make out of an item among them.
private _lineage = [];
private _current = _config;

while {isClass _current} do {
    _lineage pushBack (toLowerANSI (configName _current));
    _current = inheritsFrom _current;
};

if (_lineage isEqualTo []) then {
    _lineage = [_key];
};

// What the item's own mod says - only what it really sets, and only what can be used. The older keys:
// a size needs two numbers of at least one cell, compartments two numbers each.
private _mod = createHashMap;
private _gridSize = getArray (_config >> QGVARMAIN(gridSize));

if (_gridSize isEqualTypeArray [0, 0] && {(_gridSize select 0) >= 1} && {(_gridSize select 1) >= 1}) then {
    _mod set ["gridSize", _gridSize apply {floor _x}];
};

if (isNumber (_config >> QGVARMAIN(stackSize))) then {
    _mod set ["stackSize", getNumber (_config >> QGVARMAIN(stackSize))];
};

private _grids = getArray (_config >> QGVARMAIN(grids));

if (_grids isNotEqualTo [] && {_grids findIf {!(_x isEqualTypeArray [0, 0])} < 0}) then {
    _mod set ["grids", _grids];
};

private _slots = floor (getNumber (_config >> QGVARMAIN(slots)));

if (_slots > 0) then {
    _mod set ["slots", _slots];
};

// The keys written the way the rules write the same value. They sit next to the older ones, which
// fnc_resolve asks only for what these leave open. Config does not change while the game runs, so a
// value that cannot be read is named once here, not on every look.
private _found = createHashMap;

{
    private _entry = _config >> _x;

    if (isText _entry) then {_found set [_x, getText _entry]};
    if (isNumber _entry) then {_found set [_x, getNumber _entry]};
} forEach CONFIG_KEYS;

if (count _found > 0) then {
    ([_found] call FUNC(readConfigKeys)) params ["", "_values", "_notes"];

    {
        WARNING_2("Config of %1: %2",_class,_x);
    } forEach _notes;

    {
        _mod set [_x, _y];
    } forEach _values;
};

private _name = getText (_config >> "displayName");
private _short = getText (_config >> "displayNameShort");

if (_name isEqualTo "") then {_name = _class};
if (_short isEqualTo "") then {_short = _name};

private _facts = createHashMapFromArray [
    ["class", [_class, configName _config] select (isClass _config)],
    ["lc", _key],
    ["root", _root],
    ["kind", _kind],
    ["category", _category],
    ["mass", _mass],
    ["rounds", _rounds],
    ["capacity", [0, _rounds] select (_kind == "magazine")],
    ["maxLoad", _maxLoad],
    ["lineage", _lineage],
    ["addon", toLowerANSI ((configSourceAddonList _config) param [0, ""])],
    ["mod", _mod],
    ["name", _name],
    ["short", _short],
    ["description", getText (_config >> "descriptionShort")],
    ["picture", getText (_config >> "picture")]
];

_cache set [_key, _facts];

_facts
