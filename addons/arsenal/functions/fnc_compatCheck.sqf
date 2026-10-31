#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Checks, once at preInit, that what this addon relies on of ACE is there - the functions and data that
 * open ACE Arsenal with a vanilla box's items - and sets GVAR(ready). Not ready, ACE Arsenal opens without
 * the grid panel, the vanilla Virtual Arsenal stays vanilla, and the RPT says why.
 *
 * The panel also reads ACE's internals: the ids of its list, its "+" arrow and its message line, which tab
 * is open (ace_arsenal_currentLeftPanel), its record of the unit's items (ace_arsenal_currentItems), and
 * calls ace_arsenal_fnc_updateRightPanel, ace_arsenal_fnc_fireItemsChangedEvent and
 * ace_arsenal_fnc_message. Those it can do without are each guarded where they are used; a missing one,
 * or another ACE version than the one checked (ACE_TESTED), gets one line in the RPT.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Ready <BOOL>
 *
 * Example:
 * call aio_arsenal_fnc_compatCheck;
 *
 * Public: No
 */

private _missing = [];

{
    if (isNil _x) then {
        _missing pushBack _x;
    };
} forEach [
    QACEFUNC(arsenal,openBox),
    QACEFUNC(arsenal,addVirtualItems),
    QACEFUNC(common,displayText),
    QACEFUNC(common,canInteractWith)
];

// The list ACE scanned the game's config into at start (a vanilla box with everything in it).
if (isNil {uiNamespace getVariable QACEGVAR(arsenal,configItems)}) then {
    _missing pushBack QACEGVAR(arsenal,configItems);
};

private _ready = _missing isEqualTo [];

if (!_ready) then {
    private _list = _missing joinString " ";

    ERROR_1("ACE Arsenal does not look as this version of the mod expects (missing: %1) - no grid panel and the vanilla Virtual Arsenal stays vanilla.",_list);
};

private _optional = [
    QACEFUNC(arsenal,updateRightPanel), QACEFUNC(arsenal,fireItemsChangedEvent), QACEFUNC(arsenal,message)
] select {isNil _x};

if (_ready && {_optional isNotEqualTo []}) then {
    private _list = _optional joinString " ";

    WARNING_1("ACE Arsenal lacks %1 - the grid panel keeps ACE's list right in a simpler way.",_list);
};

private _version = getText (configFile >> "CfgPatches" >> "ace_arsenal" >> "versionStr");

if (_ready && {(_version select [0, count ACE_TESTED]) isNotEqualTo ACE_TESTED}) then {
    WARNING_2("ACE Arsenal %1 is not the %2 the grid panel was checked against - should it misbehave compare the ids in this addon's script_component.hpp with ACE's defines.hpp.",_version,ACE_TESTED);
};

GVAR(ready) = _ready;

_ready
