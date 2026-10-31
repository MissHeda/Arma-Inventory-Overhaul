#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the inventory window for a unit and what it looks into - the containers the engine named when
 * the inventory was asked for (fnc_onInventoryOpened) - and builds it in the player's chosen look: makes
 * the dialog, notes the living person looked into and hands the display to fnc_attach, which does the
 * rest, with no hooks - the inventory itself.
 *
 * Should the window not open, nothing does: there is no vanilla inventory to fall back to (fnc_guardVanilla
 * keeps it closed), so the reason goes to the RPT.
 *
 * A living person looked into - whole, or by the backpack they wear - is kept apart (GVAR(person),
 * GVAR(personMode)): they walk off by themselves, so fnc_onFrame watches them.
 *
 * What it was opened on - a crate, vehicle, body, person or pile, not the player's own gear - is noted
 * (GVAR(openedOn)): the container opens with a sound, and a movement key closes the window on foot
 * (fnc_onKeyDown). The vehicle and place he had are kept to tell when he was taken away (fnc_checkTaken).
 *
 * One line in the RPT per window that opens ("open: <class> kind <family> rows x cols <grid> ..."): what it
 * was opened on and beside it, the grid each has, and whether the loot column shows it - shown, locked and
 * why, or no section at all. With fnc_onInventoryOpened's "asked:" line before it, a container that does
 * not open says where it stopped.
 *
 * Nothing the last window waited for carries over (fnc_attach).
 *
 * Never over the vanilla inventory: a dialog is made as the child of the one on top, and a child closes
 * with its parent. Another mod can have the engine open RscDisplayInventory beside this mod's handler
 * (fnc_onInventoryOpened answers true, but a handler of theirs may not); fnc_guardVanilla closes it as it
 * loads and again a frame later - and a window made in between would be its child and go with that second
 * close, "the window closes at once". So while a vanilla inventory is open it is closed first and the
 * window opens a frame later, at most OPEN_TRIES frames on. "Open" includes a display the guard closed
 * that is not gone yet: the engine may no longer list it (findDisplay) while it still holds it, and a
 * window made then hangs under it all the same - the guard keeps those (uiNamespace einv_gui_closing) and
 * the window waits for them too. One still held after OPEN_TRIES frames that findDisplay no longer finds
 * does not keep the window from opening.
 *
 * What the engine asked for always wins over a guess. The guard opens the window on a guess - the soldier's
 * own gear, the vehicle he sits in or looks at - when a vanilla inventory came up that the unit's handler
 * was not asked for (fnc_guardVanilla). Such an opening says the frame that display came up in, and gives
 * way, before and while it waits, as soon as the handler was asked in that frame or since: the handler's
 * own opening names the vehicle or crate the engine opened and is on its way. So it does to an opening
 * that was asked for and waits for that display to go as well (GVAR(openWaiting)). A window made on a
 * guess is noted (GVAR(openGuess)), so the handler's opening that comes after it takes its place
 * (fnc_onInventoryOpened).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container the unit opened, or objNull <OBJECT>
 * 2: Second container (the ground next to a crate), or objNull <OBJECT>
 * 3: Frames already waited for a vanilla inventory to go - for the call itself, which waits <NUMBER>
 *    (default: 0)
 * 4: The frame a vanilla inventory nobody asked for came up in, when this is the guard's guess in its place
 *    (fnc_guardVanilla); -1 for an opening something asked for <NUMBER> (default: -1)
 *
 * Return Value:
 * Opened, or opens a frame later <BOOL>
 *
 * Example:
 * [player, cursorObject, objNull] call einv_gui_fnc_open;
 *
 * Public: Yes
 */

disableSerialization;

params ["_unit", ["_container", objNull], ["_secondary", objNull], ["_waited", 0, [0]], ["_guess", -1, [0]]];

if (!hasInterface || {!alive _unit}) exitWith {false};

// A guess gives way to the engine's own opening - the unit's handler was asked since the vanilla inventory came
// up - and to any other opening that waits for that display to go.
if (_guess >= 0 && {(GVAR(askedFrame) max GVAR(openWaiting)) >= _guess}) exitWith {
    INFO("The unit's handler was asked, or another opening waits, while the window waited to open on a guess - the guess gives way to it.");
    false
};

