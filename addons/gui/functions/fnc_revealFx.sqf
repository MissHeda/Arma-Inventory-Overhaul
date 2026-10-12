#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * An item just found: on its tile, built anew without its "?", the picture, name and count fade in,
 * and a flash in the accent colour dies away over it (fnc_flashTile). Only ctrlCommit times it -
 * nothing waits on it, and a rebuild meanwhile simply ends it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The item, as it stood in the search queue (fnc_markHidden) <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _head] call einv_gui_fnc_revealFx;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_item"];

private _tile = [_display, _item, REVEAL_FLASH_ALPHA, REVEAL_FLASH] call FUNC(flashTile);
private _background = _tile getOrDefault ["background", controlNull];

if (isNull _background || {_tile getOrDefault ["hidden", false]}) exitWith {};

{
    if (_x isNotEqualTo _background) then {
        _x ctrlSetFade 1;
        _x ctrlCommit 0;
        _x ctrlSetFade 0;
        _x ctrlCommit REVEAL_FADE;
    };
} forEach (_tile getOrDefault ["controls", []]);
