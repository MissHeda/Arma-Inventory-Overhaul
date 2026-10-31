#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * What Enhanced First Aid Kits' kits tab of ACE Arsenal shows: whether it is open, and the kit picked in its list.
 * That mod lays its tab over ACE's panels without telling ACE - ACE's current tab stays the one it was, and none of
 * ACE's events says anything - so the tab itself is read: its flag that it is up (efak_arsenal_active) and the row
 * picked in its list of the kits carried (EFAK_IDC_KIT_LIST): one row per kit, whose data is that kit's instance
 * class; a row of kits still being made ready has the type's prototype; a notice row ("no kits") has nothing.
 * Without that list, what the tab noted of the pick (efak_arsenal_selected). Cheap enough to be asked every frame
 * (aio_arsenal_fnc_onFrame).
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * [the tab is open <BOOL>, class of the row picked, "" for none <STRING>, a row of kits being made ready <BOOL>] <ARRAY>
 *
 * Example:
 * [findDisplay 1127001] call aio_compat_efak_fnc_arsenalFocus;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

if !(missionNamespace getVariable [QEFAKGVAR(arsenal,active), false]) exitWith {[false, "", false]};

private _list = _display displayCtrl EFAK_IDC_KIT_LIST;
private _row = if (isNull _list) then {-1} else {lbCurSel _list};

if (_row >= 0 && {_row < lbSize _list}) exitWith {
    private _kind = _list lbValue _row;

    [true, ["", _list lbData _row] select (_kind in [EFAK_ROW_KITS, EFAK_ROW_PREPARING]), _kind == EFAK_ROW_PREPARING]
};

[
    true,
    [missionNamespace getVariable [QEFAKGVAR(arsenal,selected), ""]] param [0, "", [""]],
    [missionNamespace getVariable [QEFAKGVAR(arsenal,selectedPreparing), false]] param [0, false, [false]]
]
