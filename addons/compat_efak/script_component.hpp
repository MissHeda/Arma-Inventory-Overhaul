#define COMPONENT compat_efak
#define COMPONENT_BEAUTIFIED EINV - Enhanced First Aid Kits
#include "\z\einv\addons\main\script_mod.hpp"
#include "\z\einv\addons\main\script_macros.hpp"

// Enhanced First Aid Kits' variables and functions, the way that mod names them - the same with
// Enhanced Utility Pouches, which brings its framework along.
#define EFAK_PREFIX efak

#define EFAKGVAR(module,var)         TRIPLES(EFAK_PREFIX,module,var)
#define QEFAKGVAR(module,var)        QUOTE(EFAKGVAR(module,var))

#define EFAKFUNC(module,function)    TRIPLES(DOUBLES(EFAK_PREFIX,module),fnc,function)
#define QEFAKFUNC(module,function)   QUOTE(EFAKFUNC(module,function))

// Enhanced First Aid Kits' own allowance when it asks how many fit into what is left of a kit: masses
// are decimals, and three bandages at 0.4 must still fit into 1.2 (MASS_EPSILON, efak gui defines.hpp).
#define KIT_MASS_EPSILON 0.0001

// How deep kits packed inside kits are followed - deeper than that mod ever nests them
// (EFAK_RESTORE_MAX_DEPTH is 3).
#define KIT_MAX_DEPTH 4
