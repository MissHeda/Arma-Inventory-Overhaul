#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// A pile Ravage's search made and has not filled yet (_uncheckedLoot): its own handler (fnc_checkLoot, spawned
// from the player's InventoryOpened) fills it and asks the engine to open it again. The window waits for that:
// this opening is held back. 0.7.2 relied on Ravage's second asking alone, and in some missions it never came
// through (Discord report with video, 0.7.2: the window opened on the player's gear only). So the pile is watched
// here as well (fnc_watchPile): once it is filled the window opens on it if Ravage's own asking has not opened it
// already, and a pile Ravage did not fill within a moment is filled by Ravage's own function first.
EGVAR(gui,openingHolds) pushBack {
    params ["_unit", "_container"];

    if (isNull _container || {isNil {_container getVariable "_uncheckedLoot"}}) exitWith {false};

    // Ravage's filling function is missing (its player scripts did not run): nothing would ever fill the
    // pile, and it opens as it is.
    if (isNil "fnc_checkLoot") exitWith {false};

    [_unit, _container] call FUNC(watchPile);

    true
};

ADDON = true;
