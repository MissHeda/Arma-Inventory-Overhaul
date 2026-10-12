#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Creates a line of text. Font, size and colour are set here rather than in the class, because the
 * style decides them.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in, or controlNull for the display <CONTROL>
 * 2: Position [x, y, w, h] <ARRAY>
 * 3: Text <STRING>
 * 4: Font size, as a height <NUMBER>
 * 5: Colour, [] for the class's own <ARRAY>
 * 6: Font, "" for the class's own <STRING>
 * 7: Alignment - 0 left, 1 right, 2 centre <NUMBER> (default: 0)
 *
 * Return Value:
 * The label <CONTROL>
 *
 * Example:
 * [_display, controlNull, [0.1, 0.1, 0.2, 0.03], "Vest", 0.025, [1, 1, 1, 1], "PuristaSemibold", 0] call einv_gui_fnc_uiLabel;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", "_text", "_size", ["_color", []], ["_font", ""], ["_align", 0]];

private _class = ["EINV_Label", "EINV_LabelRight", "EINV_LabelCenter"] select ((_align max 0) min 2);
private _ctrl = [_display, _class, _parent, _rect] call FUNC(uiCreate);

if (_font isNotEqualTo "") then {
    _ctrl ctrlSetFont _font;
};

_ctrl ctrlSetFontHeight _size;

if (_color isNotEqualTo []) then {
    _ctrl ctrlSetTextColor _color;
};

_ctrl ctrlSetText _text;

_ctrl
