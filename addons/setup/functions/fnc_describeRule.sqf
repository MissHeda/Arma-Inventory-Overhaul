#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * One statement of a setup as a sentence players read, rather than the rules language it is written in:
 *
 *   @mag_rifle > size=1x3                 Rifle magazines: 1×3 cells
 *   class=ACE_fieldDressing+ > stack=20   Class ACE_fieldDressing and everything based on it: 20 per tile
 *   @ak: kind=magazine class~762x39       Group ak: kind magazine, class contains 762x39
 *
 * Groups by their names in the items addon's stringtable or a preset's config, a group of the player's
 * own by its id. A shaped item (size=xx/x-) is told by its cells and the box around them, "3 cells
 * shaped in 2×2"; a shaped compartment (grid=xxx/x-x) by its size and its cells, a canvas (grid=aab/acc)
 * as "3 compartments on a 7×7 canvas", like=X by the class.
 *
 *   class=My_Vest > like=V_PlateCarrier1_rgr grid=xxxx/x--x
 *                                         Class My_Vest: like V_PlateCarrier1_rgr, compartments
 *                                         4×2 shaped, 6 cells
 *
 * Arguments:
 * 0: The statement: a rule, [conditions, values] as einv_items_fnc_parseRules lists them under "rules" -
 *    or, with 2, a group, [id, conditions] as under "groups" <ARRAY>
 * 1: The setup it belongs to, as einv_items_fnc_parseRules returns it - its preset names the groups first <HASHMAP> (default: empty)
 * 2: It is a group <BOOL> (default: false)
 * 3: Only what a rule sets, without whom it is for - for a list that names the class itself, by its
 *    picture and display name (fnc_changeRows) <BOOL> (default: false)
 *
 * Return Value:
 * Sentence <STRING>
 *
 * Example:
 * [(einv_setup_draft get "rules") select 0, einv_setup_draft] call einv_setup_fnc_describeRule;
 *
 * Public: No
 */

params [["_rule", [], [[]]], ["_ast", createHashMap, [createHashMap]], ["_isGroup", false, [false]], ["_valuesOnly", false, [false]]];

// The word between alternatives, spaced here rather than in the stringtable, where spaces at the ends of
// a text are easily lost.
private _or = format [" %1 ", LLSTRING(Desc_Or)];

private _fnc_capital = {
    params ["_text"];

    (toUpper (_text select [0, 1])) + (_text select [1])
};

private _fnc_groupLabel = {
    params ["_id"];

    private _key = format ["STR_einv_items_Group_%1", _id];

    if (isLocalized _key) exitWith {localize _key};

    // A preset of another mod may name its groups in its own config: the setup's preset first.
    private _presets = configFile >> "CfgEinvRulesets";
    private _label = "";

    {
        private _name = getText (_x >> "Groups" >> _id >> "name");

        if (_name isNotEqualTo "") exitWith {
            _label = _name;
        };
    } forEach ([_presets >> toLower (_ast getOrDefault ["base", "default"])] + ("true" configClasses _presets));

    if (_label isNotEqualTo "") exitWith {_label};

    (_id splitString "_") joinString " "
};

private _fnc_op = {
    params ["_op"];

    switch (_op) do {
        case "<": {LLSTRING(Op_lt)};
        case "<=": {LLSTRING(Op_le)};
        case ">": {LLSTRING(Op_gt)};
        case ">=": {LLSTRING(Op_ge)};
        default {LLSTRING(Op_is)};
    }
};

// Mass and load in the game's own units (tenths of a pound), with the kilograms ACE shows beside them.
private _fnc_kg = {
    params ["_value"];

    format ["%1 (%2 kg)", _value, ((parseNumber _value) * MASS_TO_KG) toFixed 2]
};

private _fnc_condition = {
    params [["_negated", false], ["_key", ""], ["_op", "="], ["_values", []]];

    private _text = switch (_key) do {
        case "@": {
            (_values apply {[_x] call _fnc_groupLabel}) joinString _or
        };
        case "kind": {
            format [LLSTRING(Cond_kind), _values joinString _or]
        };
        case "cat": {
            format [LLSTRING(Cond_cat), _values joinString _or]
        };
        case "class": {
            if (_op isEqualTo "~") then {
                format [LLSTRING(Cond_classContains), _values joinString _or]
            } else {
                // X+ is X and every class that inherits from it.
                private _names = _values apply {
                    if (count _x > 1 && {(_x select [count _x - 1]) isEqualTo "+"}) then {
                        format [LLSTRING(Cond_classPlus), _x select [0, count _x - 1]]
                    } else {
                        _x
                    }
                };

                format [LLSTRING(Cond_class), _names joinString _or]
            }
        };
        case "addon": {
            format [[LLSTRING(Cond_addon), LLSTRING(Cond_addonContains)] select (_op isEqualTo "~"), _values joinString _or]
        };
        case "well": {
            format [LLSTRING(Cond_well), _values joinString _or]
        };
        case "for": {
            format [LLSTRING(Cond_for), _values joinString _or]
        };
        case "mass": {
            format [LLSTRING(Cond_mass), [_op] call _fnc_op, (_values apply {[_x] call _fnc_kg}) joinString _or]
        };
        case "load": {
            format [LLSTRING(Cond_load), [_op] call _fnc_op, (_values apply {[_x] call _fnc_kg}) joinString _or]
        };
        case "rounds": {
            format [LLSTRING(Cond_rounds), [_op] call _fnc_op, _values joinString _or]
        };
        default {
            format ["%1%2%3", _key, _op, _values joinString "|"]
        };
    };

    if (_negated) then {
        _text = format [LLSTRING(Desc_Not), _text];
    };

    _text
};

