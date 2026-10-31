#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Sorts a container or a kit: the holder's places emptied and everything laid out anew by the order the
 * player has chosen - by name, heaviest first, largest first or by kind (SORT_MODES) - by its authority,
 * for everyone who looks into it (the storage's op "sort", fnc_sendMoves). The Sort button on a section's
 * caption line (fnc_drawSection) and on a kit window's title row (fnc_drawWindow) come here. The order is
 * each player's own, kept in the profile; it travels with the op, which runs where the container's root is
 * local and writes the places everyone reads, so the result is the same on every machine.
 *
 * A click on the button steps to the next order first ("step"), and every Sort button on the window shows
 * the new one at once (fnc_sortButtons).
 *
 * A rearrangement is a rummage and it cannot be refused: it sounds when it is sent. Clicked fast, the button steps the order with
 * every click but sends one sort per COALESCE_REQUEST, the latest order (fnc_coalesce) - the profile is written then too.
 *
 * Arguments:
 * 0: The container, or the key of a kit's grid <OBJECT or STRING>
 * 1: Its root, objNull to look it up (aio_storage_fnc_rootOf) <OBJECT> (default: objNull)
 * 2: Step to the next order first <BOOL> (default: false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [cursorObject, objNull, true] call aio_gui_fnc_sortHolder;
 *
 * Public: No
 */

params ["_holder", ["_root", objNull, [objNull]], ["_step", false, [false]]];

if (_holder isEqualType objNull && {isNull _holder}) exitWith {};

if (_step) then {
    GVAR(sortMode) = SORT_MODES select (((SORT_MODES find GVAR(sortMode)) + 1) mod count SORT_MODES);

    profileNamespace setVariable [QGVAR(sortMode), GVAR(sortMode)];

    // Every Sort button shows the new order, the one that was clicked included.
    [] call FUNC(sortButtons);
};

// The sort itself (a request to the authority and the profile written to disk) goes out once per rest for a run of clicks, with the
// order the last of them left (fnc_coalesce): a click steps the order and shows it at once, what is sent is the latest.
[format ["sort|%1", _holder], {
    params ["_holder", "_root", "_step"];

    if (_step) then {
        saveProfileNamespace;
    };

    ["search", "", [_holder, objNull] select (_holder isEqualType "")] call FUNC(playSound);

    [[createHashMapFromArray [["kind", "sort"], ["from", _holder], ["fromRoot", _root], ["order", GVAR(sortMode)]]]] call FUNC(sendMoves);
}, [_holder, _root, _step], COALESCE_REQUEST] call FUNC(coalesce);
