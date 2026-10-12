// COMPONENT should be defined in the script_component.hpp and included BEFORE this hpp

#define MAINPREFIX z
#define PREFIX einv

#include "script_version.hpp"

#define VERSION     MAJOR.MINOR
#define VERSION_STR MAJOR.MINOR.PATCH
#define VERSION_AR  MAJOR,MINOR,PATCH

#define VERSION_CONFIG version = MAJOR.MINOR; versionStr = QUOTE(MAJOR.MINOR.PATCH); versionAr[] = {MAJOR,MINOR,PATCH}

// Minimal required game version.
#define REQUIRED_VERSION 2.16

#ifdef COMPONENT_BEAUTIFIED
    #define COMPONENT_NAME QUOTE(COMPONENT_BEAUTIFIED)
#else
    #define COMPONENT_NAME QUOTE(EINV - COMPONENT)
#endif
