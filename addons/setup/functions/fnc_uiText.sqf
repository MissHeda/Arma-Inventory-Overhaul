#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a text of several lines, wrapped at a width, and says how high it came out - so what follows
 * can go right under it whatever the language and the UI size. A structured text, measured once its
 * words are in.
 *
 * The text is shown as it is: characters the structured text would read as markup are written out.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Top left corner and width [x, y, w], relative to the group <ARRAY>
 * 3: Text <STRING>
 * 4: Font size, as a height <NUMBER> (default: TEXT_BODY)
 * 5: Colour <ARRAY> (default: [1, 1, 1, 1])
 * 6: Font <STRING> (default: "PuristaMedium")
 *
 * Return Value:
 * Height taken <NUMBER>
 *
 * Example:
 * private _height = [_display, _group, [0, 0, 0.3], "A long text", 0.02, [1, 1, 1, 1], "PuristaMedium"] call einv_setup_fnc_uiText;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_position", ["_text", "", [""]], ["_size", TEXT_BODY, [0]], ["_color", [1, 1, 1, 1], [[]]], ["_font", "PuristaMedium", [""]]];
_position params ["_left", "_top", "_width"];

if (_text isEqualTo "") exitWith {0};

private _ctrl = [_display, "EINV_StructuredText", _parent, [_left, _top, _width, UNIT * 10]] call EFUNC(gui,uiCreate);
_ctrl ctrlSetStructuredText parseText format [
    "<t font='%1' color='%2' size='%3'>%4</t>",
    _font, [_color] call FUNC(hex), _size / STRUCTURED_SIZE, [_text] call FUNC(escape)
];

private _height = ceil ((ctrlTextHeight _ctrl) / pixelH) * pixelH;

(ctrlPosition _ctrl) params ["_ctrlX", "_ctrlY", "_ctrlW"];

_ctrl ctrlSetPosition [_ctrlX, _ctrlY, _ctrlW, _height];
_ctrl ctrlCommit 0;

_height
