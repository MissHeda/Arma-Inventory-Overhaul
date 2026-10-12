#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the camera back to its start view (a double click on the free middle): the default distance and
 * direction and the soldier's chest as the target. The distance is never less than the soldier needs to fit
 * the free middle (fnc_cameraRect).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call einv_arsenal_fnc_cameraReset;
 *
 * Public: No
 */

GVAR(cameraPosition) = [3 max GVAR(cameraMinDistance), 0, 5, [0, 0, 0.9]];
