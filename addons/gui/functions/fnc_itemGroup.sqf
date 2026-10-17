#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which category of the strip at the side of a loot box (fnc_drawGroupStrip) an item belongs to, kept per class: one of
 *   "medical"  - a medical item (the category of fnc_getInfo: ACE's, a first aid kit, a bandage) and the kits of
 *                Enhanced First Aid Kits
 *   "weapon"   - a rifle, handgun or launcher and what goes on a weapon: muzzle, optic, rail, bipod
 *   "ammo"     - a magazine or a grenade
 *   "gear"     - a uniform, vest, backpack, headgear, night vision, goggles or binoculars
 *   "food"     - what ACE's field rations lets a soldier eat or drink (its config says how much it satisfies), and the
 *                classes whose names say food and drink
 *   "tool"     - a map, GPS, radio, compass or watch, an ACRE or TFAR radio, and the usual gadgets by name (wire cutters,
 *                cable ties, a flashlight, a defusal kit and the like)
 *   "misc"     - everything else
 * The first that applies, in that order. Not a rule of the window: a mod's own items fall where their kind and category
 * put them, nothing is asked of the item's config but ACE's field rations.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * "weapon", "ammo", "gear", "medical", "food", "tool" or "misc" <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call einv_gui_fnc_itemGroup;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _key = toLowerANSI _class;
private _cache = uiNamespace getVariable QGVAR(itemGroups);

if (isNil "_cache") then {
    _cache = createHashMap;
    uiNamespace setVariable [QGVAR(itemGroups), _cache];
};

private _cached = _cache get _key;

if (!isNil "_cached") exitWith {_cached};

private _info = [_class] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];
private _root = _info getOrDefault ["root", ""];
private _config = if (_root isEqualTo "") then {configNull} else {configFile >> _root >> _class};
private _group = "misc";

call {
    if (_kind isEqualTo "kit" || {(_info getOrDefault ["category", CATEGORY_MISC]) == CATEGORY_MEDICAL}) exitWith {
        _group = "medical";
    };

    if (_kind in ["rifle", "handgun", "launcher", "muzzle", "optic", "rail", "bipod"]) exitWith {
        _group = "weapon";
    };

    if (_kind in ["magazine", "grenade"]) exitWith {
        _group = "ammo";
    };

    if (_kind in ["uniform", "vest", "backpack", "headgear", "nvg", "goggles", "binocular"]) exitWith {
        _group = "gear";
    };

    // ACE's field rations says in config how much an item satisfies; a mod without it is told by the class's name.
    if (
        getNumber (_config >> "acex_field_rations_hungerSatiated") > 0 || {getNumber (_config >> "acex_field_rations_thirstQuenched") > 0}
        || {["ration", "_mre", "mre_", "canteen", "waterbottle", "water_bottle", "food", "drink", "beverage"] findIf {_x in _key} >= 0}
    ) exitWith {
        _group = "food";
    };

    if (
        _kind in ["map", "gps", "radio", "compass", "watch"]
        || {([_class] call FUNC(soundFamily)) isEqualTo "device"}
        || {["wirecutter", "clacker", "defusal", "cabletie", "flashlight", "altimeter", "kestrel", "microdagr", "rangecard", "spottingscope", "maptools", "toolkit", "minedetector", "entrenching", "tacticalladder"] findIf {_x in _key} >= 0}
    ) exitWith {
        _group = "tool";
    };
};

_cache set [_key, _group];

_group
