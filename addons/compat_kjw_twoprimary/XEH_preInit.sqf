#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// KJW's Two Primary Weapons keeps both primaries of the player in his variables: KJW_TwoPrimaryWeapons_
// primaryPrimaryInfo and _secondPrimaryInfo, each as weaponsItems gives a weapon, and _secondPrimaryEquipped says
// which of the two is in the hands - the other one is on the back, shown by holders of its own hanging on him
// (KJW_TwoPrimaryWeapons_GWH, its fnc_updateShownWeapon). The window shows the one on the back as a slot of its own
// next to the primary (aio_storage_fnc_secondPrimary) and changes it the way that mod does - so that mod's key
// switches to a weapon put there here as to one it put there itself. Those holders are never loot: the nearby
// list and the ground leave out whatever hangs on someone (aio_storage_fnc_getNearby, fnc_getGroundHolder), and
// the window leaves them out of what it opens (aio_gui_fnc_onInventoryOpened).
//
// On every machine: a move is done where the unit is local, its slots are read anywhere.
if (count EGVAR(storage,secondPrimaryMod) > 0) then {
    WARNING_1("%1 is loaded as well - the second primary slot follows KJW's Two Primary Weapons now.",EGVAR(storage,secondPrimaryMod) get "name");
};

EGVAR(storage,secondPrimaryMod) = createHashMapFromArray [
    ["name", "KJW's Two Primary Weapons"],
    ["get", {_this call FUNC(get)}],
    ["set", {_this call FUNC(set)}],
    ["accepts", {_this call FUNC(accepts)}],
    ["keybind", ["KJW's Two Primary Weapons", "KJW_TwoPrimaryWeapons_SwitchToSecondPrimary"]]
];

ADDON = true;
