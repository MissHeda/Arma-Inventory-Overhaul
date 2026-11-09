#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a server or a mission forces the colours (the CBA setting aio_gui_paletteText, set with a priority of 1 or more on
 * "server" or "mission", fnc_settingForced): then everyone wears those, and the palette button is not drawn (fnc_paletteAllowed).
 * A forced empty text forces nothing - a server that forces all of its settings at once (a cba_settings.sqf from an export)
 * keeps everyone's own colours.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Forced <BOOL>
 *
 * Example:
 * call aio_gui_fnc_paletteForced;
 *
 * Public: No
 */

((missionNamespace getVariable [QGVAR(paletteText), ""]) trim [" ", 0]) isNotEqualTo ""
    && {[QGVAR(paletteText)] call FUNC(settingForced)}
