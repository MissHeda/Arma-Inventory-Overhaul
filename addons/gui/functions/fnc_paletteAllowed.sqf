#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether the player may pick the window's colours: the server setting "Players may pick their colours"
 * (einv_gui_playerColours, on by default). Off, the header has no palette button and what a player saved is left
 * alone and ignored (fnc_palette), so everyone sees their own Arma colour and the colours the themes start with.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Allowed <BOOL>
 *
 * Example:
 * private _allowed = [] call einv_gui_fnc_paletteAllowed;
 *
 * Public: No
 */

(missionNamespace getVariable [QGVAR(playerColours), true]) isNotEqualTo false && {!([] call FUNC(paletteForced))}
