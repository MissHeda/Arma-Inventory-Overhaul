#include "script_component.hpp"

// ACE Arsenal's grid panel registers its handlers in XEH_preInit: the Eden editor runs no postInit.

if (!hasInterface) exitWith {};

// The vanilla Virtual Arsenal: once every addon's postInit has run, the handlers mods put on its events are
// counted, so a handler a mission adds later can be told from them (fnc_biCountHandlers).
[FUNC(biCountHandlers), []] call CBA_fnc_execNextFrame;
