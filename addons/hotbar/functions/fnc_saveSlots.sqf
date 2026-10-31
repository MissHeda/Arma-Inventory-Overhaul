#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes the slots to the profile (fnc_loadSlots reads them there).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_hotbar_fnc_saveSlots;
 *
 * Public: No
 */

profileNamespace setVariable ["aio_hotbar_slots", +GVAR(slots)];
saveProfileNamespace;
