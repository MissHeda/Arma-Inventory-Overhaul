#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether Enhanced First Aid Kits' kits tab is open in ACE Arsenal - the kits' button in ACE's left bar, under the
 * backpack's -, and the kit picked in its list (aio_compat_efak_fnc_arsenalFocus). That tab lies over ACE's panels
 * while ACE's own tab stays the one it was, so no container is open in ACE's sense then (fnc_selected), and the panel
 * shows the soldier's uniform, vest and backpack folded, the picked kit's grid unfolded and the staging space
 * (fnc_layout). Read every frame (fnc_onFrame): the tab tells nobody when it opens, closes or another kit is picked.
 * Never open without the compat addon (Enhanced First Aid Kits not loaded).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY> (default: the open one)
 *
 * Return Value:
 * [the tab is open <BOOL>, class of the row picked, "" for none <STRING>, a row of kits being made ready <BOOL>] <ARRAY>
 *
 * Example:
 * ([_display] call aio_arsenal_fnc_focusedKit) params ["_open", "_picked", "_preparing"];
 *
 * Public: No
 */

disableSerialization;

params [["_display", uiNamespace getVariable [QGVAR(display), displayNull], [displayNull]]];

if (isNull _display || {isNil QEFUNC(compat_efak,arsenalFocus)}) exitWith {[false, "", false]};

[_display] call EFUNC(compat_efak,arsenalFocus)
