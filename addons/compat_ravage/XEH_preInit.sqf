#include "script_component.hpp"

ADDON = false;

// A pile Ravage's search made and has not filled yet (_uncheckedLoot): its own handler (fnc_checkLoot, spawned
// from the player's InventoryOpened) fills it and opens it again - the window waits for that asking. Only while
// that handler is there (fnc_checkLoot, set by Ravage's player scripts): without it the pile would never be
// asked for again, and it opens as it is.
EGVAR(gui,openingHolds) pushBack {
    params ["", "_container"];

    !isNull _container && {!isNil "fnc_checkLoot"} && {!isNil {_container getVariable "_uncheckedLoot"}}
};

ADDON = true;
