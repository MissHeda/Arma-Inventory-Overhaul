#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Gives a control of the window a tip that shows on the window's own glass - the name at the mouse, round as the comparison
 * card (fnc_setTipText) - instead of the engine's square tooltip box. The control notes when the mouse comes onto it and leaves
 * it (uiNamespace hoverTip), and fnc_updateHover shows its tip while nothing else is named there. A control that cannot tell
 * the mouse is on it (static text, a picture) keeps the engine's tooltip.
 *
 * Arguments:
 * 0: Control <CONTROL>
 * 1: Tip, "" for none <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_button, "Fold this box"] call aio_gui_fnc_setTooltip;
 *
 * Public: No
 */

params [["_ctrl", controlNull, [controlNull]], ["_tip", "", [""]]];

if (isNull _ctrl) exitWith {};

// Buttons, fields and active text report the mouse; anything else keeps the engine's box.
if !((ctrlType _ctrl) in [1, 2, 11, 16]) exitWith {
    _ctrl ctrlSetTooltip _tip;
};

_ctrl setVariable [QGVAR(tip), _tip];

if (_ctrl getVariable [QGVAR(tipHooked), false]) exitWith {};

_ctrl setVariable [QGVAR(tipHooked), true];

// Kept for the look by place: the engine reports the mouse entering some controls unreliably - in the columns' groups, and as a
// guest on another mod's display (ACE Arsenal) - the tip showed only after a click, so the hover looks for it under the mouse
// (fnc_updateHover).
private _tipped = uiNamespace getVariable [QGVAR(tipCtrls), []];
_tipped = _tipped select {!isNull _x};
_tipped pushBack _ctrl;
uiNamespace setVariable [QGVAR(tipCtrls), _tipped];
_ctrl ctrlAddEventHandler ["MouseEnter", {
    params ["_ctrl"];

    uiNamespace setVariable [QGVAR(hoverTip), _ctrl];
    GVAR(lastMouse) = [];
}];
// A press keeps the tip: the engine reports the mouse leaving a button while it is pressed, and the tip of the Sort and
// fold buttons went away on a left click (it is the same button under the same mouse).
{
    _ctrl ctrlAddEventHandler [_x, {
        params ["_ctrl"];

        uiNamespace setVariable [QGVAR(hoverTip), _ctrl];
        GVAR(lastMouse) = [];
    }];
} forEach ["MouseButtonDown", "MouseButtonUp", "ButtonClick"];

_ctrl ctrlAddEventHandler ["MouseExit", {
    params ["_ctrl"];

    if ((uiNamespace getVariable [QGVAR(hoverTip), controlNull]) isEqualTo _ctrl) then {
        uiNamespace setVariable [QGVAR(hoverTip), controlNull];
        GVAR(lastMouse) = [];
    };
}];
