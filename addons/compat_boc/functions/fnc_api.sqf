#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The prefix of the BackpackOnChest that is loaded: "bocr_main" for the Redux (mjc4wilton), "zade_boc" for the
 * original (DerZade), "" for neither. Both name their functions the same after it - _fnc_chestpack (the class of
 * the pack on the chest, "" for none), _fnc_actionOnChest, _fnc_actionOnBack and _fnc_actionSwap, which take the
 * unit and do all of the move themselves, its cargo, radios and animation included.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Prefix <STRING>
 *
 * Example:
 * call aio_compat_boc_fnc_api;
 *
 * Public: No
 */

private _found = ["bocr_main", "zade_boc"] select {!isNil (_x + "_fnc_actionSwap") && {!isNil (_x + "_fnc_chestpack")}};

_found param [0, ""]
