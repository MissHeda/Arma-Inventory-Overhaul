#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The search field in the header, like Tarkov's stash search: what is typed fades every tile whose
 * name does not match (fnc_applyFilter), so what is looked for stands out. A magnifying glass, the
 * placeholder while it is empty, and the field over the whole box takes the cursor on a click.
 *
 * Drawn on every build like the rest of the header: the text is kept (GVAR(filter)), and a field that
 * had the cursor gets it back (GVAR(filterFocus), set by fnc_build), at the end of the text.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Where, [x, y, w, h] <ARRAY>
 * 2: Theme <HASHMAP>
 * 3: Placeholder shown while the field is empty - another window names what it searches <STRING>
 *    (default: "Search items", the inventory's)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.01, 0.2, 0.04], _theme] call einv_gui_fnc_drawFilter;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_rect", "_theme", ["_placeholderText", LLSTRING(Filter_Placeholder), [""]]];
_rect params ["_left", "_top", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _muted = _theme getOrDefault ["muted", [0.412, 0.443, 0.494, 1]];

[_display, controlNull, _rect, _theme getOrDefault ["button", [1, 1, 1, 0.06]], (_theme getOrDefault ["radius", 0]) min (_height / 2)] call FUNC(uiPanel);

private _iconH = _height * 0.5;
private _padX = SQUARE(_height * 0.3);

[_display, controlNull, [_left + _padX, _top + (_height - _iconH) / 2, SQUARE(_iconH), _iconH], UI_TEX(icon_search_ca), _muted] call FUNC(uiIcon);

private _textX = _left + _padX + SQUARE(_iconH) + SQUARE(_height * 0.2);
private _textW = _left + _width - _padX - _textX;
private _size = _height * 0.48;

private _placeholder = [_display, controlNull, [_textX, _top, _textW, _height], _placeholderText, _size, _muted, _font, 0] call FUNC(uiLabel);
_placeholder ctrlShow (GVAR(filter) isEqualTo "");

// A click anywhere on the box puts the cursor in the field.
private _hit = [_display, "EINV_Hitbox", controlNull, _rect] call FUNC(uiCreate);
_hit ctrlAddEventHandler ["ButtonClick", {ctrlSetFocus (uiNamespace getVariable [QGVAR(filterEdit), controlNull])}];

private _edit = [_display, "EINV_Edit", controlNull, [_textX, _top + (_height - _size * 1.4) / 2, _textW, _size * 1.4]] call FUNC(uiCreate);
_edit ctrlSetFont _font;
_edit ctrlSetFontHeight _size;
_edit ctrlSetTextColor (_theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]]);
_edit ctrlSetText GVAR(filter);
_edit ctrlSetTooltip LLSTRING(Filter_Tooltip);
_edit setVariable [QGVAR(placeholder), _placeholder];

_edit ctrlAddEventHandler ["EditChanged", {
    params ["_edit", "_text"];

    GVAR(filter) = trim _text;
    (_edit getVariable [QGVAR(placeholder), controlNull]) ctrlShow (_text isEqualTo "");
    call FUNC(applyFilter);
}];

// Somewhere for the cursor to go when typing is done (Return, or a click elsewhere): a button no one
// sees, which does nothing when pressed.
private _sink = [_display, "EINV_Hitbox", controlNull, [safezoneX, safezoneY, 0, 0]] call FUNC(uiCreate);

uiNamespace setVariable [QGVAR(filterEdit), _edit];
uiNamespace setVariable [QGVAR(filterSink), _sink];
uiNamespace setVariable [QGVAR(filterRect), _rect];

// Otherwise the cursor goes nowhere: a control that had it and was deleted with the rebuild would hand
// it on, perhaps to the field - and the keys would type into it.
if (GVAR(filterFocus)) then {
    ctrlSetFocus _edit;
    _edit ctrlSetTextSelection [count GVAR(filter), 0];
} else {
    ctrlSetFocus _sink;
};
