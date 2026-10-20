#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// Where things lie is kept on each container for everyone, by its authority - the machine where the
// container's root is local (fnc_writePlaces) - so it goes away with the container. What an item is lives
// in the items addon's cache, and how containers are split up comes from the rules
// (einv_items_fnc_getInfo, "grid").

// The grids missions give single objects (einv_grid, see fnc_getBlocks), as read: text -> spec, []
// for one that cannot be read. Read once per text, so a broken one is named in the RPT once.
GVAR(objectGrids) = createHashMap;

// The ops a transaction may name, op -> function name. Other addons add theirs in their preInit
// (einv_compat_efak: kitTake, kitPut, kitPlace, kitMove, kitRemoveIfEmpty). "repack" is the
// storage's own, asked for by einv_magazines.
GVAR(ops) = createHashMapFromArray [
    ["place", QFUNC(opPlace)], ["placeMany", QFUNC(opPlaceMany)], ["sort", QFUNC(opSort)],
    ["normalize", QFUNC(opNormalize)], ["move", QFUNC(opMove)], ["take", QFUNC(opTake)],
    ["put", QFUNC(opPut)], ["putGround", QFUNC(opPutGround)], ["takeOff", QFUNC(opTakeOff)],
    ["putOn", QFUNC(opPutOn)], ["repack", QFUNC(opRepack)], ["migrate", QFUNC(opMigrate)],
    ["strict", QFUNC(opStrict)], ["split", QFUNC(opSplit)]
];

// Checks every op passes on the machine that runs it: CODE [op, args, requester, root] -> "" or a reason.
// The window's living-person rules go here (einv_gui_fnc_personGuard), the locks (einv_locks_fnc_guard) and
// ACRE2's radio slot (einv_compat_acre_fnc_guard). Settlement skips them: the system puts things back.
GVAR(guards) = [];

// Variables a uniform, vest or backpack carries on its own container object that must survive a move: the
// window takes things out and puts them in anew, which makes a new object (a TFAR long-range radio keeps
// its frequencies in "radio_settings"). Compat addons add names here in their preInit
// (einv_compat_tfar); fnc_snapshot reads them, fnc_restore sets them.
GVAR(carryVariables) = [];

// Holders that are no object, by the part of their key before ":" - "kit" from einv_compat_efak:
// HashMap "entries" CODE [holder] -> entries, "root" CODE [holder, hint] -> root (fnc_rootOf hands on
// its second argument as the hint), "verify" CODE [holder, root] -> BOOL, "blocks" CODE [holder] ->
// compartments as fnc_blocksFor gives them, [] for an open grid that grows (fnc_getBlocks; left out, the
// grid is open), and the names of its ops for "take", "put", "place" and "move" - settlement puts a
// payload back into such a holder with its "put" op (fnc_settle), and the window builds its phases from
// them (einv_gui_fnc_sendMoves).
GVAR(holderTypes) = createHashMap;

// Same kind of item, class -> canonical key (fnc_layoutKey).
GVAR(layoutKeys) = createHashMap;

// What a weapon takes in one slot, "weapon|mag", "weapon|mag2" or "weapon|items" (lower case) -> a HashMap of the
// lower case class names it takes (fnc_slotAccepts). Read from config once per weapon: config does not change
// during a mission, and asking the engine for the compatible magazines of every slot at every lift is not cheap.
GVAR(compatSets) = createHashMap;

// Where a unit's uniform, vest and backpack keep their things travels inside its loadouts, in the extended
// info CBA keeps with them: written when a loadout is read, read back when one is set (fnc_onLoadoutGet,
// fnc_onLoadoutSet). On every machine - a loadout is set where the code that sets it runs, and the Eden
// editor runs this too.
["CBA_loadoutGet", {_this call FUNC(onLoadoutGet)}] call CBA_fnc_addEventHandler;
["CBA_loadoutSet", {_this call FUNC(onLoadoutSet)}] call CBA_fnc_addEventHandler;

// Units local here whose cargo changed and whose surplus - what their uniform, vest or backpack holds beyond
// the grid - is to be looked at, [unit, not before, tries so far, requester] each (fnc_queueMigrate,
// fnc_tickMigrate). Filled by the triggers in XEH_postInit, fnc_onLoadoutSet and the arsenal addon.
GVAR(migrateDue) = [];

// While a phase's ops run here: the places they changed, [[holder, records], ...] - written once at the
// end - and what the ops read of each holder, holder netId or kit key -> HashMap (fnc_execute).
GVAR(executing) = false;
GVAR(buffer) = [];
GVAR(cache) = createHashMap;

