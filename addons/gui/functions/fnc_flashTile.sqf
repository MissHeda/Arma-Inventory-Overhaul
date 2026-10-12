#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Lights a tile up in the accent colour for a moment - where a dragged item landed, or an item just
 * found (fnc_revealFx). Only ctrlCommit times it: nothing waits on it, and a rebuild simply ends it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: Where the tile is, [container, class, row, col, cells, compartment] as fnc_findTile takes it <ARRAY>
 * 2: How strong the light starts <NUMBER> (default: 0.3)
 * 3: How long it takes to die away, in seconds <NUMBER> (default: 0.45)
 *
 * Return Value:
 * The tile, an empty HashMap when it is not on the window <HASHMAP>
 *
 * Example:
 * [_display, [_box, "firstaidkit", 0, 2, 1, 0]] call einv_gui_fnc_flashTile;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_item", ["_alpha", 0.3], ["_duration", 0.45]];

private _found = _item call FUNC(findTile);

if (_found isEqualTo []) exitWith {createHashMap};

private _tile = _found select 1;
private _background = _tile getOrDefault ["background", controlNull];

if (isNull _background) exitWith {_tile};

private _color = +(GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]]);
_color set [3, _alpha];

private _flash = [_display, "EINV_PanelRect", ctrlParentControlsGroup _background, ctrlPosition _background] call FUNC(uiCreate);
_flash ctrlSetBackgroundColor _color;
_flash ctrlSetFade 0;
_flash ctrlCommit 0;
_flash ctrlSetFade 1;
_flash ctrlCommit _duration;

_tile
