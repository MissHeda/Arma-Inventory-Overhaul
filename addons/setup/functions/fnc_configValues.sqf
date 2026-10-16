#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keys of an item's config (einv_items_fnc_parseConfigEntry) as the values of a rule: einv_size is
 * "footprint", einv_stack "stack", einv_grid "grid", einv_weight "weight", einv_name "name", einv_icon
 * "icon", einv_picture "picture" and einv_use "use". The one place the two names are matched - the import of config lines
 * (fnc_importClasses) and the layout export (fnc_exportClasses) both read it.
 *
 * Arguments:
 * 0: The keys, by lowercase config key <HASHMAP>
 *
 * Return Value:
 * The values, by field of a rule, as fnc_upsertRules takes them <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["einv_grid", "6x4"]]] call einv_setup_fnc_configValues;
 *
 * Public: No
 */

params [["_keys", createHashMap, [createHashMap]]];

private _values = createHashMap;

{
    _x params ["_key", "_field"];

    if (_key in _keys) then {
        _values set [_field, _keys get _key];
    };
} forEach [
    ["einv_size", "footprint"], ["einv_stack", "stack"], ["einv_grid", "grid"], ["einv_weight", "weight"], ["einv_name", "name"],
    ["einv_icon", "icon"], ["einv_picture", "picture"], ["einv_use", "use"]
];

_values
