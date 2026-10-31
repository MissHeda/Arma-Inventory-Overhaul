#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The inventory window opens anew (einv_gui_fnc_open): the kits open in the last one closed with it,
 * and every kit counts as untouched again - what may go back into a kit whose packing is switched off
 * is counted from now on (fnc_repackable).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_compat_efak_fnc_onWindowOpen;
 *
 * Public: No
 */

GVAR(opened) = [];
GVAR(holders) = createHashMap;
GVAR(arsenalHolders) = createHashMap;
GVAR(kitStart) = createHashMap;
