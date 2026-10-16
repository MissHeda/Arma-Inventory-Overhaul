#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the draft says about the size of one kind of container - the General step's rows (fnc_drawGeneral): the
 * rule all kind=uniform > grid=5x5 of the text (fnc_allRule finds it, fnc_upsertKinds writes it).
 *
 * Arguments:
 * 0: The kind, one of GENERAL_KINDS <STRING>
 *
 * Return Value:
 * [state, across, down] <ARRAY>
 *   state  - "auto" (no rule: the size comes from the container's load), "fixed" (every container of the kind is
 *            WxH, one compartment) or "other" (a rule that sets a grid the row cannot show as a size - a pattern, a
 *            number of cells, compartments typed in at the text - which a change in the row replaces)
 *   across, down - the size of a fixed one, 0 for the rest
 *
 * Example:
 * ["uniform"] call einv_setup_fnc_kindRule;
 *
 * Public: No
 */

params [["_kind", "", [""]]];

private _rules = GVAR(draft) getOrDefault ["rules", []];
private _index = [_rules, [_kind]] call FUNC(allRule);

if (_index < 0) exitWith {["auto", 0, 0]};

private _grid = toLower (((_rules select _index) select 1) getOrDefault ["grid", ""]);

if (_grid isEqualTo "") exitWith {["auto", 0, 0]};

if (_grid regexMatch "^[0-9]+x[0-9]+$") exitWith {
    private _sides = _grid splitString "x";

    ["fixed", parseNumber (_sides select 0), parseNumber (_sides select 1)]
};

["other", 0, 0]
