#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Whether a player can still reach into a person's gear: both on foot and close enough - PERSON_KEEP
 * on the player's machine, which also asks ACE whether the two may interact (the person claimed by
 * someone else, the player handcuffed, on a ladder...). The person's machine is more lenient,
 * PERSON_KEEP_REMOTE and nothing of ACE's: positions reach it late, and ACE's conditions read what
 * only the player's machine knows (visibleMap, curatorCamera).
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Person <OBJECT>
 * 2: Asked on the player's machine <BOOL> (default: false)
 *
 * Return Value:
 * In reach <BOOL>
 *
 * Example:
 * [ACE_player, cursorObject, true] call aio_gui_fnc_personInReach;
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_person", objNull, [objNull]], ["_here", false, [false]]];

!isNull _person && {alive _player}
&& {isNull objectParent _person} && {isNull objectParent _player}
&& {_player distance _person <= ([PERSON_KEEP_REMOTE, PERSON_KEEP] select _here)}
&& {!_here || {[_player, _person, ["isNotSwimming"]] call ACEFUNC(common,canInteractWith)}}
