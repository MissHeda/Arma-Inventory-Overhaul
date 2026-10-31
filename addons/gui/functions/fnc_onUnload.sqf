#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The window closed - however it closed: Escape, the Gear key, the close button, fnc_onFrame because the
 * unit can no longer use it, or another script. Every one of them ends here, so this is where the frame
 * is stopped (fnc_stopFrame).
 *
 * And where the RPT is told why, one line "window closed: <reason>": the reason the window's own path gave
 * (fnc_closeDisplay - a movement key, Escape, the Gear key, the close button, a rule of fnc_onFrame, the
 * vanilla inventory under it) or, with none given, that something else closed it - another mod's
 * closeDialog or closeDisplay, with the exit code it used. A window that closes "at once" with another
 * mod loaded says here which it was.
 *
 * A repack of magazines still running ends with it, its result written (einv_magazines). What the window was
 * opened on closes with a sound.
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

params ["", ["_exitCode", -1]];

private _reason = GVAR(closeReason);

if (_reason isEqualTo "") then {
    _reason = if ((["guest", [], false] call FUNC(hook)) isEqualTo true) then {
        "the display it was a guest on closed"
    } else {
        format ["from outside - another mod or a script closed it (closeDialog or closeDisplay, exit code %1)", _exitCode]
    };
};

// The two reasons that come as a key, in words.
_reason = (createHashMapFromArray [
    ["move", "a movement key"], ["taken", "the soldier was taken away from what he looted"]
]) getOrDefault [_reason, _reason];

INFO_1("window closed: %1",_reason);

// The volumes set in the sound dropdown are kept, should the window close with it open - and the colours set in the palette.
[] call FUNC(soundSettle);
[] call FUNC(paletteSettle);

// A palette popover that was open went with the display: it must not come back with the next window (fnc_build makes it again).
if ((GVAR(menuFor) param [0, ""]) isEqualTo "palette") then {
    uiNamespace setVariable [QGVAR(menu), []];
    GVAR(menuFor) = [];
    GVAR(menuState) = [];
};

// A repack in progress ends with the window: what was moved so far is written (einv_magazines).
if (!isNil QEFUNC(magazines,stop)) then {
    ["Closed"] call EFUNC(magazines,stop);
};

// The container that was looted closes with a sound - unless the soldier was taken from it, is out cold or
// sits in it.
if (
    !isNull GVAR(openedOn) && {alive GVAR(unit)} && {[GVAR(unit)] call ACEFUNC(common,isAwake)}
    && {objectParent GVAR(unit) isNotEqualTo GVAR(openedOn)} && {GVAR(closeReason) isNotEqualTo "taken"}
) then {
    ["close", "", GVAR(openedOn)] call FUNC(playSound);
};

// Better Inventory's stack move may work again (fnc_open).
if (!isNil "bettInv_stackMove") then {
    bettInv_stackMove = 0;
};

GVAR(openedOn) = objNull;
GVAR(openGuess) = false;
GVAR(openParent) = objNull;
GVAR(openPos) = [];
GVAR(moveHeld) = [];

call FUNC(stopFrame);

call EFUNC(storage,flushPlaces);

// A drag under way ends with the window, without fnc_endDrag: its timing line (einv_gui_debugTiming) is written here.
call FUNC(logDrag);
[""] call FUNC(logFrame);

GVAR(press) = [];
GVAR(dragging) = false;
GVAR(stripDrag) = [];
GVAR(dragTarget) = [];

// What still waited for the hands is dropped with the window: it was only waiting, nothing was sent or changed
// (fnc_queueMoves). A move that already went out finishes on its own.
GVAR(handQueue) = [];
GVAR(coalesced) = createHashMap;
GVAR(pageWanted) = createHashMap;
GVAR(handStarted) = -1;
GVAR(queueDirty) = false;
GVAR(queueFrom) = 0;
GVAR(handWaiting) = createHashMap;
GVAR(handBoxes) = [];
GVAR(statusLive) = false;
GVAR(roomCache) = [];
GVAR(quickHeldKey) = -1;

GVAR(person) = objNull;
GVAR(personMode) = "";

// The controls went with the display; nothing may still point at them.
uiNamespace setVariable [QGVAR(created), []];
uiNamespace setVariable [QGVAR(grids), []];
uiNamespace setVariable [QGVAR(slots), []];
uiNamespace setVariable [QGVAR(glowCache), createHashMap];
uiNamespace setVariable [QGVAR(glowNext), 0];
uiNamespace setVariable [QGVAR(dragGlow), []];
uiNamespace setVariable [QGVAR(parts), createHashMap];
GVAR(hover) = [];
GVAR(lastMouse) = [];
uiNamespace setVariable [QGVAR(hint), controlNull];
uiNamespace setVariable [QGVAR(hoverRing), []];
uiNamespace setVariable [QGVAR(hoverGeom), []];
uiNamespace setVariable [QGVAR(hoverHold), []];
uiNamespace setVariable [QGVAR(inspectGroup), controlNull];
uiNamespace setVariable [QGVAR(inspectRect), []];
uiNamespace setVariable [QGVAR(windows), []];
uiNamespace setVariable [QGVAR(turnedPictures), []];
uiNamespace setVariable [QGVAR(windowTrash), []];
uiNamespace setVariable [QGVAR(scrollRestore), []];
uiNamespace setVariable [QGVAR(keepColumns), createHashMap];
uiNamespace setVariable [QGVAR(keepPixels), createHashMap];
uiNamespace setVariable [QGVAR(zones), []];
uiNamespace setVariable [QGVAR(cell), []];
GVAR(windowMove) = [];
GVAR(theme) = createHashMap;
GVAR(context) = createHashMap;

// A window that attached with hooks (fnc_attach) takes them along: the next one, the inventory, has none.
GVAR(hooks) = createHashMap;

uiNamespace setVariable [QGVAR(display), displayNull];
