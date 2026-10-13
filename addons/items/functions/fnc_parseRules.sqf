#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads a rules text - the setting einv_items_rules, a preset's statements or a pasted setup - into
 * its parts. What they mean (which groups exist, which preset is there) is fnc_compileRules' job; this
 * only reads, and leaves out what it cannot read with a warning that names it, so one typo never costs
 * the rest.
 *
 * Statements are separated by commas; line breaks count as commas too. The writer (fnc_writeRules)
 * only ever uses ", ".
 *
 *   einv1 base=default cell=5             the header, read only as the first statement: the preset to
 *                                         build on (base=none for none) and the config mass per grid
 *                                         cell. Without one, the text reads as einv1 base=default.
 *                                         A renamed preset's old id reads as the new one
 *                                         (PRESET_ALIASES: base=tarkov is base=realism).
 *   @rifle_mags: kind=magazine mass<=20   a group: a name for a selection, used as @rifle_mags. A name
 *                                         defined twice means either. An own group replaces the
 *                                         preset's group of the same name; @name inside it means the
 *                                         preset's group, to add to it.
 *   kind=grenade > stack=3                a rule: conditions, then what it sets. No condition means
 *                                         every item; the ">" only makes it easier to read.
 *
 * Conditions must all hold; "|" means either, a "!" in front means not:
 *   kind=rifle|handgun             what an item is (fnc_getFacts): rifle, handgun, launcher, binocular,
 *                                  muzzle, optic, rail, bipod, headgear, nvg, vest, uniform, map, gps,
 *                                  radio, compass, watch, item, magazine, grenade, backpack, goggles,
 *                                  crate, vehicle, unknown
 *   cat=medical                    its tile's category: misc, gear, weapon, ammo, medical
 *   class=X  class=X+  class~abc   that class; X and every class built on it; a class name holding
 *                                  the text (MIN_SEARCH letters at least)
 *   addon=x  addon~abc             the CfgPatches class that brought it in
 *   well=X                         a magazine of that magazine well
 *   for=X                          a magazine the weapon X loads
 *   mass<=20  rounds>=50  load>160 config mass, a magazine's rounds, what a container holds - with
 *                                  = < <= > >=
 *   @group                         a member of that group
 *
 * What a rule sets:
 *   like=V_PlateCarrier1_rgr everything the rules make of that class but its name - size, stack, grid
 *                            and weight, asked when an item is looked at (fnc_resolve), so a later
 *                            change to that class follows. The rule's other values go on top.
 *   size=2x3 (or shape=2x3)  the cells it takes, across and down; size=mass: as many as it weighs;
 *                            size=xx/x- drawn as a grid's compartment is (fnc_parseMask): rows by /,
 *                            x a cell, - a hole - an L of 3 cells. At most SHAPE_MAX each way
 *   stack=10                 how many share a tile, 1 to MAX_STACK
 *   grid=...                 a container's compartments, see fnc_parseGrid - also a canvas,
 *                            grid=aaa/aba/aaa, its compartments where they were drawn
 *   weight=1.25              its weight in kg instead of its config's
 *   name=Field_kit           the name it shows, written as fnc_encodeName does
 *
 * A shape is read to its smallest form and written back the shortest way (fnc_formatMask): xx/xx is
 * 2x2. Named shapes and turns (L3, 10/11, @1) are not read: such a value is left out with a warning,
 * the rest of its rule stays.
 *
 * Left out, with a warning: a statement holding a character other than letters, digits, space and
 * _ + . / % : | @ ! < > = ~ - (a semicolon, quotes, the hash or a backslash would break CBA's
 * settings); unknown keys; a condition after what a rule sets; a header that is not the first
 * statement; a statement that sets nothing; everything past MAX_STATEMENTS statements - and the whole
 * text past TEXT_MAX characters, which then reads as the default.
 *
 * Arguments:
 * 0: Rules text <STRING>
 *
 * Return Value:
 * The text's parts <HASHMAP>
 *   "version"  - the header's number <NUMBER>
 *   "base"     - the preset it builds on: "default", "none" or a CfgEinvRulesets class, lowercase
 *                <STRING>
 *   "cell"     - config mass per grid cell, -1 when the header sets none <NUMBER>
 *   "groups"   - [[id, conditions], ...] in text order, ids lowercase <ARRAY>
 *   "rules"    - [[conditions, values], ...] in text order <ARRAY>
 *   "warnings" - what was left out or cut down, and why <ARRAY of STRING>
 * A condition is [negated, key, op, values], the values the texts between the "|", class names as
 * written; a group in a condition is key "@", op "=" and the group ids. A rule's values are a HashMap:
 * "like" (a class name as written), "footprint" ("WxH", a shape like "xx/x-" or "mass"), "stack"
 * <NUMBER>, "grid" (as
 * fnc_formatGrid writes it), "weight" (kg <NUMBER>), "name" (the name as it shows).
 *
 * Example:
 * ["einv1 base=default, kind=grenade > stack=3"] call einv_items_fnc_parseRules;
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _warnings = [];
private _groups = [];
private _rules = [];
private _version = 1;
private _base = "default";
private _cell = -1;

