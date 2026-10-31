#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The keys of an item's config (aio_items_fnc_parseConfigEntry) as the values of a rule: aio_size is
 * "footprint", aio_stack "stack", aio_grid "grid", aio_weight "weight", aio_name "name", aio_icon
 * "icon", aio_picture "picture", aio_use "use" and aio_cat "cats". The one place the two names are matched - the import of config lines
 * (fnc_importClasses) and the layout export (fnc_exportClasses) both read it.
 *
 * Arguments:
 * 0: The keys, by lowercase config key <HASHMAP>
 *
 * Return Value:
 * The values, by field of a rule, as fnc_upsertRules takes them <HASHMAP>
 *
 * Example:
 * [createHashMapFromArray [["aio_grid", "6x4"]]] call aio_setup_fnc_configValues;
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
    ["aio_size", "footprint"], ["aio_stack", "stack"], ["aio_grid", "grid"], ["aio_weight", "weight"], ["aio_name", "name"],
    ["aio_icon", "icon"], ["aio_picture", "picture"], ["aio_use", "use"], ["aio_cat", "cats"]
];

_values
