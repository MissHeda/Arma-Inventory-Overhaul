#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The unit's InventoryOpened handler: opens this window instead of the vanilla inventory.
 *
 * Answering true keeps the vanilla display from opening. The window itself opens a frame later -
 * the engine is still in the middle of handling the key or the action that asked for the inventory.
 *
 * A living person opened by the engine looks into the whole person, as far as the settings allow
 * (fnc_canOpenPerson): ACE's "Inventory" on the unconscious names the unit itself, the engine's
 * backpack action - ACE's backpack interaction, a script - the backpack they wear. ACE dragging clones,
 * persons a mission closed and persons out of reach (fnc_personInReach) open nothing. A body opened by
 * the backpack it wears - ACE's "Open <backpack>" on the dead, a script - is the whole body as well,
 * the way its "Inventory" opens it: bodies are open to everyone, so nothing is asked.
 *
 * With the window switched off (einv_gui_replaceVanilla) the vanilla inventory opens - in multiplayer
 * only on the player's own gear. Whatever other players can reach as well - a crate, a vehicle, a body,
 * a person, a pile with something in it - opens here all the same: the engine's own inventory is not
 * serialised with the authorities that change those containers, and two players taking the same item
 * there could both get it. The empty pile the engine makes at the player's feet for its ground panel
 * holds nothing anyone could take. Once a mission the window says why (GVAR(openHint), fnc_open).
 *
 * What is locked to the player (einv_locks_fnc_canReach: a lock of a side, a group or the admins, a
 * mission's lockInventory, ACE's vehicle lock) is asked first. The engine's own lock keeps the player out
 * of it already, this window is for a lock set a moment ago and for any script that asks the engine
 * anyway: ACE's click sounds, as for a locked vehicle. With the window on, it opens all the same and
 * shows the container as a locked section - the player sees why; with it switched off, the vanilla
 * inventory opens on the player's own gear instead.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container it opened, or objNull <OBJECT>
 * 2: Second container (the ground next to a crate), or objNull <OBJECT>
 *
 * Return Value:
 * Vanilla inventory blocked <BOOL>
 *
 * Example:
 * [player, cursorObject, objNull] call einv_gui_fnc_onInventoryOpened;
 *
 * Public: No
 */

params ["_unit", ["_container", objNull], ["_secondary", objNull]];

// Asked for on purpose, by fnc_openVanilla - when this window could not open.
if (diag_tickTime < GVAR(bypassUntil)) exitWith {
    GVAR(bypassUntil) = -1;
    false
};

// Locked to this player (einv_locks). The engine's own lock keeps them out already; this is for a lock set a
// moment ago and for any script that asks the engine anyway. ACE's click, as for a locked vehicle.
private _refused = [_container, _secondary] select {!isNull _x && {!(([_unit, _x] call EFUNC(locks,canReach)) select 0)}};

if (_refused isNotEqualTo [] && {_unit isEqualTo ACE_player}) then {
    playSound "ACE_Sound_Click";
};

// The vanilla inventory (this window switched off): on the player's own gear instead.
if (!GVAR(replaceVanilla) && {_refused isNotEqualTo []} && {_unit isEqualTo ACE_player}) exitWith {
    [{_this call FUNC(openVanilla)}, [_unit, objNull]] call CBA_fnc_execNextFrame;
    true
};

// Switched off: the vanilla inventory - in multiplayer only on the player's own gear. Anything another
// player can reach as well opens here: the engine's own inventory is not serialised with the authorities
// that change those containers. The pile the engine makes at the feet for its ground panel is empty -
// nothing to take twice there.
if (!GVAR(replaceVanilla) && {!isMultiplayer || {[_container, _secondary] findIf {
    !isNull _x
    && {!(_x in [_unit, uniformContainer _unit, vestContainer _unit, backpackContainer _unit])}
    && {!([_x] call EFUNC(storage,isGroundHolder)) || {([_x] call EFUNC(storage,getContents)) isNotEqualTo []}}
} < 0}}) exitWith {false};

if (_unit isNotEqualTo ACE_player) exitWith {false};

// Already open: the engine asked again, from a script or a second key press. One window is enough.
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {true};

// A living person, opened by the engine, first or beside the ground - or a body by its backpack.
private _person = objNull;
private _body = objNull;
private _zipped = false;

{
    private _wearer = if (_x isKindOf "CAManBase") then {_x} else {objectParent _x};

    // A body named itself is opened whole already, as the engine named it.
    if (
        _wearer isKindOf "CAManBase" && {_wearer isNotEqualTo _unit}
        && {_x isEqualTo backpackContainer _wearer || {_x isEqualTo _wearer && {alive _wearer}}}
    ) exitWith {
        if (!alive _wearer) exitWith {
            _body = _wearer;
        };

        _person = _wearer;

        // ACE zips for a backpack the engine opens first (ace_backpacks_fnc_onOpenInventory) - not again.
        _zipped = _forEachIndex == 0 && {_x isNotEqualTo _wearer};
    };
} forEach [_container, _secondary];

// A body by its backpack: the whole body, with what the engine named beside it - the ground at the
// player's feet. Mia, 2026-10-10: the same as on the living, where it once showed the backpack alone.
if (!isNull _body) then {
    private _rest = [_container, _secondary] select {
        !isNull _x && {!(_x in [_body, uniformContainer _body, vestContainer _body, backpackContainer _body])}
    };

    _container = _body;
    _secondary = _rest param [0, objNull];
};

private _mode = if (isNull _person) then {""} else {[_person] call FUNC(canOpenPerson)};

// An ACE dragging clone (a copy of a body's gear) or a person the mission closed: nothing opens.
if (!isNull _person && {_mode isEqualTo ""}) exitWith {
    [LLSTRING(Hint_NoAccess)] call ACEFUNC(common,displayTextStructured);
    true
};

// Out of reach by the window's own rule (fnc_personInReach): claimed by someone else - dragged, carried,
// escorted - or the player dragging or carrying them. ACE medical's "Inventory" asks none of that, and
// the window would close again at its first check, the person told for nothing.
if (!isNull _person && {!([_unit, _person, true] call FUNC(personInReach))}) exitWith {
    [LLSTRING(Hint_OutOfReach)] call ACEFUNC(common,displayTextStructured);
    true
};

if (!isNull _person) then {
    // What the engine named beside the person - the ground at the player's feet - stays beside them.
    private _rest = [_container, _secondary] select {
        !isNull _x && {!(_x in [_person, uniformContainer _person, vestContainer _person, backpackContainer _person])}
    };

    _container = [backpackContainer _person, _person] select (_mode isEqualTo "whole");
    _secondary = _rest param [0, objNull];
};

// A player who switched the window off and still finds it here is told why - once a mission, as the
// window comes up (fnc_open).
if (!GVAR(replaceVanilla) && {!GVAR(sharedHintShown)}) then {
    GVAR(sharedHintShown) = true;
    GVAR(openHint) = "SharedHere";
};

[{
    params ["_unit", "_container", "_secondary", "_person", "_zipped"];

    if ([_unit, _container, _secondary] call FUNC(open) && {!isNull _person}) then {
        [_unit, _person, _zipped] call FUNC(notifyPerson);
    };
}, [_unit, _container, _secondary, _person, _zipped]] call CBA_fnc_execNextFrame;

true
