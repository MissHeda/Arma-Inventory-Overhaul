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
 * A compact Sort button (fnc_sortChip: the icon and "Sort", or the icon alone) keeps its words; its tooltip
 * names the order instead, "Sort: Name - click for Weight" (fnc_sortText).
 *
 * Arguments:
 * 0: The controls fnc_uiButton returned for a Sort button, to register - [] for none, only to refresh
 *    <ARRAY> (default: [])
 * 1: Compact, as fnc_sortChip - 0 the full label, 1 or 2 the order only in its tooltip <NUMBER> (default: 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_button] call aio_gui_fnc_sortButtons;
 *
 * Public: No
 */

disableSerialization;

params [["_button", [], [[]]], ["_compact", 0, [0]]];

private _buttons = (uiNamespace getVariable [QGVAR(sortButtons), []]) select {!isNull (_x select 1)};

// The hit area comes last (fnc_uiButton), the label - where there is one - right before it. [label or
// controlNull, hit area, compact].
if (_button isNotEqualTo []) then {
    private _labelControl = _button param [count _button - 2, controlNull];

    if !((ctrlClassName _labelControl) in ["AIO_Label", "AIO_LabelRight", "AIO_LabelCenter"]) then {
        _labelControl = controlNull;
    };

    _buttons pushBack [_labelControl, _button select -1, _compact];
};

uiNamespace setVariable [QGVAR(sortButtons), _buttons];

([GVAR(sortMode)] call FUNC(sortText)) params ["_label", "_tip", "_compactTip"];

private _caption = [_label, GVAR(theme)] call FUNC(caption);

{
    _x params ["_labelControl", "_hit", ["_isCompact", 0]];

    if (_isCompact > 0) then {
        [_hit, _compactTip] call FUNC(setTooltip);
    } else {
        _labelControl ctrlSetText _caption;
        [_hit, _tip] call FUNC(setTooltip);
    };
} forEach _buttons;
