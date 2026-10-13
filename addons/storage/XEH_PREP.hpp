// What a container holds
PREP(getContents);
PREP(getMaxLoad);
PREP(isGroundHolder);
PREP(getOwner);
PREP(getMass);

// Where things lie, for everyone: each holder's places, written by its authority
PREP(getLayout);
PREP(entryKey);
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
PREP(opSort);
PREP(opNormalize);
PREP(opMove);
PREP(opTake);
PREP(opPut);
PREP(opPutGround);
PREP(opTakeOff);
PREP(opPutOn);
PREP(opRepack);

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

// Compartments
PREP(blocksFor);
PREP(getBlocks);
PREP(seedTaken);
PREP(cellsFree);
PREP(takeCells);
PREP(overlaps);
PREP(hasSpace);
