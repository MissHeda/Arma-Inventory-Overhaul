#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Turns the strip of a loot box to the next group of categories (fnc_stripEntries) when there are more categories than it has
 * fields: the same fields get another picture, name and category (nothing is made or deleted), and a field a short last group
 * leaves over is hidden. Which group a box shows is kept in GVAR(stripPages) until the window is attached again.
 *
 * Arguments:
 * 0: The box's container <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_crate] call einv_gui_fnc_stripMore;
 *
 * Public: No
 */

disableSerialization;

params [["_holder", objNull, [objNull]]];

private _infos = uiNamespace getVariable [QGVAR(sectionInfo), []];
private _info = _infos param [_infos findIf {(_x getOrDefault ["holder", objNull]) isEqualTo _holder && {"strip" in _x}}, createHashMap];

if (count _info == 0) exitWith {};

private _at = GVAR(stripPages) findIf {(_x select 0) isEqualTo _holder};
private _page = if (_at < 0) then {0} else {(GVAR(stripPages) select _at) select 1};

([_page] call FUNC(stripEntries)) params ["", "_pages"];

_page = (_page + 1) mod _pages;

if (_at >= 0) then {
    GVAR(stripPages) deleteAt _at;
};

GVAR(stripPages) pushBack [_holder, _page];

([_page] call FUNC(stripEntries)) params ["_entries"];

{
    _x params ["", "_field", "_picture", "_hit"];

    private _entry = _entries param [_forEachIndex, []];
    private _on = _entry isNotEqualTo [];

    ((_info get "strip") select _forEachIndex) set [0, ["", _entry param [0, ""]] select _on];

    {_x ctrlShow _on} forEach _field;
    _picture ctrlShow _on;
    _hit ctrlShow _on;

    if (_on) then {
        _picture ctrlSetText (_entry select 1);
        _hit setVariable [QGVAR(kind), _entry select 0];
        _hit ctrlSetTooltip (_entry select 2);
    };
} forEach (_info get "strip");

[_holder] call FUNC(paintGroupStrip);
