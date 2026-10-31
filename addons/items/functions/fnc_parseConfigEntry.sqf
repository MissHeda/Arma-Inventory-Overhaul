#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads config lines like the ones fnc_configEntry writes - one class or several, under their root or
 * without it - into what they set, for the setup wizard's import and for anyone checking a snippet:
 *
 *   class CfgVehicles { class B_Carryall_blk { einv_grid = "1x3+5x7+1x3"; }; };
 *
 * Only the keys of an item (CONFIG_KEYS: einv_size, einv_stack, einv_grid, einv_weight, einv_name,
 * einv_icon, einv_picture, einv_use, einv_cat) are taken, and each value is read the way an item's config is (fnc_readConfigKeys), so what
 * comes back is what the rules would have made of it: a grid as fnc_formatGrid writes it, a size as the
 * rules write it, the stack and the weight as numbers, an icon as [scale, across, down], a use list as an array, and nothing
 * that could not be read. A class with no key left is not in the answer.
 *
 * The reader is lenient about the rest of the file: comments (// and a block comment) are skipped,
 * so are "class X;" declarations, the parent after a colon (class X: Y), every other property and
 * every class inside an item's class (class ItemInfo, class Armory). A class under CfgWeapons,
 * CfgVehicles, CfgMagazines or CfgGlasses is an item; a class at the top that is none of those is an
 * item itself, so the line "class V_X { einv_grid = ""24""; };" without its root reads too. The same
 * class twice: its keys together, the later one winning. Case does not matter in the keys.
 *
 * What cannot be read - a key that is not a text or a number, an einv_ key that is none of the eight, a
 * value the rules would leave out - is named in the messages. Without an array for them, they go to
 * the RPT. A text over CONFIG_TEXT_MAX characters is not read at all.
 *
 * Arguments:
 * 0: Config text <STRING>
 * 1: An array the messages (STRING, each naming its class) are added to <ARRAY> (default: nil, the RPT)
 *
 * Return Value:
 * [[class, keys], ...] in the order the classes first appear <ARRAY>
 *   class - the class as written <STRING>
 *   keys  - what it sets, by config key in lowercase: "einv_size" "2x1" / "xx/x-" / "mass" <STRING>,
 *           "einv_stack" <NUMBER>, "einv_grid" <STRING>, "einv_weight" kg <NUMBER>, "einv_name"
 *           <STRING>, "einv_icon" [scale, across, down] <ARRAY>, "einv_picture" <STRING>, "einv_use" [containers] <ARRAY>, "einv_cat" [categories] <ARRAY> - only the ones set <HASHMAP>
 *
 * Example:
 * ["class CfgVehicles { class B_Carryall_blk { einv_grid = ""1x3+5x7+1x3""; }; };"] call einv_items_fnc_parseConfigEntry;
 * // [["B_Carryall_blk", createHashMapFromArray [["einv_grid", "1x3+5x7+1x3"]]]]
 *
 * Public: Yes
 */

params [["_text", "", [""]], ["_messages", nil, [[]]]];

private _notes = [];
private _result = [];

if (count _text > CONFIG_TEXT_MAX) exitWith {
    _notes pushBack format ["The text is %1 characters long, more than the %2 a snippet may have - nothing read.", count _text, CONFIG_TEXT_MAX];

    if (isNil "_messages") then {
        {WARNING_1("Config snippet: %1",_x)} forEach _notes;
    } else {
        _messages append _notes;
    };

    _result
};

// ----- Tokens -----
// [type, value, text]: 0 a name (letters, digits, _), 1 a string, 2 a number, 3 one other character.
// Comments and white space are gone. A doubled quote inside a string is a quote, as in config.

private _codes = toArray _text;
private _length = count _codes;
private _tokens = [];
private _i = 0;

private _fnc_isWord = {
    params ["_c"];

    (_c >= 48 && {_c <= 57}) || {_c >= 65 && {_c <= 90}} || {_c >= 97 && {_c <= 122}} || {_c == 95} || {_c == 46}
};

while {_i < _length} do {
    private _c = _codes select _i;
    private _next = _codes param [_i + 1, 0];

    switch (true) do {
        case (_c <= 32): {
            _i = _i + 1;
        };
        case (_c == 34): {
            private _string = [];
            private _open = true;

            _i = _i + 1;

            while {_open && {_i < _length}} do {
                private _d = _codes select _i;

                if (_d == 34 && {(_codes param [_i + 1, 0]) == 34}) then {
                    _string pushBack 34;
                    _i = _i + 2;
                } else {
                    if (_d == 34) then {
                        _open = false;
                    } else {
                        _string pushBack _d;
                    };

                    _i = _i + 1;
                };
            };

            _tokens pushBack [1, toString _string, ""];
        };
        case (_c == 47 && {_next == 47}): {
            while {_i < _length && {!((_codes select _i) in [10, 13])}} do {
                _i = _i + 1;
            };
        };
        case (_c == 47 && {_next == 42}): {
            _i = _i + 2;

            while {_i < _length && {!((_codes select _i) == 42 && {(_codes param [_i + 1, 0]) == 47})}} do {
                _i = _i + 1;
            };

            _i = _i + 2;
        };
        case (([_c] call _fnc_isWord) || {_c == 45 && {(_next >= 48 && {_next <= 57}) || {_next == 46}}}): {
            private _start = _i;

            // A minus belongs to the number after it.
            if (_c == 45) then {
                _i = _i + 1;
            };

            while {_i < _length && {[_codes select _i] call _fnc_isWord}} do {
                _i = _i + 1;
            };

            private _word = toString (_codes select [_start, _i - _start]);
            private _digits = toArray ([_word, _word select [1]] select (_c == 45));

            // Digits with one dot at most make a number; anything else (3AS_Clone) is a name.
            private _isNumber = _digits findIf {(_x < 48 || {_x > 57}) && {_x != 46}} < 0
                && {_digits findIf {_x >= 48 && {_x <= 57}} >= 0}
                && {({_x == 46} count _digits) <= 1};

            if (_isNumber) then {
                _tokens pushBack [2, parseNumber _word, _word];
            } else {
                _tokens pushBack [0, _word, _word];
            };
        };
        default {
            _tokens pushBack [3, toString [_c], toString [_c]];
            _i = _i + 1;
        };
    };
};

// ----- Reading -----

private _roots = CONFIG_ROOTS apply {toLowerANSI _x};
private _total = count _tokens;
private _frames = [];
private _classes = createHashMap;
private _order = [];

private _fnc_isSymbol = {
    params ["_token", "_character"];

    (_token select 0) == 3 && {(_token select 1) isEqualTo _character}
};

private _fnc_tokenAt = {
    params ["_at"];

    _tokens param [_at, [-1, "", ""]]
};

// The tokens of one statement from _from to its semicolon (or the brace closing the class, which stays),
// an array's braces counted: [tokens, where the next statement starts].
private _fnc_statement = {
    params ["_from"];

    private _depth = 0;
    private _at = _from;
    private _taken = [];
    private _done = false;

    while {!_done && {_at < _total}} do {
        private _token = _tokens select _at;
        private _isSemicolon = [_token, ";"] call _fnc_isSymbol;
        private _isOpen = [_token, "{"] call _fnc_isSymbol;
        private _isClose = [_token, "}"] call _fnc_isSymbol;

        if (_depth == 0 && {_isSemicolon}) then {
            _done = true;
            _at = _at + 1;
        } else {
            if (_depth == 0 && {_isClose}) then {
                _done = true;
            } else {
                if (_isOpen) then {_depth = _depth + 1};
                if (_isClose) then {_depth = _depth - 1};

                _taken pushBack _token;
                _at = _at + 1;
            };
        };
    };

    [_taken, _at]
};

// An item's class is done: its keys join those the same class had before.
private _fnc_finish = {
    params ["_frame"];

    _frame params ["_kind", "_name", "_keys"];

    if (_kind isNotEqualTo "item" || {count _keys == 0}) exitWith {};

    private _lower = toLowerANSI _name;
    private _known = _classes get _lower;

    if (isNil "_known") then {
        _classes set [_lower, [_name, _keys]];
        _order pushBack _lower;
    } else {
        {
            (_known select 1) set [_x, _y];
        } forEach _keys;
    };
};

private _t = 0;

while {_t < _total} do {
    private _token = _tokens select _t;
    private _frame = _frames param [0, ["", "", createHashMap]];

    switch (true) do {
        // class Name { ... }, class Name: Parent { ... } or the declaration class Name;
        case ((_token select 0) == 0 && {toLowerANSI (_token select 1) isEqualTo "class"}): {
            private _name = [_t + 1] call _fnc_tokenAt;
            private _at = _t + 2;

            if ([[_at] call _fnc_tokenAt, ":"] call _fnc_isSymbol) then {
                _at = _at + 2;
            };

            if ([[_at] call _fnc_tokenAt, "{"] call _fnc_isSymbol) then {
                // At the top a root holds items, any other class is an item; inside a root a class is
                // an item; deeper down nothing is read.
                private _kind = "skip";

                if (_frames isEqualTo []) then {
                    _kind = ["item", "root"] select ((toLowerANSI (_name select 2)) in _roots);
                } else {
                    if ((_frame select 0) isEqualTo "root") then {
                        _kind = "item";
                    };
                };

                _frames = [[_kind, _name select 2, createHashMap]] + _frames;
                _t = _at + 1;
            } else {
                _t = (([_at] call _fnc_statement) select 1) max (_t + 1);
            };
        };
        case ([_token, "}"] call _fnc_isSymbol): {
            if (_frames isNotEqualTo []) then {
                [_frames deleteAt 0] call _fnc_finish;
            };

            _t = _t + 1;

            if ([[_t] call _fnc_tokenAt, ";"] call _fnc_isSymbol) then {
                _t = _t + 1;
            };
        };
        // An array's brace, or a block that is none of the above: balanced, not read.
        case ([_token, "{"] call _fnc_isSymbol): {
            _frames = [["skip", "", createHashMap]] + _frames;
            _t = _t + 1;
        };
        // key = value;  key[] = {...};  inside an item's class
        case ((_token select 0) == 0 && {(_frame select 0) isEqualTo "item"}): {
            ([_t] call _fnc_statement) params ["_taken", "_after"];

            private _key = toLowerANSI (_token select 1);
            private _equals = _taken findIf {[_x, "="] call _fnc_isSymbol};
            private _value = _taken select [(_equals + 1) max 0];

            if (_equals > 0 && {_key in CONFIG_KEYS}) then {
                if (count _value == 1 && {((_value select 0) select 0) in [1, 2]}) then {
                    (_frame select 2) set [_key, (_value select 0) select 1];
                } else {
                    _notes pushBack format ["%1: %2 is a text or a number - left out", _frame select 1, _key];
                };
            } else {
                if (_equals > 0 && {(_key select [0, 5]) isEqualTo "einv_"}) then {
                    _notes pushBack format ["%1: %2 is none of %3 - left out", _frame select 1, _key, CONFIG_KEYS joinString ", "];
                };
            };

            _t = _after max (_t + 1);
        };
        default {
            _t = _t + 1;
        };
    };
};

// Braces left open: what was read of the classes in them counts.
while {_frames isNotEqualTo []} do {
    [_frames deleteAt 0] call _fnc_finish;
};

// ----- What the keys say -----

{
    (_classes get _x) params ["_name", "_keys"];

    ([_keys] call FUNC(readConfigKeys)) params ["_canonical", "", "_problems"];

    {
        _notes pushBack format ["%1: %2", _name, _x];
    } forEach _problems;

    if (count _canonical > 0) then {
        _result pushBack [_name, _canonical];
    };
} forEach _order;

if (isNil "_messages") then {
    {WARNING_1("Config snippet: %1",_x)} forEach _notes;
} else {
    _messages append _notes;
};

_result
