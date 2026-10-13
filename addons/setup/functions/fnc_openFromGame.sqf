#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the setup wizard from a running mission - the keybind and the cog in the inventory's header. The
 * inventory window closes first: the two never share the screen. The wizard opens a frame later over the
 * game's own screen, in direct mode, so what it saves goes straight into CBA's settings.
 *
 * Opened from the inventory, the inventory comes back when the wizard closes, however it closes - the
 * player was busy with their gear and should not be left on the bare game. It comes back the way the
 * Gear key opens it, so the engine checks again what the player can still reach - or, for a living
 * person the player was looking into, the way the person action opens them (einv_gui_fnc_openPerson,
 * quiet: they were told already), which checks reach and permission again.
 *
 * Arguments:
 * 0: Step to open at, 0 (Start) to 3 (Review) <NUMBER> (default: 0)
 * 1: Class to look at in that step, "" for none <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [0, ""] call einv_setup_fnc_openFromGame;
 *
 * Public: No
 */

disableSerialization;

params [["_step", 0, [0]], ["_focusClass", "", [""]]];

if (!hasInterface) exitWith {};

// Already open: one wizard is enough.
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

// What the inventory showed, to open it again afterwards: whose it was and what it looked into. Read
// before it closes - its unload forgets the person (einv_gui_fnc_onUnload).
private _inventory = uiNamespace getVariable [QEGVAR(gui,display), displayNull];
private _return = [];

if (!isNull _inventory) then {
    _return = [EGVAR(gui,unit), EGVAR(gui,container), EGVAR(gui,person)];
    _inventory closeDisplay 2;
};

// A frame later, once the inventory is gone: a window made in the same frame as the last one closes
// does not reliably get the keyboard.
[{
    params ["_step", "_focusClass", "_return"];

    // Over Zeus while it is open, as ACE's Arsenal does - on the game's screen it would open behind it.
    private _parent = findDisplay 312;

    if (isNull _parent) then {
        _parent = findDisplay 46;
    };

    if (isNull _parent) exitWith {};

    private _display = [_parent, "direct", _step, _focusClass] call (missionNamespace getVariable [QFUNC(open), {}]);

    // The wizard did not open: the player gets their inventory back straight away.
    if (isNil "_display" || {!(_display isEqualType displayNull)} || {isNull _display}) exitWith {
        ERROR("The setup wizard did not open.");

        _return params [["_unit", objNull], ["_container", objNull], ["_person", objNull]];

        // A living person opens again as the person action opens them; out of reach by now or no longer
        // allowed, the player gets their own inventory.
        if (alive _person && {[_person, true] call EFUNC(gui,openPerson)}) exitWith {};

        if (alive _unit) then {
            _unit action ["Gear", [_container, objNull] select (alive _person)];
        };
    };

    if (_return isEqualTo []) exitWith {};

    // Who and what, as plain data in the mission namespace - never the display itself.
    GVAR(reopenInventory) = _return;

    _display displayAddEventHandler ["Unload", {
        private _return = missionNamespace getVariable [QGVAR(reopenInventory), []];
        GVAR(reopenInventory) = [];

        // A frame later again: the wizard is still on the screen while its unload handlers run. The
        // engine's own way to the inventory then, as the Gear key takes it - einv_gui takes over from
        // there. Not for a player who is someone else by now or dead, nor over an inventory already open.
        [{
            params [["_unit", objNull], ["_container", objNull], ["_person", objNull]];

            if (!alive _unit || {_unit isNotEqualTo ACE_player} || {isNull findDisplay 46}) exitWith {};
            if (!isNull (uiNamespace getVariable [QEGVAR(gui,display), displayNull])) exitWith {};

            // A living person: as the person action opens them, quietly - they were told already. Out of
            // reach by now or no longer allowed, the player's own inventory instead.
            if (alive _person && {[_person, true] call EFUNC(gui,openPerson)}) exitWith {};

            _unit action ["Gear", [_container, objNull] select (alive _person)];
        }, _return] call CBA_fnc_execNextFrame;
    }];
}, [_step, _focusClass, _return]] call CBA_fnc_execNextFrame;
