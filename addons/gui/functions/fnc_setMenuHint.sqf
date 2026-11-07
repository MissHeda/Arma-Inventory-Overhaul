#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Writes a tip onto the colour popover's hint line (fnc_openPaletteMenu): grey words, as many lines as the line has room for.
 *
 * Arguments:
 * 0: The hint line <CONTROL>
 * 1: Tip <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_line, "Turns the item you are dragging"] call aio_gui_fnc_setMenuHint;
 *
 * Public: No
 */

params [["_line", controlNull, [controlNull]], ["_tip", "", [""]]];

if (isNull _line) exitWith {};

private _size = _line getVariable [QGVAR(hintSize), UNIT * 0.45];

// As tags, as fnc_gradientText writes its words: set with setAttributes the size was not taken and the tip came out at the
// control's own size, too big for its line and cut off at the card's foot (Mia, 0.6.93).
private _escaped = ((toArray _tip) apply {
    switch (_x) do {
        case 38: {"&amp;"};
        case 60: {"&lt;"};
        case 62: {"&gt;"};
        case 10: {"<br/>"};
        default {toString [_x]};
    };
}) joinString "";

(ctrlPosition _line) params ["", "", "", ["_room", 0]];

// Still taller than its line - a long tip or a large text scale: a little smaller until it fits, so nothing is cut off.
for "_i" from 0 to 6 do {
    _line ctrlSetStructuredText parseText format [
        "<t font='PuristaMedium' size='%1' color='#C7C7C7' align='left'>%2</t>", _size / (UNIT * 0.7), _escaped
    ];

    if (_room <= 0 || {ctrlTextHeight _line <= _room}) exitWith {};

    _size = _size * 0.9;
};
