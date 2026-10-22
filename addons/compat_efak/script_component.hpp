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

// Enhanced First Aid Kits' kits tab in ACE Arsenal, as that mod names its pieces (efak_arsenal's defines.hpp,
// efak 1.1.2): the list of the kits the soldier carries, laid over ACE's left list (IDC_EFAK_KIT_LIST - one row per
// kit, its lbData the kit's instance class, its lbValue the row's kind: ROW_KITS 0, ROW_PREPARING 1 for kits
// still being made ready, whose data is the type's prototype, ROW_NOTICE 2); the list of what the picked kit may
// hold, laid over ACE's right list and built like it (IDC_EFAK_CONTENTS - lnbData [row, 0] the class, lnbValue
// [row, 2] 1 for a row that cannot be added, lnbText [row, 2] how many the kit holds), its "-" and "+"
// (IDC_EFAK_ARROW_MINUS, IDC_EFAK_ARROW_PLUS) and its sort bar (IDC_EFAK_SORT, where ACE's own is). And what the tab
// may change about a kit type (efak_core_fnc_getArsenalEditing: EDIT_NOTHING 0, EDIT_REMOVE 1, EDIT_ALL 2).
#define EFAK_IDC_KIT_LIST 88503
#define EFAK_IDC_ARROW_MINUS 88508
#define EFAK_IDC_ARROW_PLUS 88509
#define EFAK_IDC_CONTENTS 88510
#define EFAK_IDC_SORT 88522
#define EFAK_ROW_KITS 0
#define EFAK_ROW_PREPARING 1
#define EFAK_EDIT_NOTHING 0
#define EFAK_EDIT_REMOVE 1
#define EFAK_EDIT_ALL 2
