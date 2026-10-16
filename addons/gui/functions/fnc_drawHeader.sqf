#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the header along the top of the window, the same in every look but in its colours: the title
 * on the left; on the right the cog of the setup wizard, the search field, the speaker for the search
 * rustle, the camera switch (white like the rest, dimmed while off; left out where the setting is forced -
 * fnc_cameraForced) and Close, each on a piece of the window's glass. A line under it, the width of the content.
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
    [_left + SQUARE(_iconH * 1.4), HEAD_Y, SQUARE(UNIT * 10), HEAD_H],
    [LLSTRING(Title), _theme] call FUNC(caption),
    UNIT * 0.95,
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

// The hit area is the last of a button's controls (fnc_uiButton). Tooltips are plain text.
private _fnc_tooltip = {
    params ["_controls", "_text"];

    if (_controls isNotEqualTo []) then {
        (_controls select (count _controls - 1)) ctrlSetTooltip _text;
    };
};

private _square = SQUARE(HEAD_H);

private _close = [_display, controlNull, [_square] call _fnc_place, "close", "", UI_TEX(icon_close_ca), _theme, {
    ["the close button"] call FUNC(closeDisplay);
}] call FUNC(uiButton);
[_close, LLSTRING(Close)] call _fnc_tooltip;

// The camera switch, white like the other icons of the header. Its state shows in the icon's strength: the
// button's ink, dimmed while the camera is off. Not drawn at all where a server or a mission forces the
// setting (fnc_cameraForced): the player has no choice to make then.
if !(call FUNC(cameraForced)) then {
    private _cameraTheme = createHashMap;
    _cameraTheme merge _theme;

    if (!GVAR(cameraOn)) then {
        private _ink = +(_theme getOrDefault ["buttonText", [0.88, 0.88, 0.88, 1]]);

        _ink set [3, (_ink param [3, 1]) * 0.45];
        _cameraTheme set ["buttonText", _ink];
    };

    private _camera = [_display, controlNull, [_square] call _fnc_place, "camera", "", UI_TEX(icon_camera_ca), _cameraTheme, {
        call FUNC(toggleCamera);
    }] call FUNC(uiButton);
    [_camera, LLSTRING(Camera_Tooltip)] call _fnc_tooltip;
};

// The speaker: the rustle while searching, on or muted (fnc_toggleSearchSound).
private _sound = [
    _display, controlNull, [_square] call _fnc_place, "searchSound", "",
    [UI_TEX(icon_sound_on_ca), UI_TEX(icon_sound_off_ca)] select GVAR(searchMuted), _theme, {call FUNC(toggleSearchSound)}
] call FUNC(uiButton);
[_sound, [LLSTRING(SearchSound_Mute), LLSTRING(SearchSound_Unmute)] select GVAR(searchMuted)] call _fnc_tooltip;

// The search field (fnc_drawFilter).
[_display, [SQUARE(UNIT * 11)] call _fnc_place, _theme] call FUNC(drawFilter);

// The cog: the setup wizard (einv_setup) - how big items are, how many share a tile, how containers are
// split, the same for everyone. Drawn only for whoever may open it (einv_setup_fnc_canOpen, the setting
// "Who may open the setup"); whoever may not change the server's setup sees it read-only and can still copy
// it to share. This window closes for it and comes back when the wizard closes
// (einv_setup_fnc_openFromGame).
if (!isNil QEFUNC(setup,openFromGame) && {["direct"] call (missionNamespace getVariable [QEFUNC(setup,canOpen), {true}])}) then {
    private _target = ["direct"] call (missionNamespace getVariable [QEFUNC(setup,canEdit), {createHashMap}]);
    private _canSave = !isNil "_target" && {_target isEqualType createHashMap} && {_target getOrDefault ["canSave", false]};

    private _setup = [_display, controlNull, [_square] call _fnc_place, "setup", "", UI_TEX(icon_setup_ca), _theme, {
        [0, ""] call EFUNC(setup,openFromGame);
    }] call FUNC(uiButton);
    [_setup, [LELSTRING(setup,OpenWizard_ReadOnly), LELSTRING(setup,OpenWizard)] select _canSave] call _fnc_tooltip;
};

// ----- Under the header -----

[_display, controlNull, [_left, safezoneY + UNIT * 2.6, CONTENT_W, pixelH], _theme get "line"] call FUNC(uiPanel);
