#include "script_component.hpp"

if (!hasInterface) exitWith {};

// The weight of the second handgun is this mod's to count (aio_weight_fnc_getExtraLoad, "weighed" in
// aio_storage_secondHandgunMod), not KJW's: KJW adds it to ACE's virtual load when it hangs a holder on the player and
// takes it off again when it deletes one - by deltas, which drifted with every swap in KJW's Two Primary Weapons
// (0.7.3). A total worked out afresh each time cannot drift. KJW's own counting is switched off once its postInit set
// it, and what its holders hanging now added is taken off again once.
[{!isNil "KJW_TwoSecondaryWeapons_addACEweight"}, {
    if !(KJW_TwoSecondaryWeapons_addACEweight isEqualTo true) exitWith {};

    KJW_TwoSecondaryWeapons_addACEweight = false;

    private _unit = player;

    {
        private _mass = _x getVariable ["KJW_TwoSecondaryWeapons_mass", 0];

        if (_mass != 0 && {!isNil "ace_movement_fnc_addLoadToUnitContainer"}) then {
            [_unit, _unit, -_mass] call ace_movement_fnc_addLoadToUnitContainer;
        };

        _x setVariable ["KJW_TwoSecondaryWeapons_mass", 0];
    } forEach ((_unit getVariable ["KJW_TwoSecondaryWeapons_currentWeaponObjects", []]) select {!isNull _x});

    INFO("KJW's Two Secondary Weapons: the second handgun is weighed by this mod now (KJW's ACE weight switched off).");

    if (!isNil QEFUNC(weight,queueVirtualLoad)) then {
        call EFUNC(weight,queueVirtualLoad);
    };
}] call CBA_fnc_waitUntilAndExecute;