// One window at a time. An opening that named a container and finds one made a moment before says so in the RPT.
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {
    if (!isNull _container) then {
        private _named = typeOf _container;

        INFO_1("refused: a window is open already - %1 does not open in it.",_named);
    };

    false
};

private _vanilla = findDisplay IDD_VANILLA_INVENTORY;

// Vanilla inventories the guard closed that are not gone yet - whether findDisplay still lists them or not.
private _closing = (uiNamespace getVariable [QGVAR(closing), []]) select {!isNull _x};

uiNamespace setVariable [QGVAR(closing), _closing];

private _wait = !isNull _vanilla || {_closing isNotEqualTo []};

// Out of frames, with nothing the engine lists any more: the held ones are on their way out and no parent
// to a new dialog.
if (_wait && {_waited >= OPEN_TRIES} && {isNull _vanilla}) then {
    INFO("A closed vanilla inventory is still held but no longer listed - opening the window anyway.");
    _wait = false;
};

if (_wait) exitWith {
    // An opening that was asked for waits: a guess the guard makes meanwhile gives way to it (fnc_guardVanilla).
    if (_guess < 0) then {
        GVAR(openWaiting) = diag_frameNo;
    };

    if (!isNull _vanilla) then {
        [_vanilla] call FUNC(guardVanilla);
    };

    if (_waited >= OPEN_TRIES) exitWith {
        ERROR("The vanilla inventory does not close - another mod keeps opening it. The window stays closed.");
        false
    };

    if (_waited == 0) then {
        INFO("The vanilla inventory is open or closing as the window should open - opening the window a frame later.");
    };

    [{_this call FUNC(open)}, [_unit, _container, _secondary, _waited + 1, _guess]] call CBA_fnc_execNextFrame;
    true
};

if !(createDialog "EINV_InventoryDialog") exitWith {
    ERROR("Could not create the inventory dialog.");
    false
};

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (isNull _display) exitWith {false};

// A living person looked into, whole or by the backpack they wear: watched while the window is open
// (fnc_onFrame) - a crate stays where it is, a person walks off.
GVAR(person) = objNull;
GVAR(personMode) = "";

private _wearer = if (_container isKindOf "CAManBase") then {_container} else {objectParent _container};

if (alive _wearer && {_wearer isKindOf "CAManBase"} && {_wearer isNotEqualTo _unit}) then {
    if (_container isEqualTo _wearer) exitWith {
        GVAR(person) = _wearer;
        GVAR(personMode) = "whole";
    };

    if (_container isEqualTo backpackContainer _wearer) then {
        GVAR(person) = _wearer;
        GVAR(personMode) = "backpack";
    };
};

// The window itself: state, mouse, first build, frame - with no hooks, the plain inventory.
if !([_display, _unit, _container, _secondary, createHashMap, "pfh"] call FUNC(attach)) exitWith {
    ERROR("Could not attach the inventory window.");

    // This dialog by name, not the topmost one (closeDialog 0): that may be another mod's.
    GVAR(closeReason) = "the window could not attach (fnc_attach)";
    _display closeDisplay 2;
    false
};

// Made on a guess: the engine's opening that comes after it takes its place (fnc_onInventoryOpened).
GVAR(openGuess) = _guess >= 0;

