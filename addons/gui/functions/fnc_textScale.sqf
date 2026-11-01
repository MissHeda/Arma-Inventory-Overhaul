#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * How much larger than at tile scale 1 the window's words are drawn (TEXT_UNIT): the words grow with the tiles
 * (aio_gui_cellScale), so a player who makes his tiles larger to make them out gets captions, buttons, the footer's
 * key hints, the page bars and the kit windows' title rows that are just as easy to read (a tester, 2026-10-19: the
 * tiles grew, the captions stayed tiny).
 *
 * The share is the cell the window really has (fnc_getCell, and fnc_capCell where a window caps it for itself - ACE
 * Arsenal's panel) over the cell at tile scale 1 (CELL_BASE_PX), so whatever caps the tiles caps the words with them.
 * It is never below TEXT_SCALE_MIN (the tile scale's own floor: the words shrink with the tiles too) nor above TEXT_SCALE_MAX, and
 * never so small that a caption's words (TEXT_REF of a UNIT) are under TEXT_MIN_PX pixels high: on a low resolution
 * the words are the floor's size whatever the tiles are.
 *
 * The player's text size (aio_gui_textSize, TEXT_SIZE_MIN to TEXT_SIZE_MAX, set in the size popover or in CBA's options)
 * multiplies what the tiles give, before the floor: larger words on small tiles, or smaller ones on large tiles - never under the
 * floor.
 *
 * Kept in uiNamespace aio_gui_textScale with the cell, the UNIT and the text size it was worked out for, so it is worked out
 * again only when one of them changes (a window caps its cell, the resolution changes, the size popover moves) and is the same
 * for everything drawn meanwhile.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The share, at most TEXT_SCALE_MAX * TEXT_SIZE_MAX <NUMBER>
 *
 * Example:
 * private _size = UNIT * 0.42 * (call aio_gui_fnc_textScale);
 *
 * Public: No
 */

// The player's own text size on top (aio_gui_textSize), read from the mission namespace as the tile scale is (fnc_getCell).
private _size = missionNamespace getVariable [QGVAR(textSize), 1];

if !(_size isEqualType 0) then {
    _size = 1;
};

_size = (_size max TEXT_SIZE_MIN) min TEXT_SIZE_MAX;

private _cellH = (call FUNC(getCell)) select 1;
private _key = [_cellH, UNIT, _size];
private _kept = uiNamespace getVariable [QGVAR(textScale), []];

if ((_kept param [0, []]) isEqualTo _key) exitWith {_kept select 1};

private _base = CELL_BASE_PX max 1;
private _byCell = (_cellH / pixelH) / _base;

// The caption's words in pixels at the share 1, and the share that brings them up to the floor.
private _floor = TEXT_MIN_PX / ((UNIT * TEXT_REF / pixelH) max 1);

private _scale = ((((_byCell max TEXT_SCALE_MIN) min TEXT_SCALE_MAX) * _size) max _floor) min (TEXT_SCALE_MAX * TEXT_SIZE_MAX);

uiNamespace setVariable [QGVAR(textScale), [_key, _scale]];

_scale
