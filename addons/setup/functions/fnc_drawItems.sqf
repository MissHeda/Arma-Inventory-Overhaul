#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Step 2, Items: how many cells an item takes, how many share a tile, how much it weighs and what it is
 * called, class by class - or a whole family at once.
 *   - Left: every weapon, magazine, piece of gear and item of the game and its mods, to search by class or
 *     name with wildcards (B_Bergen*, *Carryall*) (fnc_drawClassList over the class index,
 *     fnc_buildIndex), each with its size and stack in the draft and where they come from - or, in the
 *     tree view, one class and every class built on it (fnc_drawTree).
 *   - Right: the one picked, its cells to draw - a rectangle by its width and height, or any shape cell by
 *     cell -, its stack, weight and name (fnc_drawItemEditor). Apply writes one rule for exactly that class
 *     into the draft - or, for a class picked in the tree, one rule for it and everything built on it
 *     (class=X+); Save at Review puts it to use. Export and Import work with config lines.
 * Ctrl+F puts the cursor in the search.
 *
 * Opened for a class (fnc_open with a class, GVAR(focus)), it starts with that one picked and found.
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
 * [_display, _group, _theme, []] call einv_setup_fnc_drawItems;
 *
 * Public: No
 */

disableSerialization;

params ["_display", "_group", "_theme"];

(ctrlPosition _group) params ["", "", "_width", "_height"];

private _font = _theme getOrDefault ["font", "PuristaMedium"];
private _fontBold = _theme getOrDefault ["fontBold", "PuristaSemibold"];
private _colorText = _theme getOrDefault ["text", [1, 1, 1, 1]];
private _colorText2 = _theme getOrDefault ["text2", [0.78, 0.78, 0.78, 1]];

private _padX = WIZ_PAD_X;
private _innerW = _width - _padX * 2;
private _gapX = SQUARE(UNIT * 0.5);
private _cursorY = UNIT * 0.4;
private _bottom = _height - UNIT * 0.5;

// Opened for a class the rules engine knows: that one, found and picked.
if (GVAR(focus) isNotEqualTo "") then {
    private _facts = [GVAR(focus)] call EFUNC(items,getFacts);

    if ((_facts get "root") isNotEqualTo "") then {
        GVAR(selection) set ["items", _facts get "class"];
        GVAR(editScope) set ["items", "class"];
        GVAR(listState) set ["items", [_facts get "class", "all", false, 0]];
        GVAR(focus) = "";
    };
};

[_display, _group, [_padX, _cursorY, _innerW, UNIT * 1.1], LLSTRING(Items_Title), TEXT_HEAD, _colorText, _fontBold, 0] call EFUNC(gui,uiLabel);

_cursorY = _cursorY + UNIT * 1.1;
_cursorY = _cursorY + ([_display, _group, [_padX, _cursorY, _innerW], LLSTRING(Items_Help), TEXT_SMALL, _colorText2, _font] call FUNC(uiText)) + UNIT * 0.4;

private _listW = (_innerW - _gapX) * 0.45;

[_display, _group, [_padX, _cursorY, _listW, _bottom - _cursorY], _theme, "items"] call FUNC(drawClassList);
[_display, _group, [_padX + _listW + _gapX, _cursorY, _innerW - _listW - _gapX, _bottom - _cursorY], _theme] call FUNC(drawItemEditor);

// Ctrl+F: into the search.
GVAR(stepKey) = {
    params ["_key", "", "_ctrl", "", "_up"];

    if (_up || {!_ctrl} || {_key != DIK_F}) exitWith {false};

    ctrlSetFocus (uiNamespace getVariable [QGVAR(searchEdit), controlNull]);

    true
};
