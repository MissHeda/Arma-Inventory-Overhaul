#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The window closed - however it closed: Escape, the Gear key, the close button, fnc_onFrame because the
 * unit can no longer use it, or another script. Every one of them ends here, so this is where the frame
 * is stopped (fnc_stopFrame) and the camera is given back to the player.
 *
 * A repack of magazines still running ends with it, its result written (einv_magazines). What the window was
 * opened on closes with a sound, and the soldier who looked into it stands up again (fnc_poseEnd).
 *
 * The places of the player's own uniform, vest and backpack, set here at once by their own moves and
 * sent to everyone else at most every two seconds, go out now (einv_storage_fnc_flushPlaces): whoever
 * looks into the player next sees what the window showed.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Exit code <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, 2] call einv_gui_fnc_onUnload;
 *
 * Public: No
 */

// A repack in progress ends with the window: what was moved so far is written (einv_magazines).
if (!isNil QEFUNC(magazines,stop)) then {
    ["Closed"] call EFUNC(magazines,stop);
};

// The container that was looted closes with a sound - unless the soldier was taken from it, is out cold or
// sits in it - and he stands up from his gear (fnc_poseEnd).
if (
    !isNull GVAR(openedOn) && {alive GVAR(unit)} && {[GVAR(unit)] call ACEFUNC(common,isAwake)}
    && {objectParent GVAR(unit) isNotEqualTo GVAR(openedOn)} && {GVAR(closeReason) isNotEqualTo "taken"}
) then {
    ["close", "", GVAR(openedOn)] call FUNC(playSound);
};

[] call FUNC(poseEnd);

// Better Inventory's stack move may work again (fnc_open).
if (!isNil "bettInv_stackMove") then {
    bettInv_stackMove = 0;
};

GVAR(openedOn) = objNull;
GVAR(openParent) = objNull;
GVAR(openPos) = [];
GVAR(moveHeld) = [];

call FUNC(stopFrame);

call FUNC(cameraStop);

call EFUNC(storage,flushPlaces);

GVAR(press) = [];
GVAR(dragging) = false;
GVAR(dragTarget) = [];

GVAR(person) = objNull;
GVAR(personMode) = "";

// The controls went with the display; nothing may still point at them.
uiNamespace setVariable [QGVAR(created), []];
uiNamespace setVariable [QGVAR(grids), []];
uiNamespace setVariable [QGVAR(slots), []];
GVAR(hover) = [];
GVAR(lastMouse) = [];
uiNamespace setVariable [QGVAR(hint), controlNull];
uiNamespace setVariable [QGVAR(hoverRing), []];
uiNamespace setVariable [QGVAR(inspectGroup), controlNull];
uiNamespace setVariable [QGVAR(inspectRect), []];
uiNamespace setVariable [QGVAR(windows), []];
uiNamespace setVariable [QGVAR(windowTrash), []];
uiNamespace setVariable [QGVAR(scrollRestore), []];
uiNamespace setVariable [QGVAR(zones), []];
GVAR(windowMove) = [];
GVAR(theme) = createHashMap;
GVAR(context) = createHashMap;

// A window that attached with hooks (fnc_attach) takes them along: the next one, the inventory, has none.
GVAR(hooks) = createHashMap;

uiNamespace setVariable [QGVAR(display), displayNull];
