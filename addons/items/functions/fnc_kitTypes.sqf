#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * The kit types Enhanced First Aid Kits knows - a pouch type of Enhanced Utility Pouches as well -, from
 * its registry in config (EFAK_Kits): each type's own class (the prototype, "efak_IFAK"), how many
 * instance classes that mod makes of it ("efak_IFAK_1" and on) and the capacity its config gives it. The
 * same list that mod reads for its own efak_core_fnc_isKit, read here from config, so it is known in the
 * editor and the game's menus too, where none of that mod's functions run. Config does not change while
 * the game runs, so it is read once and kept in uiNamespace. Without that mod there is no registry and no
 * kit.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Lowercase prototype class -> [prototype as config names it, how many instances, capacity in config
 * mass]; shared, do not change it <HASHMAP>
 *
 * Example:
 * [] call aio_items_fnc_kitTypes;
 *
 * Public: No
 */

private _kitTypes = uiNamespace getVariable QGVAR(kitTypes);

if (isNil "_kitTypes") then {
    _kitTypes = createHashMap;

    private _cfgWeapons = configFile >> "CfgWeapons";

    {
        private _item = getText (_x >> "item");

        if (_item isNotEqualTo "" && {isClass (_cfgWeapons >> _item)}) then {
            _kitTypes set [toLowerANSI _item, [
                configName (_cfgWeapons >> _item), (getNumber (_x >> "instances")) max 1, (getNumber (_x >> "capacity")) max 1
            ]];
        };
    } forEach ("true" configClasses (configFile >> "EFAK_Kits"));

    uiNamespace setVariable [QGVAR(kitTypes), _kitTypes];
};

_kitTypes
