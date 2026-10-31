#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * This addon's part of the window's signature (einv_gui_fnc_getSignature): a count of changes to the
 * kits it shows, and the revision of each open kit's places. A kit's contents and name change without
 * any cargo changing, and another player rearranging an open kit changes only its places - written by
 * the kit's authority as a public variable (einv_storage_fnc_writePlaces), which raises no event here -
 * so the window would not see either otherwise. The kits the ACE Arsenal's panel shows as sections
 * (GVAR(arsenalHolders)) count as open ones: a tile moved within one changes only its places too.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [count of changes, [revision of each open kit's places, in the order they were opened], [revision of each
 * kit section's places in the Arsenal's panel, by class]] <ARRAY>
 *
 * Example:
 * call einv_compat_efak_fnc_signature;
 *
 * Public: No
 */

private _arsenal = keys GVAR(arsenalHolders);
_arsenal sort true;

[
    GVAR(stamp),
    GVAR(opened) apply {(["kit:" + toLowerANSI _x] call EFUNC(storage,readPlaces)) param [0, 0]},
    _arsenal apply {(["kit:" + _x] call EFUNC(storage,readPlaces)) param [0, 0]}
]
