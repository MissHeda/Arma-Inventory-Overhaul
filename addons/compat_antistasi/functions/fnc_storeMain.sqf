#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * HALs' HALs_store_fnc_main (Antistasi's trader window): every "container canAdd [class, count]" it asks - its Buy
 * button, the colour of a row - counts the grid as well (fnc_canAdd), as the server's check does (fnc_canAddItem).
 * Antistasi's own file otherwise (fnc_patched).
 *
 * Arguments:
 * As HALs_store_fnc_main
 *
 * Return Value:
 * As HALs_store_fnc_main
 *
 * Public: No
 */

_this call (["storeMain", A3A_FILE_STOREMAIN, [
    ["_container canAdd [_classname, _amount - 1]", format ["([_container, _classname, _amount - 1] call %1)", QFUNC(canAdd)]],
    ["_container canAdd [_classname, _amount]", format ["([_container, _classname, _amount] call %1)", QFUNC(canAdd)]]
]] call FUNC(patched))
