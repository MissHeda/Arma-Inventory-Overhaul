#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the footer along the bottom of the window, the same in every look but in its colours: the
 * keys that close the window on the left, the hint in the middle ((uiNamespace getVariable [QGVAR(hint), controlNull]), written by
 * fnc_updateHover), the version on the right. All of it on a strip of the window's glass, the width of
 * the content. The key hints name G to drop, the selection on Ctrl+click and the menu on the right mouse button - in the order Esc, quick move
 * (its key, F by default, or the double click while it has none), drop, hotbar, select, menu; the mouse buttons are ACE's pictures,
 * not words (fnc_uiKeyHint). The hotbar adds
 * its own keys at the end (einv_hotbar_fnc_footerHint - only when that addon is loaded, and only in the
 * inventory). A window that attached names its own keys (the "footerKeys"
 * hook, [[key, text], ...]).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_gui_fnc_drawFooter;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_theme"];

private _keyH = UNIT * 0.9;

// The footer lies on the world, not on a pane: grey words straight on it vanish over a bright sky or a
// white wall, whatever their grey. The window's glass under it keeps them readable over anything, and
// what is on it keeps as far from its ends as from its top and bottom.
[_display, controlNull, [CONTENT_X, FOOT_Y, CONTENT_W, FOOT_H], _theme getOrDefault ["panel", []], (_theme getOrDefault ["radius", 0]) min (FOOT_H / 2)] call FUNC(uiPanel);

private _pad = SQUARE((FOOT_H - _keyH) / 2);
private _left = CONTENT_X + _pad;
private _width = CONTENT_W - _pad * 2;

// ----- Key hints -----

private _keyX = _left;

// The keys: the inventory's own, unless the window that attached names its own ("footerKeys").
// The mouse buttons are ACE's pictures (fnc_uiKeyHint: "@right", "Ctrl+@left"), a modifier a key cap before them.
// The quick move is the player's key (fnc_quickKeyName), the double click while it has none.
private _quickKey = call FUNC(quickKeyName);

// The drop is the player's key too (fnc_dropKeyName); with none set there is no hint, the menu's Drop row is left.
private _dropKey = call FUNC(dropKeyName);

// Their order: Esc, the quick move, drop, the hotbar's range, select, the menu. Selecting is the inventory's only:
// where another window attaches (the Arsenal) Ctrl+click still moves a tile over (fnc_onMouseButton).
private _inventory = call FUNC(isInventoryMode);

private _keys = if (_inventory) then {
    [
        [LLSTRING(Key_Escape), LLSTRING(Close)],
        [[_quickKey, "@double"] select (_quickKey isEqualTo ""), LLSTRING(QuickMove)],
        [_dropKey, LLSTRING(Drop)],
        (if (!isNil QEFUNC(hotbar,footerHint)) then {call EFUNC(hotbar,footerHint)} else {["", ""]}),
        ["Ctrl+@left", LLSTRING(Select)],
        ["@right", LLSTRING(Menu)]
    ]
} else {
    [
        [LLSTRING(Key_Escape), LLSTRING(Close)],
        ["Ctrl+@left", LLSTRING(QuickMove)],
        [_dropKey, LLSTRING(Drop)],
        ["@right", LLSTRING(Menu)]
    ]
};

private _ownKeys = ["footerKeys", [], []] call FUNC(hook);

if (_ownKeys isEqualType [] && {_ownKeys isNotEqualTo []}) then {
    _keys = _ownKeys;
};

{
    _x params ["_key", "_text"];

    if (_key isEqualTo "") then {continue};

    private _taken = [_display, controlNull, [_keyX, FOOT_Y + (FOOT_H - _keyH) / 2], _key, _text, _theme, _keyH] call FUNC(uiKeyHint);

    if (isNil "_taken") then {
        _taken = 0;
    };

    _keyX = _keyX + _taken;
} forEach _keys;

// ----- Version -----

private _versionW = SQUARE(UNIT * 4);

[
    _display,
    controlNull,
    [_left + _width - _versionW, FOOT_Y, _versionW, FOOT_H],
    format ["v%1", getText (configFile >> "CfgPatches" >> "einv_main" >> "versionStr")],
    UNIT * 0.62,
    _theme get "muted",
    _theme get "font",
    1
] call FUNC(uiLabel);

// ----- The hint -----

// Centred on the screen, with as much room on both sides as the wider of the two ends takes. In the key
// hints' size, on their line: structured text starts at the top of its box, so the box starts half a
// line above the footer's middle, where their words are centred.
private _side = ((_keyX - _left) max _versionW) + SQUARE(UNIT * 0.5);
private _hintSize = UNIT * 0.558;

uiNamespace setVariable [QGVAR(hint), [_display, "EINV_FooterHint", controlNull, [_left + _side, FOOT_Y + (FOOT_H - _hintSize) / 2 - pixelH, _width - _side * 2, _hintSize * 1.4]] call FUNC(uiCreate)];
