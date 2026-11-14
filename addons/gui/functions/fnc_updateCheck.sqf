#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a newer Arma Inventory Overhaul than this build is on the Workshop - asked of a file in the mod's repository on
 * GitHub, since a script can ask neither Steam nor the Workshop: updates/outdated/<version>.html is there for every released
 * version a newer release replaced (tools/mark_outdated.py, run with a Workshop update). The engine only tells whether the
 * address loaded (htmlLoad, ctrlHTMLLoaded), which is all that is asked. The address is allowed in this mod's config
 * (CfgCommands, addons/main/config.cpp).
 *
 * The game stands still while the address loads - 0.2 to 0.5 seconds measured, 0.7.21 -, so it is asked once per game, as the
 * mission's display comes up (XEH_postInit), and the answer kept until the game ends (uiNamespace). No connection, or the
 * player's setting aio_gui_updateCheck off: nothing known, which reads as up to date. So does a mission or a dedicated server
 * with a CfgCommands of its own: that list counts in place of this mod's, and the address is refused at once.
 *
 * A host that cannot be found answers at once (37 ms); one that never answers holds the game for 21 seconds (both measured,
 * 0.7.23). A profile that met that once is not asked again (UPDATE_SLOW).
 *
 * Arguments:
 * 0: Version asked about <STRING> (default: this build's)
 * 1: Ask now, whatever the setting says or was answered before, and keep nothing - for a test <BOOL> (default: false)
 *
 * Return Value:
 * "outdated", "current" (no newer one known), or "" when it was not asked <STRING>
 *
 * Example:
 * call aio_gui_fnc_updateCheck;
 *
 * Public: No
 */

// Without its two slashes in a row: in a macro the preprocessor takes them for a comment and cuts the address off there.
// From how many seconds on an answer counts as too slow to ask again.
#define UPDATE_SLOW 3

#define UPDATE_HOST "raw.githubusercontent.com/MissHeda/Arma-Inventory-Overhaul/main/updates/outdated"

params [["_version", QUOTE(VERSION_STR), [""]], ["_test", false, [false]]];

if (!hasInterface) exitWith {""};

private _known = uiNamespace getVariable [QGVAR(updateState), ""];

if (!_test && {_known isNotEqualTo ""}) exitWith {_known};
if (!_test && {!(missionNamespace getVariable [QGVAR(updateCheck), true])}) exitWith {""};

// A connection on which the address took UPDATE_SLOW seconds or more once - a host that does not answer holds the game for
// 21 seconds, measured 0.7.23 - is not asked again from this profile.
if (!_test && {profileNamespace getVariable [QGVAR(updateCheckSlow), false]}) exitWith {""};

// Numbers and dots only: the version goes into an address.
if !(_version regexMatch "[0-9]+(\.[0-9]+)*") exitWith {""};

disableSerialization;

private _display = findDisplay 46;

if (isNull _display) exitWith {""};

// A control off the screen: only whether it loaded counts.
private _html = _display ctrlCreate ["RscHTML", -1];

_html ctrlSetPosition [safeZoneX - 1, safeZoneY - 1, 0.01, 0.01];
_html ctrlCommit 0;

private _start = diag_tickTime;

_html htmlLoad format ["https:%1%1%2/%3.html", "/", UPDATE_HOST, _version];

private _state = ["current", "outdated"] select (ctrlHTMLLoaded _html);

ctrlDelete _html;

private _took = diag_tickTime - _start;

INFO_3("Update check: version %1 is %2 (asked in %3 ms).",_version,_state,round (_took * 1000));

if (!_test && {_took >= UPDATE_SLOW}) then {
    profileNamespace setVariable [QGVAR(updateCheckSlow), true];
    saveProfileNamespace;
    WARNING_1("The update check held the game for %1 s - it is off for this profile from now on.",round _took);
};

if (!_test) then {
    uiNamespace setVariable [QGVAR(updateState), _state];
};

_state
