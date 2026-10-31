#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The width a button needs for what it holds, laid out the centred way (fnc_uiButton with "centred"): the
 * room at either side, the icon and the gap after it where there is one, and the label with TEXT_SLACK
 * over its measured width - the engine draws wider than getTextWidth says, and the label is centred in
 * that room, so it stands in the middle of the button whatever it really measures. The callers pass the height and
 * text size they draw with - on the window both grow with the tile scale (TEXT_UNIT, fnc_textScale) - so a larger
 * label gets a wider button.
 *
 * Arguments:
 * 0: Label, "" for none <STRING>
 * 1: Icon texture, "" for none <STRING>
 * 2: Height of the button <NUMBER>
 * 3: Text height - the label's size <NUMBER>
 * 4: Theme <HASHMAP>
 *
 * Return Value:
 * Width, in screen units <NUMBER>
 *
 * Example:
 * ["Sort", "", 0.017, 0.0125, _theme] call aio_gui_fnc_buttonWidth;
 *
 * Public: No
 */

params ["_text", "_icon", "_height", "_size", "_theme"];

private _caption = [_text, _theme] call FUNC(caption);
private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _hasIcon = _icon isNotEqualTo "";
private _hasText = _caption isNotEqualTo "";

private _iconW = [0, SQUARE(_height * BUTTON_ICON)] select _hasIcon;
private _gap = [0, SQUARE(_height * BUTTON_GAP)] select (_hasIcon && {_hasText});
private _textW = [0, (_caption getTextWidth [_font, _size]) * TEXT_SLACK] select _hasText;

SQUARE(_height * BUTTON_PAD) * 2 + _iconW + _gap + _textW
