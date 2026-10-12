#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Creates a button the way the inventory draws them (einv_gui_fnc_uiButton): a flat surface with an icon
 * and a label centred together, lighting up under the mouse - but with the wizard's own way to run its
 * code a moment later (fnc_uiHit), which also works in Eden.
 *
 * Styles: "" a light film; "accent" filled with the accent, for the one thing a card is for (Save, Apply);
 * "ghost" no surface until the mouse is on it, for icons in a row; "danger" a film with the label in the
 * loss colour (Reset, Delete). Disabled, it is greyed out and only shows its tooltip.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Controls group to create it in <CONTROL>
 * 2: Position [x, y, w, h], relative to the group <ARRAY>
 * 3: Label, "" for none <STRING> (default: "")
 * 4: Icon texture, "" for none <STRING> (default: "")
 * 5: Theme <HASHMAP> (default: empty)
 * 6: Code, called with the arguments as _this <CODE> (default: {})
 * 7: Arguments <ANY> (default: [])
 * 8: Enabled <BOOL> (default: true)
 * 9: Style, "", "accent", "ghost" or "danger" <STRING> (default: "")
 * 10: Tooltip, "" for none <STRING> (default: "")
 *
 * Return Value:
 * The controls, the hit area last <ARRAY>
 *
 * Example:
 * [_display, _group, [0, 0, 0.1, 0.03], "Save", "", _theme, {[] call einv_setup_fnc_save}, [], true, "accent"] call einv_setup_fnc_uiAction;
 *
 * Public: No
 */

disableSerialization;

params [
    "_display", "_parent", "_rect", ["_text", "", [""]], ["_icon", "", [""]], ["_theme", createHashMap, [createHashMap]],
    ["_code", {}, [{}]], ["_arguments", []], ["_enabled", true, [true]], ["_style", "", [""]], ["_tooltip", "", [""]]
];
_rect params ["_left", "_top", "_width", "_height"];

private _fill = _theme getOrDefault ["button", [1, 1, 1, 0.08]];
private _fillHover = _theme getOrDefault ["buttonHover", [1, 1, 1, 0.12]];
private _ink = _theme getOrDefault ["buttonText", [0.698, 0.734, 0.784, 1]];

switch (_style) do {
    case "accent": {
        _fill = _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]];
        _fillHover = ACCENT_HOVER;
        _ink = _theme getOrDefault ["onAccent", [0.086, 0.094, 0.114, 1]];
    };
    case "ghost": {
        _fill = [0, 0, 0, 0];
    };
    case "danger": {
        _ink = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
    };
};

if (!_enabled) then {
    _fill = [DISABLED_FILL, [0, 0, 0, 0]] select (_style isEqualTo "ghost");
    _fillHover = _fill;
    _ink = DISABLED_INK;
};

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _controls = [_display, _parent, _rect, _fill, (_theme getOrDefault ["radius", 0]) min (_height / 2)] call EFUNC(gui,uiPanel);
private _surface = +_controls;

// Laid out as the inventory's buttons are: an icon alone in the middle, with a label both kept off the
// edges, the label fitted with some slack - names fitted to their exact width were cut off in the game.
private _hasIcon = _icon isNotEqualTo "";
private _size = _height * 0.5;
private _iconH = _height * 0.56;
private _iconW = [0, SQUARE(_iconH)] select _hasIcon;
private _gap = [0, SQUARE(_height * 0.22)] select (_hasIcon && {_text isNotEqualTo ""});
private _pad = SQUARE(_height * 0.3);
private _room = _width - _pad * 2 - _iconW - _gap;
private _shown = "";
private _textW = 0;

if (_text isNotEqualTo "" && {_room > 0}) then {
    _shown = [_text, _room, _font, _size] call EFUNC(gui,fitText);
    _textW = (_shown getTextWidth [_font, _size]) min _room;
};

private _start = _left + (((_width - _iconW - _gap - _textW) / 2) max ([_pad, 0] select (_shown isEqualTo "")));

if (_hasIcon) then {
    _controls pushBack ([_display, _parent, [_start, _top + (_height - _iconH) / 2, _iconW, _iconH], _icon, _ink] call EFUNC(gui,uiIcon));
};

if (_shown isNotEqualTo "") then {
    // Left-aligned in a box running to the button's edge: whatever the engine draws wider than measured
    // spills to the right, never off the left.
    private _labelX = _start + _iconW + _gap;

    _controls pushBack ([_display, _parent, [_labelX, _top, _left + _width - _labelX, _height], _shown, _size, _ink, _font, 0] call EFUNC(gui,uiLabel));
};

_controls pushBack ([_display, _parent, _rect, _surface, _fill, _fillHover, _code, _arguments, _enabled, _tooltip] call FUNC(uiHit));

_controls
