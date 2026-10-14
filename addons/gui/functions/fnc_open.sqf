#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Opens the inventory window for a unit and what it looks into - the containers the engine named when
 * the inventory was asked for (fnc_onInventoryOpened) - and builds it in the player's chosen look: makes
 * the dialog, notes the living person looked into and hands the display to fnc_attach, which does the
 * rest, with no hooks - the inventory itself.
 *
 * Should the window not open, the vanilla inventory does instead: a player must never be left without
 * any inventory at all.
 *
 * A living person looked into - whole, or by the backpack they wear - is kept apart (GVAR(person),
 * GVAR(personMode)): they walk off by themselves, so fnc_onFrame watches them.
 *
 * What it was opened on - a crate, vehicle, body, person or pile, not the player's own gear - is noted
 * (GVAR(openedOn)): the soldier takes the looting pose (fnc_poseStart), the container opens with a sound,
 * and a movement key closes the window (fnc_onKeyDown). The stance, vehicle and place he had are kept for
 * the end (fnc_poseEnd, fnc_poseCheck).
 *
 * Nothing the last window waited for carries over (fnc_attach). A hint left for this opening
 * (GVAR(openHint), fnc_onInventoryOpened) shows once the window is up.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container the unit opened, or objNull <OBJECT>
 * 2: Second container (the ground next to a crate), or objNull <OBJECT>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [player, cursorObject, objNull] call einv_gui_fnc_open;
 *
 * Public: Yes
 */

disableSerialization;

params ["_unit", ["_container", objNull], ["_secondary", objNull]];

if (!hasInterface || {!alive _unit}) exitWith {false};
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {false};

if !(createDialog "EINV_InventoryDialog") exitWith {
    ERROR("Could not create the inventory dialog - opening the vanilla inventory instead.");
    [_unit, _container] call FUNC(openVanilla);
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
    ERROR("Could not attach the inventory window - opening the vanilla inventory instead.");
    closeDialog 0;
    [_unit, _container] call FUNC(openVanilla);
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

// What this opening has to say, once (fnc_onInventoryOpened). The build already looked at what the mouse
// is on (fnc_drawTopLayer), so the first frame finds nothing new there to write over it.
if (GVAR(openHint) isNotEqualTo "") then {
    [GVAR(openHint)] call FUNC(flashHint);
    GVAR(openHint) = "";
};

true
