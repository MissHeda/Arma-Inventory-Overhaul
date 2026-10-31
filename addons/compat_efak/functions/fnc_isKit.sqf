#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a class is a kit of Enhanced First Aid Kits or a pouch of Enhanced Utility Pouches - a kit
 * nobody has carried yet (a prototype) as well as one with contents of its own.
 *
 * Arguments:
 * 0: Class <STRING>
 *
 * Return Value:
 * A kit <BOOL>
 *
 * Example:
 * ["efak_IFAK_7"] call aio_compat_efak_fnc_isKit;
 *
 * Public: Yes
 */

params [["_class", "", [""]]];

_class isNotEqualTo "" && {[_class] call EFAKFUNC(core,isKit)}
