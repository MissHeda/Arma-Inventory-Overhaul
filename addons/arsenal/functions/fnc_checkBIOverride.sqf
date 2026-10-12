#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * At preInit: whether the file of BIS_fnc_arsenal in force is this addon's. Another mod's winning the entry
 * is named once in the RPT; the safety net is all that works then.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * This addon's file is in force <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_checkBIOverride;
 *
 * Public: No
 */

private _file = getText (configFile >> "CfgFunctions" >> "A3_Bootcamp" >> "Inventory" >> "arsenal" >> "file");
private _ours = QPATHTOF(functions\fnc_biArsenal.inc.sqf);

// Paths are not case sensitive, and a leading backslash may or may not be there.
private _fnc_same = {
    params ["_one", "_other"];

    private _slash = toString [92];

    _one = toLowerANSI _one;
    _other = toLowerANSI _other;

    if ((_one select [0, 1]) isEqualTo _slash) then {_one = _one select [1]};
    if ((_other select [0, 1]) isEqualTo _slash) then {_other = _other select [1]};

    _one isEqualTo _other
};

if ([_file, _ours] call _fnc_same) exitWith {true};

WARNING_2("BIS_fnc_arsenal comes from %1 and not from %2 - the vanilla arsenal can only be caught by the safety net.",_file,_ours);

false
