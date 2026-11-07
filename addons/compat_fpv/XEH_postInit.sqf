#include "script_component.hpp"

// Ukraine FPV Drone turns its item into a drone from the player's "Put" event: the item lands on a plain
// GroundWeaponHolder and its function UA_fnc_fpv_createUavOnItemCheck removes it and creates the drone. This window puts
// things on the ground through the storage (a scripted pile, no engine "Put"), so the storage's event is answered here
// instead: raised where the pile is made (the server), the item taken out of the pile there and the drone deployed by the
// mod's own function on the machine of the unit that dropped it - the machine the mod runs it on.
[QEGVAR(storage,groundPut), {_this call FUNC(onGroundPut)}] call CBA_fnc_addEventHandler;

// On the unit's machine: the drone is deployed.
[QGVAR(deploy), {_this call FUNC(deploy)}] call CBA_fnc_addEventHandler;

// The mod's own way back is its ACE interaction, which asks the engine whether the item fits (canAdd - this window lets
// the containers exceed the config load, so the answer is often no) and then only says there is no room. This entry
// shows just then, and asks the grid instead. The mod has no way back without ACE, so neither has this.
if (hasInterface && {isClass (configFile >> "CfgPatches" >> "ace_interact_menu")}) then {
    private _action = [
        QGVAR(pack),
        LLSTRING(Action_PackUp),
        "",
        {_this call FUNC(packStatement)},
        {_this call FUNC(packCondition)}
    ] call ACEFUNC(interact_menu,createAction);

    ["ua_drone_base_F", 0, ["ACE_MainActions"], _action, true] call ACEFUNC(interact_menu,addActionToClass);
};
