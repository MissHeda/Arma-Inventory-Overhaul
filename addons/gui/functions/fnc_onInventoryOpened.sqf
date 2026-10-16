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
 * On foot, an opening that names nothing to loot - nothing, or only the empty pile the engine makes at the
 * feet - takes in the vehicle the player looks at, when the window may open on it (fnc_canOpenVehicle):
 * the vanilla inventory shows the vehicle there, and an engine or a script that names none would leave
 * the window on the soldier's own gear.
 *
 * What the engine names always wins over a guess. A window the guard opened in place of a vanilla
 * inventory that came up before this handler was asked (fnc_guardVanilla: on the soldier's own gear, or
 * the vehicle he sits in or looks at) closes when the engine now names something to loot - a vehicle, a
 * crate, a body - and the window opens again a frame later on that (fnc_open, GVAR(openGuess)).
 *
 * Each asking is one line in the RPT ("asked: <container> - beside it <second> - the player on foot or
 * seated in <vehicle>"), and each refusal one more ("refused: ..." and why): a report that a container
 * does not open then says whether the engine asked at all, and where it stopped.
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

// That this handler was asked, and when: a vanilla inventory that comes up right after it did so although the
// handler answered, which fnc_guardVanilla tells from one this handler never heard of. Before everything
// else here, for a unit that is not the player's and an opening that is refused as well.
GVAR(askedFrame) = diag_frameNo;

// What the engine named, one line per asking: a container that "does not open" shows in the RPT whether the
// engine asked at all, with what, and where the player was - on foot or in a seat.
private _named = [_container, _secondary] apply {["nothing", typeOf _x] select !isNull _x};
private _seat = ["on foot", "seated in " + typeOf objectParent _unit] select !isNull objectParent _unit;

INFO_3("asked: %1 - beside it %2 - the player %3.",_named select 0,_named select 1,_seat);

// A soldier the player no longer is - the body a team switch left behind, a unit a script ran the action on:
// there is no window for it.
if (_unit isNotEqualTo ACE_player) exitWith {
    INFO_1("refused: %1 is not the player's unit (ACE_player) - nothing opens.",typeOf _unit);
};

// What the engine named to loot, the first of it: not the soldier's own, not the empty pile the engine makes at
// the feet for its ground panel.
private _own = [_unit, uniformContainer _unit, vestContainer _unit, backpackContainer _unit];
private _loot = ([_container, _secondary] select {
    !isNull _x && {!(_x in _own)}
    && {!([_x] call EFUNC(storage,isGroundHolder)) || {([_x] call EFUNC(storage,getContents)) isNotEqualTo []}}
}) param [0, objNull];
private _namesLoot = !isNull _loot;

// On foot with nothing to loot named - nothing at all, or only the empty pile at the feet: the vehicle the
// player looks at joins, when the window may open on it (fnc_canOpenVehicle: in the window's reach, cells to
// show, not locked to him). The engine names a vehicle itself when the player stands at it; this is for an
// opening that named none - a script's action ["Gear", objNull], an engine that passed only the unit. What
// he looks at only, as the Gear key aims: never a vehicle behind him.
if (isNull objectParent _unit && {!_namesLoot}) then {
    private _looked = cursorObject;

    if ([_unit, _looked] call FUNC(canOpenVehicle)) then {
        INFO_1("added: %1 - the player looks at it in reach and the engine named nothing to loot.",typeOf _looked);

        // The pile at the feet stays beside it.
        _secondary = ([_container, _secondary] select {!isNull _x && {!(_x in _own)}}) param [0, objNull];
        _container = _looked;

        // It is the loot of this opening now: a window opened on a guess without it gives way to it (below).
        _loot = _looked;
        _namesLoot = true;
    };
};

// Locked to this player (einv_locks). The engine's own lock keeps them out already; this is for a lock set a
// moment ago and for any script that asks the engine anyway. ACE's click, as for a locked vehicle. The window
// opens all the same and shows it as a locked section; the RPT says why.
private _refused = [];

{
    if (!isNull _x) then {
        ([_unit, _x] call EFUNC(locks,canReach)) params ["_reachable", "_why"];

        if (!_reachable) then {
            _refused pushBack _x;
            INFO_2("refused: %1 is locked to this player (%2) - shown as a locked section.",typeOf _x,_why);
        };
    };
} forEach [_container, _secondary];

if (_refused isNotEqualTo []) then {
    playSound "ACE_Sound_Click";
};

// A window the guard opened on a guess - a vanilla inventory came up before the engine asked this handler, and
// the window took its place on the soldier's own gear or the vehicle he sat in or looked at (fnc_guardVanilla) -
// gives way when the engine names something to loot now that it does not show, or the vehicle the player looks
// at joined this opening (above): what was asked for wins.
// It closes, and the window opens again a frame later on what was named, as below - the inventory's window
// only, never a window of another mod this addon is a guest on.
private _window = uiNamespace getVariable [QGVAR(display), displayNull];

if (!isNull _window && {GVAR(openGuess)} && {_namesLoot} && {call FUNC(isInventoryMode)}) then {
    GVAR(openGuess) = false;

    // The guess was right: the window shows it already.
    if (_loot in [GVAR(container), GVAR(secondary)]) exitWith {};

    private _lootClass = typeOf _loot;

    INFO_1("replaced: the window opened on a guess gives way to %1 - the engine asked for it.",_lootClass);

    ["it gave way to what the engine asked for (fnc_onInventoryOpened)"] call FUNC(closeDisplay);
    _window = displayNull;
};

// Already open: the engine asked again, from a script or a second key press. One window is enough.
if (!isNull _window) exitWith {
    INFO("refused: the window is open already - nothing more opens.");
};

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
    INFO_1("refused: %1 may not be opened (a dragging clone or einv_noAccess) - nothing opens.",typeOf _person);
    [LLSTRING(Hint_NoAccess)] call ACEFUNC(common,displayTextStructured);
};

// Out of reach by the window's own rule (fnc_personInReach): claimed by someone else - dragged, carried,
// escorted - or the player dragging or carrying them. ACE medical's "Inventory" asks none of that, and
// the window would close again at its first check, the person told for nothing.
if (!isNull _person && {!([_unit, _person, true] call FUNC(personInReach))}) exitWith {
    INFO_1("refused: %1 is out of reach - nothing opens.",typeOf _person);
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
