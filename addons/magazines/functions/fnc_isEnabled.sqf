#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether magazines may be repacked in the window now: the setting is on (a server with a mod of its own
 * for refilling magazines switches it off for everyone), ACE's repack and its interaction check are
 * there (ACE's repack schedule is not public - a renamed function switches the feature off rather than
 * break it), and the window is the plain inventory. The Arsenal and later editor windows attach with a
 * hook table (aio_gui_fnc_isInventoryMode) and hand out full magazines anyway.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Repacking is on <BOOL>
 *
 * Example:
 * call aio_magazines_fnc_isEnabled;
 *
 * Public: No
 */

(missionNamespace getVariable [QGVAR(repack), false])
&& {!isNil QACEFUNC(magazinerepack,simulateRepackEvents)}
&& {!isNil QACEFUNC(common,canInteractWith)}
&& {[] call EFUNC(gui,isInventoryMode)}
