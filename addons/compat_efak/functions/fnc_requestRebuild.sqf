#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A kit the window shows changed: counted into the window's signature (fnc_signature), and the window
 * asked to look at once (aio_gui_fnc_requestRebuild) - it builds again on its next frame, not while a
 * tile is held. Only variables change here: it runs inside Enhanced First Aid Kits' own events, which
 * that mod raises in the middle of a write.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call aio_compat_efak_fnc_requestRebuild;
 *
 * Public: No
 */

GVAR(stamp) = GVAR(stamp) + 1;

call EFUNC(gui,requestRebuild);
