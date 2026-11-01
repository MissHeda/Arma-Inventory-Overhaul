#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The list in ACE's right column that is shown now: ACE's own (IDC 15), or - while Enhanced First Aid Kits' kits tab
 * lies over ACE's panels (fnc_focusedKit) - that tab's list of what the picked kit may hold, at the same place
 * (aio_compat_efak_fnc_arsenalControls). For the focus given back once the mouse leaves the panel (fnc_onFrame).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * The list <CONTROL>
 *
 * Example:
 * [_display] call aio_arsenal_fnc_rightList;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if ((([_display] call FUNC(focusedKit)) select 0) && {!isNil QEFUNC(compat_efak,arsenalControls)}) exitWith {
    ([_display] call EFUNC(compat_efak,arsenalControls)) select 0
};

// The vanilla arsenal: the cargo list of the open tab of its right side, the one enabled.
if (GVAR(kind) isEqualTo "bi") exitWith {
    private _tab = (BI_CARGO_TABS select {ctrlEnabled (_display displayCtrl (BI_IDC_LIST + _x))}) param [0, -1];

    [controlNull, _display displayCtrl (BI_IDC_LIST + _tab)] select (_tab >= 0)
};

_display displayCtrl ARSENAL_IDC_LIST
