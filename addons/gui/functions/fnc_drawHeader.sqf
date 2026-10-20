#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the header along the top of the window, the same in every look but in its colours: the title
 * on the left; on the right the cog of the setup wizard, the search field (on the buttons' own surface), the speaker (it opens the dropdown
 * of the sound volumes, fnc_openSoundMenu; a right click mutes everything or brings it back), the camera
 * switch (left out where the setting is forced - fnc_cameraForced) and Close, each on a piece of the
 * window's glass. The buttons and the search field's frame are dark, the column panels' colour one step lighter
 * (fnc_headerStyle), one step lighter again under the mouse. A button that is on - the camera, the speaker while
 * its dropdown is open - shows it by an accent-tinted icon and a thin accent line under it, not by a fill; an
 * icon that is off is dimmed. All of them are squares of the header's height with the same gap. A line under the
 * header, the width of the content. The title's words grow with the tile scale (TEXT_UNIT, fnc_textScale); the
 * buttons are icons on the header's fixed height and stay as they are.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _theme] call einv_gui_fnc_drawHeader;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_theme"];

private _left = CONTENT_X;
private _gap = SQUARE(UNIT * 0.3);

// ----- Title -----

private _iconH = UNIT * 1.1;

[_display, controlNull, [_left, HEAD_Y + (HEAD_H - _iconH) / 2, SQUARE(_iconH), _iconH], UI_TEX(icon_inventory_ca), _theme get "accent"] call FUNC(uiIcon);

[
    _display,
    controlNull,
    [_left + SQUARE(_iconH * 1.4), HEAD_Y, SQUARE(TEXT_UNIT * 10), HEAD_H],
    [LLSTRING(Title), _theme] call FUNC(caption),
    TEXT_UNIT * 0.95,
    _theme get "text",
    _theme get "fontBold",
    0
] call FUNC(uiLabel);

// ----- Buttons, from the right edge inwards -----

// Room for the icon, the gaps and the label the way fnc_uiButton lays them out, and some slack on the
// label: names fitted to their exact width were still cut off in the phase 1 test.
private _fnc_buttonW = {
    params ["_text"];

    private _caption = [_text, _theme] call FUNC(caption);

    SQUARE(HEAD_H * 1.4) + (_caption getTextWidth [_theme get "font", HEAD_H * 0.48]) * 1.15
};

private _nextRight = CONTENT_X + CONTENT_W;

// The header lies on the world, not on a pane: a light film with grey words on it vanishes over a
// bright sky. So each place gets the window's glass first, in the same shape as the film that goes on
// it. The title, in the brightest text, stands on its own.
private _fnc_place = {
    params ["_width"];

    private _rect = [_nextRight - _width, HEAD_Y, _width, HEAD_H];
    _nextRight = _nextRight - _width - _gap;

    [_display, controlNull, _rect, _theme getOrDefault ["panel", []], (_theme getOrDefault ["radius", 0]) min (HEAD_H / 2)] call FUNC(uiPanel);

    _rect
};

// The theme a header button is drawn with: the lit surface of fnc_headerStyle in place of the theme's button
// colours, which are made for the columns. Dimmed: the icon at less than half its strength.
private _fnc_buttonTheme = {
    params [["_on", false], ["_dim", false]];

    ([_theme, _on] call FUNC(headerStyle)) params ["_fill", "_hover", "_ink"];

    if (_dim) then {
        _ink = +_ink;
        _ink set [3, (_ink param [3, 1]) * 0.45];
    };

    private _buttonTheme = createHashMap;
    _buttonTheme merge _theme;
    _buttonTheme set ["button", _fill];
    _buttonTheme set ["buttonHover", _hover];
    _buttonTheme set ["buttonText", _ink];

    _buttonTheme
};

// The hit area is the last of a button's controls (fnc_uiButton). Tooltips are plain text.
private _fnc_tooltip = {
    params ["_controls", "_text"];

    if (_controls isNotEqualTo []) then {
        (_controls select -1) ctrlSetTooltip _text;
    };
};

private _square = SQUARE(HEAD_H);

// The thin accent line under a button that is on, inside the bottom of its square and in from the round corners.
// Made before the button, so its hit area lies over it.
private _fnc_underline = {
    params ["_rect", "_shown"];

    private _inset = (_theme getOrDefault ["radius", 0]) max ((_rect select 3) * 0.2);
    private _line = [
        _display, controlNull, [(_rect select 0) + SQUARE(_inset), (_rect select 1) + (_rect select 3) - pixelH * 4, (_rect select 2) - SQUARE(_inset) * 2, pixelH * 2],
        _theme getOrDefault ["accent", [0.84, 0.54, 0.1, 1]]
    ] call FUNC(uiPanel);

    {_x ctrlShow _shown} forEach _line;

    _line
};

