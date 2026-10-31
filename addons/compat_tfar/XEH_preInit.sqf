#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// TFAR keeps a long-range radio's frequencies on the backpack object itself (the variable "radio_settings").
// The window takes things out and puts them in anew, which makes a new backpack object on every move: the
// storage carries this variable from the old container to the new one (aio_storage_carryVariables), or
// every long-range backpack moved through the window would forget its frequencies.
EGVAR(storage,carryVariables) pushBackUnique "radio_settings";

ADDON = true;
