#include "..\script_component.hpp"
/*
 * Author: Miss Heda
 * Whether a phase on a root runs on this machine at once, without the hub: in single player and in Eden
 * always; in multiplayer only on this machine's own player unit - its owner never changes while the
 * player is connected -, an object made on this machine only and marked so (einv_storage_localOnly, the
 * Arsenal's staging space: the hub could not even see it), and, on the server, for objNull (ground work).
 * Everything else goes through the hub, also on the hosting player's machine and for a unit remote
 * controlled with Zeus.
 *
 * Arguments:
 * 0: Root <OBJECT>
 *
 * Return Value:
 * Runs here at once <BOOL>
 *
 * Example:
 * [player] call einv_storage_fnc_isLocalRoot;
 *
 * Public: No
 */

params [["_root", objNull, [objNull]]];

// Single player and Eden: every root is this machine's - a whole transaction runs in one frame.
if (!isMultiplayer) exitWith {true};

// The ground and anything else only the server does.
if (isNull _root) exitWith {isServer};

// An object made with createVehicleLocal exists on this machine alone and never changes hands. The mark
// is set where it is made, never sent anywhere.
if (_root getVariable [QGVAR(localOnly), false]) exitWith {local _root};

// Locality can be true on two machines for a moment while a root changes hands (the engine tells the old
// and the new owner separately), so only a root that never changes hands takes the short way: this
// machine's own player unit. A headless client or a dedicated server has no player - objNull, which a
// root here never is.
_root isEqualTo player
