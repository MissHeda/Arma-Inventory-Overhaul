#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Writes what Enhanced First Aid Kits' kits tab of ACE Arsenal still has staged, before the panel changes a kit.
 * That tab keeps its "+" and "-" as staged edits and writes them a second after the last click
 * (efak_arsenal_fnc_queueFlush). Written first, the kit the panel then changes holds what that tab shows, the
 * panel's checks see it (fnc_canPackNew, fnc_discard, fnc_drop), and nothing of the tab is replayed onto the panel's
 * change afterwards (efak_arsenal_fnc_onContentsChanged); the late write that was waiting finds nothing left to do.
 * Nothing while that tab is closed or where its addon is not loaded.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Something was asked to be written <BOOL>
 *
 * Example:
 * [] call aio_compat_efak_fnc_arsenalFlush;
 *
 * Public: No
 */

if (!(missionNamespace getVariable [QEFAKGVAR(arsenal,active), false]) || {isNil QEFAKFUNC(arsenal,flush)}) exitWith {false};

[] call EFAKFUNC(arsenal,flush);

true
