#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the window stays open (the "keepOpen" hook): the unit it dresses lives. A box of a vanilla
 * arsenal that was deleted closes it as well. The inventory's own rule reads ACE_player, which is nil in
 * the Eden editor and not the unit in Zeus.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Stay open <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_keepOpen;
 *
 * Public: No
 */

if (isNull GVAR(center) || {!alive GVAR(center)}) exitWith {false};

// A vanilla box is the object the soldier stands at; an ACE box can go without closing the window (it says
// so when it is removed: fnc_onBoxRemoved).
!(GVAR(source) isEqualTo "bi" && {isNull GVAR(box)})
