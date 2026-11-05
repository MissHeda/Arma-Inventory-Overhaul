#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// WebKnight's Two Primary Weapons keeps the weapon on the back in a box hanging on the soldier (DummyWeapon_Wbk,
// its inventory locked) and the weapon itself in his variable WBK_SecondWeapon, [box, weapon]. The window shows
// it as a slot of its own next to the primary (aio_storage_fnc_secondPrimary) and changes it the way that mod
// does - so that mod's key switches to a weapon put there here as to one it put there itself. The box is never
// loot: the nearby list and the ground leave out whatever hangs on someone (aio_storage_fnc_getNearby,
// fnc_getGroundHolder), and the window leaves the box out of what it opens (aio_gui_fnc_onInventoryOpened).
//
// On every machine: a move is done where the unit is local, its slots are read anywhere.
if (count EGVAR(storage,secondPrimaryMod) > 0) then {
    WARNING_1("%1 is loaded as well - the second primary slot follows WebKnight's Two Primary Weapons now.",EGVAR(storage,secondPrimaryMod) get "name");
};

EGVAR(storage,secondPrimaryMod) = createHashMapFromArray [
    ["name", "WebKnight's Two Primary Weapons"],
    ["get", {_this call FUNC(get)}],
    ["set", {_this call FUNC(set)}],
    ["keybind", ["WebKnight's Two Primary Weapons", "WBK_DualWeapons_MainKeybind"]]
];

ADDON = true;
