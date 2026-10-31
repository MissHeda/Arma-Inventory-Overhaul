#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which category an item is in when no rule and no config key says otherwise (cats=, einv_cat): the built-in
 * mapping. It lives here so that the window's strip, the compartments that accept only some categories and the
 * setup wizard all read one answer (fnc_getInfo "groups"). Kept per class in the item's facts. The first that
 * applies, in this order:
 *   "medical"  - a medical item (the category of fnc_getFacts: ACE's, a first aid kit, a bandage) and the kits of
 *                Enhanced First Aid Kits
 *   "weapon"   - a rifle, handgun or launcher and what goes on a weapon: muzzle, optic, rail, bipod
 *   "grenade"  - what is thrown or put down and goes off: a hand grenade, a smoke, a flash, a chemlight, a 40 mm
 *                round (the kind grenade), and a mine or charge (a magazine whose ammo simulates a mine or a
 *                directional bomb)
 *   "ammo"     - every other magazine
 *   "gear"     - a uniform, vest, backpack, headgear, night vision, goggles or binoculars
 *   "food"     - what ACE's field rations lets a soldier eat or drink (its config says how much it satisfies), and the
 *                classes whose names say food and drink
 *   "tool"     - a map, GPS, radio, compass or watch, an ACRE or TFAR radio, and the usual gadgets by name (wire
 *                cutters, cable ties, a flashlight, a defusal kit and the like)
 *   "misc"     - everything else
 * Not a rule of the window: a mod's own items fall where their kind and category put them, nothing is asked of the
 * item's config but ACE's field rations, the radios' marks and a mine's ammo.
 *
 * Arguments:
 * 0: The item's facts (fnc_getFacts) <HASHMAP>
 *
 * Return Value:
 * "weapon", "ammo", "grenade", "gear", "medical", "food", "tool" or "misc" <STRING>
 *
 * Example:
 * [["arifle_MX_F"] call einv_items_fnc_getFacts] call einv_items_fnc_defaultGroup;
 *
 * Public: No
 */

params [["_facts", createHashMap, [createHashMap]]];

private _cached = _facts get "group";

if (!isNil "_cached") exitWith {_cached};

private _kind = _facts getOrDefault ["kind", ""];
private _root = _facts getOrDefault ["root", ""];
private _class = _facts getOrDefault ["class", ""];
private _key = _facts getOrDefault ["lc", toLowerANSI _class];
private _config = if (_root isEqualTo "") then {configNull} else {configFile >> _root >> _class};
private _group = "misc";

call {
    if (_kind isEqualTo "kit" || {(_facts getOrDefault ["category", CATEGORY_MISC]) == CATEGORY_MEDICAL}) exitWith {
        _group = "medical";
    };

    if (_kind in ["rifle", "handgun", "launcher", "muzzle", "optic", "rail", "bipod"]) exitWith {
        _group = "weapon";
    };

    if (_kind isEqualTo "grenade") exitWith {
        _group = "grenade";
    };

    if (_kind isEqualTo "magazine") exitWith {
        // A mine or a charge is a magazine that is put down, not loaded.
        private _simulation = toLowerANSI getText (configFile >> "CfgAmmo" >> getText (_config >> "ammo") >> "simulation");

        _group = ["ammo", "grenade"] select (_simulation in ["shotmine", "shotboundingmine", "shotdirectionalbomb"]);
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
        // ACRE's and TFAR's radios are items of no kind of their own.
        || {getNumber (_config >> "acre_isRadio") == 1}
        || {getText (_config >> "tf_radio") isNotEqualTo ""}
        || {getNumber (_config >> "tf_prototype") == 1}
        || {getText (_config >> "tf_parent") isNotEqualTo ""}
        || {getText (_config >> "einv_sound") isEqualTo "device"}
        || {["wirecutter", "clacker", "defusal", "cabletie", "flashlight", "altimeter", "kestrel", "microdagr", "rangecard", "spottingscope", "maptools", "toolkit", "minedetector", "entrenching", "tacticalladder"] findIf {_x in _key} >= 0}
    ) exitWith {
        _group = "tool";
    };
};

_facts set ["group", _group];

_group
