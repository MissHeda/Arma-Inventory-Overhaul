#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What the inspect card adds for a kit: how full it is (fnc_fillState: in that mod's own measure, or in
 * cells for a kit a rule or its config gives a grid), and what is in it -
 * a line per kind of item, opened magazines with their rounds, a handful at most and then how many
 * kinds more. Nothing for a kit nobody has carried yet.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * Rows [[label, value], ...] - a label of "" continues the one above <ARRAY>
 *
 * Example:
 * ["efak_IFAK_7"] call einv_compat_efak_fnc_inspectRows;
 *
 * Public: No
 */

params [["_class", "", [""]]];

if (
    !([_class] call FUNC(isKit))
    || {toLowerANSI _class in (missionNamespace getVariable [QEFAKGVAR(core,needsConversion), createHashMap])}
) exitWith {[]};

if !(missionNamespace getVariable [QEFAKGVAR(core,contentsSynced), true]) exitWith {
    [[LLSTRING(Inspect_Contents), LLSTRING(Loading)]]
};

private _rows = [[LLSTRING(Inspect_Filled), ([_class] call FUNC(fillState)) select 0]];

private _contents = [_class] call EFAKFUNC(core,getContents);

if (_contents isEqualTo []) exitWith {
    _rows pushBack [LLSTRING(Inspect_Contents), LLSTRING(Inspect_Empty)];
    _rows
};

// A line for "and n more" only where it saves more than one.
private _shown = [count _contents, 6] select (count _contents > 7);
private _label = LLSTRING(Inspect_Contents);

{
    _x params ["_item", "_count"];

    private _name = [_item] call EFAKFUNC(core,getItemName);
    private _charges = [_item, [_class, _item] call EFAKFUNC(core,getCharges)] call EFAKFUNC(core,formatCharges);
    private _amount = ["", format [" ×%1", _count]] select (_count > 1);

    _rows pushBack [_label, _name + _amount + _charges];
    _label = "";
} forEach (_contents select [0, _shown]);

if (_shown < count _contents) then {
    _rows pushBack ["", format [LLSTRING(Inspect_More), count _contents - _shown]];
};

_rows