private _ast = createHashMapFromArray [
    ["version", _version],
    ["base", _base],
    ["cell", _cell],
    ["groups", _groups],
    ["rules", _rules],
    ["warnings", _warnings]
];

// A text this long is a mistake - a pasted file, say - and every machine would have to read it.
if (count _text > TEXT_MAX) exitWith {
    _warnings pushBack format ["The text is %1 characters long, more than the %2 a setup may have - read as %3.", count _text, TEXT_MAX, DEFAULT_RULES];
    _ast
};

if (count _text > TEXT_WARN) then {
    _warnings pushBack format ["The text is %1 characters long - past %2, a text box may cut it off.", count _text, TEXT_WARN];
};

// ----- What may stand where -----

private _allowed = createHashMap;
{_allowed set [_x, true]} forEach (toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 _+./%:|@!<>=~-");
_allowed set [9, true];

private _idChars = createHashMap;
{_idChars set [_x, true]} forEach (toArray "abcdefghijklmnopqrstuvwxyz0123456789_");

private _classChars = createHashMap;
{_classChars set [_x, true]} forEach (toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_");

// What a size that is no WxH may be made of to look like a shape: a name, a mask, a turn.
private _shapeChars = createHashMap;
{_shapeChars set [_x, true]} forEach (toArray "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/@");

private _valueKeys = ["like", "size", "shape", "stack", "grid", "weight", "name"];

private _numberOps = ["=", "<", "<=", ">", ">="];
private _keyOps = createHashMapFromArray [
    ["kind", ["="]],
    ["cat", ["="]],
    ["class", ["=", "~"]],
    ["addon", ["=", "~"]],
    ["well", ["="]],
    ["for", ["="]],
    ["mass", _numberOps],
    ["rounds", _numberOps],
    ["load", _numberOps]
];

// ----- Small helpers -----

// A statement as warnings name it - long ones cut, the warning only has to point at it.
private _fnc_short = {
    params ["_statement"];

    if (count _statement > 60) then {(_statement select [0, 57]) + "..."} else {_statement}
};

private _fnc_isId = {
    params ["_id"];

    _id isNotEqualTo "" && {(toArray _id) findIf {!(_x in _idChars)} < 0}
};

private _fnc_isClass = {
    params ["_name"];

    _name isNotEqualTo "" && {(toArray _name) findIf {!(_x in _classChars)} < 0}
};

private _fnc_isWhole = {
    params ["_digits"];

    _digits isNotEqualTo "" && {(toArray _digits) findIf {_x < 48 || {_x > 57}} < 0}
};

// Digits with one dot at most: 12, 0.5, 2.25. No sign - nothing the rules compare is below zero.
private _fnc_isNumber = {
    params ["_digits"];

    private _codes = toArray _digits;

    _codes findIf {_x >= 48 && {_x <= 57}} >= 0
    && {_codes findIf {(_x < 48 || {_x > 57}) && {_x != 46}} < 0}
    && {({_x == 46} count _codes) <= 1}
};

private _fnc_isValue = {
    params ["_token"];

    private _equals = _token find "=";

    _equals > 0 && {(toLowerANSI (_token select [0, _equals])) in _valueKeys}
};

// ----- What a rule sets -----
// Each gives [field, value], or [] when the value is left out. What is cut down or left out goes into
// _notes, which the statement's reader keeps.

private _fnc_footprint = {
    params ["_raw"];

    private _lower = toLowerANSI _raw;

    if (_lower isEqualTo "mass") exitWith {["footprint", "mass"]};

    // Drawn, with no digit in it: a shape, read the way a grid's compartment is.
    private _codes = toArray _lower;

    if (_codes isNotEqualTo [] && {_codes findIf {!(_x in [120, 45, 47])} < 0}) exitWith {
        private _shape = [_lower] call FUNC(parseMask);

        if ((_shape select 0) < 0) exitWith {
            _notes pushBack format ["size=%1: %2 - this part is left out", _raw, _shape select 2];
            []
        };

        // Larger than the wizard's board: its top left part, read again (fnc_parseMask cuts it).
        if ((_shape select 0) > SHAPE_MAX || {(_shape select 1) > SHAPE_MAX}) then {
            _shape = [_lower, SHAPE_MAX, SHAPE_MAX] call FUNC(parseMask);

            if ((_shape select 0) > 0) then {
                _notes pushBack format ["size=%1: a shape is at most %2 cells each way - cut to %3", _raw, SHAPE_MAX, _shape call FUNC(formatMask)];
            };
        };

        if ((_shape select 0) < 1) exitWith {
            _notes pushBack format ["size=%1: a shape is at most %2 cells each way, and its top left part has no cell - this part is left out", _raw, SHAPE_MAX];
            []
        };

        ["footprint", _shape call FUNC(formatMask)]
    };

    private _cross = _lower find "x";
    private _w = -1;
    private _h = -1;

    if (_cross > 0) then {
        private _across = _lower select [0, _cross];
        private _down = _lower select [_cross + 1];

        if ([_across] call _fnc_isWhole && {[_down] call _fnc_isWhole}) then {
            _w = parseNumber _across;
            _h = parseNumber _down;
        };
    };

    // No WxH and no shape: a shape's name or a turn are not read, anything else is no size.
    if (_w < 0) exitWith {
        if ((toArray _raw) findIf {!(_x in _shapeChars)} < 0) then {
            _notes pushBack format ["size=%1: named shapes and turns are not read - draw it like xx/x- or write 2x3 - this part is left out", _raw];
        } else {
            _notes pushBack format ["size=%1 is no size like 2x3, xx/x- or mass - this part is left out", _raw];
        };
        []
    };

    if (_w < 1 || {_h < 1}) exitWith {
        _notes pushBack format ["size=%1: an item takes at least one cell each way - this part is left out", _raw];
        []
    };

    if (_w > STORAGE_COLS || {_h > MAX_ROWS}) then {
        _w = _w min STORAGE_COLS;
        _h = _h min MAX_ROWS;
        _notes pushBack format ["size=%1: at most %2 across and %3 down - cut to %4x%5", _raw, STORAGE_COLS, MAX_ROWS, _w, _h];
    };

    ["footprint", format ["%1x%2", _w, _h]]
};

// A class name as a condition's class= has it: letters, digits and _ only. Whether config knows it is
// asked when an item is looked at - a mod that is not loaded is no mistake in the text.
private _fnc_like = {
    params ["_raw"];

    if !([_raw] call _fnc_isClass) exitWith {
        _notes pushBack format ["like=%1 is no class name - letters, digits and _ only - this part is left out", _raw];
        []
    };

    ["like", _raw]
};

private _fnc_stack = {
    params ["_raw"];

    if !([_raw] call _fnc_isWhole) exitWith {
        _notes pushBack format ["stack=%1 is no whole number - this part is left out", _raw];
        []
    };

    private _count = parseNumber _raw;

    if (_count < 1) then {
        _notes pushBack format ["stack=%1: a tile holds at least one - read as 1", _raw];
        _count = 1;
    };

    if (_count > MAX_STACK) then {
        _notes pushBack format ["stack=%1: at most %2 - cut down", _raw, MAX_STACK];
        _count = MAX_STACK;
    };

    ["stack", _count]
};

private _fnc_grid = {
    params ["_raw"];

    ([_raw] call FUNC(parseGrid)) params ["_spec", "_messages"];

    _notes append _messages;

    if (_spec isEqualTo []) exitWith {[]};

    ["grid", [_spec] call FUNC(formatGrid)]
};

private _fnc_weight = {
    params ["_raw"];

    if !([_raw] call _fnc_isNumber) exitWith {
        _notes pushBack format ["weight=%1 is no weight in kg like 1.5 - this part is left out", _raw];
        []
    };

    // To the gram: finer would come back from str as 1e-05, which no rule can read again.
    private _kg = (round ((parseNumber _raw) * 1000)) / 1000;

    if (_kg > MAX_WEIGHT) then {
        _notes pushBack format ["weight=%1: at most %2 kg - cut down", _raw, MAX_WEIGHT];
        _kg = MAX_WEIGHT;
    };

    ["weight", _kg]
};

private _fnc_name = {
    params ["_raw"];

    private _name = trim ([_raw] call FUNC(decodeName));

    if (_name isEqualTo "") exitWith {
        _notes pushBack "name= without a name - this part is left out";
        []
    };

    if (count _name > MAX_NAME) then {
        _notes pushBack format ["name=%1: at most %2 characters - cut down", _raw, MAX_NAME];
        _name = _name select [0, MAX_NAME];
    };

    ["name", _name]
};

private _fnc_value = {
    params ["_token"];

    private _equals = _token find "=";
    private _raw = _token select [_equals + 1];

    switch (toLowerANSI (_token select [0, _equals])) do {
        case "like": {[_raw] call _fnc_like};
        case "size";
        case "shape": {[_raw] call _fnc_footprint};
        case "stack": {[_raw] call _fnc_stack};
        case "grid": {[_raw] call _fnc_grid};
        case "weight": {[_raw] call _fnc_weight};
        case "name": {[_raw] call _fnc_name};
        default {[]};
    }
};

// ----- Conditions -----
// Each gives [error, condition]; an error drops the whole statement.

private _fnc_groupCond = {
    params ["_token", "_negated"];

    private _parts = _token splitString "|";

    if (count _parts > MAX_ALTERNATIVES) exitWith {
        [format ["'%1' has more than %2 choices", _token, MAX_ALTERNATIVES], []]
    };

    if (_parts isEqualTo [] || {_parts findIf {(_x select [0, 1]) isNotEqualTo "@" || {!([toLowerANSI (_x select [1])] call _fnc_isId)}} >= 0}) exitWith {
        [format ["'%1' is no group like @name or @a|@b", _token], []]
    };

    ["", [_negated, "@", "=", _parts apply {toLowerANSI (_x select [1])}]]
};

private _fnc_checkValues = {
    params ["_token", "_negated", "_key", "_op", "_values"];

    private _error = "";

    switch (_key) do {
        case "kind": {
            _values = _values apply {toLowerANSI _x};

            {
                if !(_x in ITEM_KINDS) then {
                    _notes pushBack format ["kind=%1: there is no such kind, so this matches nothing", _x];
                };
            } forEach _values;
        };
        case "cat": {
            _values = _values apply {toLowerANSI _x};

            {
                if !(_x in CATEGORY_NAMES) then {
                    _notes pushBack format ["cat=%1: there is no such category (%2), so this matches nothing", _x, CATEGORY_NAMES joinString ", "];
                };
            } forEach _values;
        };
        case "class": {
            if (_op isEqualTo "~") then {
                _values = _values apply {toLowerANSI _x};

                if (_values findIf {count _x < MIN_SEARCH || {!([_x] call _fnc_isClass)}} >= 0) then {
                    _error = format ["'%1': class~ looks for a part of a class name, %2 letters at least", _token, MIN_SEARCH];
                };
            } else {
                // X, or X+ for X and every class built on it.
                private _bad = _values findIf {
                    private _name = _x;

                    if ((_name select [count _name - 1]) isEqualTo "+") then {
                        _name = _name select [0, count _name - 1];
                    };

                    !([_name] call _fnc_isClass)
                };

                if (_bad >= 0) then {
                    _error = format ["'%1': '%2' is no class name", _token, _values select _bad];
                };
            };
        };
        case "addon": {
            _values = _values apply {toLowerANSI _x};

            if (_values findIf {!([_x] call _fnc_isClass) || {_op isEqualTo "~" && {count _x < MIN_SEARCH}}} >= 0) then {
                _error = format ["'%1' is no addon name - for addon~, %2 letters at least", _token, MIN_SEARCH];
            };
        };
        case "well";
        case "for": {
            if (_values findIf {!([_x] call _fnc_isClass)} >= 0) then {
                _error = format ["'%1' is no class name", _token];
            };
        };
        default {
            if (_values findIf {!([_x] call _fnc_isNumber)} >= 0) then {
                _error = format ["'%1': %2 compares with numbers like 20 or 0.5", _token, _key];
            };
        };
    };

    if (_error isNotEqualTo "") exitWith {[_error, []]};

    ["", [_negated, _key, _op, _values]]
};

private _fnc_keyCond = {
    params ["_token", "_negated"];

    // The key is the letters up to the operator.
    private _keyEnd = (toArray _token) findIf {!((_x >= 97 && {_x <= 122}) || {_x >= 65 && {_x <= 90}})};

    if (_keyEnd <= 0) exitWith {
        [format ["'%1' is no condition like kind=rifle", _token], []]
    };

    private _key = toLowerANSI (_token select [0, _keyEnd]);
    private _rest = _token select [_keyEnd];
    private _op = "";

    // Two-character operators first, or "<=" would read as "<" and a value starting with "=".
    {
        if ((_rest select [0, count _x]) isEqualTo _x) exitWith {_op = _x};
    } forEach ["<=", ">=", "=", "~", "<", ">"];

    private _ops = _keyOps getOrDefault [_key, []];

    if (_ops isEqualTo []) exitWith {
        [format ["'%1': there is no key '%2' (%3)", _token, _key, (keys _keyOps) joinString ", "], []]
    };

    if !(_op in _ops) exitWith {
        [format ["'%1': %2 goes with %3", _token, _key, _ops joinString " "], []]
    };

    private _values = (_rest select [count _op]) splitString "|";

    if (_values isEqualTo []) exitWith {
        [format ["'%1' has no value", _token], []]
    };

    if (count _values > MAX_ALTERNATIVES) exitWith {
        [format ["'%1' has more than %2 choices", _token, MAX_ALTERNATIVES], []]
    };

    [_token, _negated, _key, _op, _values] call _fnc_checkValues
};

private _fnc_cond = {
    params ["_token"];

    private _negated = (_token select [0, 1]) isEqualTo "!";

    if (_negated) then {
        _token = _token select [1];
    };

    if ((_token select [0, 1]) isEqualTo "@") exitWith {[_token, _negated] call _fnc_groupCond};

    [_token, _negated] call _fnc_keyCond
};

// ----- Statements -----

private _fnc_header = {
    params ["_tokens"];

    _version = (parseNumber ((toLowerANSI (_tokens select 0)) select [4])) max 1;

    if (_version > 1) then {
        _warnings pushBack format ["The text was written for a newer version (einv%1) - read as far as this one understands it.", _version];
    };

    {
        private _equals = _x find "=";
        private _key = "";
        private _value = "";

        if (_equals > 0) then {
            _key = toLowerANSI (_x select [0, _equals]);
            _value = toLowerANSI (_x select [_equals + 1]);
        };

        switch (_key) do {
            case "base": {
                if ([_value] call _fnc_isId) then {
                    _base = _value;

                    // A preset renamed since the text was written: built on the new one, said once in
                    // the RPT - the wizard writes the new id the next time it saves.
                    private _alias = PRESET_ALIASES findIf {(_x select 0) isEqualTo _value};

                    if (_alias >= 0) then {
                        _base = (PRESET_ALIASES select _alias) select 1;

                        if !(missionNamespace getVariable [QGVAR(aliasWarned), false]) then {
                            missionNamespace setVariable [QGVAR(aliasWarned), true];
                            INFO_2("Rules: base=%1 is now base=%2 - read as that.",_value,_base);
                        };
                    };
                } else {
                    _warnings pushBack format ["Header: '%1' is no preset name - built on default.", _x];
                };
            };
            case "cell": {
                if ([_value] call _fnc_isNumber) then {
                    private _number = (round ((parseNumber _value) * 100)) / 100;
                    private _clamped = (_number max CELL_MIN) min CELL_MAX;

                    if (_clamped != _number) then {
                        _warnings pushBack format ["Header: cell=%1 - between %2 and %3, cut to %4.", _value, CELL_MIN, CELL_MAX, _clamped];
                    };

                    _cell = _clamped;
                } else {
                    _warnings pushBack format ["Header: cell=%1 is no number - left out.", _value];
                };
            };
            default {
                _warnings pushBack format ["Header: '%1' is neither base= nor cell= - left out.", _x];
            };
        };
    } forEach (_tokens select [1]);
};

private _fnc_groupDef = {
    params ["_tokens", "_short"];

    private _notes = [];
    private _first = _tokens select 0;
    private _colon = _first find ":";
    private _id = toLowerANSI (_first select [1, _colon - 1]);
    private _rest = _tokens select [1];

    // "@name:kind=rifle" without the space reads too.
    private _after = _first select [_colon + 1];

    if (_after isNotEqualTo "") then {
        _rest = [_after] + _rest;
    };

    if !([_id] call _fnc_isId) exitWith {
        _warnings pushBack format ["'%1': '@%2' is no group name - letters, digits and _ only - left out.", _short, _id];
    };

    if (_rest isEqualTo []) exitWith {
        _warnings pushBack format ["'%1': a group needs at least one condition - left out.", _short];
    };

    private _conds = [];
    private _error = "";

    {
        if (_x isEqualTo ">" || {[_x] call _fnc_isValue}) exitWith {
            _error = "a group only holds conditions - what to set goes into a rule like @name > size=1x2";
        };

        ([_x] call _fnc_cond) params ["_condError", "_cond"];

        if (_condError isNotEqualTo "") exitWith {
            _error = _condError;
        };

        _conds pushBack _cond;
    } forEach _rest;

    {
        _warnings pushBack format ["'%1': %2.", _short, _x];
    } forEach _notes;

    if (_error isNotEqualTo "") exitWith {
        _warnings pushBack format ["'%1': %2 - left out.", _short, _error];
    };

    _groups pushBack [_id, _conds];
};

private _fnc_rule = {
    params ["_tokens", "_short"];

    private _notes = [];
    private _conds = [];
    private _values = createHashMap;
    private _inValues = false;
    private _arrow = false;
    private _error = "";

    {
        if (_error isNotEqualTo "") exitWith {};

        switch (true) do {
            case (_x isEqualTo ">"): {
                if (_arrow || {_inValues}) then {
                    _error = "a second '>', or one after what the rule sets";
                } else {
                    _arrow = true;
                };
            };
            case ([_x] call _fnc_isValue): {
                _inValues = true;

                private _result = [_x] call _fnc_value;

                // A field given twice: the later one counts, as between rules.
                if (_result isNotEqualTo []) then {
                    _values set [_result select 0, _result select 1];
                };
            };
            default {
                if (_inValues || {_arrow}) then {
                    _error = format ["'%1' comes after what the rule sets - conditions go first", _x];
                } else {
                    ([_x] call _fnc_cond) params ["_condError", "_cond"];

                    if (_condError isEqualTo "") then {
                        _conds pushBack _cond;
                    } else {
                        _error = _condError;
                    };
                };
            };
        };
    } forEach _tokens;

    {
        _warnings pushBack format ["'%1': %2.", _short, _x];
    } forEach _notes;

    if (_error isNotEqualTo "") exitWith {
        _warnings pushBack format ["'%1': %2 - left out.", _short, _error];
    };

    if (count _values == 0) exitWith {
        if (_inValues) then {
            _warnings pushBack format ["'%1': nothing it sets could be read - left out.", _short];
        } else {
            _warnings pushBack format ["'%1' sets nothing - a rule ends with what it sets, like > size=1x2 - left out.", _short];
        };
    };

    _rules pushBack [_conds, _values];
};

// ----- The text -----

private _count = 0;

{
    private _statement = trim _x;

    // Nothing between two commas, or after the last one, is no mistake.
    if (_statement isEqualTo "") then {continue};

    _count = _count + 1;

    if (_count > MAX_STATEMENTS) exitWith {
        _warnings pushBack format ["More than %1 statements - the rest are left out.", MAX_STATEMENTS];
    };

    private _short = [_statement] call _fnc_short;
    private _bad = (toArray _statement) findIf {!(_x in _allowed)};

    if (_bad >= 0) then {
        _warnings pushBack format ["'%1': a rule cannot hold '%2' - left out.", _short, toString [(toArray _statement) select _bad]];
        continue;
    };

    private _tokens = _statement splitString (toString [32, 9]);
    private _first = toLowerANSI (_tokens select 0);

    if ((_first select [0, 4]) isEqualTo "einv" && {[_first select [4]] call _fnc_isWhole}) then {
        if (_count == 1) then {
            [_tokens] call _fnc_header;
        } else {
            _warnings pushBack format ["'%1': the header (einv1 ...) is only read as the first statement - left out.", _short];
        };

        continue;
    };

    if ((_first select [0, 1]) isEqualTo "@" && {_first find ":" >= 0}) then {
        [_tokens, _short] call _fnc_groupDef;
        continue;
    };

    [_tokens, _short] call _fnc_rule;
} forEach (_text splitString (toString [44, 10, 13]));

_ast set ["version", _version];
_ast set ["base", _base];
_ast set ["cell", _cell];

_ast
