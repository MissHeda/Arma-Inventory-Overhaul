#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Takes one field of a class in the Items or Containers step back to its default, at once: the rule of the class
 * (or of its tree) loses that field - and so the answer is what the rest of the draft makes of it
 * (fnc_classDefault) -, and what was drawn in the editor and not applied yet for it is dropped with it. What the
 * editor holds for other fields stays. Ends in fnc_upsertRule: an undo step, and the step drawn again.
 *
 * Arguments:
 * 0: Class <STRING>
 * 1: The step, "items" or "containers" <STRING>
 * 2: The fields to take away, as the rules write them: "footprint", "stack", "weight", "name", "use", "cats", "grid",
 *    "like" <ARRAY>
 * 3: For the class and everything built on it <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["V_PlateCarrier1_rgr", "containers", ["grid", "like"]] call einv_setup_fnc_resetField;
 *
 * Public: No
 */

params [["_class", "", [""]], ["_mode", "items", [""]], ["_fields", [], [[]]], ["_tree", false, [false]]];

private _lc = toLowerANSI _class;

if (_mode isEqualTo "containers") then {
    GVAR(cellWork) deleteAt _lc;
} else {
    private _canvas = GVAR(itemWork) getOrDefault [_lc, createHashMap];

    if (count _canvas > 0) then {
        // The cells go back to the shape the class would have; the editor's other fields are kept as they are.
        if ("footprint" in _fields) then {
            private _footprint = ([_class, ["footprint"]] call FUNC(classDefault)) getOrDefault ["footprint", [1, 1, []]];
            private _fresh = [[_footprint], SHAPE_MAX, SHAPE_MAX, SHAPE_MAX] call FUNC(canvasFromBlocks);

            _fresh set ["start", [_fresh] call FUNC(canvasBlocks)];

            {
                private _value = _canvas get _x;

                if (!isNil "_value") then {
                    _fresh set [_x, _value];
                };
            } forEach ["stack", "weightText", "nameText", "iconPercent", "pictureText", "useList", "catsList"];

            _canvas = _fresh;
            GVAR(itemWork) set [_lc, _canvas];
        };

        // Dropped, the field is what the draft says: the default once its rule is gone.
        {
            private _key = ["stack", "weight", "name", "use", "cats"] find _x;

            if (_key >= 0) then {
                _canvas deleteAt (["stack", "weightText", "nameText", "useList", "catsList"] select _key);
            };
        } forEach _fields;
    };
};

[_class, createHashMap, _fields, _tree] call FUNC(upsertRule);
