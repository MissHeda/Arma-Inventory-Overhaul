#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Which of a unit's uniform, vest and backpack the arsenal has open in its left panel, and what it
 * holds - the item list ACE itself counts with (uniformItems, vestItems, backpackItems), so a count
 * here is the count the arsenal shows.
 *
 * Arguments:
 * 0: Unit the arsenal dresses <OBJECT>
 *
 * Return Value:
 * [0 uniform / 1 vest / 2 backpack, container, items], [] while none of them is open <ARRAY>
 *
 * Example:
 * [ace_arsenal_center] call einv_arsenal_fnc_getCargo;
 *
 * Public: No
 */

params [["_center", objNull, [objNull]]];

private _panel = missionNamespace getVariable [QACEGVAR(arsenal,currentLeftPanel), -1];
private _index = [ARSENAL_IDC_UNIFORM, ARSENAL_IDC_VEST, ARSENAL_IDC_BACKPACK] find _panel;

if (isNull _center || {_index < 0}) exitWith {[]};

private _container = [uniformContainer _center, vestContainer _center, backpackContainer _center] select _index;

if (isNull _container) exitWith {[]};

private _items = switch (_index) do {
    case 0: {uniformItems _center};
    case 1: {vestItems _center};
    default {backpackItems _center};
};

[_index, _container, _items]
