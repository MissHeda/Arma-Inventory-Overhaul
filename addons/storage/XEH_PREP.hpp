// What a container holds
PREP(getContents);
PREP(getMaxLoad);
PREP(isGroundHolder);
PREP(isForeignHolder);
PREP(getOwner);
PREP(getMass);

// Where things lie, for everyone: each holder's places, written by its authority
PREP(getLayout);
PREP(entryKey);
PREP(stackCounts);
PREP(stackFor);
PREP(setCount);
PREP(setRecords);
PREP(findSpots);
PREP(payloadKey);
PREP(layoutKey);
PREP(readPlaces);
PREP(writePlaces);
PREP(flushPlaces);
PREP(dropPlaces);
PREP(normalize);
PREP(tagNested);
PREP(newUid);
PREP(machineId);
PREP(rootOf);
PREP(verifyChain);
PREP(liesIn);
PREP(isLocalRoot);
PREP(inReach);
PREP(findEntry);
PREP(onLoadoutPlaces);
PREP(dumpPlaces);

// What a unit wears and carries, and what is being looted
PREP(getEquipment);
PREP(getSections);
PREP(getLootSections);
PREP(getNearby);
PREP(orderSections);

// Moving what a tile stands for from one container to another
PREP(snapshot);
PREP(clearCargo);
PREP(normalizeWeapon);
PREP(restore);
PREP(removeEntry);
PREP(removeSameClass);
PREP(addPayload);
PREP(hasRoom);
PREP(backpackIntoBackpack);
PREP(setPlace);
PREP(moveEntry);
PREP(getGroundHolder);
PREP(pruneScriptedPile);

// Transactions: every move as phases on one root each, run by that root's authority
PREP(request);
PREP(requestNext);
PREP(execute);
PREP(journalNote);
PREP(phaseFinalize);
PREP(settle);
PREP(runPhase);
PREP(tick);
PREP(nextFrame);
PREP(onAnswer);
PREP(opPlace);
PREP(opPlaceMany);
PREP(opSplit);
PREP(opSort);
PREP(opNormalize);
PREP(opMove);
PREP(opTake);
PREP(opPut);
PREP(opPutGround);
PREP(opTakeOff);
PREP(opPutOn);
PREP(opRepack);
PREP(opMigrate);

// The hub on the server: carries what a transaction took out between machines until it landed
PREP(hubStart);
PREP(hubNext);
PREP(hubRoute);
PREP(hubPhaseDone);
PREP(hubDisconnect);
PREP(hubTick);
PREP(greetServer);
PREP(hubReady);

// Nearby and the ground
PREP(isNear);
PREP(groundPos);

// Where several things go at once: which fit into which container, and where
PREP(plan);

// Equipment slots: what is in them, what fits, putting on and taking off
PREP(getSlot);
PREP(slotAccepts);
PREP(slotFor);
PREP(partFor);
PREP(weaponPart);
PREP(addWeapon);
PREP(equip);
PREP(unequip);
PREP(putOn);
PREP(takeOff);

// Entries sent over the network: as arrays, never with a tile's controls in them
PREP(entryToArray);
PREP(entryFromArray);

// Making what did not exist - what ACE Arsenal's grid panel puts in where ACE's own add was refused:
// payloads, putting new items in, counting a class - and the places a loadout carries
PREP(makePayload);
PREP(addNew);
PREP(countClass);
PREP(onLoadoutGet);
PREP(onLoadoutSet);
PREP(topUpLoadout);
PREP(setUnitLoadout);

// Adding new things to a unit through the grid (fnc_addToUnit, for missions and other mods): the worn containers
// in the order to try them, and how many of a class each has room for
PREP(addToUnit);
PREP(addFit);
PREP(unitTargets);

// Surplus: what a unit's uniform, vest or backpack holds beyond its grid, moved on to the next container
// with room - asked for when its cargo changed, carried out by the unit's authority (op "migrate")
PREP(requestMigrate);
PREP(queueMigrate);
PREP(tickMigrate);
PREP(wornHeld);
PREP(migratePasses);

// The player's overflow sweep: what the grid has no room for and no other worn container takes goes onto the
// ground next to the player (the setting aio_storage_migrate switches it off with the rest of the surplus pass)
PREP(queueSweep);
PREP(sweepTick);
PREP(sweepBusy);
PREP(requestSweep);

// Compartments
PREP(blocksFor);
PREP(getBlocks);
PREP(seedTaken);
PREP(cellsFree);
PREP(takeCells);
PREP(blockMode);
PREP(blockOrder);
PREP(slotOf);
PREP(overlaps);
PREP(hasSpace);

// Use from containers: what the settings "Use items from the uniform / vest / backpack" allow, and the
// reload key in front of the engine
PREP(useMode);
PREP(useRefresh);
PREP(useState);
PREP(useKind);
PREP(useCarried);
PREP(useBlockedIn);
PREP(useKindName);
PREP(reloadGuard);
PREP(useHint);
PREP(useTrack);
PREP(onReloaded);
PREP(reloadPick);
PREP(loadMagazine);
PREP(reloadUndo);
PREP(reloadTidy);
PREP(reloadBusy);
PREP(noteHandLoad);
PREP(throwState);
PREP(throwSelect);
PREP(throwGuard);
PREP(throwTick);

// Strict mode: what a setting on Strict keeps out of a unit's uniform, vest or backpack lives in a hidden
// holder on the unit - a public variable, no object - and is shown as the container's own tiles all the
// same (fnc_getContents). Op "strict" keeps holder and cargo in line.
PREP(hiddenLists);
PREP(hiddenWrite);
PREP(hiddenAdd);
PREP(hiddenAmmo);
PREP(hiddenPayload);
PREP(hiddenTake);
PREP(hiddenPut);
PREP(hiddenActive);
PREP(hiddenRoute);
PREP(hiddenCounts);
PREP(hiddenClasses);
PREP(hiddenReturn);
PREP(hiddenDue);
PREP(hiddenSweep);
PREP(opStrict);
PREP(fitRecords);
