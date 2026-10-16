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
PREP(runDeferred);

// Who may open it at all and save where, what is in use, and the draft being edited
PREP(canOpen);
PREP(canEdit);
PREP(getActive);
PREP(targetValue);
PREP(setDraft);
PREP(commit);
PREP(undo);
PREP(reload);
PREP(onRulesChanged);
PREP(isDirty);
PREP(sourceEmpty);
PREP(countChanges);
PREP(changeRows);
PREP(statements);
PREP(sanitize);

// Saving, sharing and keeping
PREP(save);
PREP(replay);
PREP(importText);
PREP(openImport);
PREP(exportText);
PREP(personalPresets);
PREP(shippedPresets);
PREP(presetName);
PREP(describeRule);

// The window and its steps
PREP(drawFrame);
PREP(showStep);
PREP(drawStart);
PREP(drawChanges);
// The Start step's "Everything else": the rules with "all" it writes, found by their selector
PREP(allRule);
PREP(upsertAll);
PREP(drawItems);
PREP(drawContainers);
PREP(drawReview);
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
PREP(openPicturePicker);
PREP(drawPicturePicker);
PREP(pickPicture);
PREP(drawPictureRow);
PREP(drawIconBlock);
PREP(drawBoxPreview);
PREP(cellChanged);
PREP(classBlocks);
PREP(drawPreview);
PREP(canvasFromBlocks);
PREP(canvasBlocks);
PREP(canvasBox);
PREP(answerText);
PREP(kitRoom);
PREP(weightText);
PREP(weightValue);
PREP(ownClassRules);
PREP(upsertRule);
PREP(upsertRules);

// The inheritance tree: which classes are built on one, how the lists show them, and when an edit applies
// to all of them
PREP(classRoot);
PREP(treeIndex);
PREP(classTree);
PREP(treeRows);
PREP(drawTree);
PREP(editScope);

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
PREP(fitEditArea);
PREP(uiChip);
PREP(uiCanvas);
PREP(uiSegmented);
PREP(uiDropdown);
PREP(screenRect);
PREP(hex);
PREP(escape);

#include "XEH_PREP_entry.hpp"
