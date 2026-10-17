// Opening and closing the wizard, and its keys
PREP(open);
PREP(onLoad);
PREP(onUnload);
PREP(onKeyDown);
PREP(onKeyUp);
PREP(onMouse);
PREP(close);

// Code a moment later - also in Eden and over the menus, where CBA's frame handlers do not run
PREP(defer);
PREP(restoreScroll);
PREP(runDeferred);

// Who may open it at all and save where, what is in use, and the draft being edited: the rules and the server
// settings, two settings that are one setup
PREP(canOpen);
PREP(canEdit);
PREP(getActive);
PREP(targetValue);
PREP(targetValues);
PREP(setDraft);
PREP(setSettingsDraft);
PREP(commit);
PREP(commitSettings);
PREP(commitSetup);
PREP(setSetting);
PREP(resetAll);
PREP(atDefault);
PREP(undo);
PREP(reload);
PREP(onRulesChanged);
PREP(isDirty);
PREP(sourceEmpty);
PREP(countChanges);
PREP(changeRows);
PREP(ruleStep);
PREP(settingText);
PREP(statements);
PREP(sanitize);

// Saving, sharing and keeping
PREP(save);
PREP(replay);
PREP(importText);
PREP(importSettings);
PREP(openImport);
PREP(exportText);
PREP(openExport);
PREP(openChanges);
PREP(shippedPresets);
PREP(presetName);
PREP(describeRule);

// The window and its steps
PREP(drawFrame);
PREP(footerButtonW);
PREP(showStep);
PREP(drawGeneral);
PREP(drawChanges);
// The General step's size for each kind of container: the rules with "all kind=..." it writes, found by their selector
PREP(allRule);
PREP(kindRule);
PREP(upsertKinds);
PREP(drawItems);
PREP(drawContainers);
PREP(setHint);
PREP(popover);
PREP(closePopover);
PREP(topLayer);
PREP(confirm);

// The Items and Containers steps: the class index, its lists, the editors, and the one rule per class
// they write
PREP(buildIndex);
PREP(indexChunk);
PREP(classKind);
PREP(searchFilter);
PREP(searchHit);
PREP(drawClassList);
PREP(drawResults);
PREP(drawPager);
PREP(answerLine);
PREP(drawItemEditor);
PREP(drawCellEditor);
PREP(drawCellBlocks);
PREP(drawSameAs);
PREP(pictureCatalog);
PREP(pictureChunk);
PREP(pictureCategory);
PREP(pictureKey);
PREP(openPicturePicker);
PREP(drawPicturePicker);
PREP(pickPicture);
PREP(iconEntries);
PREP(drawPictureRow);
PREP(drawUseRow);
PREP(drawCatRow);
// The General step's Categories card: the setup's own categories, their names and pictures
PREP(drawCategories);
PREP(setCategory);
PREP(renameCategory);
PREP(addCategory);
PREP(deleteCategory);
PREP(newCategoryId);
PREP(drawCellAttrs);
PREP(cellBlock);
PREP(drawIconBlock);
PREP(drawBoxPreview);
PREP(cellChanged);
PREP(classBlocks);
PREP(drawPreview);
PREP(canvasFromBlocks);
PREP(canvasBlocks);
PREP(canvasMatch);
PREP(canvasPick);
PREP(canvasBox);
PREP(answerText);
PREP(kitRoom);
PREP(weightText);
PREP(weightValue);
PREP(ownClassRules);
PREP(upsertRule);
PREP(upsertRules);
PREP(classDefault);
PREP(resetField);

// The inheritance tree: which classes are built on one, how the lists show them, and when an edit applies
// to all of them
PREP(classRoot);
PREP(treeIndex);
PREP(classTree);
PREP(treeRows);
PREP(drawTree);
PREP(editScope);
PREP(treeTop);

// Export and import at the editors: the config lines of a class (or a tree), and a pasted setup of them
PREP(editorTools);
PREP(exportClasses);
PREP(importClasses);
PREP(applyClassImport);
PREP(configValues);
PREP(openExportChoice);
PREP(openImportChoice);
PREP(openClassImport);

// Widgets, on the inventory's UI kit
PREP(uiHit);
PREP(uiAction);
PREP(uiCard);
PREP(uiText);
PREP(uiToggle);
PREP(uiStepper);
PREP(uiEdit);
PREP(uiNumber);
PREP(uiField);
PREP(uiReset);
PREP(fitEditArea);
PREP(uiChip);
PREP(uiCanvas);
PREP(uiSegmented);
PREP(uiDropdown);
PREP(screenRect);
PREP(hex);
PREP(escape);

#include "XEH_PREP_entry.hpp"