private _fnc_grid = {
    params ["_grid"];

    private _lower = toLower _grid;
    private _spec = ([_lower] call EFUNC(items,parseGrid)) select 0;

    switch (true) do {
        case (_lower isEqualTo "auto"): {
            LLSTRING(Value_GridAuto)
        };
        case (_lower regexMatch "^[0-9]+$"): {
            format [LLSTRING(Value_GridCells), _lower]
        };
        case (_lower regexMatch "^[0-9]+%$"): {
            format [LLSTRING(Value_GridPercent), _lower select [0, count _lower - 1]]
        };
        // Compartments, each WxH or a shape: rows of x (a cell) and - (a hole) separated by /; or a
        // canvas, a letter per compartment, said in one go: "3 compartments on a 7×7 canvas".
        case ((_spec param [0, ""]) isEqualTo "blocks"): {
            private _blocks = _spec select 1;
            private _placed = _blocks select {(_x param [3, []]) isNotEqualTo []};
            private _parts = [];
            private _canvasSaid = false;

            {
                _x params ["_cols", "_rows", ["_holes", []], ["_pos", []]];

                switch (true) do {
                    case (_pos isNotEqualTo [] && {count _placed > 1}): {
                        if (!_canvasSaid) then {
                            _parts pushBack format [
                                LLSTRING(Value_GridCanvas), count _placed,
                                selectMax (_placed apply {((_x select 3) select 0) + (_x select 0)}),
                                selectMax (_placed apply {((_x select 3) select 1) + (_x select 1)})
                            ];
                            _canvasSaid = true;
                        };
                    };
                    case (_holes isEqualTo []): {
                        _parts pushBack format ["%1×%2", _cols, _rows];
                    };
                    default {
                        _parts pushBack format [LLSTRING(Value_GridShape), _cols, _rows, _cols * _rows - count _holes];
                    };
                };
            } forEach _blocks;

            format [LLSTRING(Value_GridBlocks), _parts joinString " + "]
        };
        default {
            // A pattern by name, perhaps with its number of cells: rig, rig:16.
            (_lower splitString ":") params [["_pattern", ""], ["_cells", ""]];

            private _key = format ["STR_einv_setup_Pattern_%1", _pattern];
            private _name = [_pattern, localize _key] select (isLocalized _key);

            [format [LLSTRING(Value_GridPatternCells), _name, _cells], format [LLSTRING(Value_GridPattern), _name]] select (_cells isEqualTo "")
        };
    }
};

private _fnc_values = {
    params ["_values"];

    private _parts = [];
    private _footprint = _values getOrDefault ["footprint", ""];

    // First, as the writer has it: what the rest goes on top of.
    if ("like" in _values) then {
        _parts pushBack format [LLSTRING(Value_Like), _values get "like"];
    };

    if (_footprint isNotEqualTo "") then {
        private _size = (toLower _footprint) splitString "x";

        // A drawn shape (size=xx/x-) has no digit: told by its cells and the box around them.
        private _mask = if ((toArray _footprint) findIf {_x >= 48 && {_x <= 57}} < 0) then {[_footprint] call EFUNC(items,parseMask)} else {[-1]};

        _parts pushBack (switch (true) do {
            case (_footprint == "mass"): {LLSTRING(Value_Mass)};
            case ((_mask select 0) > 0): {
                _mask params ["_cols", "_rows", "_holes"];

                format [LLSTRING(Value_SizeShape), _cols, _rows, _cols * _rows - count _holes]
            };
            case (count _size == 2 && {parseNumber (_size select 0) > 0} && {parseNumber (_size select 1) > 0}): {
                format [LLSTRING(Value_Size), _size select 0, _size select 1]
            };
            default {format [LLSTRING(Value_Shape), _footprint]};
        });
    };

    if ("stack" in _values) then {
        private _stack = _values get "stack";

        _parts pushBack ([format [LLSTRING(Value_Stack), _stack], LLSTRING(Value_NoStack)] select (_stack isEqualTo 1));
    };

    if ("grid" in _values) then {
        _parts pushBack ([_values get "grid"] call _fnc_grid);
    };

    if ("weight" in _values) then {
        _parts pushBack format [LLSTRING(Value_Weight), _values get "weight"];
    };

    if ("name" in _values) then {
        _parts pushBack format [LLSTRING(Value_Name), _values get "name"];
    };

    _parts joinString ", "
};

if (_isGroup) exitWith {
    _rule params [["_id", "", [""]], ["_conditions", [], [[]]]];

    private _what = if (_conditions isEqualTo []) then {
        LLSTRING(Desc_Every)
    } else {
        (_conditions apply {_x call _fnc_condition}) joinString ", "
    };

    format [LLSTRING(Desc_Group), [_id] call _fnc_groupLabel, _what]
};

_rule params [["_conditions", [], [[]]], ["_values", createHashMap, [createHashMap]]];

if (_valuesOnly) exitWith {[_values] call _fnc_values};

private _subject = if (_conditions isEqualTo []) then {
    LLSTRING(Desc_Every)
} else {
    [(_conditions apply {_x call _fnc_condition}) joinString ", "] call _fnc_capital
};

private _what = [_values] call _fnc_values;

if (_what isEqualTo "") exitWith {_subject};

format [LLSTRING(Desc_Rule), _subject, _what]
