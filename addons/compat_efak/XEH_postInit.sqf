#include "script_component.hpp"

// Moves into, out of and between kits go through the storage's transactions (XEH_preInit): each kit op
// runs where the kit's root is local, checked there against what the kit holds at that moment, and what
// it takes out travels through the server's hub like any other payload - never lost. So nothing of this
// addon listens on the network; what follows only keeps the window up to date with Enhanced First Aid
// Kits.

if (!hasInterface) exitWith {};

// Enhanced First Aid Kits' own events. They only mark the window for a look: the mod raises them
// inside this addon's own writes - and on a host inside freeInstance - where nothing may be built
// yet. A move of this window builds right after its answer anyway; anything else - another player, a
// medic using a bandage, the mod's own kit window - shows within a frame. That mod registers its
// handlers in preInit, so its tables are up to date before these run. The inspect card shows a kit's
// weight and contents too, and is drawn anew only with the window: a kit inspected but not open - in a
// crate, inside another kit - would keep what it held. A kit's grid in ACE Arsenal's panel (GVAR(arsenalHolders)) is
// no open kit, and that mod's own kits tab fills it beside the panel: it is looked at the same way.
[QEFAKGVAR(core,contentsChanged), {
    params [["_class", "", [""]]];

    if (
        (GVAR(opened) findIf {_x == _class}) >= 0 || {(EGVAR(gui,inspect) param [0, ""]) == _class}
        || {toLowerANSI _class in GVAR(arsenalHolders)}
    ) then {
        call FUNC(requestRebuild);
    };
}] call CBA_fnc_addEventHandler;

// A kit's name shows on its tile wherever it lies.
[QEFAKGVAR(core,labelChanged), {
    call FUNC(requestRebuild);
}] call CBA_fnc_addEventHandler;

// A joining player's kits arrive from the server all at once: until then each one looks empty, and no
// kit may change through the window (fnc_notReady).
[QEFAKGVAR(core,syncAll), {
    call FUNC(requestRebuild);
}] call CBA_fnc_addEventHandler;

// A kit type's settings - its capacity, its name, whether packing is on - or whether kits may go into
// kits at all.
["CBA_SettingChanged", {
    params [["_setting", "", [""]]];

    if ((_setting select [0, 14]) == "efak_core_kit_" || {_setting == QEFAKGVAR(core,allowNesting)}) then {
        call FUNC(requestRebuild);
    };
}] call CBA_fnc_addEventHandler;
