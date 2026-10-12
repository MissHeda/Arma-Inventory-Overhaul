#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a name for "name=" in a rules text. The rules split at spaces and commas, and CBA's settings
 * must never see a ";", a quote or a backslash - so a name keeps only letters, digits, "-" and "."
 * as they are, a space becomes "_", and every other character is written as its UTF-8 bytes, each as
 * "%" and two hex digits: "Field kit (3)" -> "Field_kit_%283%29", "Verbandpäckchen" ->
 * "Verbandp%C3%A4ckchen". An underscore of its own is written %5F, so it does not come back as a
 * space. fnc_decodeName turns it back.
 *
 * Arguments:
 * 0: Name as it should show <STRING>
 *
 * Return Value:
 * The name as the rules write it <STRING>
 *
 * Example:
 * ["Field kit (3)"] call einv_items_fnc_encodeName;
 *
 * Public: Yes
 */

params [["_text", "", [""]]];

private _hex = toArray "0123456789ABCDEF";
private _out = [];

{
    switch (true) do {
        case (_x == 32): {_out pushBack 95};
        case ((_x >= 48 && {_x <= 57}) || {_x >= 65 && {_x <= 90}} || {_x >= 97 && {_x <= 122}} || {_x in [45, 46]}): {
            _out pushBack _x;
        };
        default {
            // The character's UTF-8 bytes: one below 128, else a lead byte and continuation bytes.
            private _bytes = switch (true) do {
                case (_x < 128): {[_x]};
                case (_x < 2048): {[192 + floor (_x / 64), 128 + (_x mod 64)]};
                case (_x < 65536): {[224 + floor (_x / 4096), 128 + ((floor (_x / 64)) mod 64), 128 + (_x mod 64)]};
                default {[240 + floor (_x / 262144), 128 + ((floor (_x / 4096)) mod 64), 128 + ((floor (_x / 64)) mod 64), 128 + (_x mod 64)]};
            };

            {
                _out append [37, _hex select (floor (_x / 16)), _hex select (_x mod 16)];
            } forEach _bytes;
        };
    };
} forEach (toArray _text);

toString _out
