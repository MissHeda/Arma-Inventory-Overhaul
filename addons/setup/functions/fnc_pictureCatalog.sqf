#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The catalog the picture picker (fnc_drawPicturePicker) searches: every picture of every class the wizard
 * indexes (fnc_buildIndex), once each, with the classes and names that own it - the item picture a rule can
 * ask for with picture=. Built from the class index's rows, in pieces of a few milliseconds
 * (fnc_pictureChunk) like the index itself, so the window never stands still; this starts that, or picks it
 * up again, and says whether it is done. It waits for the index.
 *
 * Kept in uiNamespace for the whole game session, as the index is: classes do not change while the game runs.
 * An entry is [path, path in lowercase, what a search looks through, name of the first owner, class of the first
 * owner, how many classes own it, their classes in lowercase (PICKER_OWNERS at most), their names, the categories
 * of its owners - "items", "gear", "vehicles", fnc_pictureCategory, its key - fnc_pictureKey, the class that
 * owned it last]; the list is sorted by the first owner's name, and "byPath" holds the entries by key.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The catalog is complete <BOOL>
 *
 * Example:
 * call aio_setup_fnc_pictureCatalog;
 *
 * Public: No
 */

private _catalog = uiNamespace getVariable QGVAR(pictures);

if (isNil "_catalog") then {
    // entries - by lowercase path while it is read; list - the sorted entries once complete
    // position - how many rows have been passed; token, tick - which run of pieces is the live one, and when it last ran
    _catalog = createHashMapFromArray [
        ["done", false],
        ["entries", createHashMap],
        ["list", []],
        ["position", 0],
        ["token", 0],
        ["tick", -1]
    ];

    uiNamespace setVariable [QGVAR(pictures), _catalog];
};

if (_catalog get "done") exitWith {true};

// The rows are the index's: wait for it.
if !(call FUNC(buildIndex)) exitWith {false};

// A run of pieces goes on every frame while it is busy; one that has not run for a second was dropped (the window
// closed) and a new run takes over where it stopped.
if (diag_tickTime - (_catalog get "tick") > 1) then {
    private _token = (_catalog get "token") + 1;

    _catalog set ["token", _token];
    _catalog set ["tick", diag_tickTime];

    [FUNC(pictureChunk), [_token]] call FUNC(defer);
};

false
