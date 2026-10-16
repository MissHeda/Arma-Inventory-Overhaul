#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Puts the bar on the screen: the titles display (RscTitles, on its own layer) with, in its group, a box,
 * a picture, a key, a count and a bar for each slot, and a line for messages above them. The picture has a
 * twin in a group that cuts it (EINV_HotbarClip), for an item drawn larger or moved by its rules (icon=). The
 * bar starts faded out; fnc_hudFrame fades it in.
 *
 * The colours are the player's own interface colours (Options > Game > Colors), read from the profile
 * here: the box's background, the text, the warning and the error colour. They are kept in
 * GVAR(hudColors); the controls in uiNamespace "einv_hotbar_hudCtrls" - the mission namespace is saved with
 * the game and cannot hold controls.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The display, displayNull when it could not be made <DISPLAY>
 *
 * Example:
 * call einv_hotbar_fnc_hudCreate;
 *
 * Public: No
 */

disableSerialization;

QGVAR(hud) cutRsc [QGVAR(RscHud), "PLAIN", -1, false];

private _display = uiNamespace getVariable [QGVAR(hud), displayNull];
private _group = _display displayCtrl HUD_GROUP_IDC;

if (isNull _display || {isNull _group}) exitWith {displayNull};

// The interface colours: red, green, blue and alpha in the profile, one variable each.
private _fnc_color = {
    params ["_name", "_default"];

    [0, 1, 2, 3] apply {
        profileNamespace getVariable [format ["IGUI_%1_RGB_%2", _name, ["R", "G", "B", "A"] select _x], _default select _x]
    }
};

GVAR(hudColors) = createHashMapFromArray [
    ["bcg", ["BCG", [0, 0, 0, 0.5]] call _fnc_color],
    ["text", ["TEXT", [1, 1, 1, 0.8]] call _fnc_color],
    ["warning", ["WARNING", [0.8, 0.5, 0, 0.8]] call _fnc_color],
    ["error", ["ERROR", [0.8, 0, 0, 0.8]] call _fnc_color]
];

private _text = GVAR(hudColors) get "text";
private _slotW = HUD_SLOT_W;
private _slotH = HUD_SLOT_H;
private _pad = 0.1 * GUI_GRID_H;
private _lineH = 0.9 * GUI_GRID_H;
private _slots = [];

for "_i" from 0 to (SLOT_COUNT - 1) do {
    private _x0 = _i * (_slotW + HUD_GAP_W);
    private _y0 = HUD_MESSAGE_H;

    private _box = _display ctrlCreate ["EINV_HotbarBox", -1, _group];
    _box ctrlSetPosition [_x0, _y0, _slotW, _slotH];
    _box ctrlSetBackgroundColor (GVAR(hudColors) get "bcg");
    _box ctrlCommit 0;

    // The picture leaves the key's line at the top and the bar's at the bottom free.
    private _pictureRect = [_x0 + _pad, _y0 + _lineH * 0.6, _slotW - _pad * 2, _slotH - _lineH * 0.6 - HUD_BAR_H - _pad];
    private _picture = _display ctrlCreate ["EINV_HotbarPicture", -1, _group];
    _picture ctrlSetPosition _pictureRect;
    _picture ctrlCommit 0;

    // The same picture again, for an item whose rules draw it larger, smaller or moved (icon=): in a group of
    // the picture's place, which cuts it. Made here, in this place in the order of drawing, so the key and
    // the count lie over it; hidden until fnc_hudDraw needs it.
    private _clip = _display ctrlCreate ["EINV_HotbarClip", -1, _group];
    _clip ctrlSetPosition _pictureRect;
    _clip ctrlShow false;
    _clip ctrlCommit 0;

    private _zoom = _display ctrlCreate ["EINV_HotbarPicture", -1, _clip];

    private _key = _display ctrlCreate ["EINV_HotbarKey", -1, _group];
    _key ctrlSetPosition [_x0 + _pad, _y0, _slotW - _pad * 2, _lineH];
    _key ctrlSetTextColor _text;
    _key ctrlCommit 0;

    private _count = _display ctrlCreate ["EINV_HotbarCount", -1, _group];
    _count ctrlSetPosition [_x0 + _pad, _y0 + _slotH - _lineH - HUD_BAR_H, _slotW - _pad * 2, _lineH];
    _count ctrlSetTextColor _text;
    _count ctrlCommit 0;

    private _bar = _display ctrlCreate ["EINV_HotbarBar", -1, _group];
    _bar ctrlSetPosition [_x0, _y0 + _slotH - HUD_BAR_H, _slotW, HUD_BAR_H];
    _bar ctrlSetTextColor _text;
    _bar progressSetPosition 0;
    _bar ctrlCommit 0;

    _slots pushBack createHashMapFromArray [
        ["box", _box], ["picture", _picture], ["clip", _clip], ["zoom", _zoom], ["pictureRect", _pictureRect], ["key", _key],
        ["count", _count], ["bar", _bar]
    ];
};

private _message = _display ctrlCreate ["EINV_HotbarMessage", -1, _group];
_message ctrlSetPosition [0, 0, HUD_W, HUD_MESSAGE_H];
_message ctrlCommit 0;

// Faded out until the first frame brings it in.
_group ctrlSetFade 1;
_group ctrlCommit 0;

uiNamespace setVariable [QGVAR(hudCtrls), createHashMapFromArray [["group", _group], ["slots", _slots], ["message", _message]]];

GVAR(hudVisible) = false;
GVAR(hudSignature) = "";
GVAR(nextCount) = 0;

_display
