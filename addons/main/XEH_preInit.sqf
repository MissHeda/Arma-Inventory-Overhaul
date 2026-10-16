#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The settings of the mod that are the same for everyone - the server's or the mission's to decide - are no
// rows of CBA's menu: the setup wizard's General page edits them, and CBA keeps them in one text box
// (einv_main_settings, see initSettings.inc.sqf), which is parsed into the variables the rest of the mod reads
// (fnc_applySettings). Every addon registers its own with fnc_addSetting, in its initSettings.inc.sqf, where
// it used to call CBA_fnc_addSetting.
//   serverSettings - name (the variable's, einv_gui_searchTime) -> its definition, a HashMap
//   serverKeys     - key (the name without the prefix, lowercase) -> name
//   serverOrder    - the names in the order they were registered
//   settingsApplied - the text box's text has been put into effect at least once, with the scripts
GVAR(serverSettings) = createHashMap;
GVAR(serverKeys) = createHashMap;
GVAR(serverOrder) = [];
GVAR(settingsApplied) = false;

#include "initSettings.inc.sqf"

// Until CBA's settings are ready CBA runs no setting's script: a change of the text then - saved in Eden, which
// never gets that far, or confirmed in CBA's menu there - only reaches CBA's own variable. Its event for that
// (handled by CBA first, which sets the variable) puts the values into the settings' variables as well; once
// the settings are ready, the text's own script does it.
["cba_settings_refreshSetting", {
    params [["_setting", "", [""]]];

    if (!isNil "cba_settings_ready" || {_setting != QGVAR(settings)}) exitWith {};

    [missionNamespace getVariable [QGVAR(settings), ""]] call FUNC(applySettings);
}] call CBA_fnc_addEventHandler;

ADDON = true;
