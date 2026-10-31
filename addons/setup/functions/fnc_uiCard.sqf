#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a card on a step: a light film over the wizard's glass, with round corners and a caption at its
 * top - as Enhanced First Aid Kits lays its cards on its window.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Caption, "" for none <STRING> (default: "")
 * 4: Theme <HASHMAP> (default: empty)
 *
 * Return Value:
 * Where its content starts, as a y in the group <NUMBER>
 *
 * Example:
 * private _contentY = [_display, _group, [0, 0, 0.3, 0.2], "Cell size", _theme] call aio_setup_fnc_uiCard;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_parent", "_rect", ["_title", "", [""]], ["_theme", createHashMap, [createHashMap]]];
_rect params ["_left", "_top", "_width"];

[_display, _parent, _rect, _theme getOrDefault ["card", [1, 1, 1, 0.055]], _theme getOrDefault ["radius", 0]] call EFUNC(gui,uiPanel);

if (_title isEqualTo "") exitWith {_top + CARD_PAD_Y};

private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _titleW = _width - CARD_PAD_X * 2;

[
    _display, _parent, [_left + CARD_PAD_X, _top + CARD_PAD_Y, _titleW, CARD_CAPTION_H],
    [[_title, _theme] call EFUNC(gui,caption), _titleW, _fontBold, UNIT * 0.72] call EFUNC(gui,fitText), UNIT * 0.72,
    _theme getOrDefault ["text", [1, 1, 1, 1]], _fontBold, 0
] call EFUNC(gui,uiLabel);

_top + CARD_PAD_Y + CARD_CAPTION_H + UNIT * 0.15
