#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A new id for a nested uniform, vest or backpack (fnc_tagNested), unique across machines: this
 * machine's id (fnc_machineId) and its own counter (GVAR(nextUid)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Id, "<machine id>-<n>" <STRING>
 *
 * Example:
 * call einv_storage_fnc_newUid;
 *
 * Public: No
 */

// Only the authority of a container hands out ids for what lies in it, and one machine counts on its
// own: two machines can never hand out the same one.
GVAR(nextUid) = GVAR(nextUid) + 1;

format ["%1-%2", call FUNC(machineId), GVAR(nextUid)]
