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

_display displayCtrl ARSENAL_IDC_LIST
