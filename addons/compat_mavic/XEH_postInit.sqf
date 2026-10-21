#include "script_component.hpp"

// Mavic 3 (Improved) turns its item into a drone from the player's "Put" event: the item lands on a plain
// GroundWeaponHolder and its function Mavic_fnc_createMavicOnItemCheck removes it and creates the drone. This
// window puts things on the ground through the storage (a scripted pile, no engine "Put"), so the storage's
// event is answered here instead: raised where the pile is made (the server), the item taken out of the pile
// there and the drone deployed by the mod's own function on the machine of the unit that dropped it - the
// machine the mod runs it on.
[QEGVAR(storage,groundPut), {_this call FUNC(onGroundPut)}] call CBA_fnc_addEventHandler;

// On the unit's machine: the drone is deployed.
[QGVAR(deploy), {_this call FUNC(deploy)}] call CBA_fnc_addEventHandler;

// ACE interaction on a deployed drone > Pack up drone. The mod's own way back is a vanilla user action whose
// check asks the engine whether the item fits (canAdd - this window lets the containers exceed the config load,
// so the answer is often no) and whose statement adds the item by the engine and deletes the drone whether it
// arrived or not; mirrored into ACE's menu by other mods it did nothing for the tester. This entry asks the
// grid for room instead and sees to it that the item arrives (fnc_packStatement). The mod's own function
// does the rest (grenades, the terminal, the crew).
if (hasInterface) then {
    private _action = [
        QGVAR(pack),
        LLSTRING(Action_PackUp),
        "\A3\ui_f\data\igui\cfg\actions\take_ca.paa",
        {_this call FUNC(packStatement)},
        {_this call FUNC(packCondition)},
        {},
        [],
        {[0, 0, 0]},
        3
    ] call ACEFUNC(interact_menu,createAction);

    {
        [_x, 0, ["ACE_MainActions"], _action] call ACEFUNC(interact_menu,addActionToClass);
    } forEach ["Mavic3_drone_base_F", "Mavic3T_drone_base_F", "Mavic3N_drone_base_F", "Mavic3X_drone_base_F"];
};
