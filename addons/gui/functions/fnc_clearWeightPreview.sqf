#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Takes back what lifting something showed about weight (fnc_previewWeight): the preview on the weight card
 * is deleted; the drag's hint is forgotten, so the next one writes its own. First thing when a drag ends. A
 * build needs nothing of this - it deletes the controls.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_gui_fnc_clearWeightPreview;
 *
 * Public: No
 */

disableSerialization;

ctrlDelete (uiNamespace getVariable [QGVAR(weightPreview), controlNull]);
uiNamespace setVariable [QGVAR(weightPreview), controlNull];
uiNamespace setVariable [QGVAR(dragExternal), false];
GVAR(dragHintShown) = [];
