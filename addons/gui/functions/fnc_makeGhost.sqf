#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Makes the picture that follows the mouse while an item is dragged, in the shape it is held in
 * (GVAR(dragSize)) - turned a quarter when it was turned (fnc_rotateDrag) - and the count under its
 * bottom right corner while a stack is held. Made again on every turn; fnc_updateDrag moves them.
 *
 * Tiles dragged together (GVAR(dragGroup)) have the grabbed tile's picture and a counter of their own
 * ("×6", or how many fit once there is a container under the mouse). When they keep their arrangement
 * every tile's picture follows the mouse at its own offset - at most GROUP_GHOSTS of them, made once,
 * below the grabbed tile's - and fnc_updateDrag shows them only then (uiNamespace dragGhosts: control,
 * offset in the group, where the picture lies in its box, tile).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call einv_gui_fnc_makeGhost;
 *
 * Public: No
 */

disableSerialization;

params ["_display"];

ctrlDelete (uiNamespace getVariable [QGVAR(dragGhost), controlNull]);
ctrlDelete (uiNamespace getVariable [QGVAR(dragCounter), controlNull]);

private _entry = uiNamespace getVariable [QGVAR(dragEntry), createHashMap];
private _info = [_entry getOrDefault ["class", ""]] call EFUNC(items,getInfo);

(call FUNC(getCell)) params ["_cellW", "_cellH"];

// ----- The other tiles of a group, below the grabbed one's picture -----
if (GVAR(dragGroup) isNotEqualTo [] && {(uiNamespace getVariable [QGVAR(dragGhosts), []]) isEqualTo []}) then {
    private _grids = uiNamespace getVariable [QGVAR(grids), []];
    private _grabbed = GVAR(press) param [0, -1];
    private _grabbedTile = ((_grids param [_grabbed, createHashMap]) getOrDefault ["tiles", []]) param [GVAR(press) param [1, -1], createHashMap];
    private _ghosts = [];

    {
        if (count _ghosts >= GROUP_GHOSTS - 1) exitWith {};

        _x params ["_gridIndex", "_tileIndex"];

        private _tile = ((_grids param [_gridIndex, createHashMap]) getOrDefault ["tiles", []]) param [_tileIndex, createHashMap];

        // The grabbed tile has the main picture; a tile of another compartment has no place beside it.
        if (count _tile == 0 || {_gridIndex == _grabbed && {_tileIndex == (GVAR(press) param [1, -1])}} || {_gridIndex != _grabbed}) then {continue};

        private _tileInfo = [_tile getOrDefault ["class", ""]] call EFUNC(items,getInfo);

        (_tileInfo getOrDefault ["size", [1, 1]]) params ["_tileSizeW", "_tileSizeH"];

        private _tileW = _tile getOrDefault ["w", _tileSizeW];
        private _tileH = _tile getOrDefault ["h", _tileSizeH];
        private _tileRect = [0, 0, _tileW * _cellW, _tileH * _cellH];
        private _tileTurned = _tile getOrDefault ["rotated", _tileW != _tileSizeW && {_tileSizeW != _tileSizeH}];
        private _picture = _tileInfo getOrDefault ["picture", ""];

        private _ghost = if (_tileTurned) then {
            [_display, controlNull, _tileRect, _picture, [1, 1, 1, 0.8], _tileSizeW / (_tileSizeH max 1)] call FUNC(uiPictureTurned)
        } else {
            [_display, controlNull, _tileRect, _picture, [1, 1, 1, 0.8]] call FUNC(uiPicture)
        };

        (ctrlPosition _ghost) params ["_ghostX", "_ghostY"];

        _ghost ctrlShow false;
        _ghosts pushBack [
            _ghost, ((_tile getOrDefault ["col", 0]) - (_grabbedTile getOrDefault ["col", 0])) * _cellW,
            ((_tile getOrDefault ["row", 0]) - (_grabbedTile getOrDefault ["row", 0])) * _cellH, _ghostX, _ghostY, _tileTurned
        ];
    } forEach GVAR(dragGroup);

    uiNamespace setVariable [QGVAR(dragGhosts), _ghosts];
};
GVAR(dragSize) params ["_w", "_h"];
(_info getOrDefault ["size", [1, 1]]) params ["_sizeW", "_sizeH"];

private _rect = [0, 0, _w * _cellW, _h * _cellH];
private _turned = GVAR(dragRot) == 1;
private _picture = _info getOrDefault ["picture", ""];

private _ghost = if (_turned) then {
    [_display, controlNull, _rect, _picture, [1, 1, 1, 0.8], _sizeW / (_sizeH max 1)] call FUNC(uiPictureTurned)
} else {
    [_display, controlNull, _rect, _picture, [1, 1, 1, 0.8]] call FUNC(uiPicture)
};

// Where the picture lies in the box it is moved by.
(ctrlPosition _ghost) params ["_ghostX", "_ghostY"];

uiNamespace setVariable [QGVAR(dragGhost), _ghost];
uiNamespace setVariable [QGVAR(dragGhostOffset), [_ghostX, _ghostY]];
uiNamespace setVariable [QGVAR(dragTurned), _turned];

// How many of the stack go - only for a stack; for a group always, how many tiles are dragged.
if ((_entry getOrDefault ["count", 1]) > 1 || {GVAR(dragGroup) isNotEqualTo []}) then {
    private _counter = [
        _display, controlNull, [0, 0, SQUARE(UNIT * 1.6), UNIT * 0.75], "", UNIT * 0.55,
        GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]], GVAR(theme) getOrDefault ["fontBold", "PuristaSemibold"], 2
    ] call FUNC(uiLabel);

    _counter ctrlSetBackgroundColor [0.05, 0.05, 0.05, 0.95];
    uiNamespace setVariable [QGVAR(dragCounter), _counter];
};
