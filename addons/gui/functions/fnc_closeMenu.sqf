#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Closes the context menu (fnc_openMenu), the sound dropdown (fnc_openSoundMenu) or the palette popover
 * (fnc_openPaletteMenu), if one is open. Its layer goes with everything in it, and the
 * focus it took goes back to what had it before - or the search field's sink when that is gone - so a field
 * being typed in has the keys again. A palette popover that is only made again keeps the text of the field being typed in
 * (einv_gui_paletteTyping).
 *
 * The layer is hidden at once and deleted in the next frame (einv_gui_windowTrash, fnc_onFrame), as a kit
 * window is: a right press beside the card closes it from the layer's own mouse event, and a control must
 * not be deleted inside its own event.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A menu was open <BOOL>
 *
 * Example:
 * call einv_gui_fnc_closeMenu;
 *
 * Public: No
 */

disableSerialization;

private _controls = uiNamespace getVariable [QGVAR(menu), []];
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// The menu has the focus: its own button, or the row or hit area a click went to.
private _hadFocus = !isNull _display && {
    private _focused = focusedCtrl _display;

    !isNull _focused && {ctrlParentControlsGroup _focused in _controls}
};

// The palette popover being made again (einv_gui_menuRemake) while a number or the hex code is typed in one of its fields: the
// field and its text are kept for the new one (fnc_openPaletteMenu), whose cursor is in it again.
if (GVAR(menuRemake) && {_controls isNotEqualTo []} && {(GVAR(menuFor) param [0, ""]) isEqualTo "palette"} && {!isNull _display}) then {
    private _focused = focusedCtrl _display;
    private _fields = (uiNamespace getVariable [QGVAR(paletteRows), createHashMap]) getOrDefault ["fields", []];
    private _at = [-1, _fields find _focused] select !isNull _focused;

    uiNamespace setVariable [
        QGVAR(paletteTyping), [[], [uiNamespace getVariable [QGVAR(paletteTab), 0], _at, ctrlText _focused]] select (_at >= 0)
    ];
};

private _trash = uiNamespace getVariable [QGVAR(windowTrash), []];

{
    _x ctrlShow false;
    _trash pushBack _x;
} forEach _controls;

uiNamespace setVariable [QGVAR(windowTrash), _trash];
uiNamespace setVariable [QGVAR(menu), []];
uiNamespace setVariable [QGVAR(menuRect), []];
GVAR(menuState) = [];

if (_hadFocus) then {
    private _back = uiNamespace getVariable [QGVAR(menuFocusBack), controlNull];

    if (isNull _back) then {
        _back = uiNamespace getVariable [QGVAR(filterSink), controlNull];
    };

    if (!isNull _back) then {
        ctrlSetFocus _back;
    };
};

uiNamespace setVariable [QGVAR(menuFocusBack), controlNull];

// The sound dropdown under the speaker is a menu of this kind (fnc_openSoundMenu): what was set in it is written
// to the profile, and the speaker is drawn for the state it is in.
if (_controls isNotEqualTo [] && {(GVAR(menuFor) param [0, ""]) isEqualTo "sound"}) then {
    GVAR(menuFor) = [];

    [] call FUNC(soundSettle);
};

// So is the palette popover (fnc_openPaletteMenu): what was chosen is written to the profile. Not when it is only made
// again - over a build or on top of a redraw (einv_gui_menuRemake) - where it stays open and a slider held goes on.
if (_controls isNotEqualTo [] && {(GVAR(menuFor) param [0, ""]) isEqualTo "palette"}) then {
    GVAR(menuFor) = [];

    if (!GVAR(menuRemake)) then {
        [] call FUNC(paletteSettle);
    };
};

_controls isNotEqualTo []
