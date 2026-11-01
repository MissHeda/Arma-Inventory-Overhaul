#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The panel's state, started afresh for an arsenal that opened - ACE Arsenal's (fnc_onOpened) or the vanilla one's
 * (fnc_biOpened): its display, the question of fnc_confirmClose, what is folded, pressed, watched and dragged.
 *
 * Arguments:
 * 0: The arsenal's display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_arsenal_fnc_initState;
 *
 * Public: No
 */

disableSerialization;

params [["_display", displayNull, [displayNull]]];

uiNamespace setVariable [QGVAR(display), _display];
uiNamespace setVariable [QGVAR(confirm), controlNull];
uiNamespace setVariable [QGVAR(confirmControls), []];
uiNamespace setVariable [QGVAR(confirmMoved), []];
uiNamespace setVariable [QGVAR(confirmBar), [controlNull, 0]];
uiNamespace setVariable [QGVAR(confirmButtons), []];
GVAR(confirmPress) = -1;

GVAR(openedAt) = diag_tickTime;
GVAR(ungreyQueued) = false;
GVAR(attached) = false;
GVAR(shown) = true;
GVAR(panelRect) = [];
GVAR(hintRect) = [];
GVAR(removeZone) = -1;
GVAR(snapshot) = [objNull, createHashMap];
GVAR(kept) = [];
GVAR(keptAt) = 0;
GVAR(loadoutFrame) = -1;
GVAR(itemsSeen) = false;
GVAR(cargoPending) = false;
GVAR(dirty) = false;
GVAR(dragZone) = "";
GVAR(folded) = createHashMap;
GVAR(foldKeys) = [];
GVAR(foldTab) = "";
GVAR(listPress) = [];
GVAR(listSel) = [];
GVAR(watch) = [];
GVAR(scrollHold) = [];
GVAR(scrollKey) = "";
GVAR(scrollPixels) = 0;
GVAR(ctrlHeld) = false;
GVAR(pictureCache) = createHashMap;
GVAR(stagingCount) = 0;
GVAR(collapsedScroll) = ["", 0];
GVAR(listDragClass) = "";
GVAR(listDragIdc) = ARSENAL_IDC_LIST;
GVAR(unfoldSince) = -1;
GVAR(focusSeen) = [false, "", false];
GVAR(focusBuilt) = [false, "", false];
GVAR(focusKit) = "";
GVAR(kitVerdicts) = [[], createHashMap];
GVAR(kitUngreyAt) = 0;
