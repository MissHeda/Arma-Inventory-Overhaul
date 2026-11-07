#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How large the design card is drawn (fnc_openSizeMenu, fnc_openPaletteMenu): with Arma's interface size (Options > Game > Layout,
 * getResolution's UI scale) - very small as ever, each step up larger (Mia, 0.6.96: "the text is still very small ... scale it
 * with what the player set as interface size") - but never past the screen. How far a card may grow is learnt the first time it
 * is drawn: every size on it grows alike, so its height and width at one scale tell the scale that just fits.
 *
 * Arguments:
 * 0: The card, "size" or "palette" <STRING>
 * 1: Its height as drawn, for the check (default: 0 - asks for the scale) <NUMBER>
 * 2: Its width as drawn (default: 0) <NUMBER>
 * 3: The scale it was drawn at (default: 1) <NUMBER>
 *
 * Return Value:
 * Without a height: the scale to draw at <NUMBER>
 * With one: it is too large for the screen and has to be made again at the scale learnt now <BOOL>
 *
 * Example:
 * ["size"] call aio_gui_fnc_cardScale;
 * ["size", _height, _width, _scale] call aio_gui_fnc_cardScale;
 *
 * Public: No
 */

params [["_card", "", [""]], ["_height", 0, [0]], ["_width", 0, [0]], ["_used", 1, [0]]];

private _key = format [QGVAR(cardFit_%1), _card];

// Interface size: very small 0.47, small 0.55, normal 0.7, large 0.85, very large 1.
private _wanted = 1 + (((getResolution select 5) - 0.47) max 0) * 1.05;

if (_height <= 0) exitWith {
    (_wanted min (uiNamespace getVariable [_key, 9])) max 1
};

// The room under the header the card stands in (its _top in fnc_openSizeMenu), and the screen's width.
private _top = (HEAD_Y + HEAD_H + UNIT * 0.5) max (safezoneY + UNIT * 2.6 + pixelH * 3);
private _roomH = safezoneY + safezoneH - _top - UNIT * 0.3;
private _roomW = safezoneW - UNIT;
private _fit = _used * ((_roomH / (_height max pixelH)) min (_roomW / (_width max pixelW)));

uiNamespace setVariable [_key, _fit];

// Made again once only per scale it learnt: the card's lines are rounded, a second try never shrinks it for good.
private _again = _used > ((_fit max 1) + 0.01) && {(uiNamespace getVariable [_key + "_tried", -1]) != _used};

uiNamespace setVariable [_key + "_tried", [-1, _used] select _again];

_again