private _closeRect = [_square] call _fnc_place;

private _close = [_display, controlNull, _closeRect, "close", "", UI_TEX(icon_close_ca), [] call _fnc_buttonTheme, {
    ["the close button"] call FUNC(closeDisplay);
}] call FUNC(uiButton);
[_close, LLSTRING(Close)] call _fnc_tooltip;

// The camera switch. Its state shows in the button: an accent icon and line while the camera is on, a dimmed icon
// while it is off. Not drawn at all where a server or a mission forces the setting
// (fnc_cameraForced): the player has no choice to make then.
if !(call FUNC(cameraForced)) then {
    private _cameraRect = [_square] call _fnc_place;

    if (GVAR(cameraOn)) then {
        [_cameraRect, true] call _fnc_underline;
    };

    private _camera = [
        _display, controlNull, _cameraRect, "camera", "", UI_TEX(icon_camera_ca),
        [GVAR(cameraOn), !GVAR(cameraOn)] call _fnc_buttonTheme, {[] call FUNC(toggleCamera)}
    ] call FUNC(uiButton);
    [_camera, LLSTRING(Camera_Tooltip)] call _fnc_tooltip;
};

// The speaker: a click opens the dropdown of the sound volumes under it (fnc_openSoundMenu), a right click
// mutes everything or brings it all back (fnc_soundSet). It shows the muted speaker, dimmed, while nothing
// is audible, and an accent icon and line while its dropdown is open (fnc_updateSoundButton, which keeps it up to
// date without a rebuild - the controls and the place under which the dropdown opens are kept for it).
private _silent = [""] call FUNC(soundMuted);
private _soundRect = [_square] call _fnc_place;
private _soundLine = [_soundRect, false] call _fnc_underline;

private _sound = [
    _display, controlNull, _soundRect, "sound", "", [UI_TEX(icon_sound_on_ca), UI_TEX(icon_sound_off_ca)] select _silent,
    [false, _silent] call _fnc_buttonTheme, {
        if ((_this select 0) < 0) then {
            ["all"] call FUNC(soundSet);
        } else {
            // Once per rest for a run of clicks (fnc_coalesce).
            ["soundmenu", {[uiNamespace getVariable [QGVAR(display), displayNull]] call FUNC(openSoundMenu)}, [], COALESCE_GAP] call FUNC(coalesce);
        };
    }
] call FUNC(uiButton);
[_sound, LLSTRING(Sound_Tooltip)] call _fnc_tooltip;

uiNamespace setVariable [QGVAR(soundButton), _sound];
uiNamespace setVariable [QGVAR(soundLine), _soundLine];
uiNamespace setVariable [QGVAR(soundAnchor), _soundRect];

// The search field (fnc_drawFilter): on the window's glass that _fnc_place laid under it, with the one film of the buttons' surface over
// it - not two (a film of its own under the field's made it lighter than the buttons beside it, Mia 0.5.7).
private _searchRect = [SQUARE(UNIT * 11)] call _fnc_place;

([_theme, false] call FUNC(headerStyle)) params ["_searchFill"];

[_display, _searchRect, _theme, LLSTRING(Filter_Placeholder), _searchFill] call FUNC(drawFilter);

// The cog: the setup wizard (einv_setup) - how big items are, how many share a tile, how containers are
// split, the same for everyone. Drawn only for whoever may open it (einv_setup_fnc_canOpen: who runs the
// server or is logged in as admin), asked at every draw so a login shows at once. This window closes for it
// and comes back when the wizard closes (einv_setup_fnc_openFromGame).
if (!isNil QEFUNC(setup,openFromGame) && {call (missionNamespace getVariable [QEFUNC(setup,canOpen), {false}])}) then {
    private _target = ["direct"] call (missionNamespace getVariable [QEFUNC(setup,canEdit), {createHashMap}]);
    private _canSave = !isNil "_target" && {_target isEqualType createHashMap} && {_target getOrDefault ["canSave", false]};

    private _setup = [_display, controlNull, [_square] call _fnc_place, "setup", "", UI_TEX(icon_setup_ca), [] call _fnc_buttonTheme, {
        [0, ""] call EFUNC(setup,openFromGame);
    }] call FUNC(uiButton);
    [_setup, [LELSTRING(setup,OpenWizard_ReadOnly), LELSTRING(setup,OpenWizard)] select _canSave] call _fnc_tooltip;
};

// ----- Under the header -----

[_display, controlNull, [_left, safezoneY + UNIT * 2.6, CONTENT_W, pixelH], _theme get "line"] call FUNC(uiPanel);
