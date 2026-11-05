#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What a table of menu rules (GVAR(menuHideRules), GVAR(doubleClickRules)) says for an item, looked up the way
 * CBA looks up its item context menu: the item's class, then every class it is built on, then its subtype
 * ("##" + subtype), its type ("#" + type) and everything ("#All"). Keys are kept in lowercase.
 *
 * Arguments:
 * 0: The table, key -> value <HASHMAP>
 * 1: Item or object class <STRING>
 *
 * Return Value:
 * The values found, the most specific first <ARRAY>
 *
 * Example:
 * [aio_gui_doubleClickRules, "30Rnd_65x39_caseless_mag"] call aio_gui_fnc_menuRules;
 *
 * Public: No
 */

params [["_table", createHashMap, [createHashMap]], ["_class", "", [""]]];

if (_class isEqualTo "" || {count _table == 0}) exitWith {[]};

private _found = [];
private _config = _class call CBA_fnc_getItemConfig;

if (isNull _config) then {
    _config = configFile >> "CfgVehicles" >> _class;
};

while {!isNull _config} do {
    private _key = toLowerANSI configName _config;

    if (_key in _table) then {_found pushBack (_table get _key)};

    _config = inheritsFrom _config;
};

(_class call BIS_fnc_itemType) params [["_type", "", [""]], ["_subtype", "", [""]]];

{
    if (_x in _table) then {_found pushBack (_table get _x)};
} forEach [toLowerANSI format ["##%1", _subtype], toLowerANSI format ["#%1", _type], "#all"];

_found
