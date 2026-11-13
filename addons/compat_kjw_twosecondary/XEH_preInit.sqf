#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// KJW's Two Secondary Weapons keeps both handguns of the player in his variables: KJW_TwoSecondaryWeapons_
// primarySecondaryInfo and _secondSecondaryInfo, each as weaponsItems gives a weapon, and _secondSecondaryEquipped says
// which of the two is in the hands - the other one hangs on him, shown by holders of its own (its
// fnc_updateShownWeapon). The window shows that one as a slot of its own next to the handgun, "handgun2"
// (aio_storage_fnc_secondPrimary with that slot) and changes it the way that mod does - so that mod's key switches to
// a handgun put there here as to one it put there itself. Those holders are never loot: the nearby list and the ground
// leave out whatever hangs on someone (aio_storage_fnc_getNearby, fnc_getGroundHolder), and the window leaves them out
// of what it opens (aio_gui_fnc_onInventoryOpened). That mod saves both handguns with a loadout itself (CBA's extended
// loadout info).
//
// On every machine: a move is done where the unit is local, its slots are read anywhere.
EGVAR(storage,secondHandgunMod) = createHashMapFromArray [
    ["name", "KJW's Two Secondary Weapons"],
    ["get", {_this call FUNC(get)}],
    ["set", {_this call FUNC(set)}],
    ["accepts", {_this call FUNC(accepts)}],
    ["weighed", true],
    ["keybind", ["KJW's Two Secondary Weapons", "KJW_TwoSecondaryWeapons_SwitchToSecondary"]]
];

ADDON = true;
