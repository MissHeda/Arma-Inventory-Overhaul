#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes a display the window. Everything fnc_open does once the inventory's dialog exists, for any
 * display that carries the dim layer and the first control (IDC_DIM, IDC_FIRST): the unit and the
 * containers it looks into, the window's state started afresh, the mouse handlers, the first build and
 * the frame. The inventory attaches with no hooks; ACE Arsenal's grid panel (aio_arsenal) and later
 * editor windows attach with a table of them (fnc_hook), which is how they differ from it. With no hooks
 * every function of this addon behaves as it always did (fnc_isInventoryMode). A display that belongs to
 * another mod and carries neither the dim layer nor the first control takes part as a guest (the "guest"
 * flag): only what this addon made there is ever swept, and that mod's handlers keep every click.
 *
 * Refuses when another display is the window already: there is one session of this addon at a time.
 *
 * The state of a living person looked into (GVAR(person), GVAR(personMode)) is the inventory's own and
 * is set by fnc_open before it attaches. A kit window of Enhanced First Aid Kits opened in the window
 * before is closed (aio_compat_efak - only when that addon is loaded).
 *
 * Nothing the last window waited for carries over (moves under way, answers, drift), nor the tiles it
 * had selected; what lies around is read for the first build
 * (fnc_readNearby, in the inventory only).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Unit the window is for <OBJECT>
 * 2: Container the unit opened, or objNull <OBJECT>
 * 3: Second container (the ground next to a crate), or objNull <OBJECT>
 * 4: Hooks, name -> CODE or flag, see fnc_hook <HASHMAP> (default: createHashMap)
 * 5: What drives the frame - "pfh", a CBA per-frame handler, or "draw3d", a Draw3D mission event handler
 *    (the one that runs in the Eden editor) <STRING> (default: "pfh")
 *
 * Return Value:
 * Attached <BOOL>
 *
 * Example:
 * [_display, player, objNull, objNull, createHashMap, "pfh"] call aio_gui_fnc_attach;
 *
 * Public: No
 */

disableSerialization;

params [
    ["_display", displayNull, [displayNull]],
    ["_unit", objNull, [objNull]],
    ["_container", objNull, [objNull]],
    ["_secondary", objNull, [objNull]],
    ["_hooks", createHashMap, [createHashMap]],
    ["_driver", "pfh", [""]]
];

if (isNull _display) exitWith {false};

// The dialog of the inventory has registered itself already (its onLoad); any other display is the window
// only from here on.
private _current = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _current && {_current isNotEqualTo _display}) exitWith {false};

uiNamespace setVariable [QGVAR(display), _display];

// The cell is worked out afresh for this window, with the player's tile scale as it is now (fnc_getCell).
uiNamespace setVariable [QGVAR(cell), []];

// Nor does it close for a reason given to the last one (fnc_closeDisplay, fnc_onUnload).
GVAR(closeReason) = "";

GVAR(unit) = _unit;
GVAR(container) = _container;
GVAR(secondary) = _secondary;
GVAR(hooks) = _hooks;

GVAR(openedAt) = diag_tickTime;

// The items being searched start again from now - the window was closed meanwhile.
GVAR(searchStarted) = -1;
GVAR(searchRuns) = [];

{
    {ctrlDelete _x} forEach (_x select 2);
    ctrlDelete (_x select 3);
} forEach GVAR(searchMarks);

GVAR(searchMarks) = [];
GVAR(searchDirty) = true;
GVAR(sealDragOver) = createHashMap;
GVAR(opened) = [];

// The kits opened in the last window close with it (aio_compat_efak - only when that addon is loaded).
if (!isNil QEFUNC(compat_efak,onWindowOpen)) then {
    call EFUNC(compat_efak,onWindowOpen);
};

GVAR(filter) = "";
GVAR(filterFocus) = false;

// Nothing is chosen at the side of a box, no box has its search stopped, and no caption line holds a chip yet.
GVAR(groupFilters) = [];
GVAR(stripPages) = [];
GVAR(coalesced) = createHashMap;
GVAR(pageWanted) = createHashMap;
GVAR(searchPaused) = [];
GVAR(searchIdle) = [];
GVAR(searchSeen) = [];
GVAR(statusLive) = false;

// The inspect card went with the window it was opened in, however that closed - only where it stood is
// kept for the next one (GVAR(inspectPos)).
GVAR(inspect) = [];
GVAR(inspectMove) = [];
GVAR(covered) = false;

// The kit windows went with it too, and where they stood with them: opened again, a kit comes up
// beside its tile (fnc_openWindow).
GVAR(windowOrder) = [];
GVAR(windowPos) = createHashMap;
GVAR(windowAnchor) = createHashMap;
GVAR(windowFresh) = [];
GVAR(windowScroll) = createHashMap;
GVAR(windowMove) = [];
GVAR(middle) = [];
uiNamespace setVariable [QGVAR(windows), []];
uiNamespace setVariable [QGVAR(windowTrash), []];
uiNamespace setVariable [QGVAR(scrollRestore), []];

// A fresh window: nothing of the last one may carry over, not even where its columns were scrolled.
uiNamespace setVariable [QGVAR(created), []];
GVAR(theme) = createHashMap;

// Nor what it waited for: moves of the last window still under way finish on their own, wherever their
// items end up - this one shows what is there (fnc_onFrame). Drift is noted anew as its holders are
// drawn (fnc_drawCompartments).
GVAR(inFlight) = createHashMap;
GVAR(answers) = [];
GVAR(drift) = [];

// The hands' queue went with it: nothing was sent, so nothing is lost (fnc_queueMoves).
GVAR(handQueue) = [];
GVAR(handStarted) = -1;
GVAR(queueDirty) = false;
GVAR(queueFrom) = 0;
GVAR(handWaiting) = createHashMap;
GVAR(handBoxes) = [];
GVAR(roomCache) = [];
GVAR(quickHeldKey) = -1;

// The selection is view state of one window, and no press on an empty cell waits.
GVAR(selection) = [];
GVAR(selectionSide) = "";
GVAR(selectionAnchor) = [];
GVAR(emptyPress) = [];
GVAR(dragGroup) = [];
GVAR(signatureParts) = [];

// Moving items: the mouse buttons anywhere on the window (fnc_build adds the same to every group). On
// another mod's display (the "guest" flag) its own handlers and controls get every click and turn of the
// wheel as well, whatever this addon made of them: these never answer that they took it.
if ((["guest", [], false] call FUNC(hook)) isEqualTo true) then {
    _display displayAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton); false}];
    _display displayAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton); false}];
    _display displayAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ); false}];
} else {
    _display displayAddEventHandler ["MouseButtonDown", {[true, _this] call FUNC(onMouseButton)}];
    _display displayAddEventHandler ["MouseButtonUp", {[false, _this] call FUNC(onMouseButton)}];
    _display displayAddEventHandler ["MouseZChanged", {[_this] call FUNC(onMouseZ)}];
};

call FUNC(readNearby);
[_display] call FUNC(build);

GVAR(nextCheck) = 0;
GVAR(nextSignature) = diag_tickTime + SIGNATURE_INTERVAL;
[_driver] call FUNC(startFrame);

true
