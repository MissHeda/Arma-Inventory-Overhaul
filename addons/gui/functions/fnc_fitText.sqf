#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shortens a text to a width, ending it in "..." - a label draws its words past its own edge, over
 * whatever stands next to it. Cut by characters, so names with umlauts stay whole.
 *
 * Leaves TEXT_SLACK room: the engine draws wider than getTextWidth says - in the phase 1 test names
 * fitted to the full width were cut off, and in phase 3 the footer hints still were at 12 %.
 *
 * Arguments:
 * 0: Text <STRING>
 * 1: Width, in screen units <NUMBER>
 * 2: Font <STRING>
 * 3: Font size, as a height <NUMBER>
 *
 * Return Value:
 * The text, shortened where it has to be <STRING>
 *
 * Example:
 * ["Multiple First Aid Kit Plus (MFAK+)", 0.1, "PuristaMedium", 0.025] call einv_gui_fnc_fitText;
 *
 * Public: No
 */

params ["_text", "_width", "_font", "_size"];

// A hair of room on top: a box made exactly as wide as its text (text width times TEXT_SLACK) must keep
// the whole text - rounding would otherwise cut "Vest" to "Ve...".
_width = _width / TEXT_SLACK * 1.02;

if ((_text getTextWidth [_font, _size]) <= _width) exitWith {_text};

// The most characters that still fit with the dots, found by halving.
private _chars = toArray _text;
private _fits = 0;
private _over = count _chars;

while {_over - _fits > 1} do {
    private _try = floor ((_fits + _over) / 2);

    if (((toString (_chars select [0, _try])) + "...") getTextWidth [_font, _size] <= _width) then {
        _fits = _try;
    } else {
        _over = _try;
    };
};

private _kept = _chars select [0, _fits];

// No space in front of the dots.
while {_kept isNotEqualTo [] && {(_kept select (count _kept - 1)) == 32}} do {
    _kept deleteAt (count _kept - 1);
};

(toString _kept) + "..."
