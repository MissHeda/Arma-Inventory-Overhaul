#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// What Ravage's "Search" does once it was held, made over (fnc_patchAction).
GVAR(onCompleted) = {call FUNC(search)};

// A pile Ravage's own search made and has not filled yet (_uncheckedLoot) - one started before its action was made
// over (fnc_patchAction), or by a mission's own copy of it: filled right here, by Ravage's own function (fnc_checkLoot), before the window opens on it. Ravage fills it from its own InventoryOpened handler, spawned - a
// moment later, by when the pile was gone: the engine opened its vanilla inventory on the empty pile first, the
// window closed that, and the engine deletes an empty pile whose inventory closes (in-game test 0.7.7: the pile was
// null at once, the window opened on the player's gear only - Discord reports 0.7.2 to 0.7.6). Filled now, it opens
// as any pile with something in it; Ravage's own handler then finds nothing left to fill, and its second asking for
// the pile finds the window open on it already.
EGVAR(gui,openingHolds) pushBack {
    params ["_unit", "_container", "_secondary"];

    if (isNil "fnc_checkLoot") exitWith {false};

    {
        if (!isNull _x && {!isNil {_x getVariable "_uncheckedLoot"}}) then {
            INFO_1("Ravage's search pile %1 filled now, before the window opens.",typeOf _x);
            [_unit, _x] call fnc_checkLoot;
        };
    } forEach [_container, _secondary];

    false
};

ADDON = true;
