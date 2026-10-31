#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the palette button in the header (fnc_drawHeader) for the state it is in, in place, without building the window
 * again: an accent icon and the thin accent line under the button while the popover under it is open
 * (fnc_openPaletteMenu), the plain button otherwise. Asked when the popover opens and closes (fnc_paletteSettle). The
 * mouse's light on the surface (fnc_uiButton) is kept up to date as well.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_updatePaletteButton;
 *
 * Public: No
 */

disableSerialization;

private _controls = uiNamespace getVariable [QGVAR(paletteButton), []];

if (_controls isEqualTo [] || {isNull (_controls select -1)}) exitWith {};

private _open = (uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] && {(GVAR(menuFor) param [0, ""]) isEqualTo "palette"};

([GVAR(theme), _open] call FUNC(headerStyle)) params ["_fill", "_hover", "_ink"];

// The accent line under the button shows while the popover is open.
{_x ctrlShow _open} forEach (uiNamespace getVariable [QGVAR(paletteLine), []]);

private _rects = _controls select {ctrlClassName _x isEqualTo "AIO_PanelRect"};
private _corners = _controls select {ctrlClassName _x isEqualTo "AIO_PanelCorner"};

// A surface in the gradient (fnc_gradientSurface) keeps its pieces' colours: the fill is the same open or closed.
if ((((_controls select -1) getVariable [QGVAR(graded), [[]]]) select 0) isEqualTo []) then {
    {_x ctrlSetBackgroundColor _fill} forEach _rects;
    {_x ctrlSetTextColor _fill} forEach _corners;

    (_controls select -1) setVariable [QGVAR(surface), [_rects, _corners, _fill, _hover]];
};

{_x ctrlSetTextColor _ink} forEach (_controls select {ctrlClassName _x isEqualTo "AIO_Icon"});
