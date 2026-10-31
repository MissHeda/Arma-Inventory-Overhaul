#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads a name as "name=" in a rules text has it, see fnc_encodeName: "_" is a space, "%" with two
 * hex digits one byte of a UTF-8 character. A "%" without two hex digits after it stays as it is, and
 * bytes that make no UTF-8 character come out one character each - a typo shows in the name instead
 * of losing it.
 *
 * As a path (picture=) an underscore stays an underscore, and a "/" comes out as the backslash the engine
 * writes its paths with.
 *
 * Arguments:
 * 0: Name as the rules write it <STRING>
 * 1: Read it as a path <BOOL> (default: false)
 *
 * Return Value:
 * The name as it should show <STRING>
 *
 * Example:
 * ["Field_kit_%283%29"] call aio_items_fnc_decodeName;
 *
 * Public: Yes
 */

params [["_text", "", [""]], ["_path", false, [false]]];

private _chars = toArray _text;
private _count = count _chars;
private _out = [];
private _bytes = [];

// A hex digit's value, -1 for anything else.
private _fnc_hex = {
    params ["_code"];

    switch (true) do {
        case (_code >= 48 && {_code <= 57}): {_code - 48};
        case (_code >= 65 && {_code <= 70}): {_code - 55};
        case (_code >= 97 && {_code <= 102}): {_code - 87};
        default {-1};
    }
};

// The bytes collected so far, as UTF-8 characters.
private _fnc_flush = {
    private _index = 0;
    private _total = count _bytes;

    while {_index < _total} do {
        private _lead = _bytes select _index;
        private _length = switch (true) do {
            case (_lead < 128): {1};
            case (_lead >= 240): {4};
            case (_lead >= 224): {3};
            case (_lead >= 192): {2};
            default {0};
        };
        private _code = -1;

        if (_length > 0 && {_index + _length <= _total}) then {
            private _tail = _bytes select [_index + 1, _length - 1];

            if (_tail findIf {_x < 128 || {_x > 191}} < 0) then {
                _code = switch (_length) do {
                    case 1: {_lead};
                    case 2: {(_lead - 192) * 64 + ((_tail select 0) - 128)};
                    case 3: {(_lead - 224) * 4096 + ((_tail select 0) - 128) * 64 + ((_tail select 1) - 128)};
                    default {(_lead - 240) * 262144 + ((_tail select 0) - 128) * 4096 + ((_tail select 1) - 128) * 64 + ((_tail select 2) - 128)};
                };
            };
        };

        if (_code < 0) then {
            _out pushBack _lead;
            _index = _index + 1;
        } else {
            _out pushBack _code;
            _index = _index + _length;
        };
    };

    _bytes resize 0;
};

private _index = 0;

while {_index < _count} do {
    private _char = _chars select _index;
    private _high = -1;
    private _low = -1;

    if (_char == 37 && {_index + 2 < _count}) then {
        _high = [_chars select (_index + 1)] call _fnc_hex;
        _low = [_chars select (_index + 2)] call _fnc_hex;
    };

    if (_high >= 0 && {_low >= 0}) then {
        _bytes pushBack (_high * 16 + _low);
        _index = _index + 3;
    } else {
        call _fnc_flush;
        _out pushBack (switch (true) do {
            case (_path && {_char == 47}): {92};
            case (!_path && {_char == 95}): {32};
            default {_char};
        });
        _index = _index + 1;
    };
};

call _fnc_flush;

toString _out
