#define COMPONENT compat_antistasi_arsenal
#define COMPONENT_BEAUTIFIED AIO - Antistasi Arsenal
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// The vanilla arsenal's tab indices JNA keeps its stock by (IDC_RSCDISPLAYARSENAL_TAB_* of BI's defineResinclDesign.inc):
// the magazines of the open container's cargo tab and the list of all magazines - both counted in rounds, not magazines.
#define JNA_TAB_CARGOMAG 21
#define JNA_TAB_CARGOMAGALL 26

// One empty list per tab, as JNA's jna_dataList and jn_fnc_arsenal_cargoToArray have them.
#define JNA_EMPTY [[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]
