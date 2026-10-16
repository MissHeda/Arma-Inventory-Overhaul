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
 * or the card shows, no context menu is open (the menu is the topmost layer and hides the name) and
 * nothing is dragged, and only when something made after it is still there. The name keeps its text, place
 * and size; the card is drawn again from the rows it was made from (fnc_drawCompare). Controls in a group -
 * the tiles' hover, selection and flash - lie under it anyway: their group was made before it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Made again <BOOL>
 *
 * Example:
 * [] call einv_gui_fnc_raiseTooltip;
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable [QGVAR(display), displayNull];
private _tip = uiNamespace getVariable [QGVAR(tipShown), controlNull];

if (isNull _display || {isNull _tip} || {!ctrlShown _tip}) exitWith {false};
if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] || {GVAR(dragging)}) exitWith {false};

private _created = uiNamespace getVariable [QGVAR(created), []];
private _at = _created find _tip;

// Not the last live control made on the display: something went over it.
if (_at < 0 || {(_created select [_at + 1]) findIf {!isNull _x} < 0}) exitWith {false};

private _position = ctrlPosition _tip;
private _made = true;

if (_tip isEqualTo (uiNamespace getVariable [QGVAR(tooltip), controlNull])) then {
    private _text = ctrlText _tip;
    private _width = _tip getVariable [QGVAR(width), 0];
    private _height = _tip getVariable [QGVAR(height), UNIT * 0.85];

    ctrlDelete _tip;
    _created deleteAt _at;

    private _new = [_display] call FUNC(makeTooltip);

    _new ctrlSetText _text;
    _new ctrlSetPosition _position;
    _new ctrlCommit 0;
    _new setVariable [QGVAR(width), _width];
    _new setVariable [QGVAR(height), _height];
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
