#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the draft makes of a class in one line, for the cards of the class list and the rows of its tree
 * (fnc_drawResults, fnc_drawTree): the grid on the Containers step, the size and the stack on the Items
 * step, each with where it comes from (fnc_answerText) - "6x4 (your rule)", "3 × 1x2 (preset)", "2x3, 5 per
 * tile (inherited from ACE_fieldDressing)".
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: Step: "items" or "containers" <STRING>
 *
 * Return Value:
 * [line, an own rule of the draft decides it] <ARRAY>
 *
 * Example:
 * ["B_Carryall_blk", "containers"] call aio_setup_fnc_answerLine;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_mode", "items", [""]]];

private _info = [_class, GVAR(draftRules), GVAR(draftCache)] call EFUNC(items,getInfo);
private _own = (([] call FUNC(ownClassRules)) select 0) getOrDefault [toLowerANSI _class, createHashMap];
private _answer = "";
private _isOwn = false;

if (_mode isEqualTo "containers") then {
    ([_info, "grid", _own] call FUNC(answerText)) params ["_words", "_from"];

    _answer = format [LLSTRING(Answer_Line), _words, _from];
    _isOwn = (((_info get "src") getOrDefault ["grid", ""]) select [0, 4]) isEqualTo "own:";
} else {
    ([_info, "size", _own] call FUNC(answerText)) params ["_sizeWords", "_sizeFrom"];
    ([_info, "stack", _own] call FUNC(answerText)) params ["_stackWords", "_stackFrom"];

    private _src = _info get "src";

    _isOwn = ({((_src getOrDefault [_x, ""]) select [0, 4]) isEqualTo "own:"} count ["footprint", "stack"]) > 0;
    _answer = switch (true) do {
        // Weapons, uniforms, vests and backpacks never share a tile: only the size says anything.
        case ((_src getOrDefault ["stack", ""]) isEqualTo "forced"): {format [LLSTRING(Answer_Line), _sizeWords, _sizeFrom]};
        case (_sizeFrom isEqualTo _stackFrom): {format [LLSTRING(Answer_Line), format ["%1, %2", _sizeWords, _stackWords], _sizeFrom]};
        default {format ["%1 · %2", format [LLSTRING(Answer_Line), _sizeWords, _sizeFrom], format [LLSTRING(Answer_Line), _stackWords, _stackFrom]]};
    };
};

[_answer, _isOwn]
