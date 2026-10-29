#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A line of structured text whose letters run from one colour into another, left to right, as Discord's gradient names do: one
 * colour per letter, mixed by its place in the line. The titles of the window (fnc_uiLabel) and the name at the mouse
 * (fnc_setTipText) are drawn with it while the palette's titles gradient is on.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Font, "" for PuristaMedium <STRING>
 * 2: Font size, as a height <NUMBER>
 * 3: Alignment - 0 left, 1 right, 2 centre <NUMBER>
 * 4: The first letter's colour [r, g, b, a] <ARRAY>
 * 5: The last letter's colour [r, g, b] <ARRAY>
 *
 * Return Value:
 * Structured text, for EINV_StructuredText <TEXT>
 *
 * Example:
 * ["Inventory", "PuristaSemibold", 0.03, 0, [0.3, 0.6, 1, 1], [0.7, 0.4, 1]] call einv_gui_fnc_gradientText;
 *
 * Public: No
 */

params [["_text", "", [""]], ["_font", "", [""]], ["_size", 0.03, [0]], ["_align", 0, [0]], ["_from", [1, 1, 1, 1], [[]]], ["_to", [1, 1, 1], [[]]]];

private _codes = toArray _text;
private _last = (count _codes - 1) max 1;
private _digits = "0123456789ABCDEF";
private _alpha = _from param [3, 1];
private _letters = [];

{
    private _at = _forEachIndex / _last;
    private _bytes = [0, 1, 2] apply {round ((((_from select _x) + ((_to select _x) - (_from select _x)) * _at) max 0 min 1) * 255)};
    private _hex = (_bytes + [round (_alpha * 255)]) apply {(_digits select [floor (_x / 16), 1]) + (_digits select [_x mod 16, 1])};
    private _letter = switch (_x) do {
        case 38: {"&amp;"};
        case 60: {"&lt;"};
        case 62: {"&gt;"};
        default {toString [_x]};
    };

    _letters pushBack format ["<t color='#%1%2%3%4'>%5</t>", _hex select 3, _hex select 0, _hex select 1, _hex select 2, _letter];
} forEach _codes;

parseText format [
    "<t font='%1' size='%2' align='%3'>%4</t>",
    [_font, "PuristaMedium"] select (_font isEqualTo ""), _size / (UNIT * 0.7), ["left", "right", "center"] select ((_align max 0) min 2),
    _letters joinString ""
]
