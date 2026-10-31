#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * A key pressed on ACE Arsenal's display, in place of the handler its config sets (fnc_interceptClose): Escape
 * closes the window, but asks first when something does not fit (fnc_confirmClose); with the question open,
 * Escape is "Keep editing" and no other key reaches ACE. Every other key goes to ACE's own handler as it
 * would have, and its answer is ours. ACE's loadouts display takes Escape for itself while it is open, so
 * Escape is left to ACE then.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 * 1: Key (DIK code) <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [_display, 1, false, false, false] call aio_arsenal_fnc_onAceKey;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]], ["_key", 0, [0]]];

if !(isNull (uiNamespace getVariable [QGVAR(confirm), controlNull])) exitWith {
    if (_key == DIK_ESCAPE) then {
        [] call FUNC(closeConfirm);
    };

    true
};

if (_key == DIK_ESCAPE && {isNull (findDisplay ARSENAL_IDD_LOADOUTS)}) exitWith {
    [_display, 2] call FUNC(confirmClose);
    true
};

// ACE's config calls its handler as ["onKeyDown", the event's arguments, the display's class name].
private _handled = ["onKeyDown", _this, "ace_arsenal_display"] call ACEFUNC(arsenal,onKeyDown);

[false, _handled] select (_handled isEqualType true)
