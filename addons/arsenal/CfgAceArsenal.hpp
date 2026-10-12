// ACE Arsenal's display, handed over to the Enhanced Arsenal (einv_arsenal_fnc_handOver) unless the player
// chose ACE's own window. Only onLoad is ours: the hand-over disarms the display's other handlers itself, so
// mods that patch them (ACE Arsenal Extended's onUnload) keep working in ACE's own window.
//
// The string is written out plainly, not with QUOTE: it needs ACE's names and commas inside brackets, which
// a macro argument cannot carry. When the hand-over does not take the display - the setting, a missing
// piece, Eden, or this build's skeleton - the rest is ACE's own onLoad, word for word as ACE 3.21.2 has it
// (ui\RscAttributes.hpp), so ACE's window opens as it always did.
class ace_arsenal_display {
    onLoad = "if ([_this select 0] call (missionNamespace getVariable ['einv_arsenal_fnc_handOver', {false}])) exitWith {}; ['onLoad', _this, 'ace_arsenal_display'] call ace_arsenal_fnc_onArsenalOpen";
};
