// The window's geometry and timings (UNIT, SEARCH_FRAMES, SEARCH_RING_SIZE, DIK codes).
#include "\z\einv\addons\gui\defines.hpp"

// ACE's progress bar lets a repack go on in a vehicle, swimming and sitting
// (ace_magazinerepack_fnc_startRepackingMagazine) - so does ours.
#define REPACK_EXCEPTIONS ["isNotInside", "isNotSwimming", "isNotSitting"]

// The ring on the magazine being filled is the search ring (gui/ui/search_ring_01..32_ca). gui's own
// SEARCH_RING names the folder of the addon it is used in, so the path is spelled out here.
#define REPACK_RING(N) format ["%1\search_ring_%2_ca.paa", QPATHTOEF(gui,ui), [str (N), "0" + str (N)] select ((N) < 10)]
