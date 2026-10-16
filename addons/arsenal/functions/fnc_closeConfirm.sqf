#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes the question of fnc_confirmClose off ACE Arsenal's display: its card and the glass that kept the mouse
 * from ACE's controls under it go, and the focus goes back to ACE's list. Nothing is closed or removed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call einv_arsenal_fnc_closeConfirm;
 *
 * Public: No
 */

disableSerialization;

private _card = uiNamespace getVariable [QGVAR(confirm), controlNull];
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

uiNamespace setVariable [QGVAR(confirm), controlNull];

if (!isNull _card) then {
    ctrlDelete _card;
};

if (!isNull _display) then {
    private _list = _display displayCtrl ARSENAL_IDC_LIST;

    if (!isNull _list && {ctrlShown _list} && {ctrlEnabled _list}) then {
        ctrlSetFocus _list;
    };
};

// The panel is drawn anew should it have been touched while the question was up.
GVAR(dirty) = true;
