#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * At preInit: checks that this addon's BIS_fnc_arsenal is the one in force (fnc_checkBIOverride) and
 * registers the safety net on the vanilla arsenal's opening (fnc_biSafetyNet).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_biInit;
 *
 * Public: No
 */

call FUNC(checkBIOverride);
call FUNC(biSafetyNet);
