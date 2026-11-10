#include "script_component.hpp"

if (!hasInterface) exitWith {};

// The weight of the weapon on the back is this mod's to count (aio_weight_fnc_getExtraLoad, "weighed" in
// aio_storage_secondPrimaryMod), not KJW's. KJW adds it to ACE's virtual load when it hangs a holder on the
// player and takes it off again when it deletes one - by deltas, which drifted with every swap (Discord report,
// 0.7.3: the weight went down a little each time, until it was negative). A total worked out afresh each time
// cannot drift. KJW's own counting is switched off once its postInit set it, and what its holders hanging now
// added is taken off again once.
[{!isNil "KJW_TwoPrimaryWeapons_addACEweight"}, {
    if !(KJW_TwoPrimaryWeapons_addACEweight isEqualTo true) exitWith {};

    KJW_TwoPrimaryWeapons_addACEweight = false;

    private _unit = player;

    {
        private _mass = _x getVariable ["KJW_TwoPrimaryWeapons_mass", 0];

        if (_mass != 0 && {!isNil "ace_movement_fnc_addLoadToUnitContainer"}) then {
            [_unit, _unit, -_mass] call ace_movement_fnc_addLoadToUnitContainer;
        };

        _x setVariable ["KJW_TwoPrimaryWeapons_mass", 0];
    } forEach ((_unit getVariable ["KJW_TwoPrimaryWeapons_currentWeaponObjects", []]) select {!isNull _x});

    INFO("KJW's Two Primary Weapons: the weapon on the back is weighed by this mod now (KJW's ACE weight switched off).");

    if (!isNil QEFUNC(weight,queueVirtualLoad)) then {
        call EFUNC(weight,queueVirtualLoad);
    };
}] call CBA_fnc_waitUntilAndExecute;
