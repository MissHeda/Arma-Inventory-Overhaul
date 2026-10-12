#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which family of CfgEinvSounds an item sounds like, kept per class. The first that applies:
 *   1. the item's config entry einv_sound, naming a class of CfgEinvSounds (a mod's own choice)
 *   2. an ACRE or TFAR radio that is no backpack: "device"
 *   3. a medical item (the category of fnc_getInfo): "medic"
 *   4. a kit of Enhanced First Aid Kits or Enhanced Utility Pouches: "medic"
 *   5. by its kind: rifle, handgun, launcher, muzzle, optic, rail, bipod, magazine, grenade, vest, backpack,
 *      uniform, headgear (also night vision and goggles), device (radio and GPS), binocular
 *   6. anything else - an item, a map, a compass, a watch, an unknown class: "Default"
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * A class of CfgEinvSounds <STRING>
 *
 * Example:
 * ["arifle_MX_F"] call einv_gui_fnc_soundFamily;
 *
 * Public: No
 */

params [["_class", "", [""]]];

private _key = toLowerANSI _class;
private _cached = GVAR(soundFamilies) get _key;

if (!isNil "_cached") exitWith {_cached};

private _info = [_class] call EFUNC(items,getInfo);
private _kind = _info getOrDefault ["kind", ""];
private _root = _info getOrDefault ["root", ""];
private _config = if (_root isEqualTo "") then {configNull} else {configFile >> _root >> _class};

private _family = "Default";

call {
    // The item's own mod says how it sounds.
    private _own = getText (_config >> "einv_sound");

    if (_own isNotEqualTo "" && {isClass (configFile >> "CfgEinvSounds" >> _own)}) exitWith {
        _family = _own;
    };

    // ACRE's and TFAR's radios - not the backpack radios, which are backpacks.
    if (
        _kind isNotEqualTo "backpack" && {
            getNumber (_config >> "acre_isRadio") == 1
            || {getText (_config >> "tf_radio") isNotEqualTo ""}
            || {getNumber (_config >> "tf_prototype") == 1}
            || {getText (_config >> "tf_parent") isNotEqualTo ""}
        }
    ) exitWith {
        _family = "device";
    };

    if ((_info getOrDefault ["category", CATEGORY_MISC]) == CATEGORY_MEDICAL) exitWith {
        _family = "medic";
    };

    if (!isNil QEFUNC(compat_efak,isKit) && {[_class] call EFUNC(compat_efak,isKit)}) exitWith {
        _family = "medic";
    };

    _family = switch (_kind) do {
        case "rifle": {"rifle"};
        case "handgun": {"handgun"};
        case "launcher": {"launcher"};
        case "muzzle": {"muzzle"};
        case "optic": {"optic"};
        case "rail": {"rail"};
        case "bipod": {"bipod"};
        case "magazine": {"magazine"};
        case "grenade": {"grenade"};
        case "vest": {"vest"};
        case "backpack": {"backpack"};
        case "uniform": {"uniform"};
        case "headgear";
        case "nvg";
        case "goggles": {"headgear"};
        case "radio";
        case "gps": {"device"};
        case "binocular": {"binocular"};
        default {"Default"};
    };
};

GVAR(soundFamilies) set [_key, _family];

_family
