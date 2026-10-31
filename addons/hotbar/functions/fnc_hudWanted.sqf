#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the bar belongs on the screen now. Not in a dialog (the inventory has its own row; ACE's
 * progress bar is the one dialog the bar stays for), not in Zeus or a feature camera, not for someone
 * unconscious, dead or not in control of their unit, not with the HUD switched off. Then the setting
 * decides: "always" shows it, "while in use" for a few seconds after a key, while an item is used and
 * while a bound grenade is in the hand.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Show the bar <BOOL>
 *
 * Example:
 * call aio_hotbar_fnc_hudWanted;
 *
 * Public: No
 */

if (!(call FUNC(isActive)) || {GVAR(hudMode) == 0} || {(GVAR(slots) findIf {_x isNotEqualTo ""}) < 0}) exitWith {false};

private _unit = ACE_player;

if (
    isNull _unit || {!alive _unit} || {!local _unit} || {_unit getVariable ["ACE_isUnconscious", false]}
    || {!(shownHUD param [0, true])} || {!isNull curatorCamera} || {(call CBA_fnc_getActiveFeatureCamera) isNotEqualTo ""}
) exitWith {false};

// A dialog hides it, except ACE's progress bar, which the bar mirrors.
if (dialog && {isNull (uiNamespace getVariable ["ace_common_ctrlProgressBar", controlNull])}) exitWith {false};

if (GVAR(hudMode) == 2) exitWith {true};

// In use: a key was pressed a moment ago, a treatment runs, or a bound grenade is in the hand.
if (diag_tickTime < GVAR(hudUntil) || {GVAR(busy) isNotEqualTo []}) exitWith {true};

if (_unit getVariable ["ace_advanced_throwing_inHand", false]) exitWith {
    private _held = (currentThrowable _unit) param [0, ""];

    _held isNotEqualTo "" && {(GVAR(slots) findIf {_x == _held}) >= 0}
};

false
