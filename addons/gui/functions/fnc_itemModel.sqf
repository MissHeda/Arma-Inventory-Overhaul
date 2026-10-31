#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The model of an item that is worth a look in 3D (the inspect card's 3D view, fnc_inspect3D): read where the class lives -
 * CfgWeapons, CfgMagazines, CfgVehicles, CfgGlasses - its model=, else its modelSpecial=. Many items have no model of their own
 * and inherit the engine's stand-in, the box of a magazine, from ItemCore or CA_Magazine (the medical items of ACM, for one):
 * such a model counts as none (PLACEHOLDER_MODELS). A magazine of Arma's own lies on the ground as that box too, but has its
 * real model as modelSpecial= (the one its weapon shows) - that one is taken. Known per class for the session.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * The model's path as config gives it, "" for none <STRING>
 *
 * Example:
 * ["30Rnd_65x39_caseless_mag"] call aio_gui_fnc_itemModel; // "a3\Weapons_F\MagazineProxies\mag_65x39c_mx_30rnd.p3d"
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {""};

private _key = toLowerANSI _class;
private _known = GVAR(itemModels) get _key;

if (!isNil "_known") exitWith {_known};

private _config = switch (true) do {
    case (isClass (configFile >> "CfgWeapons" >> _class)): {configFile >> "CfgWeapons" >> _class};
    case (isClass (configFile >> "CfgMagazines" >> _class)): {configFile >> "CfgMagazines" >> _class};
    case (isClass (configFile >> "CfgVehicles" >> _class)): {configFile >> "CfgVehicles" >> _class};
    case (isClass (configFile >> "CfgGlasses" >> _class)): {configFile >> "CfgGlasses" >> _class};
    default {configNull};
};

private _found = "";

{
    private _path = getText (_config >> _x);

    // The path as config may write it: any case, with or without the leading backslash and the extension.
    private _plain = toLowerANSI _path;

    if ((_plain select [0, 1]) isEqualTo "\") then {
        _plain = _plain select [1];
    };

    if ((_plain select [count _plain - 4]) isEqualTo ".p3d") then {
        _plain = _plain select [0, count _plain - 4];
    };

    if (_plain isNotEqualTo "" && {!(_plain in PLACEHOLDER_MODELS)}) exitWith {
        _found = _path;
    };
} forEach ["model", "modelSpecial"];

GVAR(itemModels) set [_key, _found];

_found
