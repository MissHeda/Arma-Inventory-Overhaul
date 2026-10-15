#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Caps the open window's cell (fnc_getCell) for the rest of its life. A window with less room than the
 * inventory - ACE Arsenal's panel beside ACE's list (einv_arsenal_fnc_panelRect) - asks for at most so many
 * pixels, so its grid of STORAGE_COLS cells still fits there with a large tile scale (einv_gui_cellScale).
 * Every grid, tile and ghost of that window then takes the capped cell; the next window works it out
 * afresh. Said once in the RPT when it caps.
 *
 * Arguments:
 * 0: The most pixels a cell may have across and down <NUMBER>
 * 1: Where it has to fit, for the RPT <STRING> (default: "")
 *
 * Return Value:
 * The cell [width, height] in screen units <ARRAY>
 *
 * Example:
 * ([40, "the Arsenal panel"] call einv_gui_fnc_capCell) params ["_cellW", "_cellH"];
 *
 * Public: No
 */

params [["_most", 0, [0]], ["_where", "", [""]]];

private _cell = call FUNC(getCell);
private _pixels = round ((_cell select 1) / pixelH);

_most = floor _most;

// No room worth the name: what is there stays - a few pixels a cell would show nothing at all.
if (_most < 8 || {_pixels <= _most}) exitWith {_cell};

_cell = [_most * pixelW, _most * pixelH];

if (!isNull (uiNamespace getVariable [QGVAR(display), displayNull])) then {
    uiNamespace setVariable [QGVAR(cell), +_cell];
};

private _note = format ["%1 %2 %3", _where, _pixels, _most];

if ((missionNamespace getVariable [QGVAR(capNote), ""]) isNotEqualTo _note) then {
    GVAR(capNote) = _note;
    INFO_3("Tile scale too large for %1: cells of %2 px instead of %3 px there.",_where,_most,_pixels);
};

_cell
