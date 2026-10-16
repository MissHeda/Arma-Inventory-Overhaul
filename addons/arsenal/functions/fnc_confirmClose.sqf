#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal's window is to close (its Close button, Escape): if the unit it edits carries something that
 * lies on no cell of its uniform, vest or backpack - the red tiles of the panel - a card in the middle of
 * the window asks first, in the inventory's glass look: "N items do not fit your gear and will be removed:
 * <names, counts>", with "Keep editing" and "Remove and close" (fnc_answerConfirm). A glass over the window
 * keeps the mouse from ACE's controls under it; keys are held by fnc_onAceKey. While the window is open
 * those tiles stay what they are, red and shown apart. With nothing to remove, or a unit that is not local
 * here, the window closes at once, as it always did.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: The exit code the window closes with: 1 from the button, 2 from Escape <NUMBER> (default: 1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [findDisplay 1127001, 2] call einv_arsenal_fnc_confirmClose;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_code", 1, [0]]];

if (isNull _display) exitWith {};

// Asked already: a second click on the button, a key.
if !(isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {};

private _center = missionNamespace getVariable [QACEGVAR(arsenal,center), objNull];
private _found = [];

if (GVAR(ready) && {!is3DEN} && {!isNull _center} && {local _center}) then {
    _found = [_center] call FUNC(findOverflow);
};

if (_found isEqualTo []) exitWith {
    _display closeDisplay _code;
};

// How many, and of what: the same class counted together, the most first, a few named and the rest as a number.
private _total = 0;
private _byClass = createHashMap;

{
    private _entry = _x select 1;
    private _count = _entry getOrDefault ["count", 1];

    _total = _total + _count;
    _byClass set [_entry getOrDefault ["class", ""], (_byClass getOrDefault [_entry getOrDefault ["class", ""], 0]) + _count];
} forEach _found;

private _names = [];

{
    _names pushBack [_y, ([_x] call EFUNC(items,getInfo)) get "name"];
} forEach _byClass;

_names sort false;

private _listed = (_names select [0, 6]) apply {
    private _name = _x select 1;
    [_name, format ["%1 x%2", _name, _x select 0]] select ((_x select 0) > 1)
};

if (count _names > 6) then {
    _listed pushBack format ["+%1", count _names - 6];
};

private _text = if (_total == 1) then {
    format [LLSTRING(Confirm_TextOne), _listed joinString ", "]
} else {
    format [LLSTRING(Confirm_Text), _total, _listed joinString ", "]
};

uiNamespace setVariable [QGVAR(confirmCode), _code];

private _theme = call EFUNC(gui,theme);
private _font = _theme getOrDefault ["font", "RobotoCondensed"];
private _fontBold = _theme getOrDefault ["fontBold", "RobotoCondensedBold"];
private _loss = _theme getOrDefault ["loss", [0.941, 0.333, 0.353, 1]];
private _ink = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _radius = _theme getOrDefault ["radius", UNIT * 0.45];

// The colour as structured text wants it.
private _hex = "#" + ((_ink select [0, 3]) apply {
    private _value = round ((_x max 0 min 1) * 255);

    ("0123456789ABCDEF" select [floor (_value / 16), 1]) + ("0123456789ABCDEF" select [_value mod 16, 1])
} joinString "");

private _words = text _text setAttributes ["align", "center", "valign", "top", "font", _font, "color", _hex];

// The card is as high as its words: measured in a box of its width before anything is made.
private _cardW = SQUARE(UNIT * 24);
private _pad = SQUARE(UNIT * 1.2);
private _innerW = _cardW - _pad * 2;
private _probe = _display ctrlCreate ["EINV_StructuredText", -1];

_probe ctrlSetPosition [safezoneX, safezoneY, _innerW, UNIT * 20];
_probe ctrlCommit 0;
_probe ctrlSetStructuredText _words;

private _textH = ceil ((ctrlTextHeight _probe) / pixelH) * pixelH;

ctrlDelete _probe;

private _buttonH = UNIT * 1.5;
private _cardH = UNIT * 1 + UNIT * 1.8 + _textH + UNIT * 1.2 + _buttonH + UNIT * 1;
private _cardX = (safezoneW - _cardW) / 2;
private _cardY = (safezoneH - _cardH) / 2;

// The whole screen, in one group; what is in it counts from its corner. Made with ctrlCreate and held in
// uiNamespace, so the window engine, which sweeps only what it made, leaves it alone.
private _group = _display ctrlCreate ["EINV_Group", -1];

_group ctrlSetPosition [safezoneX, safezoneY, safezoneW, safezoneH];
_group ctrlCommit 0;

uiNamespace setVariable [QGVAR(confirm), _group];

[_display, _group, [0, 0, safezoneW, safezoneH], [0.04, 0.045, 0.055, 0.55]] call EFUNC(gui,uiPanel);

// Over the dimming, under the card: takes every click that is not on the card.
private _glass = _display ctrlCreate ["EINV_Hitbox", -1, _group];

_glass ctrlSetPosition [0, 0, safezoneW, safezoneH];
_glass ctrlCommit 0;

[_display, _group, [_cardX, _cardY, _cardW, _cardH], _theme getOrDefault ["panel", [0.04, 0.045, 0.055, 0.85]], _radius] call EFUNC(gui,uiPanel);
[_display, _group, [_cardX, _cardY, _cardW, _cardH], _loss, _radius] call EFUNC(gui,uiRing);

private _y = _cardY + UNIT * 1;
private _titleSize = UNIT * 1.0;

[
    _display, _group, [_cardX + _pad, _y, _innerW, UNIT * 1.4],
    [LLSTRING(Confirm_Title), _innerW, _fontBold, _titleSize] call EFUNC(gui,fitText), _titleSize, _ink, _fontBold, 2
] call EFUNC(gui,uiLabel);

_y = _y + UNIT * 1.8;

private _box = [_display, "EINV_StructuredText", _group, [_cardX + _pad, _y, _innerW, _textH]] call EFUNC(gui,uiCreate);

_box ctrlSetStructuredText _words;

_y = _y + _textH + UNIT * 1.2;

// Keep editing on the left, what removes in the loss colour on the right.
private _removeTheme = createHashMap;

_removeTheme merge _theme;
_removeTheme set ["buttonText", _loss];

private _buttonW = SQUARE(UNIT * 9);
private _gap = SQUARE(UNIT * 0.5);
private _left = _cardX + (_cardW - _buttonW * 2 - _gap) / 2;

[_display, _group, [_left, _y, _buttonW, _buttonH], "keep", LLSTRING(Confirm_Keep), "", _theme, {
    [] call FUNC(closeConfirm);
}, false, -1, true] call EFUNC(gui,uiButton);

[_display, _group, [_left + _buttonW + _gap, _y, _buttonW, _buttonH], "remove", LLSTRING(Confirm_Remove), "", _removeTheme, {
    [] call FUNC(answerConfirm);
}, false, -1, true] call EFUNC(gui,uiButton);

// The keys are held by fnc_onAceKey; the focus leaves ACE's lists and fields.
ctrlSetFocus _glass;
