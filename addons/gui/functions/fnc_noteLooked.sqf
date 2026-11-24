#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The player looked into a container that is not their own gear - searched something in it, lifted its seal, took
 * something out of it or put something in (fnc_animateSearch, fnc_afterAction). Once per window and root: the local
 * CBA event aio_gui_containerOpened, [unit, container, root] - root being the crate, vehicle, pile or body it belongs
 * to (aio_storage_fnc_rootOf). Other mods hear of it here what the engine's InventoryOpened tells them for the one
 * container it opens: a box looted from the window's nearby column never raises that (compat_antistasi: undercover).
 * The containers the engine opened the window on are noted already when it opens (fnc_attach): their InventoryOpened
 * was raised.
 *
 * Arguments:
 * 0: Container <OBJECT>
 *
 * Return Value:
 * The event was raised <BOOL>
 *
 * Example:
 * [_box] call aio_gui_fnc_noteLooked;
 *
 * Public: No
 */

params [["_container", objNull, [objNull]]];

if (isNull _container || {!(call FUNC(isInventoryMode))}) exitWith {false};

private _unit = GVAR(unit);

if (isNull _unit) exitWith {false};

private _root = [_container] call EFUNC(storage,rootOf);

if (isNull _root) then {
    _root = _container;
};

// The player's own gear is no one else's container.
if (_root isEqualTo _unit || {_root in GVAR(looked)}) exitWith {false};

GVAR(looked) pushBack _root;

[QGVAR(containerOpened), [_unit, _container, _root]] call CBA_fnc_localEvent;

true
