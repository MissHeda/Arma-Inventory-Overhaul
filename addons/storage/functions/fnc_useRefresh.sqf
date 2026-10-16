#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Notes whether any of the three "Use items from ..." settings limits something: GVAR(useActive). Everything
 * that asks where an item may be used from looks at that first and has nothing to do, at no cost, while all
 * three are on Everything. Run by each of the settings when it is set or changed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Whether something is limited <BOOL>
 *
 * Example:
 * [] call einv_storage_fnc_useRefresh;
 *
 * Public: No
 */

GVAR(useActive) = (USE_KINDS findIf {([_x] call FUNC(useMode)) isNotEqualTo USE_ALL}) >= 0;

GVAR(useActive)
