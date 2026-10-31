#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The wizard closed - however it closed: Escape, the close button, Apply in menu mode, the menu or the
 * mission under it closing. Its controls went with it; nothing may still point at them, and nothing it
 * queued is still to run.
 *
 * The draft's text stays in the mission namespace - only text and plain arrays, which a save game may
 * hold - but its compiled rules and their cache are dropped: they are made again on the next open.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Exit code <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 2] call aio_setup_fnc_onUnload;
 *
 * Public: No
 */

uiNamespace setVariable [QGVAR(display), displayNull];
uiNamespace setVariable [QGVAR(root), controlNull];
uiNamespace setVariable [QGVAR(content), controlNull];
uiNamespace setVariable [QGVAR(frame), []];
uiNamespace setVariable [QGVAR(popover), []];
uiNamespace setVariable [QGVAR(layer), controlNull];
uiNamespace setVariable [QGVAR(sink), controlNull];
uiNamespace setVariable [QGVAR(hintCtrl), controlNull];
uiNamespace setVariable [QGVAR(rawState), controlNull];
uiNamespace setVariable [QGVAR(textArea), controlNull];
uiNamespace setVariable [QGVAR(editAreas), []];
uiNamespace setVariable [QGVAR(deferred), []];

GVAR(draftRules) = createHashMap;
GVAR(draftCache) = createHashMap;
GVAR(stepKey) = {false};
GVAR(banner) = false;
