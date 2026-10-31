#include "..\script_component.hpp"
#include "..\defines.hpp"
/*
 * Author: Miss Heda
 * The sound of something happening to an item or a container, by what it is: a rifle lifted sounds like a
 * rifle, a magazine like a magazine pulled from a pouch, a vest like webbing and buckles, a bandage like a
 * crinkling packet, a crate opened like its latch. The table is the config CfgAioSounds (families of
 * actions, each up to four variants of up to three layers, all of Arma's own files by their paths); an item
 * picks its family with the config entry aio_sound, else it is found by what the item is
 * (fnc_soundFamily). Without a class the family is the container's (fnc_containerFamily).
 *
 * The looter hears it on the interface, through the effects bus, so the game's effects volume, earplugs
 * and a blast's deafness apply, times the volume of its kind and the master volume the player set in the
 * dropdown under the speaker in the header (fnc_soundGain, fnc_openSoundMenu); at 0 he hears nothing. Others
 * near the looter hear the louder ones, quieter, where his hands are (aio_gui_soundsWorld, fnc_sendNoise) -
 * the dropdown does not touch that. The same sound twice within a moment plays once; of several variants
 * never the one before.
 *
 * Actions: "lift" (an item picked up), "move" (put into a container), "drop" (onto the ground), "equip",
 * "unequip", "attach", "detach", "loadMag", "loadMagHandgun", "loadMagLauncher", "loadMagUgl", "unloadMag",
 * "rotate", "open", "close", "search", "uncover" (an item found), "inspect" and "giveBack" (taken out of a
 * container in the Arsenal panel). The old kinds keep working: "put" is "move", and ["lift"], ["search"] and ["giveBack"] with
 * no class sound as an item of no family.
 *
 * Every change of the window sounds when its answer is finished (fnc_feelAnswer), a pick-up and a turn
 * at once. The settings are read with their defaults: the Arsenal panel plays in Eden, where CBA's
 * settings may not be there.
 *
 * Arguments:
 * 0: The action <STRING> (default: "move")
 * 1: The item's class, "" for a container's sound <STRING> (default: "")
 * 2: The container it is about, for the sound of a container <OBJECT> (default: objNull)
 * 3: Others hear it too, as the action's range says <BOOL> (default: true)
 * 4: The looter hears it <BOOL> (default: true)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["lift", "arifle_MX_F"] call aio_gui_fnc_playSound;
 * ["open", "", cursorObject] call aio_gui_fnc_playSound;
 *
 * Public: Yes
 */

params [["_action", "move", [""]], ["_class", "", [""]], ["_container", objNull, [objNull]], ["_world", true, [true]], ["_ui", true, [true]]];

// The kinds of 0.1.15: put is a move now.
if (_action isEqualTo "put") then {
    _action = "move";
};

if (_action isEqualTo "") exitWith {};

private _family = if (_class isEqualTo "") then {
    [_container] call FUNC(containerFamily)
} else {
    [_class] call FUNC(soundFamily)
};

private _def = [_family, _action] call FUNC(soundDef);
private _variants = _def getOrDefault ["variants", []];

if (_variants isEqualTo [] && {(_def getOrDefault ["fallback", []]) isEqualTo []}) exitWith {};

// The same sound twice within a moment (the wheel, R held down) plays once; a sound with several variants
// never repeats the one before.
private _now = diag_tickTime;
private _key = _family + "|" + _action;

(GVAR(soundLast) getOrDefault [_key, [-1, -1]]) params ["_lastAt", "_lastVariant"];

if (_now - _lastAt < SOUND_REPEAT_GAP) exitWith {};

private _index = floor random (count _variants max 1);

if (count _variants > 1 && {_index == _lastVariant}) then {
    _index = (_index + 1) mod count _variants;
};

GVAR(soundLast) set [_key, [_now, _index]];

// Turned, a big item sounds lower than a small one.
private _pitch = _def getOrDefault ["pitch", 1];

if (_action isEqualTo "rotate") then {
    _pitch = _pitch * linearConversion [1, 8, ([_class] call EFUNC(items,getInfo)) getOrDefault ["cells", 1], 1.1, 0.85, true];
};

private _volume = _def getOrDefault ["volume", 1];
private _layers = [_variants param [_index, []], _pitch, _volume, _container] call FUNC(resolveLayers);

if (_layers isEqualTo []) then {
    _layers = [_def getOrDefault ["fallback", []], _pitch, _volume, _container] call FUNC(resolveLayers);
};

if (_layers isEqualTo []) exitWith {};

private _scale = if (_ui) then {[_action] call FUNC(soundGain)} else {0};

if (_scale > 0) then {
    {
        [_x, _scale] call FUNC(playLayer);
    } forEach _layers;
};

if (_world && {_def getOrDefault ["world", false]}) then {
    [_layers, _def getOrDefault ["range", 12], _def getOrDefault ["worldGap", NOISE_GAP], _action isEqualTo "search"] call FUNC(sendNoise);
};
