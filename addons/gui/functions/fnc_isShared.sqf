#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a change to a holder has to go through the server's hub: its root is not one this machine
 * changes at once (einv_storage_fnc_isLocalRoot) - in multiplayer everything but the player's own
 * uniform, vest and backpack and what lies in them, at any depth. Kept for the other features' rules;
 * the window's own moves ask the storage themselves (fnc_sendMoves).
 *
 * A uniform, vest or backpack opened from inside another container is found by where it was opened
 * (einv_storage_fnc_rootOf): one lying in the player's own backpack is the player's own, one lying in a
 * crate is the crate's. A holder with no known root counts as shared.
 *
 * Arguments:
 * 0: Holder - a container, or a key like "kit:..." <OBJECT or STRING>
 *
 * Return Value:
 * Shared <BOOL>
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_isShared;
 *
 * Public: No
 */

params [["_container", objNull, [objNull, ""]]];

if (_container isEqualType objNull && {isNull _container}) exitWith {false};

private _parent = objNull;

if (_container isEqualType objNull) then {
    private _index = GVAR(opened) findIf {(_x select 1) isEqualTo _container};

    if (_index >= 0) then {
        _parent = (GVAR(opened) select _index) param [2, objNull];
    };
};

!([[_container, _parent] call EFUNC(storage,rootOf)] call EFUNC(storage,isLocalRoot))
