#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The class of a row of JNA's cargo lists. JNA keeps a whole array in the row's data, str [class, stock, name, dlc]
 * ("CreateItem" of jn_fnc_arsenal), not the class alone as the vanilla arsenal does.
 *
 * Arguments:
 * 0: The list <CONTROL>
 * 1: The row <NUMBER>
 *
 * Return Value:
 * The class, "" for none <STRING>
 *
 * Example:
 * [_list, 3] call aio_compat_antistasi_arsenal_fnc_rowClass;
 *
 * Public: No
 */

params [["_list", controlNull, [controlNull]], ["_row", -1, [0]]];

if (isNull _list || {_row < 0}) exitWith {""};

private _data = if (ctrlType _list == 102) then {_list lnbData [_row, 0]} else {_list lbData _row};

if (_data isEqualTo "") exitWith {""};

// A row someone else filled with the class alone.
if ((_data select [0, 1]) isNotEqualTo "[") exitWith {_data};

private _class = (parseSimpleArray _data) param [0, ""];

[_class, ""] select !(_class isEqualType "")
