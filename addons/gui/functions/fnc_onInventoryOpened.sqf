#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The unit's InventoryOpened handler: opens this window instead of the vanilla inventory.
 *
 * The vanilla inventory never opens: the handler fnc_initUnit puts on the unit answers the engine with
 * true whatever happens here, which keeps the display away, and a display that comes up anyway is closed
 * (fnc_guardVanilla). Where this window cannot open - the unit is not the player's, the player is not
 * allowed in - nothing opens at all. The window itself opens a frame later - the engine is still in the
 * middle of handling the key or the action that asked for the inventory.
 *
 * A living person opened by the engine looks into the whole person, as far as the settings allow
 * (fnc_canOpenPerson): ACE's "Inventory" on the unconscious names the unit itself, the engine's
 * backpack action - ACE's backpack interaction, a script - the backpack they wear. ACE dragging clones,
 * persons a mission closed and persons out of reach (fnc_personInReach) open nothing. A body opened by
 * the backpack it wears - ACE's "Open <backpack>" on the dead, a script - is the whole body as well,
 * the way its "Inventory" opens it: bodies are open to everyone, so nothing is asked.
 *
 * What is locked to the player (einv_locks_fnc_canReach: a lock of a side, a group or the admins, a
 * mission's lockInventory, ACE's vehicle lock) is asked first. The engine's own lock keeps the player out
 * of it already, this window is for a lock set a moment ago and for any script that asks the engine
 * anyway: ACE's click sounds, as for a locked vehicle, and the window opens all the same and shows the
 * container as a locked section - the player sees why.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container it opened, or objNull <OBJECT>
 * 2: Second container (the ground next to a crate), or objNull <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, cursorObject, objNull] call einv_gui_fnc_onInventoryOpened;
 *
 * Public: No
 */

params ["_unit", ["_container", objNull], ["_secondary", objNull]];

// A soldier the player no longer is - the body a team switch left behind, a unit a script ran the action on:
// there is no window for it.
if (_unit isNotEqualTo ACE_player) exitWith {};

// Locked to this player (einv_locks). The engine's own lock keeps them out already; this is for a lock set a
// moment ago and for any script that asks the engine anyway. ACE's click, as for a locked vehicle.
private _refused = [_container, _secondary] select {!isNull _x && {!(([_unit, _x] call EFUNC(locks,canReach)) select 0)}};

if (_refused isNotEqualTo []) then {
    playSound "ACE_Sound_Click";
};

// Already open: the engine asked again, from a script or a second key press. One window is enough.
if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {};

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
};

// Out of reach by the window's own rule (fnc_personInReach): claimed by someone else - dragged, carried,
// escorted - or the player dragging or carrying them. ACE medical's "Inventory" asks none of that, and
// the window would close again at its first check, the person told for nothing.
if (!isNull _person && {!([_unit, _person, true] call FUNC(personInReach))}) exitWith {
    [LLSTRING(Hint_OutOfReach)] call ACEFUNC(common,displayTextStructured);
};

if (!isNull _person) then {
    // What the engine named beside the person - the ground at the player's feet - stays beside them.
    private _rest = [_container, _secondary] select {
        !isNull _x && {!(_x in [_person, uniformContainer _person, vestContainer _person, backpackContainer _person])}
    };

    _container = [backpackContainer _person, _person] select (_mode isEqualTo "whole");
    _secondary = _rest param [0, objNull];
};

[{
    params ["_unit", "_container", "_secondary", "_person", "_zipped"];

    if ([_unit, _container, _secondary] call FUNC(open) && {!isNull _person}) then {
        [_unit, _person, _zipped] call FUNC(notifyPerson);
    };
}, [_unit, _container, _secondary, _person, _zipped]] call CBA_fnc_execNextFrame;
