#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the name at the mouse - or the comparison card that stands in for it - again, so that it is the
 * last control made on the display and lies over everything else there. The engine draws what is made
 * later over what was made before and has no other order (a focused control would be drawn over the lot,
 * but the focus is the menu's and is sent back to the search field's sink on purpose, fnc_onFrame). The
 * name is made once per build (fnc_drawTopLayer), so an outline made after it on the display itself - the
 * ring round the slot the mouse is on, selection frames of a grid that is not in a group - lay over it, as
 * the frame of the backpack's slot over the very name of the backpack (a tester's screenshot, 0.4.7).
 *
 * Asked after such an outline was made (fnc_updateHover, fnc_drawSelection). It acts only when the name
 * or the card shows and nothing is dragged - with a menu or the colour popover open too, where the tip of
 * its buttons shows (an item's name does not), or it lay behind the popover, and only when something made after it is still there. The name keeps its text, place
 * and size; the card is drawn again from the rows it was made from (fnc_drawCompare). Controls in a group -
 * the tiles' hover, selection and flash - lie under it anyway: their group was made before it.
 *
 * A popup - a context menu, the part tiles of the modding view, the colour, size and sound popovers - holds the focus to lie over
 * the columns, and the engine draws the focused control's group after everything else, whenever anything was made: the name
 * made after it on the display still lay under it (Mia, #56: "WHY is the hint behind?"). So while a popup is open the name is
 * made in the popup's own layer, as its last control, and back on the display once the popup is gone - its home is always the
 * layer that is drawn last. Asked with force (fnc_closeMenu), it moves home even while it does not show.
 *
 * Arguments:
 * 0: Move it home even while it does not show <BOOL> (default: false)
 *
 * Return Value:
 * Made again <BOOL>
 *
 * Example:
 * [] call aio_gui_fnc_raiseTooltip;
 *
 * Public: No
 */

disableSerialization;

params [["_force", false, [false]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {false};

// ----- The name in the layer drawn last: an open popup's, else the display -----
private _name = uiNamespace getVariable [QGVAR(tooltip), controlNull];
private _home = (uiNamespace getVariable [QGVAR(menu), []]) param [0, controlNull];

if (!isNull _name && {ctrlParentControlsGroup _name isNotEqualTo _home} && {_force || {ctrlShown _name}}) exitWith {
    // Where it stands on the screen, into the new home's space.
    private _oldHome = ctrlParentControlsGroup _name;
    (ctrlPosition _name) params ["_relX", "_relY", "_width", "_height"];
    (if (isNull _oldHome) then {[0, 0]} else {ctrlPosition _oldHome}) params ["_oldX", "_oldY"];
    (if (isNull _home) then {[0, 0]} else {ctrlPosition _home}) params ["_homeX", "_homeY"];

    private _shown = ctrlShown _name && {!_force || {isNull _home}};
    private _text = _name getVariable [QGVAR(tipText), ""];
    private _tipW = _name getVariable [QGVAR(width), 0];
    private _tipH = _name getVariable [QGVAR(height), UNIT * 0.85];
    private _new = [_display, _home] call FUNC(makeTooltip);

    ctrlDelete _name;

    _new ctrlSetPosition [_relX + _oldX - _homeX, _relY + _oldY - _homeY, _width, _height];
    _new ctrlCommit 0;

    if (_text isNotEqualTo "") then {
        [_new, _text, _tipW, _tipH] call FUNC(setTipText);
    };

    _new ctrlShow _shown;

    uiNamespace setVariable [QGVAR(tooltip), _new];

    if ((uiNamespace getVariable [QGVAR(tipShown), controlNull]) isEqualTo _name || {_shown}) then {
        uiNamespace setVariable [QGVAR(tipShown), [controlNull, _new] select _shown];
    };

    GVAR(tooltipAt) = [];

    true
};

private _tip = uiNamespace getVariable [QGVAR(tipShown), controlNull];

if (isNull _tip || {!ctrlShown _tip}) exitWith {false};
// With a menu or the colour popover open no item's name shows (fnc_updateHover): what shows is the tip of one of its buttons, and
// it has to go over the popover too.
if (GVAR(dragging)) exitWith {false};

private _created = uiNamespace getVariable [QGVAR(created), []];
private _at = _created find _tip;

// Not the last live control made on the display: something went over it. Or a part was drawn again in its group after a click
// (fnc_redrawPart, fnc_onFrame's focus): the group then lies over the name though the list does not say so (QGVAR(tipStale)).
if (_at < 0) exitWith {false};
if (!(uiNamespace getVariable [QGVAR(tipStale), false]) && {(_created select [_at + 1]) findIf {!isNull _x} < 0}) exitWith {false};

uiNamespace setVariable [QGVAR(tipStale), false];

private _position = ctrlPosition _tip;
private _made = true;

if (_tip isEqualTo (uiNamespace getVariable [QGVAR(tooltip), controlNull])) then {
    private _text = _tip getVariable [QGVAR(tipText), ""];
    private _width = _tip getVariable [QGVAR(width), 0];
    private _height = _tip getVariable [QGVAR(height), UNIT * 0.85];

    ctrlDelete _tip;
    _created deleteAt _at;

    private _new = [_display] call FUNC(makeTooltip);

    _new ctrlSetPosition _position;
    _new ctrlCommit 0;
    [_new, _text, _width, _height] call FUNC(setTipText);
    _new ctrlShow true;

    uiNamespace setVariable [QGVAR(tooltip), _new];
    uiNamespace setVariable [QGVAR(tipShown), _new];
} else {
    // The comparison card: drawn again from what it was made from, where it is now.
    private _source = _tip getVariable [QGVAR(source), createHashMap];

    if (count _source == 0) then {
        _made = false;
    } else {
        ctrlDelete _tip;
        _created deleteAt _at;

        private _card = [_display, _source] call FUNC(drawCompare);

        _card ctrlSetPosition _position;
        _card ctrlCommit 0;

        uiNamespace setVariable [QGVAR(tipShown), _card];
    };
};

_made
