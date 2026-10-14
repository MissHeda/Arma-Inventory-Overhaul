#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Puts the rules the settings say into effect, on this machine: compiles them (fnc_compileRules) with
 * the older tables and sliders, names in the RPT what could not be read, forgets every item worked out
 * under the old rules (what config says stays, fnc_getFacts) and tells everyone who keeps something
 * worked out from them: the local CBA event einv_items_rulesChanged, with the new revision.
 *
 * Every setting that feeds the rules runs this when it changes, on every machine - CBA hands a
 * changed setting to all of them. Nothing happens when what it reads is what was compiled last: when
 * CBA reads all settings at the start, the first script compiles and the others have nothing to do.
 *
 * The server then publishes what it compiled (einv_items_rulesHash: a key of its settings, the hash of
 * its compiled rules and its version). A client that compiled the same settings into another hash
 * reads them differently - another version of the mod or of a preset - and says so once
 * (fnc_checkServerRules). Only the same settings are compared: the published hash and CBA's
 * settings reach a client in either order. Another mod setting einv_grid and the like in its config
 * does not show in the hash.
 *
 * A rules text given here stands in for the setting's, for testing, in single player or on the server only: it is kept
 * (einv_items_rulesOverride) and read in the setting's place (fnc_rulesInputs), so fnc_currentRules
 * does not compile the setting's text again behind its back and everything that asks for the rules
 * gets the test text. It holds until an empty text is given - a change to einv_items_rules shows
 * only after that.
 *
 * Arguments:
 * 0: Rules text to put into effect instead of the setting's, for testing; "" goes back to the
 *    setting's <STRING> (default: leave it as it is)
 *
 * Return Value:
 * The rules were compiled again <BOOL>
 *
 * Example:
 * [] call einv_items_fnc_loadRules;
 * ["einv1 base=realism"] call einv_items_fnc_loadRules;
 * [""] call einv_items_fnc_loadRules;
 *
 * Public: No
 */

params [["_text", nil, [""]]];

// The rules are the server's, the same for everyone: a client in multiplayer may not put a text of
// its own into effect, not even from the debug console. The hook stays for single player and the server.
if (!isNil "_text" && {isMultiplayer && {!isServer}}) then {
    diag_log text "einv: rules override ignored on a client - the rules are the server's";
    _text = nil;
};

if (!isNil "_text") then {
    if (_text isEqualTo "") then {
        GVAR(rulesOverride) = nil;
    } else {
        GVAR(rulesOverride) = _text;
    };
};

private _inputs = call FUNC(rulesInputs);

if (!isNil QGVAR(ruleset) && {_inputs isEqualTo GVAR(rulesInputs)}) exitWith {false};

private _compiled = [_inputs select 0, true] call FUNC(compileRules);

{
    WARNING_1("Rules: %1",_x);
} forEach (_compiled get "warnings");

// Everything in place before anyone hears of it: a listener asking for an item gets the new rules.
GVAR(ruleset) = _compiled;
GVAR(rulesInputs) = _inputs;
GVAR(rulesInputsKey) = hashValue _inputs;
GVAR(info) = createHashMap;
GVAR(rulesRevision) = GVAR(rulesRevision) + 1;

// Nothing to publish in Eden: there is nobody to compare with.
if (isServer && {!is3DEN}) then {
    private _published = [GVAR(rulesInputsKey), _compiled get "hash", QUOTE(VERSION_STR)];
    missionNamespace setVariable [QGVAR(rulesHash), _published, true];
    [QGVAR(rulesPublished), [_published]] call CBA_fnc_remoteEvent;
};

[] call FUNC(checkServerRules);

[QGVAR(rulesChanged), [GVAR(rulesRevision)]] call CBA_fnc_localEvent;

true
