#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the draft holds something not saved yet: another text, or the switch to force it over the
 * mission's own setup turned.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something to save <BOOL>
 *
 * Example:
 * call einv_setup_fnc_isDirty;
 *
 * Public: No
 */

(GVAR(draftText) isNotEqualTo GVAR(clean)) || {GVAR(override) isNotEqualTo GVAR(cleanOverride)}
