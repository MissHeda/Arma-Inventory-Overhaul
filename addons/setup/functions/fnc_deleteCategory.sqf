#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes a category of the setup's own out of the draft, and with it out of every place that names it, so that no item or
 * compartment is left with a category that does not exist (a compartment that named only it would take nothing for good):
 *   - the statement category=ID itself;
 *   - the categories of every item rule (cats=) - a rule left with nothing to set goes;
 *   - the categories the compartments of every grid= accept - a compartment with none left takes anything again;
 *   - the editors' unapplied work (the Items step's category chips, the Containers step's accepts).
 * One undo step. One of the built-in eight cannot be taken out.
 *
 * Arguments:
 * 0: The category's id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["bandit"] call aio_setup_fnc_deleteCategory;
 *
 * Public: No
 */

params [["_id", "", [""]]];

if (_id isEqualTo "" || {_id in ITEM_GROUPS}) exitWith {};

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _remaining = ([GVAR(draftRules)] call EFUNC(items,categories)) - [_id];
private _rules = [];

_ast set ["categories", (_ast getOrDefault ["categories", []]) select {(_x select 0) isNotEqualTo _id}];

{
    _x params ["_conds", "_values"];

    if ("cats" in _values) then {
        private _list = (_values get "cats") - [_id];

        if (_list isEqualTo []) then {
            _values deleteAt "cats";
        } else {
            _values set ["cats", _list];
        };
    };

    if ("grid" in _values) then {
        ([_values get "grid"] call EFUNC(items,parseGrid)) params ["_spec"];

        private _clean = [_spec, _remaining] call EFUNC(items,cleanGrid);

        if (_clean isNotEqualTo _spec) then {
            _values set ["grid", [_clean] call EFUNC(items,formatGrid)];
        };
    };

    if (count _values > 0) then {
        _rules pushBack [_conds, _values];
    };
} forEach (_ast getOrDefault ["rules", []]);

_ast set ["rules", _rules];

// What the editors hold, not applied yet.
{
    private _canvas = GVAR(itemWork) get _x;
    private _list = _canvas getOrDefault ["catsList", []];

    if (_id in _list) then {
        _list = _list - [_id];

        if (_list isEqualTo []) then {
            _canvas deleteAt "catsList";
        } else {
            _canvas set ["catsList", _list];
        };
    };
} forEach (keys GVAR(itemWork));

{
    private _work = GVAR(cellWork) get _x;
    private _blocks = _work getOrDefault ["blocks", []];

    {
        private _accepts = _x param [4, []];

        if (_id in _accepts) then {
            _blocks set [_forEachIndex, [_x, _accepts - [_id]] call FUNC(cellBlock)];
        };
    } forEach _blocks;

    // A painted working copy keeps them with the places of its compartments (fnc_canvasBlocks).
    private _attrs = _work getOrDefault ["attrs", []];

    {
        _x params ["_places", "_accepts", "_single", ["_grow", false]];

        if (_id in _accepts) then {
            _attrs set [_forEachIndex, [_places, [_accepts - [_id]] call EFUNC(items,orderGroups), _single, _grow]];
        };
    } forEach _attrs;

    // One that was only that category and no single slot takes anything again, and has nothing left to keep.
    if ("attrs" in _work) then {
        _work set ["attrs", _attrs select {(_x select 1) isNotEqualTo [] || {_x select 2}}];
    };
} forEach (keys GVAR(cellWork));

[_ast] call FUNC(commit);
