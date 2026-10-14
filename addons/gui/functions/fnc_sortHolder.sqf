#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Sorts a container or a kit: the holder's places emptied and everything laid out anew - largest first, by
 * kind - by its authority, for everyone who looks into it (the storage's op "sort", fnc_sendMoves). The
 * Sort button on a section's caption line (fnc_drawSection) and on a kit window's title row
 * (fnc_drawWindow) and the "Sort" row of the context menu (fnc_contextMenu) all come here.
 *
 * A rearrangement is a rummage and it cannot be refused: it sounds when it is sent.
 *
 * Arguments:
 * 0: The container, or the key of a kit's grid <OBJECT or STRING>
 * 1: Its root, objNull to look it up (einv_storage_fnc_rootOf) <OBJECT> (default: objNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject] call einv_gui_fnc_sortHolder;
 *
 * Public: No
 */

params ["_holder", ["_root", objNull, [objNull]]];

if (_holder isEqualType objNull && {isNull _holder}) exitWith {};

["search", "", [_holder, objNull] select (_holder isEqualType "")] call FUNC(playSound);

[[createHashMapFromArray [["kind", "sort"], ["from", _holder], ["fromRoot", _root]]]] call FUNC(sendMoves);
