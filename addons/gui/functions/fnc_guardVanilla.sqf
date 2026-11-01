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
 * own handler on the same event, SFX Project: Remastered (2129532219) adds a handler of its own that
 * answers nothing, a handler of another mod may answer for the engine after this one, and any mod or
 * script can open it by createDialog or an action. Left alone, it would appear over the window or in its
 * place.
 *
 * Three places call it, so no way in leaves the display open: the display's load event
 * (Extended_DisplayLoad_EventHandlers, argument 0 is the display), a check every GUARD_INTERVAL seconds
 * on every client (XEH_postInit) for one that loaded without raising the event, and fnc_onFrame while
 * the window is open. Its controls are hidden first, so nothing of it is drawn before it is gone.
 *
 * Only the vanilla inventory, by its IDD 602 (findDisplay): a display handed in that is something else -
 * another mod's display built from RscDisplayInventory's class raises the same load event - is not closed,
 * and neither is the window itself or anything over it (a cutRsc layer, a sound mod's resource, another
 * mod's dialog). With no IDD 602 open nothing is closed. Always the display object itself, never
 * closeDialog (which closes whatever dialog is topmost, maybe the window).
 *
 * The first time a display comes up it is told in the RPT with where it stood, and whether the unit's
 * handler had answered for it a moment before (askedFrame, set by fnc_onInventoryOpened):
 *  - It had: another handler's answer let the engine open the display for all that this one said true.
 *    The window is opening already (fnc_onInventoryOpened); the handler is put behind the others again
 *    (fnc_initUnit) so the next opening is answered by it last - at most every HANDLER_PAUSE seconds.
 *  - It had not: nobody asked for the window - the handler was taken off by a script, the unit is not one
 *    the handler was put on yet, a script opened the display by createDialog. The handler is put on again,
 *    and with no window open the window opens in the vanilla inventory's place, on the player's own gear -
 *    and, seated, on the vehicle's cargo, which is what the vanilla inventory shows in a seat; on foot on
 *    the vehicle the player looks at, when the window may open on it (fnc_canOpenVehicle). That is a guess,
 *    and what the engine names always wins over it: the guess is made a frame later and only when the
 *    handler was not asked in the frame the display came up or since (the engine may raise the display's
 *    load before its event); it gives way while it waits for the display to go (fnc_open), and a window
 *    already open on it closes for the engine's opening (fnc_onInventoryOpened).
 *
 * The close is made twice, in the load event and a frame later (a display closed inside its own load event
 * is not always gone): the second time through this function again, so it too looks where the window
 * stands. A display closed once is kept in uiNamespace until it is gone (fnc_open makes no window while
 * one is), as the engine may no longer list it and still hold it.
 *
 * Over the window, beside it or with no window open, the vanilla inventory goes and the window stays. Under
 * it - the window was made as its child dialog - it cannot go alone: a child closes with its parent. Then
 * both go, the RPT says so ("window closed: ..."), and the window opens again a frame later on the same
 * unit and containers, at most once every REOPEN_PAUSE seconds (fnc_open waits for the vanilla one to be
 * gone first, so this is the last resort).
 *
 * Arguments:
 * 0: The vanilla inventory <DISPLAY> (default: the one open, if any)
 * 1: The second pass, a frame after the first - schedules nothing more <BOOL> (default: false)
 *
 * Return Value:
 * Closed <BOOL>
 *
 * Example:
 * [findDisplay 602] call aio_gui_fnc_guardVanilla;
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_second", false, [false]]];

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
if (_display isNotEqualTo (uiNamespace getVariable [QGVAR(guardLast), displayNull])) then {
    uiNamespace setVariable [QGVAR(guardLast), _display];

    // Did the unit's handler answer for this opening a moment ago?
    private _asked = (diag_frameNo - GVAR(askedFrame)) <= ASK_FRAMES;

    private _how = [
        "The unit's handler was not asked for it.",
        "The unit's handler had answered true for it - another handler's answer let it open."
    ] select _asked;

    INFO_2("The vanilla inventory (IDD 602) came up - another mod or a script opened it - %1. %2 Closing it.",_where,_how);

    // The handler behind the others again, so the next opening is answered by it last. Not more often than
    // HANDLER_PAUSE, so two mods that both want the last place cannot loop.
    if (diag_tickTime > GVAR(handlerAgain) + HANDLER_PAUSE) then {
        GVAR(handlerAgain) = diag_tickTime;

        INFO("The unit handler goes behind the other handlers of the event again.");

        [PLAYER_UNIT, true] call FUNC(initUnit);
    };

    // Nobody asked for the window, so nothing is opening it: it opens in the vanilla inventory's place - on
    // the player's own gear, the display says nothing of what it was opened on. Seated, on the vehicle as
    // well, when it has a cargo space: in a seat the vanilla inventory is the vehicle's cargo, and a window
    // without it leaves the vehicle out. On foot, on the vehicle he looks at when the window may open on it
    // (fnc_canOpenVehicle), as the vanilla inventory shows it there. Not for a player who is out cold.
    // fnc_open waits until the display is gone.
    //
    // Only a guess, and the engine's own opening wins over it: should the unit's handler be asked in the frame
    // the display came up or since - the engine raised the display's load before its event, or the event came
    // a moment late - that opening names what was opened (the vehicle, the crate) and is on its way, and this
    // one would take its place with the soldier's own gear. So the guess is made a frame later and only if
    // the handler was not asked by then, nor another opening waits for this display to go (fnc_open's retry
    // is queued after this call); it gives way while it waits (fnc_open), and a window it made closes for
    // the engine's opening (fnc_onInventoryOpened).
    if (!_asked && {isNull _window}) then {
        INFO("Nothing asked for the window - opening it in place of the vanilla inventory, unless the unit's handler is asked meanwhile.");

        [{
            params ["_cameUp"];

            private _unit = PLAYER_UNIT;

            if ((GVAR(askedFrame) max GVAR(openWaiting)) >= _cameUp) exitWith {
                INFO("The unit's handler was asked after the vanilla inventory came up, or an opening waits for it to go - that opening goes ahead, nothing is guessed.");
            };

            if (
                !isNull _unit && {alive _unit} && {!(_unit getVariable ["ACE_isUnconscious", false])}
                && {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}
            ) then {
                private _vehicle = objectParent _unit;

                if (!isNull _vehicle && {([_vehicle] call EFUNC(storage,getMaxLoad)) <= 0}) then {
                    _vehicle = objNull;
                };

                // On foot: the vehicle he looks at, when the window may open on it (fnc_canOpenVehicle).
                if (isNull objectParent _unit && {[_unit, cursorObject] call FUNC(canOpenVehicle)}) then {
                    _vehicle = cursorObject;
                };

                if (!isNull _vehicle) then {
                    INFO_1("The window opens on %1 as well - the vehicle the player sits in or looks at.",typeOf _vehicle);
                };

                [_unit, _vehicle, objNull, 0, _cameUp] call FUNC(open);
            };
        }, [diag_frameNo]] call FUNC(later);
    };
};

if (_under) then {
    private _back = [GVAR(unit), GVAR(container), GVAR(secondary)];
    private _again = (call FUNC(isInventoryMode)) && {diag_tickTime > (missionNamespace getVariable [QGVAR(reopenedAt), -1e9]) + REOPEN_PAUSE};

    GVAR(closeReason) = "the vanilla inventory under it was closed (fnc_guardVanilla)";

    if (_again) then {
        GVAR(reopenedAt) = diag_tickTime;

        [{
            params ["_unit", "_container", "_secondary"];

            if (alive _unit && {_unit isEqualTo PLAYER_UNIT} && {isNull (uiNamespace getVariable [QGVAR(display), displayNull])}) then {
                [_unit, _container, _secondary] call FUNC(open);
            };
        }, _back] call CBA_fnc_execNextFrame;
    };
};

{
    _x ctrlShow false;
} forEach allControls _display;

_display closeDisplay 2;

// Held until it is gone: the engine may no longer list a display that is closing (findDisplay) and still
// have it, and a window made then is its child and goes with it (fnc_open).
private _closing = (uiNamespace getVariable [QGVAR(closing), []]) select {!isNull _x};

_closing pushBackUnique _display;
uiNamespace setVariable [QGVAR(closing), _closing];

// Still there a frame later (closed inside its own load event, or by something that opens it again). The
// same function again, not a bare close: the window may have been made meanwhile, and a close of a display
// it hangs under must be told and followed by the window opening again, not happen unseen.
if (!_second) then {
    [{
        if (!isNull _this) then {
            [_this, true] call FUNC(guardVanilla);
        };
    }, _display] call FUNC(later);
};

true
