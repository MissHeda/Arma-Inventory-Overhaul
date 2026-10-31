#define COMPONENT compat_itempreview
#define COMPONENT_BEAUTIFIED AIO - Item Preview
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// The engine's stand-in models an item without one of its own inherits (ItemCore, CA_Magazine and the dummies), in lowercase,
// without the leading backslash and the extension (fnc_hasModel).
#define PLACEHOLDER_MODELS ["a3\weapons_f\ammo\mag_univ", "a3\weapons_f\dummyweapon", "a3\weapons_f\dummyweapon_single", "a3\weapons_f\empty", "a3\data_f\cl_basic", "a3\weapons_f\dummyitem", "a3\weapons_f\dummyitemhorizontal"]
