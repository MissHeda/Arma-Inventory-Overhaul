#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The kit type that is in focus in ACE's LEFT list: the row picked there is a kit of Enhanced First Aid Kits
 * (a prototype or one of its instances). The panel then shows that type's kit grid in place of the container
 * (fnc_layout, fnc_kitSections); with no such row picked it shows no kit at all.
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

private _list = _display displayCtrl ARSENAL_IDC_LEFT_LIST;

if (isNull _list) exitWith {""};

private _row = lbCurSel _list;

if (_row < 0 || {_row >= lbSize _list}) exitWith {""};

private _class = _list lbData _row;

if (_class isEqualTo "" || {(([_class] call EFUNC(items,kitOf)) isEqualTo [])}) exitWith {""};

toLowerANSI (([_class] call EFUNC(items,kitOf)) param [0, ""])
