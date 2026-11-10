#define COMPONENT compat_ravage
#define COMPONENT_BEAUTIFIED AIO - Ravage
#include "\z\aio\addons\main\script_mod.hpp"
#include "\z\aio\addons\main\script_macros.hpp"

// How long Ravage gets to fill a searched pile itself (fnc_watchPile), and how long after that the window is
// looked at (fnc_watchOpen) - Ravage's own asking opens it in that time when it comes through.
#define RAVAGE_FILL_WAIT 1.5
#define RAVAGE_OPEN_WAIT 0.4
