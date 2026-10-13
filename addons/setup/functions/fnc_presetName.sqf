#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * A preset's name as players read it: "Default" for default, "No preset" for none, the id itself for a
 * preset no loaded mod has.
 *
 * Arguments:
 * 0: Preset id <STRING>
 *
 * Return Value:
 * Name <STRING>
 *
 * Example:
 * ["realism"] call einv_setup_fnc_presetName;
 *
 * Public: No
 */

params [["_id", "", [""]]];

_id = toLower _id;

if (_id in ["", "none"]) exitWith {LLSTRING(Preset_None)};

private _preset = (call FUNC(shippedPresets)) select {(_x select 0) isEqualTo _id};

if (_preset isEqualTo []) exitWith {_id};

(_preset select 0) select 1
