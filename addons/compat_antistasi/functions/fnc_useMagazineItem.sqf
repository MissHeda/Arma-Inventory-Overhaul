#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Antistasi's A3U_fnc_useMagazineItem (a lockpick kit is used up a little): it takes the kit from the backpack, else
 * the vest, else the uniform. Here the containers a "Use items from ..." setting allows it from come first
 * (fnc_useOrder), in that order; one that closes it only when the kit lies nowhere else - the lockpicking has begun by
 * then and Antistasi gives no way back. Antistasi's own file otherwise (fnc_patched). A kit used part way keeps its
 * cell: the grid finds a magazine with other rounds by its kind.
 *
 * Arguments:
 * As A3U_fnc_useMagazineItem: [unit, magazine]
 *
 * Return Value:
 * As A3U_fnc_useMagazineItem
 *
 * Public: No
 */

_this call (["useMagazineItem", A3A_FILE_USEMAGITEM, [[
    "private _containers = [backpackContainer _unit, vestContainer _unit, uniformContainer _unit];",
    format ["private _containers = [_unit, _magazine] call %1;", QFUNC(useOrder)]
]]] call FUNC(patched))
