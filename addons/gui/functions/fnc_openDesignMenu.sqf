#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The header's palette button (fnc_drawHeader): one card for everything about how the window looks and behaves for this player, in
 * two tabs (fnc_drawDesignTabs) - Colours (fnc_openPaletteMenu) and Layout, the sizes, spacing and the other own settings
 * (fnc_openSizeMenu). A press opens the tab that was open last (uiNamespace aio_gui_designTab), Layout where the server does not let
 * players pick their colours (fnc_paletteAllowed); a press while either is open closes it.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The tab to open, "colours" or "layout"; "" - the button: the last one, or close (default: "") <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call aio_gui_fnc_openDesignMenu;
 *
 * Public: No
 */

params ["_display", ["_tab", "", [""]]];

if (isNull _display) exitWith {};

if (_tab isEqualTo "") then {
    if ((uiNamespace getVariable [QGVAR(menu), []]) isNotEqualTo [] && {(GVAR(menuFor) param [0, ""]) in ["palette", "size"]}) exitWith {
        _tab = "close";
    };

    _tab = uiNamespace getVariable [QGVAR(designTab), "colours"];
};

if (_tab isEqualTo "close") exitWith {
    [] call FUNC(closeMenu);
};

if (_tab isEqualTo "colours" && {!([] call FUNC(paletteAllowed))}) then {
    _tab = "layout";
};

uiNamespace setVariable [QGVAR(designTab), _tab];

if (_tab isEqualTo "colours") then {
    [_display] call FUNC(openPaletteMenu);
} else {
    [_display] call FUNC(openSizeMenu);
};
