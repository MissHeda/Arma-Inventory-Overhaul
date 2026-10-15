#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Keeps the Sort buttons of the window in step with the order the player sorts by. Every Sort button drawn
 * (a section's caption line, fnc_drawSection, and a kit window's title row, fnc_drawWindow) is registered
 * here with the controls fnc_uiButton made, and gets its label and tooltip for the order now (fnc_sortText).
 * A click steps to the next order (fnc_sortHolder) and calls this again with nothing: the label of every
 * Sort button on the window changes in place, so one click on one section changes them all and nothing has
 * to be drawn again.
 *
 * The registry (uiNamespace sortButtons) is emptied by each build; controls gone with a window that was
 * drawn again are left out when it is read.
 *
 * Arguments:
 * 0: The controls fnc_uiButton returned for a Sort button, to register - [] for none, only to refresh
 *    <ARRAY> (default: [])
 *
 * Return Value:
 * None
 *
 * Example:
 * [_button] call einv_gui_fnc_sortButtons;
 *
 * Public: No
 */

disableSerialization;

params [["_button", [], [[]]]];

private _buttons = (uiNamespace getVariable [QGVAR(sortButtons), []]) select {!isNull (_x select 0)};

// The label is the control before the hit area, which comes last (fnc_uiButton).
if (count _button >= 2 && {(ctrlClassName (_button select -2)) in ["EINV_Label", "EINV_LabelRight", "EINV_LabelCenter"]}) then {
    _buttons pushBack [_button select -2, _button select -1];
};

uiNamespace setVariable [QGVAR(sortButtons), _buttons];

([GVAR(sortMode)] call FUNC(sortText)) params ["_label", "_tip"];

private _caption = [_label, GVAR(theme)] call FUNC(caption);

{
    _x params ["_labelControl", "_hit"];

    _labelControl ctrlSetText _caption;
    _hit ctrlSetTooltip _tip;
} forEach _buttons;
