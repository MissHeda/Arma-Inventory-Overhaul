#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The condition of ACE's interaction "Inventory" on a person: the window's own answers, so the entry shows
 * exactly when opening would work - the server's settings and the person's state (einv_gui_fnc_canOpenPerson:
 * awake, captive or unconscious as "Living persons" allows, or only by the backpack) and the player's reach
 * (einv_gui_fnc_personInReach: both on foot, close enough, and ACE's own conditions - the person not
 * dragged, carried or escorted by someone else, the player not handcuffed, surrendering or on a ladder).
 * einv_gui_fnc_openPerson asks both again when it runs.
 *
 * ACE asks it while its menu is open, for the person looked at only.
 *
 * Arguments:
 * 0: Person <OBJECT>
 * 1: Player - ACE_player, the controlled soldier under Zeus remote control <OBJECT>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [cursorObject, ACE_player] call einv_compat_ace_interaction_fnc_canOpen;
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_player", objNull, [objNull]]];

_target isNotEqualTo _player
&& {([_target] call EFUNC(gui,canOpenPerson)) isNotEqualTo ""}
&& {[_player, _target, true] call EFUNC(gui,personInReach)}
