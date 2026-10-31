#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a rules text from its parts (fnc_parseRules), always the same way: the header, then the categories of the
 * setup's own, the groups, then the rules, each in their order, joined with ", ". A category is written
 * "category=bandit > name=Bandit_loot picture=/a3/ui_f/data/gui/cfg/hints/gear_ca.paa" - its name and picture only where it has
 * them, "category=bandit" for one with neither. A rule's conditions come before a
 * " > ", its values in the order like, size, stack, grid, weight, name, icon, picture, use, cats. Reading what this wrote and
 * writing it again gives the same text, so two setups that mean the same can be compared as texts.
 *
 * Categories and groups go before the rules: they mean the same wherever they are defined, so that changes nothing.
 * Never a ";" - see fnc_sanitizeText.
 *
 * Arguments:
 * 0: The text's parts, as fnc_parseRules gives them <HASHMAP>
 * 1: Write the header (aio1 base=...) <BOOL> (default: true)
 *
 * Return Value:
 * Rules text <STRING>
 *
 * Example:
 * [["aio1 base=default,kind=grenade>stack=3"] call aio_items_fnc_parseRules] call aio_items_fnc_writeRules;
 *
 * Public: Yes
 */

params [["_ast", createHashMap, [createHashMap]], ["_header", true, [false]]];

private _parts = [];

private _fnc_conds = {
    params ["_conds"];

    (_conds apply {
        _x params ["_negated", "_key", "_op", "_values"];

        // A group as @name, "all" as its key alone (no op, no values), the rest as key, op and values.
        private _text = if (_key isEqualTo "@") then {
            (_values apply {"@" + _x}) joinString "|"
        } else {
            _key + _op + (_values joinString "|")
        };

        (["", "!"] select _negated) + _text
    }) joinString " "
};

private _fnc_values = {
    params ["_values"];

    private _texts = [];

    if ("like" in _values) then {_texts pushBack ("like=" + (_values get "like"))};
    if ("footprint" in _values) then {_texts pushBack ("size=" + (_values get "footprint"))};
    if ("stack" in _values) then {_texts pushBack ("stack=" + str (_values get "stack"))};
    if ("grid" in _values) then {_texts pushBack ("grid=" + (_values get "grid"))};
    if ("weight" in _values) then {_texts pushBack ("weight=" + str (_values get "weight"))};
    if ("name" in _values) then {_texts pushBack ("name=" + ([_values get "name"] call FUNC(encodeName)))};
    if ("icon" in _values) then {_texts pushBack ("icon=" + ([_values get "icon"] call FUNC(formatIcon)))};
    if ("picture" in _values) then {_texts pushBack ("picture=" + ([_values get "picture", true] call FUNC(encodeName)))};
    if ("use" in _values) then {_texts pushBack ("use=" + ([_values get "use"] call FUNC(formatUse)))};
    if ("cats" in _values) then {_texts pushBack ("cats=" + ([_values get "cats"] call FUNC(formatGroups)))};

    _texts joinString " "
};

if (_header) then {
    private _line = format ["aio1 base=%1", _ast getOrDefault ["base", "default"]];
    private _cell = _ast getOrDefault ["cell", -1];

    if (_cell > 0) then {
        _line = _line + " cell=" + str _cell;
    };

    _parts pushBack _line;
};

{
    _x params ["_id", ["_name", ""], ["_picture", ""], ["_color", ""]];

    private _values = [];

    if (_name isNotEqualTo "") then {
        _values pushBack ("name=" + ([_name] call FUNC(encodeName)));
    };

    if (_picture isNotEqualTo "") then {
        _values pushBack ("picture=" + ([_picture, true] call FUNC(encodeName)));
    };

    if (_color isNotEqualTo "") then {
        _values pushBack ("color=" + _color);
    };

    _parts pushBack (["category=" + _id, format ["category=%1 > %2", _id, _values joinString " "]] select (_values isNotEqualTo []));
} forEach (_ast getOrDefault ["categories", []]);

{
    _x params ["_id", "_conds"];

    _parts pushBack format ["@%1: %2", _id, [_conds] call _fnc_conds];
} forEach (_ast getOrDefault ["groups", []]);

{
    _x params ["_conds", "_values"];

    if (_conds isEqualTo []) then {
        _parts pushBack ([_values] call _fnc_values);
    } else {
        _parts pushBack format ["%1 > %2", [_conds] call _fnc_conds, [_values] call _fnc_values];
    };
} forEach (_ast getOrDefault ["rules", []]);

_parts joinString ", "
