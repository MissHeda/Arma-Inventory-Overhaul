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
 * (GVAR(openedOn)): the soldier takes the looting pose (fnc_poseStart), the container opens with a sound,
 * and a movement key closes the window (fnc_onKeyDown). The stance, vehicle and place he had are kept for
 * the end (fnc_poseEnd, fnc_poseCheck).
 *
 * Nothing the last window waited for carries over (fnc_attach). The camera on the soldier starts as the
 * player's setting says (einv_gui_cameraDefault); the header's button turns it for this window only - or
 * across a step aside for another mod's dialog (fnc_stepAside), which opens the same window again.
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
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container the unit opened, or objNull <OBJECT>
 * 2: Second container (the ground next to a crate), or objNull <OBJECT>
 * 3: Frames already waited for a vanilla inventory to go - for the call itself, which waits <NUMBER>
 *    (default: 0)
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

params ["_unit", ["_container", objNull], ["_secondary", objNull], ["_waited", 0, [0]]];

if (!hasInterface || {!alive _unit}) exitWith {false};
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {false};

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

    [{_this call FUNC(open)}, [_unit, _container, _secondary, _waited + 1]] call CBA_fnc_execNextFrame;
    true
};

// The camera as the player set it (einv_gui_cameraDefault), unless a step aside brings the window back as it was.
GVAR(cameraOn) = if (isNil QGVAR(cameraNext)) then {
    (missionNamespace getVariable [QGVAR(cameraDefault), "soldier"]) isEqualTo "soldier"
} else {
    GVAR(cameraNext)
};

GVAR(cameraNext) = nil;

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

// Better Inventory (workshop 2791403093) moves a whole stack from its own put and take handlers while Shift or
// Ctrl is held, on state its vanilla display sets up - state this window never sets. Its handlers do nothing
// while the flag is 1 (released again in fnc_onUnload).
if (!isNil "bettInv_stackMove") then {
    bettInv_stackMove = 1;
};

// What the window was opened on - the soldier looks into it, kneels at it, hears it open (fnc_poseStart): the
// first of the container and the second that is somebody else's loot. Not the unit, not its own uniform,
// vest or backpack, and not the empty pile the engine makes at the feet for its ground panel - opening
// one's own gear is no looting. Not for a window that attaches with hooks (fnc_attach is all the Arsenal
// calls), which has no pose and no sound.
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

GVAR(openStance) = stance _unit;

// How he held his weapon: the pose gives it back that way when the window closes (fnc_poseEnd).
GVAR(openLowered) = weaponLowered _unit;
GVAR(reloadHold) = 0;
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

    false
}];

GVAR(poseTried) = false;
[_unit, GVAR(openedOn)] call FUNC(poseStart);

if (!isNull GVAR(openedOn) && {objectParent _unit isNotEqualTo GVAR(openedOn)}) then {
    ["open", "", GVAR(openedOn)] call FUNC(playSound);
};

true
