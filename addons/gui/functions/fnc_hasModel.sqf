#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether an item has a model of its own worth a look in 3D (the inspect card's 3D view, fnc_inspect3D): the config's model
 * (model=, else modelSpecial=, read where the class lives - CfgWeapons, CfgMagazines, CfgVehicles, CfgGlasses). Many items
 * have none of their own and inherit the engine's stand-in, the box of a magazine, from ItemCore or CA_Magazine - the medical
 * items of ACM, for one. Those and items with no model at all are left out (PLACEHOLDER_MODELS). Known per class for the
 * session.
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * Has a model of its own <BOOL>
 *
 * Example:
 * ["arifle_MX_F"] call aio_gui_fnc_hasModel;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {false};

private _key = toLowerANSI _class;
private _known = GVAR(hasModel) get _key;

if (!isNil "_known") exitWith {_known};

private _config = switch (true) do {
    case (isClass (configFile >> "CfgWeapons" >> _class)): {configFile >> "CfgWeapons" >> _class};
    case (isClass (configFile >> "CfgMagazines" >> _class)): {configFile >> "CfgMagazines" >> _class};
    case (isClass (configFile >> "CfgVehicles" >> _class)): {configFile >> "CfgVehicles" >> _class};
    case (isClass (configFile >> "CfgGlasses" >> _class)): {configFile >> "CfgGlasses" >> _class};
    default {configNull};
};

private _model = getText (_config >> "model");

if (_model isEqualTo "") then {
    _model = getText (_config >> "modelSpecial");
};

// The path as config may write it: any case, with or without the leading backslash and the extension.
_model = toLowerANSI _model;

if ((_model select [0, 1]) isEqualTo "\") then {
    _model = _model select [1];
};

if ((_model select [count _model - 4]) isEqualTo ".p3d") then {
    _model = _model select [0, count _model - 4];
};

private _has = _model isNotEqualTo "" && {!(_model in PLACEHOLDER_MODELS)};

GVAR(hasModel) set [_key, _has];

_has
