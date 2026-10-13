#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 3, Containers: the cells of uniforms, vests, backpacks, crates and vehicles, class by class.
 *   - Left: every container of the game and its mods, to search by class or name (fnc_drawClassList over
 *     the class index, fnc_buildIndex), each with what the draft makes of its grid and where from.
 *   - Right: the one picked, its compartments to paint - a colour per compartment - or to build block by
 *     block, or the same as another class (fnc_drawCellEditor). Apply writes one rule for exactly that
 *     class into the draft; Save at Review puts it to use.
 * Ctrl+F puts the cursor in the search.
 *
 * Opened for a class (fnc_open with a class, GVAR(focus)) that is a container, it starts with that one
 * picked and found.
 *
 * Arguments:
 * 0: Display <DISPLAY>
 * 1: The step's group <CONTROL>
 * 2: Theme <HASHMAP>
 * 3: Arguments - none <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display, _group, _theme, []] call einv_setup_fnc_drawContainers;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_theme"];

(ctrlPosition _group) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [0.925, 0.933, 0.949, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.698, 0.734, 0.784, 1]];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _gapX = SQUARE(UNIT * 0.5);
private _cursorY = UNIT * 0.4;
private _bottom = _height - UNIT * 0.5;

// Opened for a container: that one, found and picked.
if (GVAR(focus) isNotEqualTo "") then {
    private _facts = [GVAR(focus)] call EFUNC(items,getFacts);

    if ((_facts get "kind") in CONTAINER_KINDS) then {
        GVAR(selection) set ["containers", _facts get "class"];
        GVAR(listState) set ["containers", [_facts get "class", "all", false, 0]];
        GVAR(focus) = "";
    };
};

[_display, _group, [_padX, _cursorY, _innerW, UNIT * 1.1], LLSTRING(Cont_Title), TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + UNIT * 1.1;
_cursorY = _cursorY + ([_display, _group, [_padX, _cursorY, _innerW], LLSTRING(Cont_Help), TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.4;

private _listW = (_innerW - _gapX) * 0.4;

[_display, _group, [_padX, _cursorY, _listW, _bottom - _cursorY], _theme, "containers"] call FUNC(drawClassList);
[_display, _group, [_padX + _listW + _gapX, _cursorY, _innerW - _listW - _gapX, _bottom - _cursorY], _theme] call FUNC(drawCellEditor);

// Ctrl+F: into the search.
GVAR(stepKey) = {
    params ["_key", "", "_ctrl", "", "_up"];

    if (_up || {!_ctrl} || {_key != DIK_F}) exitWith {false};

    ctrlSetFocus (uiNamespace getVariable [QGVAR(searchEdit), controlNull]);

    true
};
