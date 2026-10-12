#include "script_component.hpp"

if (isServer) then {
    // A client asking to lock or open something (fnc_setLock).
    [QGVAR(set), {_this call FUNC(setLock)}] call CBA_fnc_addEventHandler;

    // Eden's values, now that every object has run its attributes (fnc_applyEden).
    call FUNC(applyEden);
};

// Nothing below runs on a dedicated server or a headless client: the engine's own inventory is locked
// per player, on the player's own machine.
if (!hasInterface) exitWith {};

// A lock changed (fnc_setLock raises this on every machine, after the list went out).
[QGVAR(changed), {
    params ["_object"];

    [_object] call FUNC(refresh);
    GVAR(stamp) = GVAR(stamp) + 1;
}] call CBA_fnc_addEventHandler;

// What a joining player received with the mission's variables, and whatever changes about the player
// afterwards.
call FUNC(refreshAll);
[{call FUNC(refreshAll)}, LOCK_RECHECK] call CBA_fnc_addPerFrameHandler;
