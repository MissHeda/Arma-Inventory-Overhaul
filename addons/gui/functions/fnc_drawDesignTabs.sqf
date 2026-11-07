#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The two tabs on top of the design card under the header's palette button (fnc_openDesignMenu, Mia after 0.6.73): "Colours" - the
 * palette popover (fnc_openPaletteMenu) - and "Layout" - the player's sizes, spacing and other settings (fnc_openSizeMenu). Both
 * popovers draw them in the same place, so the card seems to change its page. The open one is lit in the accent colour; a press on
 * the other closes this card (written as it would be on closing) and opens that one (fnc_openDesignMenu). Where the server does not
 * let players pick their colours (fnc_paletteAllowed), Colours is dimmed and says so. What a server or a mission forces stays locked
 * on either page, as it always was (fnc_settingForced, fnc_paletteForced).
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The popover's layer <CONTROL>
 * 2: Where the tabs go, [x, y, w, h] in the layer <ARRAY>
 * 3: The open tab, "colours" or "layout" <STRING>
 * 4: Button height <NUMBER>
 * 5: Text size <NUMBER>
 * 6: The card's button theme <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _layer, [_x, _y, _w, _h], "colours", _chipH, _chipSize, _buttonTheme] call aio_gui_fnc_drawDesignTabs;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_layer", "_rect", ["_current", "colours", [""]], "_chipH", "_chipSize", "_buttonTheme"];
_rect params ["_tabsX", "_tabsY", "_tabsW", "_tabsH"];

private _accent = (GVAR(theme) getOrDefault ["accent", [1, 1, 1, 1]]) select [0, 3];
private _gap = SQUARE(UNIT * 0.2);
private _x0 = _tabsX;

{
    _x params ["_id", "_words", "_tip", "_allowed"];

    private _tabW = [_words, "", _chipH, _chipSize, _buttonTheme] call FUNC(buttonWidth);
    private _tabRect = [_x0, _tabsY + (_tabsH - _chipH) / 2, _tabW, _chipH];

    if (_id isEqualTo _current) then {
        [_display, _layer, _tabRect, _accent + [0.45], _chipH / 2] call FUNC(uiPanel);
    };

    private _theme = +_buttonTheme;

    if (!_allowed) then {
        _theme set ["buttonText", _buttonTheme getOrDefault ["muted", [0.5, 0.5, 0.5, 1]]];
    };

    private _button = [
        _display, _layer, _tabRect, _id, _words, "", _theme, {
            params ["_button", "_id"];

            // A left click only, and not on the open tab.
            if (_button < 0 || {_id isEqualTo (uiNamespace getVariable [QGVAR(designTab), ""])}) exitWith {};
            if (_id isEqualTo "colours" && {!([] call FUNC(paletteAllowed))}) exitWith {};

            [{
                params ["_id"];

                uiNamespace setVariable [QGVAR(designTab), _id];
                [] call FUNC(closeMenu);
                [uiNamespace getVariable [QGVAR(display), displayNull], _id] call FUNC(openDesignMenu);
            }, [_id]] call FUNC(later);
        }, false, _chipSize, true
    ] call FUNC(uiButton);

    [(_button param [count _button - 1, controlNull]), _tip] call FUNC(setTooltip);

    _x0 = _x0 + _tabW + _gap;
} forEach [
    ["colours", LLSTRING(Design_Colours), [LLSTRING(Design_Colours_Tip), LLSTRING(Design_ColoursLocked)] select !([] call FUNC(paletteAllowed)), [] call FUNC(paletteAllowed)],
    ["layout", LLSTRING(Design_Layout), LLSTRING(Design_Layout_Tip), true]
];

uiNamespace setVariable [QGVAR(designTab), _current];
