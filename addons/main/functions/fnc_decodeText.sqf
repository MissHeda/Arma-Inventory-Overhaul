#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Reads a text as fnc_encodeText wrote it: "%" and four hex digits are the character with that code, anything
 * else stands for itself. A "%" that no four digits follow stays a "%".
 *
 * Arguments:
 * 0: Text as it is written <STRING>
 *
 * Return Value:
 * The text <STRING>
 *
 * Example:
 * ["Not%0020allowed"] call einv_main_fnc_decodeText;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _chars = toArray _text;
private _count = count _chars;
private _out = [];
private _index = 0;

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

while {_index < _count} do {
    private _char = _chars select _index;
    private _code = -1;

    if (_char == 37 && {_index + 4 < _count}) then {
        private _digits = (_chars select [_index + 1, 4]) apply {[_x] call _fnc_hex};

        if (_digits findIf {_x < 0} < 0) then {
            _code = ((_digits select 0) * 4096) + ((_digits select 1) * 256) + ((_digits select 2) * 16) + (_digits select 3);
        };
    };

    if (_code >= 0) then {
        _out pushBack _code;
        _index = _index + 5;
    } else {
        _out pushBack _char;
        _index = _index + 1;
    };
};

toString _out