// Every phase this machine ran or holds, "id|phase|attempt" -> [state, results, revisions, time, notes]:
// a copy the hub sends again is answered from here and never run twice (fnc_runPhase, fnc_phaseFinalize).
// The key of the phase running now, "" between phases (fnc_journalNote).
GVAR(journal) = createHashMap;
GVAR(journalKey) = "";

// Phases waiting for their turn on this machine, run whole within a frame's budget (fnc_tick).
GVAR(queue) = [];

// Requests this machine sent and waits for, id -> [tx, results, callback, args, asked at, revisions,
// settlement step done, phases asked for, payloads handed to the hub's settlement [back, vehicle, ground]]
// (fnc_request, fnc_requestNext); ids and nested ids made here.
GVAR(requests) = createHashMap;
GVAR(nextRequest) = 0;
GVAR(nextUid) = 0;

// Part of every request id made here, drawn once per mission start: a player who reconnects under a
// machine id given out before starts counting again, and a phase of theirs must never meet the journal
// entry of an old phase with the same key elsewhere - it would be answered from it and never run.
GVAR(session) = format ["%1%2", floor random 100000, floor random 100000];

// The player's own containers written locally and not yet broadcast (fnc_flushPlaces), and nested objects
// or outermost containers carrying their tags or copies (einv_storage_nested) that may still have to go
// out; latest writes for kits, kit key -> [stamp, places] (the heal - objects keep theirs on themselves);
// when a kit was last normalised and last re-written for a stale copy, kit key -> [time, time]
// (fnc_opNormalize - objects keep theirs on themselves as well).
GVAR(dirty) = [];
GVAR(writtenKits) = createHashMap;
GVAR(normalizedKits) = createHashMap;

// Server: transactions it carries, id -> [transaction, results, phase under way, settlement step,
// revisions, number of its own phases, per phase [settlement step, root was an object], the phase
// under way as sent [index, ops, op map, attempt, settlement]] (fnc_hubStart); phases sent out and
// not answered, "id|phase" -> [owner, root, attempt, ops, sentAt, root netId, id, phase] - the ops
// hold what the phase carries until it is answered; phases held back, "id|phase" -> [attempt,
// retryAt, heldSince, reason, id, phase]; per root netId -> [owner, outstanding keys, changedAt,
// last sent or answered]; owner ids that left; when it next looks at held phases and re-sends
// (fnc_hubTick).
GVAR(hub) = createHashMap;
GVAR(waiting) = createHashMap;
GVAR(held) = createHashMap;
GVAR(rootWaits) = createHashMap;
GVAR(gone) = [];
GVAR(hubTickAt) = 0;

// The handshake with the server: the version of Arma Inventory Overhaul it answered with, "" until it did
// (fnc_greetServer, XEH_postInit). A client hands nothing to the hub before the server answered with this
// very version (fnc_hubReady): a server without the hub's events, or with others, would drop what the
// client already took out.
GVAR(serverVersion) = "";

// Whether any of the "Use items from ..." settings limits something; set by them (fnc_useRefresh) and read
// by everything that asks where an item may be used from, which has nothing to do while it is false. And
// whether any of them is on Strict: then what they block is kept out of the cargo, in a hidden holder on the
// unit (fnc_hiddenRoute, fnc_opStrict), which costs this one read where it is not.
GVAR(useActive) = false;
GVAR(strictActive) = false;

// Where the player's magazines lie, "creator:id" -> "uniform", "vest" or "backpack" (fnc_useTrack), so that
// a reload the game did can be told to have come from a closed container (fnc_onReloaded); whether such a
// reload is being taken back right now (fnc_reloadUndo) - until when, a time and not a flag, so one that a
// script error left behind runs out -; a magazine the window loaded by hand, [unit, weapon, class, until]
// (fnc_noteHandLoad); the one reload this mod asked the game for, spent by its first "Reloaded" event
// (fnc_loadMagazine writes it, fnc_onReloaded spends it, it runs out); when ACE's "is reloading" was first
// seen (fnc_reloadBusy); and the throw block (fnc_throwTick): whether ACE's blockThrow is set by us and for
// which unit.
GVAR(useIds) = createHashMap;
GVAR(undoUntil) = 0;
GVAR(handLoad) = [];
GVAR(reloadToken) = [];
GVAR(reloadBusySince) = 0;
GVAR(throwBlocked) = false;
GVAR(throwUnit) = objNull;

#include "initSettings.inc.sqf"

// Two stacks of one class apart in one container: the places' records carry how many a tile holds and the
// ops put, take and split by that (fnc_stackCounts, fnc_opSplit, fnc_opPut). The window asks for the new
// behaviour - a drop on a cell stays a stack of its own, Shift+click splits, a drop onto a stack of the same
// class merges - only while this is true on its machine; false switches that off again, the records already
// written stay as they are.
GVAR(stackSplits) = true;

ADDON = true;
