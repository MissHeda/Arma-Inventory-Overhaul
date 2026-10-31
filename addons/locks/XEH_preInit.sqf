#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Other mods' reasons to keep a player out of a container, CODE [unit, container] -> refusal text or ""
// (fnc_addProvider, fnc_canReach). aio_compat_ace_vehiclelock adds ACE's vehicle lock.
GVAR(providers) = [];

// Counts every change to the locks seen on this machine, so the window's signature changes with them
// (aio_gui_fnc_getSignature, later).
GVAR(stamp) = 0;

// Objects with a value from Eden's attributes, waiting for the server to make their lock once every
// object has its own (fnc_applyEden). The attribute expressions can run before this file does, so what
// they already queued stays.
if (isNil QGVAR(edenQueue)) then {
    GVAR(edenQueue) = [];
};

// The list of locked objects, aio_locks_objects, is not assigned here: it belongs to the server, and a
// client that joins later may already hold the server's value when this runs.

#include "initSettings.inc.sqf"

// Every op of a transaction asks this on the machine that runs it, whoever sent it and whatever the
// window showed (aio_storage_guards). Wrapped, so a recompiled function is the one that runs.
EGVAR(storage,guards) pushBack {_this call FUNC(guard)};

ADDON = true;
