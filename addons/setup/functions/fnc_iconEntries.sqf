#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The icons of this mod's own (the slot pictures of the equipment column and the symbols of the window, addons\gui\ui), as
 * entries of the picture picker's catalog (fnc_pictureCatalog) for its chip "Category icons": a category is drawn with a picture
 * like these. The name of an entry is its file's name read as words ("slot_cat_medical_ca" is "Medical"). Made once per
 * session, the search of the picker (fnc_searchFilter) applied to it every time.
 *
 * Arguments:
 * 0: The text typed in the picker's search field <STRING> (default: "")
 *
 * Return Value:
 * Entries, [path, lowercase path, search text, name, "", 1, [], [name], ["icons"], key] as the catalog has them <ARRAY>
 *
 * Example:
 * ["med*"] call einv_setup_fnc_iconEntries;
 *
 * Public: No
 */

params [["_typed", "", [""]]];

private _entries = uiNamespace getVariable QGVAR(iconEntries);

if (isNil "_entries") then {
    private _paths = [
        UI_TEX(slot_rifle_ca), UI_TEX(slot_handgun_ca), UI_TEX(slot_launcher_ca), UI_TEX(slot_magazine_ca), UI_TEX(slot_grenade_ca),
        UI_TEX(slot_vest_ca), UI_TEX(slot_uniform_ca), UI_TEX(slot_backpack_ca), UI_TEX(slot_headgear_ca), UI_TEX(slot_goggles_ca),
        UI_TEX(slot_nvg_ca), UI_TEX(slot_binocular_ca), UI_TEX(slot_radio_ca), UI_TEX(slot_gps_ca), UI_TEX(slot_map_ca),
        UI_TEX(slot_compass_ca), UI_TEX(slot_watch_ca), UI_TEX(slot_optic_ca), UI_TEX(slot_muzzle_ca), UI_TEX(slot_rail_ca),
        UI_TEX(slot_bipod_ca), UI_TEX(slot_cat_all_ca), UI_TEX(slot_cat_medical_ca), UI_TEX(slot_cat_food_ca), UI_TEX(slot_cat_misc_ca),
        UI_TEX(icon_star_ca), UI_TEX(icon_unique_ca), UI_TEX(icon_crate_ca), UI_TEX(icon_ground_ca), UI_TEX(icon_inventory_ca),
        UI_TEX(icon_weight_ca), UI_TEX(icon_lock_ca), UI_TEX(icon_person_ca), UI_TEX(icon_eye_ca), UI_TEX(icon_vision_ca),
        UI_TEX(icon_camera_ca), UI_TEX(icon_arsenal_ca), UI_TEX(icon_loadouts_ca), UI_TEX(icon_share_ca), UI_TEX(icon_swap_ca),
        UI_TEX(icon_unload_ca), UI_TEX(icon_giveback_ca)
    ];

    _entries = _paths apply {
        private _path = _x;
        private _parts = _path splitString (toString [92]);
        private _file = _parts select (count _parts - 1);

        // "slot_cat_medical_ca.paa" -> "Medical"
        private _words = _file select [0, count _file - 4];

        if ((_words select [count _words - 3]) isEqualTo "_ca") then {
            _words = _words select [0, count _words - 3];
        };

        {
            if ((_words select [0, count _x]) isEqualTo _x) then {
                _words = _words select [count _x];
            };
        } forEach ["slot_", "icon_", "cat_"];

        _words = (_words splitString "_") joinString " ";

        private _name = (toUpper (_words select [0, 1])) + (_words select [1]);

        [_path, toLowerANSI _path, toLowerANSI (_name + " " + _path), _name, "", 1, [], [_name], ["icons"], [_path] call FUNC(pictureKey)]
    };

    uiNamespace setVariable [QGVAR(iconEntries), _entries];
};

private _filter = [_typed] call FUNC(searchFilter);

if (_filter isEqualTo []) exitWith {_entries};

_filter params [["_needle", "", [""]], ["_expression", "", [""]], ["_literal", "", [""]]];

if (_expression isEqualTo "") exitWith {
    _entries select {((_x select 2) find _needle) >= 0}
};

_entries select {
    (_literal isEqualTo "" || {((_x select 2) find _literal) >= 0})
    && {(_x select 1) regexMatch _expression || {(toLowerANSI (_x select 3)) regexMatch _expression}}
}