// What it opened on, for the RPT: each container's class, its family (fnc_containerFamily: vehicle, crate,
// ground, body), its compartments as rows x cols (einv_storage_fnc_getBlocks - the ground's is open, it grows),
// its load, and what the window made of it: in the loot column, locked and why, the player's own gear, or no
// section at all - a pile with nothing in it has none, anything else without one was left out on the way.
private _lootSections = GVAR(context) getOrDefault ["lootSections", []];
private _ownSections = GVAR(context) getOrDefault ["ownSections", []];
private _described = ([_container, _secondary] select {!isNull _x}) apply {
    private _object = _x;
    private _grid = "worn";

    if !(_object isKindOf "CAManBase") then {
        private _blocks = [_object] call EFUNC(storage,getBlocks);

        _grid = if (_blocks isEqualTo []) then {
            "open"
        } else {
            (_blocks apply {format ["%1x%2", _x select 1, _x select 0]}) joinString "+"
        };
    };

    private _index = _lootSections findIf {
        (_x getOrDefault ["container", objNull]) isEqualTo _object
        || {(_x getOrDefault ["lockedObject", objNull]) isEqualTo _object}
        || {(_x getOrDefault ["unit", objNull]) isEqualTo _object}
    };

    private _state = switch (true) do {
        case (_index >= 0 && {(_lootSections select _index) getOrDefault ["locked", false]}): {
            format ["locked: %1", (_lootSections select _index) getOrDefault ["notice", ""]]
        };
        case (_index >= 0): {"shown"};
        case (_ownSections findIf {(_x getOrDefault ["container", objNull]) isEqualTo _object} >= 0): {"own gear"};
        default {"no section"};
    };

    format [
        "%1 kind %2 rows x cols %3 (load %4 - %5)",
        typeOf _object, [_object] call FUNC(containerFamily), _grid, [_object] call EFUNC(storage,getMaxLoad), _state
    ]
};

private _openedText = if (_described isEqualTo []) then {"nothing - own gear only"} else {_described joinString " + "};
private _openSeat = ["on foot", "seated in " + typeOf objectParent _unit] select !isNull objectParent _unit;
private _lootCount = count _lootSections;

INFO_3("open: %1 - the player %2 - %3 loot sections.",_openedText,_openSeat,_lootCount);

// Better Inventory (workshop 2791403093) moves a whole stack from its own put and take handlers while Shift or
// Ctrl is held, on state its vanilla display sets up - state this window never sets. Its handlers do nothing
// while the flag is 1 (released again in fnc_onUnload).
if (!isNil "bettInv_stackMove") then {
    bettInv_stackMove = 1;
};

// What the window was opened on - the soldier hears it open: the first of the container and the second that is
// somebody else's loot. Not the unit, not its own uniform,
// vest or backpack, and not the empty pile the engine makes at the feet for its ground panel - opening
// one's own gear is no looting. Not for a window that attaches with hooks (fnc_attach is all the Arsenal
// calls), which has no sound.
private _own = [uniformContainer _unit, vestContainer _unit, backpackContainer _unit];

GVAR(openedOn) = objNull;

{
    if (
        !isNull _x && {_x isNotEqualTo _unit} && {!(_x in _own)}
        && {!([_x] call EFUNC(storage,isGroundHolder)) || {([_x] call EFUNC(storage,getContents)) isNotEqualTo []}}
    ) exitWith {
        GVAR(openedOn) = _x;
    };
} forEach [_container, _secondary];

GVAR(openParent) = objectParent _unit;
GVAR(openPos) = getPosASL _unit;
GVAR(closeReason) = "";

// Moving stops looting (fnc_onKeyDown): which keys move, and which are held already as the window opens.
GVAR(moveKeys) = createHashMap;

{
    private _action = _x;

    {
        if (_x isEqualType 0 && {_x >= 0} && {_x < 256}) then {
            GVAR(moveKeys) set [_x, _action];
        };
    } forEach (actionKeys _action);
} forEach MOVE_ACTIONS;

GVAR(moveHeld) = MOVE_ACTIONS select {inputAction _x > 0};

_display displayAddEventHandler ["KeyUp", {
    params ["", "_key"];

    GVAR(moveHeld) = GVAR(moveHeld) - [GVAR(moveKeys) getOrDefault [_key, ""]];

    // The quick move key let go: the next press is the first of a hold again (fnc_onKeyDown).
    if (_key == GVAR(quickHeldKey)) then {
        GVAR(quickHeldKey) = -1;
    };

    false
}];

if (!isNull GVAR(openedOn) && {objectParent _unit isNotEqualTo GVAR(openedOn)}) then {
    ["open", "", GVAR(openedOn)] call FUNC(playSound);
};

true
