#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Shows a category: its group and its chip are chosen, "fits" is set to the weapon of the slot given, the
 * bar is drawn again and the pool is scrolled to where this category was left. Text in the search field is
 * cleared first - the slot or chip asks for that category, not for the search -, and the Items view is
 * brought back if the loadouts were shown.
 *
 * What changes is worked out by the catalog's frame (fnc_catalogFrame), on the next frame.
 *
 * Arguments:
 * 0: Category id <STRING>
 * 1: Slot of the weapon the parts have to fit, "" for the default <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * ["optic", "primary"] call einv_arsenal_fnc_showCategory;
 *
 * Public: No
 */

params [["_id", "", [""]], ["_fits", "", [""]]];

private _column = uiNamespace getVariable [QGVAR(column), createHashMap];
private _categories = call FUNC(categories);
private _index = _categories findIf {(_x select 0) isEqualTo _id};

if (_index < 0) exitWith {};

private _group = (_categories select _index) select 1;

// Where the old category was left.
if (GVAR(category) isNotEqualTo "") then {
    GVAR(scrollRows) set [GVAR(category), _column getOrDefault ["firstRow", 0]];
};

GVAR(group) = _group;
GVAR(category) = _id;
GVAR(lastCategory) set [_group, _id];
GVAR(fits) = _fits;

// The search field is emptied: it would list every category and grey the chips.
if (EGVAR(gui,filter) isNotEqualTo "") then {
    EGVAR(gui,filter) = "";

    private _edit = uiNamespace getVariable [QEGVAR(gui,filterEdit), controlNull];

    if (!isNull _edit) then {
        _edit ctrlSetText "";
        (_edit getVariable [QEGVAR(gui,placeholder), controlNull]) ctrlShow true;
    };

    call EFUNC(gui,applyFilter);
};

_column set ["dirty", true];
_column set ["barDirty", true];
_column set ["searchAt", 0];
_column set ["restoreRow", GVAR(scrollRows) getOrDefault [_id, 0]];
_column set ["firstRow", 0];

// The Loadouts view gives way: the column is made anew for the other view.
if (GVAR(view) isNotEqualTo "items") then {
    GVAR(view) = "items";

    ctrlDelete (_column getOrDefault ["group", controlNull]);
    _column set ["group", controlNull];

    [{
        [uiNamespace getVariable [QEGVAR(gui,display), displayNull]] call EFUNC(gui,build);
    }] call EFUNC(gui,later);
};
