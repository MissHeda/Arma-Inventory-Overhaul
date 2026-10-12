#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the footer's hint adds for what the mouse is on (the "hint" hook): on a card the size, weight,
 * rounds and "You carry 3"; on an item of the soldier's "Not in this arsenal"; on nothing what the click
 * does.
 *
 * Arguments:
 * 0: "tile", "slot" or "none" <STRING>
 * 1: Class <STRING>
 * 2: The tile or the slot's record <HASHMAP or ARRAY>
 *
 * Return Value:
 * Parts [[text, colour key], ...] <ARRAY>
 *
 * Example:
 * ["tile", "arifle_MX_F", _tile] call einv_arsenal_fnc_hintParts;
 *
 * Public: No
 */

params [["_kind", "none", [""]], ["_class", "", [""]], ["_what", createHashMap, [createHashMap, []]]];

private _parts = [];

switch (_kind) do {
    case "tile": {
        // A card of the catalog: the figures it shows besides the window's own, and what the soldier has.
        if (_what isEqualType createHashMap && {_what getOrDefault ["card", false]}) then {
            private _identity = (_what getOrDefault ["kind", ""]) in ["face", "voice", "insignia"];

            if (!_identity) then {
                private _row = [_class] call FUNC(catalogRow);
                private _carried = GVAR(carried) getOrDefault [_row param [ROW_KEY, ""], 0];

                if (_carried > 0) then {
                    _parts pushBack [format [LLSTRING(Catalog_Carried), _carried], "accent"];
                };
            };
        } else {
            // Something the soldier has and the box lacks.
            if (_what isEqualType createHashMap && {[_what] call FUNC(isUnique)}) then {
                _parts pushBack [LLSTRING(Hint_Unique), "loss"];
            };
        };
    };
    case "slot": {
        if (_class isNotEqualTo "" && {[_class] call FUNC(isUnique)}) then {
            _parts pushBack [LLSTRING(Hint_Unique), "loss"];
        };
    };
    default {};
};

_parts
