#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes the question of fnc_confirmClose off ACE Arsenal's display: its card and the dimming that kept the mouse
 * from ACE's controls under it go, and the focus goes back to ACE's list. Nothing is closed or removed. A panel
 * folded to its title row (fnc_toggleCollapse) unfolds for the session, as the things that do not fit lie in its
 * grid: to keep editing is to put them right. The profile keeps the player's choice.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_arsenal_fnc_closeConfirm;
 *
 * Public: No
 */

disableSerialization;

private _parts = uiNamespace getVariable [QGVAR(confirmControls), []];
private _display = uiNamespace getVariable [QGVAR(display), displayNull];

// A drag of the card ends with it.
["end"] call EFUNC(gui,dragHandle);

uiNamespace setVariable [QGVAR(confirm), controlNull];
uiNamespace setVariable [QGVAR(confirmControls), []];
uiNamespace setVariable [QGVAR(confirmMoved), []];
uiNamespace setVariable [QGVAR(confirmBar), [controlNull, 0]];
uiNamespace setVariable [QGVAR(confirmButtons), []];
GVAR(confirmPress) = -1;

{
    if (!isNull _x) then {
        ctrlDelete _x;
    };
} forEach _parts;

if (!isNull _display) then {
    private _list = _display displayCtrl ARSENAL_IDC_LIST;

    if (!isNull _list && {ctrlShown _list} && {ctrlEnabled _list}) then {
        ctrlSetFocus _list;
    };
};

GVAR(collapsed) = false;

// The panel is drawn anew should it have been touched while the question was up.
GVAR(dirty) = true;
