#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a unit is one of the soldiers the player leads: an AI of the player's own group, alive, with the
 * player as its leader. Its inventory, opened from the command menu, is this window too - on the player's gear
 * with the soldier's beside it (fnc_onInventoryOpened) - and it opens whole, whatever the settings say about
 * living persons (fnc_canOpenPerson asks isPlayer leader alone, as it has no player to ask about).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * A soldier the player leads <BOOL>
 *
 * Example:
 * [cursorObject] call aio_gui_fnc_isSubordinate;
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _player = PLAYER_UNIT;

alive _unit && {_unit isNotEqualTo _player} && {!isPlayer _unit}
&& {group _unit isEqualTo group _player} && {leader group _player isEqualTo _player}
