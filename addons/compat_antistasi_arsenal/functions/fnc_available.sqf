#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * How many of a class the grid panel may take from JNA's stock now, as JNA's own "+" would allow it (jn_fnc_arsenal
 * "buttonCargo"): the stock this machine was last sent (jna_dataList), less the minimum a non-member must leave
 * (jna_minItemMember per tab, A3A_arsenalLimits per class). Magazines are kept in rounds: only whole magazines are given,
 * as the panel adds full ones - a last partial magazine is left to JNA's own "+".
 *
 * Arguments:
 * 0: The class <STRING>
 *
 * Return Value:
 * How many may be taken, -1 for no limit <NUMBER>
 *
 * Example:
 * ["30Rnd_556x45_Stanag"] call aio_compat_antistasi_arsenal_fnc_available;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (_class isEqualTo "" || {isNil "jna_dataList"}) exitWith {0};

private _index = _class call jn_fnc_arsenal_itemType;

if (_index < 0) exitWith {0};

if (_index == JNA_TAB_CARGOMAG) then {
    _index = JNA_TAB_CARGOMAGALL;
};

private _stock = [jna_dataList param [_index, []], _class] call jn_fnc_arsenal_itemCount;

if (_stock == -1) exitWith {-1};

private _isMagazine = _index == JNA_TAB_CARGOMAGALL;
private _capacity = [1, getNumber (configFile >> "CfgMagazines" >> _class >> "count") max 1] select _isMagazine;

// What a non-member must leave in the arsenal.
private _member = isNil "A3A_fnc_isMember" || {(player call A3A_fnc_isMember) isEqualTo true};
private _min = 0;

if (!_member) then {
    _min = (missionNamespace getVariable ["jna_minItemMember", []]) param [_index, 0];

    private _limits = missionNamespace getVariable ["A3A_arsenalLimits", createHashMap];

    if (_limits isEqualType createHashMap) then {
        _min = _limits getOrDefault [_class, _min];
    };

    if (!(_min isEqualType 0)) then {
        _min = 0;
    };

    _min = _min * _capacity;
};

floor (((_stock - _min) max 0) / _capacity)
