#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads what an item's own config says about its size, stack, container grid, weight and name: the keys
 * einv_size, einv_stack, einv_grid, einv_weight and einv_name (CONFIG_KEYS). A value is written the
 * way the rules text writes the same thing, so a mod author learns one language:
 *
 *   einv_size = "2x1";                   size=  - WxH, a mask like "xx/x-", or "mass" (fnc_parseRules)
 *   einv_stack = 10;                     stack= - a whole number, 1 to MAX_STACK
 *   einv_grid = "1x3+5x7+1x3";           grid=  - anything fnc_parseGrid reads: "auto", "24", "120%", a
 *                                        pattern, compartments, shapes, a canvas. A plain number in
 *                                        config, einv_grid = 24, is read as the string "24".
 *   einv_weight = 0.5;                   weight= - kilograms, 0 to MAX_WEIGHT, rounded to the gram
 *   einv_name = "Short name";            name=  - the name as it shows: plain text, a space is a
 *                                        space (the rules text writes it with _), at most MAX_NAME
 *                                        characters
 *
 * Spaces in a size or grid do not matter ("1x3 + 5x7" is "1x3+5x7"). An empty value says nothing,
 * which is how a subclass takes back what it inherited. A value that cannot be read, or is past a
 * limit, is left out or cut down exactly as it would be in the rules, and said so in the messages: one
 * wrong key never costs the others.
 *
 * Shared by fnc_getFacts (the item's own config) and fnc_parseConfigEntry (a pasted snippet).
 *
 * Arguments:
 * 0: What was found: key in lowercase (einv_grid, ...) -> STRING or NUMBER, as config gives it <HASHMAP>
 *
 * Return Value:
 * [canonical, compiled, messages] <ARRAY>
 *   canonical - the values that could be read, as the rules write them, by config key:
 *               "einv_size" "2x1" / "xx/x-" / "mass", "einv_stack" <NUMBER>, "einv_grid" as
 *               fnc_formatGrid writes it, "einv_weight" kg <NUMBER>, "einv_name" <HASHMAP>
 *   compiled  - the same for fnc_resolve, by field: "size" [w, h, holes] or "mass", "stack" <NUMBER>,
 *               "grid" spec (fnc_parseGrid), "weight" kg <NUMBER>, "name" <STRING> <HASHMAP>
 *   messages  - what was left out or cut down, and why <ARRAY of STRING>
 *
 * Example:
 * [createHashMapFromArray [["einv_grid", "1x3 + 5x7"], ["einv_stack", 4]]] call einv_items_fnc_readConfigKeys;
 *
 * Public: No
 */

params [["_found", createHashMap, [createHashMap]]];

private _canonical = createHashMap;
private _compiled = createHashMap;
private _messages = [];

// A value written without any space, tab or line break.
private _fnc_squash = {
    params ["_text"];

    (_text splitString (toString [32, 9, 10, 13])) joinString ""
};

// A number from config's own NUMBER or from a text of digits with one dot; nothing for anything else.
private _fnc_number = {
    params ["_value"];

    if (_value isEqualType 0) exitWith {
        if (finite _value) then {_value} else {nil}
    };

    private _text = [_value] call _fnc_squash;
    private _codes = toArray _text;

    if (_codes findIf {_x >= 48 && {_x <= 57}} < 0
        || {_codes findIf {(_x < 48 || {_x > 57}) && {_x != 46}} >= 0}
        || {({_x == 46} count _codes) > 1}) exitWith {nil};

    parseNumber _text
};

// ----- size -----
// Read by the rules' own reader: the same limits, the same words for what is wrong.

private _size = _found getOrDefault [QGVARMAIN(size), ""];

if (_size isNotEqualTo "") then {
    if !(_size isEqualType "") then {
        _messages pushBack format ["%1 is a text like '2x1', 'xx/x-' or 'mass' - left out", QGVARMAIN(size)];
    } else {
        private _text = [_size] call _fnc_squash;

        // A comma would start a second statement of the text the rules' reader is given.
        if (_text find "," >= 0) then {
            _messages pushBack format ["%1=%2 is no size like 2x1, xx/x- or mass - left out", QGVARMAIN(size), _text];
        } else {
            private _ast = ["size=" + _text] call FUNC(parseRules);

            {
                _messages pushBack format ["%1: %2", QGVARMAIN(size), _x];
            } forEach (_ast get "warnings");

            private _rules = _ast get "rules";
            private _footprint = "";

            if (_rules isNotEqualTo []) then {
                _footprint = ((_rules select 0) select 1) getOrDefault ["footprint", ""];
            };

            if (_footprint isNotEqualTo "") then {
                _canonical set [QGVARMAIN(size), _footprint];

                // WxH has digits, a drawn shape none (fnc_parseRules let only those two and "mass" through).
                _compiled set ["size", switch (true) do {
                    case (_footprint isEqualTo "mass"): {"mass"};
                    case ((toArray _footprint) findIf {_x >= 48 && {_x <= 57}} >= 0): {
                        private _sides = _footprint splitString "x";

                        [parseNumber (_sides select 0), parseNumber (_sides select 1), []]
                    };
                    default {[_footprint] call FUNC(parseMask)};
                }];
            };
        };
    };
};

// ----- stack -----

private _stack = _found getOrDefault [QGVARMAIN(stack), ""];

if (_stack isNotEqualTo "") then {
    private _count = [_stack] call _fnc_number;

    if (isNil "_count") then {
        _messages pushBack format ["%1=%2 is no whole number - left out", QGVARMAIN(stack), _stack];
    } else {
        _count = floor _count;

        if (_count < 1) then {
            _messages pushBack format ["%1=%2: a tile holds at least one - read as 1", QGVARMAIN(stack), _stack];
            _count = 1;
        };

        if (_count > MAX_STACK) then {
            _messages pushBack format ["%1=%2: at most %3 - cut down", QGVARMAIN(stack), _stack, MAX_STACK];
            _count = MAX_STACK;
        };

        _canonical set [QGVARMAIN(stack), _count];
        _compiled set ["stack", _count];
    };
};

// ----- grid -----

private _grid = _found getOrDefault [QGVARMAIN(grid), ""];

// einv_grid = 24; is a number of cells, the same as "24".
if (_grid isEqualType 0) then {
    _grid = if (finite _grid) then {str (((floor _grid) max 0) min MAX_CELLS)} else {""};
};

if (_grid isNotEqualTo "") then {
    if !(_grid isEqualType "") then {
        _messages pushBack format ["%1 is a text like '1x3+5x7+1x3', 'rig' or '24' - left out", QGVARMAIN(grid)];
    } else {
        private _text = [_grid] call _fnc_squash;

        if (_text isNotEqualTo "") then {
            ([_text] call FUNC(parseGrid)) params ["_spec", "_notes"];

            {
                _messages pushBack format ["%1: %2", QGVARMAIN(grid), _x];
            } forEach _notes;

            if (_spec isNotEqualTo []) then {
                _canonical set [QGVARMAIN(grid), [_spec] call FUNC(formatGrid)];
                _compiled set ["grid", _spec];
            };
        };
    };
};

// ----- weight -----

private _weight = _found getOrDefault [QGVARMAIN(weight), ""];

if (_weight isNotEqualTo "") then {
    private _kg = [_weight] call _fnc_number;

    if (isNil "_kg" || {_kg < 0}) then {
        _messages pushBack format ["%1=%2 is no weight in kg like 1.5 - left out", QGVARMAIN(weight), _weight];
    } else {
        // To the gram, as the rules do: finer would not come back from str as a number a rule can read.
        _kg = (round (_kg * 1000)) / 1000;

        if (_kg > MAX_WEIGHT) then {
            _messages pushBack format ["%1=%2: at most %3 kg - cut down", QGVARMAIN(weight), _weight, MAX_WEIGHT];
            _kg = MAX_WEIGHT;
        };

        _canonical set [QGVARMAIN(weight), _kg];
        _compiled set ["weight", _kg];
    };
};

// ----- name -----

private _name = _found getOrDefault [QGVARMAIN(name), ""];

if (_name isNotEqualTo "") then {
    if !(_name isEqualType "") then {
        _messages pushBack format ["%1 is a text like 'Short name' - left out", QGVARMAIN(name)];
    } else {
        // One line: a line break or tab in a name would show as a box.
        private _text = trim ((_name splitString (toString [9, 10, 13])) joinString " ");

        if (count _text > MAX_NAME) then {
            _messages pushBack format ["%1: at most %2 characters - cut down", QGVARMAIN(name), MAX_NAME];
            _text = _text select [0, MAX_NAME];
        };

        if (_text isNotEqualTo "") then {
            _canonical set [QGVARMAIN(name), _text];
            _compiled set ["name", _text];
        };
    };
};

[_canonical, _compiled, _messages]
