#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Closes the vanilla inventory (RscDisplayInventory) the moment it is on the screen. The mod has no
 * vanilla inventory to fall back to, with the window open or not: whatever brought one up is undone here.
 *
 * The window replaces the vanilla inventory for good. The unit's handler answers the engine with true
 * (fnc_initUnit, fnc_onInventoryOpened) and no display opens - but another mod can still bring one up
 * behind that answer: Better Inventory (workshop 2791403093) patches the display itself and runs its
 * own handler on the same event, a handler of another mod may answer for the engine after this one, and
 * any mod or script can open it by createDialog or an action. Left alone, it would appear over the window
 * or in its place.
 *
 * Three places call it, so no way in leaves the display open: the display's load event
 * (Extended_DisplayLoad_EventHandlers, argument 0 is the display), a check every GUARD_INTERVAL seconds
 * on every client (XEH_postInit) for one that loaded without raising the event, and fnc_onFrame while
 * the window is open. Its controls are hidden first, so nothing of it is drawn before it is gone.
 *
 * Only the vanilla inventory, by its IDD 602 (findDisplay): a display handed in that is something else -
 * another mod's display built from RscDisplayInventory's class raises the same load event - is not closed,
 * and neither is the window itself or anything over it (a cutRsc layer, a sound mod's resource, another
 * mod's dialog). With no IDD 602 open nothing is closed.
 *
 * Over the window, beside it or with no window open, the vanilla inventory goes and the window stays. Under
 * it - the window was made as its child dialog - it cannot go alone: a child closes with its parent. Then
 * both go, the RPT says so ("window closed: ..."), and the window opens again a frame later on the same
 * unit and containers, at most once every REOPEN_PAUSE seconds (fnc_open waits for the vanilla one to be
 * gone first, so this is the last resort).
 *
 * Arguments:
 * 0: The vanilla inventory <DISPLAY> (default: the one open, if any)
 *
 * Return Value:
 * Closed <BOOL>
 *
 * Example:
 * [findDisplay 602] call einv_gui_fnc_guardVanilla;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (!hasInterface) exitWith {false};

if (isNull _display || {ctrlIDD _display != IDD_VANILLA_INVENTORY}) then {
    _display = findDisplay IDD_VANILLA_INVENTORY;
};

if (isNull _display) exitWith {false};

private _window = uiNamespace getVariable [QGVAR(display), displayNull];

if (_display isEqualTo _window) exitWith {false};

// Where it stands to the window: the window's parents up to the mission's display.
private _under = false;
private _parent = displayParent _window;

while {!isNull _parent} do {
    if (_parent isEqualTo _display) exitWith {
        _under = true;
    };

    _parent = displayParent _parent;
};

private _where = switch (true) do {
    case (isNull _window): {"no window open"};
    case (_under): {"under the window - the window closes with it and opens again"};
    case (displayParent _display isEqualTo _window): {"over the window"};
    default {"beside the window"};
};

// Once for each display that came up: the load event, the frame's check and the guard's own second close
// all find the same one.
if !(_display isEqualTo (uiNamespace getVariable [QGVAR(guardLast), displayNull])) then {
    uiNamespace setVariable [QGVAR(guardLast), _display];
    INFO_1("The vanilla inventory (IDD 602) came up - another mod or a script opened it - %1. Closing it.",_where);
};

if (_under) then {
    private _back = [GVAR(unit), GVAR(container), GVAR(secondary)];
    private _again = (call FUNC(isInventoryMode)) && {diag_tickTime > (missionNamespace getVariable [QGVAR(reopenedAt), -1e9]) + REOPEN_PAUSE};

    GVAR(closeReason) = "the vanilla inventory under it was closed (fnc_guardVanilla)";

    if (_again) then {
        GVAR(reopenedAt) = diag_tickTime;
        GVAR(cameraNext) = GVAR(cameraOn);

        [{
            params ["_unit", "_container", "_secondary"];

            if (alive _unit && {_unit isEqualTo ACE_player} && {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) then {
                [_unit, _container, _secondary] call FUNC(open);
            };
        }, _back] call CBA_fnc_execNextFrame;
    };
};

{
    _x ctrlShow false;
} forEach allControls _display;

_display closeDisplay 2;

// Still there a frame later (closed inside its own load event, or by something that opens it again).
[{
    if (!isNull _this) then {
        _this closeDisplay 2;
    };
}, _display] call FUNC(later);

true
