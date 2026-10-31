#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an item has a model of its own worth a look in 3D (the inspect card's 3D view, fnc_inspect3D) - one that is not the
 * engine's stand-in box (fnc_itemModel).
 *
 * Arguments:
 * 0: Item class <STRING>
 *
 * Return Value:
 * Has a model of its own <BOOL>
 *
 * Example:
 * ["arifle_MX_F"] call aio_gui_fnc_hasModel;
 *
 * Public: No
 */

params [["_class", "", [""]]];

([_class] call FUNC(itemModel)) isNotEqualTo ""
