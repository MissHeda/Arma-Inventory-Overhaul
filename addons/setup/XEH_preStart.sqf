#include "script_component.hpp"

// Compiled before any mission, into uiNamespace as well (CBA_fnc_compileFunction keeps them there): the
// button on CBA's Addon Options and the wizard's display ask uiNamespace for them, whatever screen they
// are on.
#include "XEH_PREP.hpp"
