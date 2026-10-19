#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The kit type that is in focus in ACE's list: the row picked there is a kit of Enhanced First Aid Kits
 * (a prototype or one of its instances). The panel unfolds the kits of that type by themselves
 * (fnc_kitSections), so the one being added or looked at is open to be filled.
 *
 * Arguments:
 * 0: ACE Arsenal's display <DISPLAY>
 *
 * Return Value:
 * The lowercase prototype of the kit type, "" when the picked row is no kit <STRING>
 *
 * Example:
 * [_display] call einv_arsenal_fnc_focusedKit;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

private _list = _display displayCtrl ARSENAL_IDC_LIST;

if (isNull _list) exitWith {""};

private _row = lnbCurSelRow _list;

if (_row < 0 || {_row >= (lnbSize _list) select 0}) exitWith {""};

private _class = _list lnbData [_row, 0];

if (_class isEqualTo "" || {(([_class] call EFUNC(items,kitOf)) isEqualTo [])}) exitWith {""};

toLowerANSI (([_class] call EFUNC(items,kitOf)) param [0, ""])
