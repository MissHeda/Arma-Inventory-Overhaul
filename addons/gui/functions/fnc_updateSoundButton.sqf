#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Draws the speaker in the header (fnc_drawHeader) for the state it is in, in place, without building the
 * window again: the muted speaker while every sound is off (fnc_soundMuted with ""), dimmed; an accent icon and
 * the thin accent line under the button while the dropdown under it is open (fnc_openSoundMenu), the plain
 * button otherwise. Asked whenever the
 * volumes change and the dropdown opens or closes (fnc_soundSettle). The mouse's light on the surface
 * (fnc_uiButton) is kept up to date as well.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call aio_gui_fnc_updateSoundButton;
 *
 * Public: No
 */

disableSerialization;

private _controls = uiNamespace getVariable [QGVAR(soundButton), []];

if (_controls isEqualTo [] || {isNull (_controls select -1)}) exitWith {};

private _open = (uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] && {(GVAR(menuFor) param [0, ""]) isEqualTo "sound"};
private _muted = [""] call FUNC(soundMuted);

([GVAR(theme), _open] call FUNC(headerStyle)) params ["_fill", "_hover", "_ink"];

// The accent line under the button shows while the dropdown is open.
{_x ctrlShow _open} forEach (uiNamespace getVariable [QGVAR(soundLine), []]);

// Muted: the icon's strength drops, as any button's does when it is off.
if (_muted && {!_open}) then {
    _ink = +_ink;
    _ink set [3, (_ink param [3, 1]) * 0.45];
};

private _rects = _controls select {ctrlClassName _x isEqualTo "AIO_PanelRect"};
private _corners = _controls select {ctrlClassName _x isEqualTo "AIO_PanelCorner"};

// A surface in the gradient (fnc_gradientSurface) keeps its pieces' colours: the fill is the same open or closed.
if ((((_controls select -1) getVariable [QGVAR(graded), [[]]]) select 0) isEqualTo []) then {
    {_x ctrlSetBackgroundColor _fill} forEach _rects;
    {_x ctrlSetTextColor _fill} forEach _corners;

    (_controls select -1) setVariable [QGVAR(surface), [_rects, _corners, _fill, _hover]];
};

{
    _x ctrlSetText ([UI_TEX(icon_sound_on_ca), UI_TEX(icon_sound_off_ca)] select _muted);
    _x ctrlSetTextColor _ink;
} forEach (_controls select {ctrlClassName _x isEqualTo "AIO_Icon"});
