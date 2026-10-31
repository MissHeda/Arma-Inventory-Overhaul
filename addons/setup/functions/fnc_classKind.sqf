#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * What the wizard's lists make of a config class: its kind, the family the Items step filters by, and what
 * it holds. One answer for the class index (fnc_indexChunk) and the tree view (fnc_treeRows), so a tree
 * lists exactly the kinds the step lists.
 *
 *   CfgWeapons   - rifles, handguns, launchers, binoculars and NVGs (weapon types 1, 2, 4, 4096) and
 *                  items (131072): uniforms, vests, headgear, attachments, kits of Enhanced First Aid
 *                  Kits (the type's own class, einv_items_fnc_kitOf - an item and a container both, its
 *                  load the capacity), the rest. Vehicle weapons have other types and are left out (""),
 *                  and so are the instance classes that mod makes of a kit: the kit's own class covers
 *                  them (class=X+, fnc_editScope).
 *   CfgMagazines - those with a picture: the ones a player carries.
 *   CfgGlasses   - goggles.
 *   CfgVehicles  - backpacks, crates (ReammoBox_F) and vehicles that hold something; no soldiers.
 * Whether the class is public (scope), named ..._Base or already listed under another root is not asked
 * here.
 *
 * Arguments:
 * 0: The class's config <CONFIG>
 * 1: The root it is in, one of INDEX_ROOTS <STRING>
 *
 * Return Value:
 * [kind, family, load] <ARRAY>
 *   kind   - the wizard's kind ("rifle", "uniform", "backpack", ...), "" for a class the lists leave out
 *   family - "weapon", "magazine", "gear", "item" or "cargo"; "" with no kind
 *   load   - what a container holds (config mass), 0 for anything else; a uniform or vest holds what the
 *            container class it brings along holds, a kit its capacity
 *
 * Example:
 * [configFile >> "CfgVehicles" >> "B_Carryall_blk", "CfgVehicles"] call einv_setup_fnc_classKind;
 *
 * Public: No
 */

params [["_config", configNull, [configNull]], ["_rootName", "", [""]]];

private _class = configName _config;
private _lc = toLowerANSI _class;
private _load = 0;

// [kind, family] - the family is what the Items step filters by; "" leaves the class out.
private _found = switch (_rootName) do {
    case "CfgWeapons": {
        private _type = getNumber (_config >> "type");
        private _itemType = getNumber (_config >> "ItemInfo" >> "type");

        // A kit of Enhanced First Aid Kits: [prototype, instance number (0 for the type's own class), ...].
        private _kit = if (_type == 131072) then {[_class] call EFUNC(items,kitOf)} else {[]};

        switch (true) do {
            case (_itemType == 616): {["nvg", "gear"]};
            case (_type == 1): {["rifle", "weapon"]};
            case (_type == 2): {["handgun", "weapon"]};
            case (_type == 4): {["launcher", "weapon"]};
            case (_type == 4096): {["binocular", "weapon"]};
            case (_type != 131072): {["", ""]};
            case (_itemType == 801): {["uniform", "gear"]};
            case (_itemType == 701): {["vest", "gear"]};
            case (_itemType == 605): {["headgear", "gear"]};
            // A kit before what its item type says (an attachment's, as CBA's misc items have): the
            // type's own class only.
            case ((_kit param [1, -1]) == 0): {
                _load = _kit select 3;
                ["kit", "item"]
            };
            case (_kit isNotEqualTo []): {["", ""]};
            case (_itemType in [101, 201, 301, 302]): {["attachment", "item"]};
            default {["item", "item"]};
        };
    };
    case "CfgMagazines": {
        [["", ""], ["magazine", "magazine"]] select (getText (_config >> "picture") isNotEqualTo "")
    };
    case "CfgGlasses": {
        [["goggles", "gear"], ["", ""]] select (_lc isEqualTo "none")
    };
    default {
        _load = getNumber (_config >> "maximumLoad");

        // A backpack that holds nothing by its config (a cosmetic one, a radio pack) is still listed: an
        // own grid gives it cells like any other, and its card says it has none until then
        // (fnc_answerText). A crate or vehicle without a load is no container.
        switch (true) do {
            case (getNumber (_config >> "isBackpack") == 1): {["backpack", "gear"]};
            case (_load <= 0): {["", ""]};
            case (_class isKindOf "ReammoBox_F"): {["crate", "cargo"]};
            case (_class isKindOf "AllVehicles" && {!(_class isKindOf "CAManBase")}): {["vehicle", "cargo"]};
            default {["", ""]};
        };
    };
};

_found params ["_kind", "_family"];

// A uniform or vest holds what the container class it brings along holds.
if (_kind in ["uniform", "vest"]) then {
    _load = getNumber (configFile >> "CfgVehicles" >> getText (_config >> "ItemInfo" >> "containerClass") >> "maximumLoad");
};

[_kind, _family, _load]
