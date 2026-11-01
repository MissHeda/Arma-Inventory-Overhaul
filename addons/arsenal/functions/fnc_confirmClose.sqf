#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * ACE Arsenal's window is to close (its Close button, Escape): if the unit it edits carries something that
 * lies on no cell of its uniform, vest or backpack - the red tiles of the panel - a card in the middle of
 * the window asks first, in the inventory's glass look: "N items do not fit your gear and will be removed:
 * <names, counts>", with "Keep editing" and "Remove and close" (fnc_answerConfirm). A dimming over the window
 * keeps the mouse from ACE's controls under it - a plain rectangle, not a button (that played its click sound
 * for every press); the clicks on the answers are taken by the display's handler (fnc_onConfirmMouse), the
 * wheel is absorbed (fnc_onOpened); keys are held by fnc_onAceKey. All of it is made straight on the
 * display, in no controls group - a group moved the card with the wheel. The card can be dragged by its
 * title strip (aio_gui_fnc_dragHandle, begun by fnc_onConfirmMouse on the press): all its controls are moved
 * one by one, the dimming staying; they are kept in a list for that and the strip's film. While the window
 * is open those tiles stay what they are, red and shown apart. With nothing to remove, or a unit that is not local
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
 * [findDisplay 1127001, 2] call aio_arsenal_fnc_confirmClose;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_code", 1, [0]]];

if (isNull _display) exitWith {};

// Asked already: a second click on the button, a key.
if !(isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {};

private _center = (call FUNC(center));
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
private _ink = _theme getOrDefault ["text", [1, 1, 1, 1]];
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
private _probe = _display ctrlCreate ["AIO_StructuredText", -1];

_probe ctrlSetPosition [safezoneX, safezoneY, _innerW, UNIT * 20];
_probe ctrlCommit 0;
_probe ctrlSetStructuredText _words;

private _textH = ceil ((ctrlTextHeight _probe) / pixelH) * pixelH;

ctrlDelete _probe;

private _buttonH = UNIT * 1.5;
private _cardH = UNIT * 1 + UNIT * 1.8 + _textH + UNIT * 1.2 + _buttonH + UNIT * 1;
private _cardX = (safezoneW - _cardW) / 2;
private _cardY = safezoneY + (safezoneH - _cardH) / 2;

_cardX = safezoneX + _cardX;

// Everything straight on the display, in no controls group: a group, even one that never scrolls, moves its
// content a little with the wheel when the content is a pixel larger than it. What is made here is found
// again by comparing the display's controls before and after, and taken out of the window engine's list of
// what it made (uiCreate notes every control of the display there), so that its sweep leaves it alone.
private _before = allControls _display;

// Dims the window and takes every click that is not on the card: a rectangle, which has no click sound (a
// button there played its sound for every press, and focused it lay over the answers).
private _dim = [_display, controlNull, [safezoneX, safezoneY, safezoneW, safezoneH], [0, 0, 0, 0.55]] call EFUNC(gui,uiPanel);

uiNamespace setVariable [QGVAR(confirm), _dim select 0];

[_display, controlNull, [_cardX, _cardY, _cardW, _cardH], _theme getOrDefault ["panel", [0.05, 0.05, 0.05, 0.92]], _radius] call EFUNC(gui,uiPanel);
[_display, controlNull, [_cardX, _cardY, _cardW, _cardH], _loss, _radius] call EFUNC(gui,uiRing);

// The strip to move the card by - the top, down to under the title - with a clear film that only takes the press
// (fnc_onConfirmMouse), never lit on hover; under the title, over the card.
private _inset = _radius max (UNIT * 0.15);
private _film = [
    _display, "AIO_PanelRect", controlNull, [_cardX + _inset, _cardY + _inset, _cardW - _inset * 2, UNIT * 2.6 - _inset]
] call EFUNC(gui,uiCreate);

_film ctrlSetBackgroundColor [1, 1, 1, 0];

private _y = _cardY + UNIT * 1;
private _titleSize = UNIT * 1.0;

[
    _display, controlNull, [_cardX + _pad, _y, _innerW, UNIT * 1.4],
    [LLSTRING(Confirm_Title), _innerW, _fontBold, _titleSize] call EFUNC(gui,fitText), _titleSize, _ink, _fontBold, 2
] call EFUNC(gui,uiLabel);

_y = _y + UNIT * 1.8;

private _box = [_display, "AIO_StructuredText", controlNull, [_cardX + _pad, _y, _innerW, _textH]] call EFUNC(gui,uiCreate);

_box ctrlSetStructuredText _words;

_y = _y + _textH + UNIT * 1.2;

// Keep editing on the left, what removes in the loss colour on the right.
private _removeTheme = createHashMap;

_removeTheme merge _theme;
_removeTheme set ["buttonText", _loss];

private _buttonW = SQUARE(UNIT * 9);
private _gap = SQUARE(UNIT * 0.5);
private _left = _cardX + (_cardW - _buttonW * 2 - _gap) / 2;

private _keep = [_display, controlNull, [_left, _y, _buttonW, _buttonH], "keep", LLSTRING(Confirm_Keep), "", _theme, {}, false, -1, true] call EFUNC(gui,uiButton);

private _remove = [_display, controlNull, [_left + _buttonW + _gap, _y, _buttonW, _buttonH], "remove", LLSTRING(Confirm_Remove), "", _removeTheme, {}, false, -1, true] call EFUNC(gui,uiButton);

// The buttons' own code is empty: their clicks are taken by the display's handler (fnc_onConfirmMouse), so a
// click cannot answer twice. The hit areas come last; fnc_hoverConfirm lights them up from the mouse every
// frame as well.
uiNamespace setVariable [QGVAR(confirmButtons), [_keep deleteAt (count _keep - 1), _remove deleteAt (count _remove - 1)]];
GVAR(confirmPress) = -1;

private _mine = allControls _display - _before;
private _created = uiNamespace getVariable [QEGVAR(gui,created), []];

{
    private _at = _created find _x;

    if (_at >= 0) then {
        _created deleteAt _at;
    };
} forEach _mine;

uiNamespace setVariable [QGVAR(confirmControls), _mine];

// What the card is moved by: everything but the dimming, which covers the window and stays.
uiNamespace setVariable [QGVAR(confirmMoved), _mine - _dim];
uiNamespace setVariable [QGVAR(confirmBar), [_film, _inset]];

// The keys are held by fnc_onAceKey; the focus leaves ACE's lists and fields for the control of no size that
// covers nothing (fnc_layout). Not for a control of the card: the engine draws the focused control over every
// other and gives it the mouse first - the focused glass lay over both answers and took their clicks.
private _sink = uiNamespace getVariable [QGVAR(focusSink), controlNull];

if (isNull _sink) then {
    _sink = _display ctrlCreate ["AIO_Hitbox", -1];
    _sink ctrlSetPosition [safezoneX, safezoneY, 0, 0];
    _sink ctrlCommit 0;

    uiNamespace setVariable [QGVAR(focusSink), _sink];
};

ctrlSetFocus _sink;
