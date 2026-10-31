#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes a free text so it can stand as a value in the text of the server settings (fnc_writeSettings): CBA's
 * settings must never see a ";", a quote or a backslash, and the text splits at commas and spaces. Letters,
 * digits, "-" and "." stay as they are; every other character is written as "%" and the four hex digits of
 * its code, a space as "%0020". fnc_decodeText turns it back.
 *
 * Arguments:
 * 0: Text <STRING>
 *
 * Return Value:
 * The text as it is written <STRING>
 *
 * Example:
 * ["Not allowed here, sorry"] call aio_main_fnc_encodeText;
 *
 * Public: No
 */

params [["_text", "", [""]]];

private _hex = toArray "0123456789ABCDEF";
private _out = [];

{
    // Four hex digits hold the characters up to 65535; a character beyond that (an emoji) is written as a "?".
    private _code = [_x, 63] select (_x > 65535);

    if ((_code >= 48 && {_code <= 57}) || {_code >= 65 && {_code <= 90}} || {_code >= 97 && {_code <= 122}} || {_code in [45, 46]}) then {
        _out pushBack _code;
    } else {
        _out append [
            37, _hex select (floor (_code / 4096)), _hex select ((floor (_code / 256)) mod 16),
            _hex select ((floor (_code / 16)) mod 16), _hex select (_code mod 16)
        ];
    };
} forEach (toArray _text);

toString _out
