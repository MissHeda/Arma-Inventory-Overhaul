#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether an object is a holder another mod uses for its own purpose and that is no loot: Helmet on Ass - Helmet
 * Slinging (Workshop 3487820370) shows a slung helmet or facewear with a ground holder of its own
 * (hoa_groundholder, hoa_groundholder_facewear) - taken for a pile, the vicinity box showed it and an item
 * dropped beside it went into it (issue #36). Such a holder is left out of the nearby list (fnc_getNearby),
 * never joined by a drop (fnc_getGroundHolder) and not opened when the engine names it (fnc_onInventoryOpened).
 * The classes are FOREIGN_HOLDERS (script_component.hpp); a class built on one counts as well.
 *
 * Arguments:
 * 0: Object <OBJECT>
 *
 * Return Value:
 * Is another mod's holder <BOOL>
 *
 * Example:
 * [cursorObject] call aio_storage_fnc_isForeignHolder;
 *
 * Public: No
 */

params [["_object", objNull, [objNull]]];

!isNull _object && {FOREIGN_HOLDERS findIf {_object isKindOf _x} >= 0}
