#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Gives several categories the colour of their items' tiles at once (category=... color=, the Categories card of the General
 * step): the selection of the card's mass edit, or one row's own field. One commit for all of them, so the list of changes and
 * Undo see one step. A built-in category with nothing else of its own goes back to what this mod ships when its colour goes.
 *
 * Arguments:
 * 0: Category ids <ARRAY of STRING>
 * 1: Colour as typed - "c83232", "#C83232" or "" for none <STRING>
 *
 * Return Value:
 * The colour was understood <BOOL>
 *
 * Example:
 * [["medical", "food"], "c83232"] call aio_setup_fnc_setCategoryColours;
 *
 * Public: No
 */

params [["_ids", [], [[]]], ["_typed", "", [""]]];

private _hex = toLowerANSI trim _typed;

if ((_hex select [0, 1]) isEqualTo "#") then {
    _hex = _hex select [1];
};

if (_hex isNotEqualTo "" && {count _hex != 6 || {((_hex splitString "") findIf {!(_x in ("0123456789abcdef" splitString ""))}) >= 0}}) exitWith {false};

_ids = _ids select {_x isEqualType "" && {_x isNotEqualTo ""}};

if (_ids isEqualTo []) exitWith {true};

private _ast = [GVAR(draftText)] call EFUNC(items,parseRules);
private _categories = +(_ast getOrDefault ["categories", []]);

{
    private _id = _x;
    private _at = _categories findIf {(_x select 0) isEqualTo _id};
    private _entry = [[_id, "", "", ""], +(_categories select _at)] select (_at >= 0);

    _entry set [3, _hex];

    if (_id in ITEM_GROUPS && {(_entry select 1) isEqualTo ""} && {(_entry select 2) isEqualTo ""} && {_hex isEqualTo ""}) then {
        if (_at >= 0) then {
            _categories deleteAt _at;
        };
    } else {
        if (_at >= 0) then {
            _categories set [_at, _entry];
        } else {
            _categories pushBack _entry;
        };
    };
} forEach _ids;

_ast set ["categories", _categories];

[_ast] call FUNC(commit);

true
