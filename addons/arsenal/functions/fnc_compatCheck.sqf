#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * Checks, once at preInit, that what this addon relies on of ACE is there - the functions and data it
 * calls, and the version its display patch was checked against (ACE_TESTED) - and sets GVAR(ready). Not
 * ready, ACE's own window opens every time and the RPT says why.
 *
 * A newer ACE than the one checked only gets a line in the RPT: the display patch (CfgAceArsenal.hpp)
 * replaces ACE's onLoad string, so an ACE that changed it would not reach the game until the patch is
 * compared with the new RscAttributes.hpp.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Ready <BOOL>
 *
 * Example:
 * call einv_arsenal_fnc_compatCheck;
 *
 * Public: No
 */

private _missing = [];

// The functions of ACE the window calls, or hands the session over to.
{
    if (isNil _x) then {
        _missing pushBack _x;
    };
} forEach [
    QACEFUNC(arsenal,openBox),
    QACEFUNC(arsenal,open3DEN),
    QACEFUNC(arsenal,onArsenalOpen),
    QACEFUNC(arsenal,addVirtualItems),
    QACEFUNC(arsenal,updateVirtualItemsFlat),
    QACEFUNC(arsenal,updateUniqueItemsList),
    QACEFUNC(arsenal,updateCurrentItemsList),
    QACEFUNC(arsenal,verifyLoadout),
    QACEFUNC(arsenal,replaceUniqueItemsLoadout),
    QACEFUNC(common,displayText),
    QACEFUNC(common,showHud),
    QACEFUNC(common,getConfigName)
];

// The lists ACE scanned the game's config into at start.
{
    if (isNil {uiNamespace getVariable _x}) then {
        _missing pushBack _x;
    };
} forEach [QACEGVAR(arsenal,configItems), QACEGVAR(arsenal,configItemsFlat)];

private _ready = _missing isEqualTo [];

if (!_ready) then {
    private _list = _missing joinString " ";

    ERROR_1("ACE Arsenal does not look as this version of the mod expects (missing: %1) - ACE's own window opens.",_list);
};

private _version = getText (configFile >> "CfgPatches" >> "ace_arsenal" >> "versionStr");

if (_ready && {(_version select [0, count ACE_TESTED]) isNotEqualTo ACE_TESTED}) then {
    WARNING_2("ACE Arsenal %1 is newer than the %2 this window's display patch was checked against - check CfgAceArsenal.hpp.",_version,ACE_TESTED);
};

GVAR(ready) = _ready;

_ready
