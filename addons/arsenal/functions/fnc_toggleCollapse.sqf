#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Folds the whole panel to its title bar, or unfolds it again: the button at the right end of the title row
 * (fnc_layout), and an item dragged out of ACE's list held over the folded panel's title bar (fnc_onFrame).
 * Folded, the panel is only its title row - no grid, no staging space, no hint line, no hit area of its own
 * under the rest of the screen - so ACE's lists and its 3D view behind it are free. Unfolded, it comes back
 * as it was, the column scrolled to where it stood (fnc_layout).
 *
 * The state is kept for the session (GVAR(collapsed)) and, per player, in the profile; it is the panel's, not
 * a container's, so it stays through the tabs and the next opening of ACE's window. The panel is built again;
 * while something is held, once it is let go (GVAR(dirty), fnc_onFrame).
 *
 * Arguments:
 * 0: -1 turn it round, 1 fold, 0 unfold <NUMBER> (default: -1)
 * 1: Build at once, not for a run of clicks together <BOOL> (default: false)
 * 2: Build even while something is held, which ends the drag <BOOL> (default: false)
 *
 * Return Value:
 * The state changed <BOOL>
 *
 * Example:
 * [] call einv_arsenal_fnc_toggleCollapse;
 *
 * Public: No
 */

disableSerialization;

params [["_state", -1, [0]], ["_now", false, [false]], ["_force", false, [false]]];

private _display = uiNamespace getVariable [QGVAR(display), displayNull];

if (!GVAR(attached) || {isNull _display}) exitWith {false};

private _fold = [_state > 0, !GVAR(collapsed)] select (_state < 0);

if (_fold isEqualTo GVAR(collapsed)) exitWith {false};

GVAR(collapsed) = _fold;
profileNamespace setVariable [QGVAR(collapsed), _fold];

GVAR(unfoldSince) = -1;

// Something held: the build comes once it is let go.
if (!_force && {EGVAR(gui,dragging) || {EGVAR(gui,press) isNotEqualTo []}}) exitWith {
    GVAR(dirty) = true;
    true
};

if (_now || {_force}) then {
    [_display] call EFUNC(gui,build);
} else {
    [] call EFUNC(gui,buildSoon);
};

true
