#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Same kind of item, for the second pass of fnc_getLayout: the lowercase ace_arsenal_uniqueBase of the
 * class (CfgWeapons, CfgMagazines) when it has one, else the lowercase class. Cached in
 * GVAR(layoutKeys).
 *
 * TFAR and ACRE radio instances and Enhanced First Aid Kits' kit instances carry one, so a record made
 * for one finds the next instance of the same radio or kit: a repacked magazine, a radio that got its
 * instance class, a kit made ready - they stay where they lay.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Key, "" for no class <STRING>
 *
 * Example:
 * ["ACRE_PRC343_ID_1"] call einv_storage_fnc_layoutKey;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "") exitWith {""};

private _lower = toLowerANSI _class;
private _key = GVAR(layoutKeys) get _lower;

if (isNil "_key") then {
    _key = _lower;

    // ACE's word for "an instance of": the class the instances were made from.
    {
        private _config = configFile >> _x >> _class;

        if (isClass _config) exitWith {
            if (isText (_config >> QACEGVAR(arsenal,uniqueBase))) then {
                private _base = getText (_config >> QACEGVAR(arsenal,uniqueBase));

                if (_base isNotEqualTo "") then {_key = toLowerANSI _base};
            };
        };
    } forEach ["CfgWeapons", "CfgMagazines"];

    GVAR(layoutKeys) set [_lower, _key];
};

_key
