#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Opens the menu under a chip of the catalog's bar that ends in an arrow - more categories, the weapon the
 * parts have to fit, the sort (the catalog's own and the ones ACE has for the category) - in the inventory's
 * context menu.
 *
 * Arguments:
 * 0: What the menu is for - "more", "fits" or "sort" <STRING>
 * 1: Where the chip is, [x, y, w, h] on the screen <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["sort", [0.7, 0.2, 0.05, 0.03]] call einv_arsenal_fnc_openChoices;
 *
 * Public: No
 */

params [["_what", "", [""]], ["_rect", [0, 0, 0, 0], [[]]]];

private _display = uiNamespace getVariable [QEGVAR(gui,display), displayNull];
private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _choices = [];

switch (_what) do {
    // The categories of the group that did not fit on the chips' lines.
    case "more": {
        private _hidden = _column getOrDefault ["moreCategories", []];

        {
            _x params ["_id", "_label"];

            _choices pushBack [_label, [_id], {
                params ["_id"];

                [_id] call FUNC(showCategory);
            }, createHashMapFromArray [["color", [[], EGVAR(gui,theme) getOrDefault ["accent", []]] select (_id isEqualTo GVAR(category))]]];
        } forEach _hidden;
    };
    // Anything, your weapons (magazines), or one of the weapons the soldier has.
    case "fits": {
        private _equipment = [GVAR(center)] call EFUNC(storage,getEquipment);
        private _slot = GVAR(fits);

        _choices pushBack [LLSTRING(Filter_FitsAny), ["any"], {
            GVAR(fits) = _this select 0;
            private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

            _column set ["dirty", true];
            _column set ["barDirty", true];
        }];

        if (GVAR(category) isEqualTo "magazine") then {
            _choices pushBack [LLSTRING(Filter_FitsWeapons), ["mine"], {
                GVAR(fits) = _this select 0;
                private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

                _column set ["dirty", true];
                _column set ["barDirty", true];
            }];
        };

        {
            private _weapon = (_equipment getOrDefault [_x, []]) param [0, ""];

            if (_weapon isNotEqualTo "") then {
                // A magazine's choice keeps the muzzle its slot named.
                private _choice = _x;

                if (GVAR(category) isEqualTo "magazine" && {(_slot splitString "_") param [1, ""] isEqualTo "mag2"} && {(_slot splitString "_") param [0, ""] isEqualTo _x}) then {
                    _choice = _slot;
                };

                _choices pushBack [[_weapon] call EFUNC(gui,itemName), [_choice], {
                    GVAR(fits) = _this select 0;
                    private _column = uiNamespace getVariable [QGVAR(column), createHashMap];

                    _column set ["dirty", true];
                    _column set ["barDirty", true];
                }];
            };
        } forEach ["primary", "handgun", "launcher", "binocular"];
    };
    // The sorts; the one chosen again turns the order round. After the catalog's own come the ones ACE
    // has for the category (not in a search over every category, which goes by name).
    case "sort": {
        private _pick = {
            params ["_id"];

            GVAR(sort) params [["_now", "name"], ["_ascending", true]];

            GVAR(sort) = [_id, [true, !_ascending] select (_id isEqualTo _now)];
            (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["dirty", true];
            (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["barDirty", true];
        };

        {
            _x params ["_id", "_label"];

            _choices pushBack [_label, [_id], _pick];
        } forEach [
            ["name", LLSTRING(Sort_Name)], ["weight", LLSTRING(Sort_Weight)], ["size", LLSTRING(Sort_Size)], ["mod", LLSTRING(Sort_Mod)]
        ];

        if (EGVAR(gui,filter) isEqualTo "") then {
            {
                _x params ["_id", "_label"];

                _choices pushBack [_label, [_id], _pick, createHashMapFromArray [["separator", _forEachIndex == 0]]];
            } forEach (["list", GVAR(category)] call FUNC(aceSorts));
        };

        _choices pushBack [LLSTRING(Sort_Reverse), [], {
            GVAR(sort) params [["_id", "name"], ["_ascending", true]];

            GVAR(sort) = [_id, !_ascending];
            (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["dirty", true];
            (uiNamespace getVariable [QGVAR(column), createHashMap]) set ["barDirty", true];
        }, createHashMapFromArray [["separator", true]]];
    };
    default {};
};

if (_choices isEqualTo [] || {isNull _display}) exitWith {};

_rect params ["_left", "_top", "_width", "_height"];

[_display, _choices, [_left, _top + _height]] call EFUNC(gui,openMenu);
