#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the list of what Save would store - every difference between the draft and what is saved where the wizard
 * saves (fnc_drawChanges "saved"): the server settings, the cell size, the kinds of container and the rules, each
 * in words and marked new, changed or removed, with a cross that takes that one change back, and a click that opens
 * it where it is set. A box below what opened it - the header's "4 changes" -, so the page the player is on stays.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Screen rectangle of what opened it - the box goes below it - or [] for the middle <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, [0.5, 0.05, 0.2, 0.03]] call einv_setup_fnc_openChanges;
 *
 * Public: No
 */

disableSerialization;

params ["_display", ["_anchor", [], [[]]]];

[_display, _anchor, [SQUARE(UNIT * 30), UNIT * 17], "", {
    params ["_display", "_inner", "_theme"];

    (ctrlPosition _inner) params ["", "", "_width", "_height"];

    [_display, _inner, [0, 0, _width, _height], _theme, "saved"] call FUNC(drawChanges);
}] call FUNC(popover);
