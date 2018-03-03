/***************************************************************************
*
*   Copyright Kai Özer, 2003-2018
*
*   This file is part of MI-SUGAR.
*
*   MI-SUGAR is free software; you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation; either version 2 of the License, or
*   (at your option) any later version.
*
*   MI-SUGAR is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with MI-SUGAR; if not, write to the Free Software Foundation, Inc.,
*   51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*
****************************************************************************/
#import "MI_DeviceModelManager.h"
#import "SugarManager.h"

NSString* MISUGAR_DEVICE_MODELS_PANEL_FRAME = @"DeviceModelsPanelFrame";

// Since the user is not allowed to change the path of the device models file
// we can put the path into a static variable which remains valid until the
// application exits.
static NSString* deviceModelsFilePath = nil;

@interface MI_DeviceModelManager (ToolbarDelegate) <NSToolbarDelegate>
@end

@implementation MI_DeviceModelManager
{
  // The keys are NSNumber objects constructed from the type of the contained models.
  // The values are NSMutableArray instances that contain MI_CircuitElementDeviceModel
  // instances for one type. Device models with names starting with "Default" are
  // reserved by MI-SUGAR.
  NSMutableDictionary<NSNumber*,NSMutableArray*>* _deviceModels;

  IBOutlet NSTextView* modelParametersArea;

  // The items of the tree view can be NSNumber instances (for the
  // the expandable items the correspond to arrays of device models
  // of a specific type), or device models (trivial).
  IBOutlet NSOutlineView* modelTree;

  IBOutlet NSWindow* deviceModelPanel;
  NSToolbarItem* deleteButton;
  NSToolbarItem* copyButton;
  NSToolbarItem* importButton;
  NSToolbarItem* exportButton;
}

- (instancetype) init
{
  if ((self = [super init]) != nil)
  {
    deviceModelPanel = nil;
    copyButton = nil;
    deleteButton = nil;
    importButton = nil;

    // Construct the device model library structure
    int g;
    _deviceModels = [[NSMutableDictionary alloc] initWithCapacity:6];
    for (g = MI_DeviceModelTypeFirst; g <= MI_DeviceModelTypeLast; g++)
        [_deviceModels setObject:[NSMutableArray arrayWithCapacity:3]
                          forKey:[NSNumber numberWithInt:g]];

    // Load the device models from the dedicated library file
    BOOL isDir;
    NSFileManager* fm = [NSFileManager defaultManager];

    // Check if the generic application support folder exists - create if necessary
    NSString* supportFolder = [[SugarManager supportFolder] stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:supportFolder isDirectory:&isDir] || !isDir)
    {
      [fm createDirectoryAtPath:supportFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    // Check if MI-SUGAR's folder in the application support folder exists
    supportFolder = [SugarManager supportFolder];
    if (![fm fileExistsAtPath:supportFolder isDirectory:&isDir])
    {
      [fm createDirectoryAtPath:supportFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    else if (!isDir)
    {
      // rename the existing file
      [fm moveItemAtPath:supportFolder toPath:[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] error:NULL];
      [fm createDirectoryAtPath:supportFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    // Check if the device model library file exists
    deviceModelsFilePath = [supportFolder stringByAppendingPathComponent:@"Device Models"];
    if ( [fm fileExistsAtPath:deviceModelsFilePath isDirectory:&isDir] )
    {
      if (isDir)
      {
        // This file is not supposed to be a directory.
        [fm moveItemAtPath:supportFolder toPath:[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] error:NULL];
      }
      else
      {
          // Unarchive the device models
        @try
        {
          NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:
                  [NSData dataWithContentsOfFile:deviceModelsFilePath]];
          id myModels = [unarchiver decodeObjectForKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
          if (myModels != nil && [myModels isKindOfClass:[NSArray class]])
          {
            for (MI_CircuitElementDeviceModel* currentModel in myModels)
            {
              [self addModel:currentModel];
            }
          }
          [unarchiver finishDecoding];
        }
        @catch (id)
        {
          NSAlert* alert = [[NSAlert alloc] init];
          alert.messageText = @"Corrupt device models file!";
          alert.informativeText = @"The content of your device models library can not be read!";
          [alert addButtonWithTitle:@"Back up"];
          [alert addButtonWithTitle:@"Delete"];
          [alert beginSheetModalForWindow:deviceModelPanel completionHandler:^(NSModalResponse returnCode){
            if (returnCode == NSAlertFirstButtonReturn)
            {
              // backing up
              NSString* targetPath = [supportFolder stringByAppendingPathComponent:@"Corrupt Device Models File"];
              [fm moveItemAtURL:[NSURL fileURLWithPath:deviceModelsFilePath] toURL:[NSURL fileURLWithPath:targetPath] error:NULL];
            }
            else
            {
              [fm removeItemAtPath:deviceModelsFilePath error:NULL];
            }
          }];
        }
      }
    }

    // There was no dedicated file for device models before version 0.5.4.
    // Models were stored in the preference file.
    // Check if the user has upgraded from such an old version.
    NSData* legacyData = [[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    NSArray* legacyModels = nil;
    if (legacyData != nil)
        legacyModels = [NSKeyedUnarchiver unarchiveObjectWithData:legacyData];
    if ( (legacyModels != nil) && ([legacyModels count] > 0) )
    {
      // One by one add those old models to the library
      // Convert (or purge) deprecated models
      for (MI_CircuitElementDeviceModel* currentModel in legacyModels)
      {
        // Check if this is one of the old specialized MOS models
        if ([currentModel type] == MI_DeviceModelTypeMOSFET)
        {
          // Deprecate and create a generic MOS model instead
          MI_MOSDeviceModel* mosModel = [[MI_MOSDeviceModel alloc] initWithName:[currentModel modelName]];
          [mosModel setDeviceParameters:[currentModel deviceParameters]];
          [self addModel:mosModel];
        }
        else
        {
          [self addModel:currentModel];
        }
      }
      // Set the legacy device models array in the user preference to empty.
      NSData* archivedArray = [NSKeyedArchiver archivedDataWithRootObject:[NSArray array]];
      [[NSUserDefaults standardUserDefaults] setObject:archivedArray forKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    }

    // Make sure the default device models are included.
    for (int p = MI_DeviceModelTypeFirst; p <= MI_DeviceModelTypeLast; p++)
    {
      NSMutableArray* currentArray = [_deviceModels objectForKey:[NSNumber numberWithInt:p]];
      if (currentArray == nil)
      {
        currentArray = [NSMutableArray arrayWithCapacity:3];
        [_deviceModels setObject:currentArray forKey:[NSNumber numberWithInt:p]];
      }
      BOOL foundDefault = NO;
      MI_CircuitElementDeviceModel* currentModel;
      for (currentModel in currentArray)
      {
        if ([[currentModel modelName] hasPrefix:@"Default"])
        {
          foundDefault = YES;
          break;
        }
      }
      if (!foundDefault)
      {
        switch (p)
        {
          case MI_DeviceModelTypeDiode:
            currentModel = [[MI_DiodeDeviceModel alloc] initWithName:@"DefaultDiode"]; break;
          case MI_DeviceModelTypeBJT:
            currentModel = [[MI_BJTDeviceModel alloc] initWithName:@"DefaultBJT"]; break;
          case MI_DeviceModelTypeJFET:
            currentModel = [[MI_JFETDeviceModel alloc] initWithName:@"DefaultJFET"]; break;
          case MI_DeviceModelTypeMOSFET:
            currentModel = [[MI_MOSDeviceModel alloc] initWithName:@"DefaultMOSFET"]; break;
          case MI_DeviceModelTypeSwitch:
            currentModel = [[MI_SwitchDeviceModel alloc] initWithName:@"DefaultSwitch"]; break;
          case MI_DeviceModelTypeTransmissionLine:
            currentModel = [[MI_TransmissionLineDeviceModel alloc] initWithName:@"DefaultTransmissionLine"]; break;
          default:
            currentModel = nil;
        }
        if (currentModel != nil)
            [currentArray addObject:currentModel];
      }
    }
  }
  return self;
}

- (void) dealloc
{
  if (deviceModelPanel != nil)
  {
    [deviceModelPanel saveFrameUsingName:MISUGAR_DEVICE_MODELS_PANEL_FRAME];
  }
  [self saveModels];
  deviceModelsFilePath = nil;
  [modelTree setDelegate:nil];
}


+ (MI_DeviceModelManager*) sharedManager
{
  static MI_DeviceModelManager* sharedDeviceModelManager = nil;
  if (sharedDeviceModelManager == nil)
  {
    sharedDeviceModelManager = [[MI_DeviceModelManager alloc] init];
  }
  return sharedDeviceModelManager;
}


- (void) showPanel
{
    if (deviceModelPanel == nil)
    {
        // Load device models
        [[NSBundle mainBundle] loadNibNamed:@"SchematicDeviceModelsPanel" owner:self topLevelObjects:nil];
        
        // Use monospaced font to display the model parameters
        [modelParametersArea setFont:[NSFont fontWithName:@"Courier" size:0.0f]];
        [modelParametersArea setContinuousSpellCheckingEnabled:NO];
        [deviceModelPanel setMovableByWindowBackground:YES];
        [deviceModelPanel setFrameUsingName:MISUGAR_DEVICE_MODELS_PANEL_FRAME];
        
        NSToolbar* toolbar = [[NSToolbar alloc] initWithIdentifier:@"DeviceModelsWindowToolbar"];
        [toolbar setAllowsUserCustomization:NO];
        [toolbar setAutosavesConfiguration:NO];
        [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
        [toolbar setDelegate:self];
        [deviceModelPanel setToolbar:toolbar];
    }
    [deviceModelPanel orderFront:self];
}

- (void) hidePanel
{
    if (deviceModelPanel != nil)
        [deviceModelPanel orderOut:self];
}

- (void) togglePanel
{
    if (deviceModelPanel == nil || ![deviceModelPanel isVisible])
        [self showPanel];
    else
        [self hidePanel];
}

// Dont call this too often, it's a file operation
- (void) saveModels
{
    // Collect all device models into one array
    NSMutableArray* all = [NSMutableArray arrayWithCapacity:20];
    int m;
    for (m = MI_DeviceModelTypeFirst; m <= MI_DeviceModelTypeLast; m++)
        [all addObjectsFromArray:[_deviceModels objectForKey:[NSNumber numberWithInt:m]]];
    // Save to file
    if (deviceModelsFilePath != nil)
        [self dumpModels:all
                  toFile:deviceModelsFilePath];
}


- (NSString*) deviceParametersForModelName:(NSString*)name
{
  for (int x = MI_DeviceModelTypeFirst; x <= MI_DeviceModelTypeLast; x++)
  {
    NSArray<MI_CircuitElementDeviceModel*>* models = [_deviceModels objectForKey:[NSNumber numberWithInt:x]];
    for (MI_CircuitElementDeviceModel* model in models)
    {
      if ([[model modelName] isEqualToString:name])
      {
        return [model deviceParameters];
      }
    }
  }
  return nil;
}


- (void) importDeviceModels:(NSArray*)models
{
  NSEnumerator* modelEnum = [models objectEnumerator];
  MI_CircuitElementDeviceModel *currentModel;
  while (currentModel = [modelEnum nextObject])
    [self addModel:currentModel];
  if (deviceModelPanel != nil)
    [modelTree reloadData];
}


- (void) addModel:(MI_CircuitElementDeviceModel*)newModel
{
  NSMutableArray* modelTypeArray = [_deviceModels objectForKey:[NSNumber numberWithInt:[newModel type]]];
  if (modelTypeArray != nil && ![modelTypeArray containsObject:newModel])
  {
    [modelTypeArray addObject:newModel];
  }
}


- (BOOL) addModelsFromFile:(NSString*)filePath
{
  BOOL success = NO;
  @try
  {
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:[NSData dataWithContentsOfFile:filePath]];
    id imported = [unarchiver decodeObjectForKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    if ( (imported != nil) && [imported isKindOfClass:[NSArray class]] )
    {
      for (MI_CircuitElementDeviceModel* currentModel in (NSArray*)imported)
      {
        [self addModel:currentModel];
      }
      success = YES;
    }
    [unarchiver finishDecoding];
  }
  @catch (id) {}
  return success;
}


- (BOOL) dumpModels:(NSArray*)models toFile:(NSString*)filePath
{
  BOOL success = YES;
  @try
  {
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:models forKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    [archiver finishEncoding];
    success = [data writeToFile:filePath atomically:YES];
  }
  @catch (id)
  {
    success = NO;
  }
  return success;
}


- (NSArray*) modelsForType:(MI_DeviceModelType)modeltype
{
  return [NSArray arrayWithArray:[_deviceModels objectForKey:[NSNumber numberWithInt:modeltype]]];
}


- (MI_CircuitElementDeviceModel*) modelForName:(NSString*)modelName
{
    int t;
    NSEnumerator* modelEnum;
    MI_CircuitElementDeviceModel* currentModel;
    for (t = MI_DeviceModelTypeFirst; t <= MI_DeviceModelTypeLast; t++)
    {
        modelEnum = [[_deviceModels objectForKey:[NSNumber numberWithInt:t]] objectEnumerator];
        while (currentModel = [modelEnum nextObject])
            if ([[currentModel modelName] isEqualToString:modelName])
                return currentModel;
    }
    return nil;
}


- (IBAction) deleteSelectedDeviceModels:(id)sender
{
  NSIndexSet* selection = [modelTree selectedRowIndexes];
  if ([selection count] <= 0)
  {
    NSBeep();
    return;
  }

  for (NSInteger k = [selection lastIndex]; k >= 0; k--)
  {
    if ([selection containsIndex:k])
    {
      id target = [modelTree itemAtRow:k];
      if ([target isKindOfClass:[MI_CircuitElementDeviceModel class]] &&
          ![[target modelName] hasPrefix:@"Default"])
      {
          [[_deviceModels objectForKey:[NSNumber numberWithInt:
              [(MI_CircuitElementDeviceModel*)target type]]] removeObject:target];
      }
    }
  }
  [modelTree deselectAll:self];
  [modelTree reloadData];
}


- (IBAction) copySelectedDeviceModels:(id)sender
{
  MI_CircuitElementDeviceModel* tmpModel = nil;
  NSIndexSet* selection = [modelTree selectedRowIndexes];
  if ([selection count] <= 0)
  {
    NSBeep();
    return;
  }

  for (NSInteger k = [selection lastIndex]; k >= 0; k--)
  {
    if ([selection containsIndex:k])
    {
      id target = [modelTree itemAtRow:k];
      if ([target isKindOfClass:[MI_CircuitElementDeviceModel class]])
      {
        tmpModel = [target mutableCopy];
        [tmpModel setModelName:[@"Copy_of_" stringByAppendingString:[tmpModel modelName]]];
        [self addModel:tmpModel];
      }
    }
  }

  // Refreshing tree
  [modelTree deselectAll:self];
  [modelTree reloadData];
  if ([selection count] == 1)
  {
    NSIndexSet* set = [NSIndexSet indexSetWithIndex:[modelTree rowForItem:tmpModel]];
    [modelTree selectRowIndexes:set byExtendingSelection:NO];
    [modelTree scrollRowToVisible:[modelTree rowForItem:tmpModel]];
  }
}


- (IBAction) importDeviceModelsFromFile:(id)sender
{
  // prompt for file
  NSOpenPanel* op = [NSOpenPanel openPanel];
  op.canChooseFiles = YES;
  op.canChooseDirectories = NO;
  op.directoryURL = [NSURL fileURLWithPath:[SugarManager supportFolder]];
  [op beginSheet:deviceModelPanel completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSModalResponseOK)
    {
      // Unarchiving device models from the selected file
      NSString* filePath = [[[op URLs] objectAtIndex:0] path];
      if (filePath != nil)
      {
        if ([self addModelsFromFile:filePath])
          [modelTree reloadData];
        else
        {
          NSAlert* alert = [[NSAlert alloc] init];
          alert.messageText = [NSString stringWithFormat:@"Could not import (all) models from file %@!", filePath];
          [alert beginSheetModalForWindow:deviceModelPanel completionHandler:nil];
        }
      }
    }
  }];
}


- (IBAction) exportSelectedDeviceModelsToFile:(id)sender
{
  if ([[modelTree selectedRowIndexes] count] > 0)
  {
    NSSavePanel* sp = [NSSavePanel savePanel];
    sp.canCreateDirectories = YES;
    sp.directoryURL = [NSURL fileURLWithPath:[SugarManager supportFolder]];
    [sp beginSheet:deviceModelPanel completionHandler:^(NSModalResponse returnCode) {
      NSIndexSet* indices = [modelTree selectedRowIndexes];
      if ([indices count] > 0)
      {
        NSMutableArray* selection = [NSMutableArray arrayWithCapacity:[indices count]];
        for (NSInteger k = [indices lastIndex]; k >= 0; k--)
          if ( [indices containsIndex:k] &&
              [[modelTree itemAtRow:k] isKindOfClass:[MI_CircuitElementDeviceModel class]] )
            [selection addObject:[modelTree itemAtRow:k]];
        // archive all device models to the selected file
        NSString* filePath = [[sp URL] path];
        if (![self dumpModels:selection toFile:filePath])
        {
          NSAlert* alert = [[NSAlert alloc] init];
          alert.messageText = [NSString stringWithFormat:@"Could not save to file %@!", filePath];
          [alert beginSheetModalForWindow:deviceModelPanel completionHandler:nil];
        }
      }
    }];
  }
  else
      NSBeep();
}


//MARK: NSTextView delegate method
// This is called whenever the user modifies the device parameters and values.
- (void) textDidChange:(NSNotification*)aNotification
{
    NSInteger n = [modelTree selectedRow];
    if (n > -1)
    {
        id selection = [modelTree itemAtRow:n];
        if ([selection isKindOfClass:[MI_CircuitElementDeviceModel class]])
            [selection setDeviceParameters:[modelParametersArea string]];
    }
    else
        NSBeep();
}


// Constrains the position of the vertical splitter
- (float)    splitView:(NSSplitView *)sender
constrainMinCoordinate:(float)proposedMin
           ofSubviewAt:(int)offset
{
  return 170.0f;
}

- (float)    splitView:(NSSplitView *)sender
constrainMaxCoordinate:(float)proposedMin
           ofSubviewAt:(int)offset
{
  return [sender frame].size.width - 170.0f;
}

@end

//MARK: NSOutlineViewDelegate and NSOutlineViewDataSource implementation

@interface MI_DeviceModelManager (OutlineView) <NSOutlineViewDelegate, NSOutlineViewDataSource>
@end

@implementation MI_DeviceModelManager (OutlineView)

- (void) outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    NSInteger n = [modelTree selectedRow];
    if ( (n > -1) &&
         ([[modelTree selectedRowIndexes] count] == 1) )
    {
        id selection = [modelTree itemAtRow:n];
        if ([selection isKindOfClass:[MI_CircuitElementDeviceModel class]])
            [modelParametersArea setString:[selection deviceParameters]];
    }
    else
        [modelParametersArea setString:@""];
}


- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
        return YES;
    else
        return NO;
}


- (BOOL) outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
        return ![[item modelName] hasPrefix:@"Default"];
    else
        return NO;
}


- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
  if ( [item isKindOfClass:[MI_CircuitElementDeviceModel class]] )
  {
    [aCell setTextColor:[NSColor colorWithDeviceRed:0.0f green:0.0f blue:0.3f alpha:1.0f]];
  }
  else
  {
    [aCell setTextColor:[NSColor colorWithDeviceRed:75.0f/255.0f green:99.0f/255.0f blue:84.0f/255.0f alpha:1.0f]];
  }
}


- (id) outlineView:(NSOutlineView *)outlineView
             child:(int)index
            ofItem:(id)item
{
  if (item == nil &&
      index >= MI_DeviceModelTypeFirst &&
      index <= MI_DeviceModelTypeLast)
  {
    for (NSNumber* a in [_deviceModels allKeys])
    {
      if ([a intValue] == index)
        return a;
    }
    return nil;
  }
  else if ([item isKindOfClass:[NSNumber class]])
    // return the child of a device model type arrays - a device model
    return [[_deviceModels objectForKey:item] objectAtIndex:index];
  else
    return nil;
}


- (id) outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            byItem:(id)item
{
  if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
  {
    return [item modelName];
  }
  switch ([((NSNumber*)item) intValue])
  {
    case MI_DeviceModelTypeDiode:   return @"Diodes";
    case MI_DeviceModelTypeBJT:     return @"BJTs";
    case MI_DeviceModelTypeJFET:    return @"JFETs";
    case MI_DeviceModelTypeMOSFET:     return @"MOSFETs";
    case MI_DeviceModelTypeSwitch:  return @"Switches";
    case MI_DeviceModelTypeTransmissionLine: return @"Transmission Lines";
    default: return nil;
  }
}


- (NSUInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
  if (item == nil)
      return [_deviceModels count];
  else if ([item isKindOfClass:[NSNumber class]])
      return [[_deviceModels objectForKey:item] count];
  else
      return 0;
}


- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
  return [item isKindOfClass:[NSNumber class]];
}


- (void) outlineView:(NSOutlineView *)outlineView
      setObjectValue:(id)anObject
      forTableColumn:(NSTableColumn *)tableColumn
              byItem:(id)item
{
  if ([anObject isKindOfClass:[NSString class]] && [item isKindOfClass:[MI_CircuitElementDeviceModel class]])
  {
    NSString* modelName = (NSString*)anObject;
    modelName = [modelName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([modelName hasPrefix:@"Default"])
    {
      modelName = [modelName stringByReplacingCharactersInRange:NSMakeRange(0, 7) withString:@"Custom"];
    }
    [[modelTree itemAtRow:[modelTree selectedRow]] setModelName:modelName];
  }
}

@end


//MARK: NSToolbarDelegate implementation


@implementation MI_DeviceModelManager (ToolbarDelegate)

- (NSArray*) toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects:@"Delete", @"Copy", @"Import", @"Export",nil];
}

- (NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
  return [NSArray arrayWithObjects:@"Delete", @"Copy", @"Import", @"Export", nil];
}


- (NSToolbarItem *)toolbar:(NSToolbar*)toolbar
     itemForItemIdentifier:(NSString*)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
  if ([itemIdentifier isEqualToString:@"Delete"])
  {
    if (deleteButton == nil)
    {
      deleteButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Delete"];
      [deleteButton setLabel:@"Delete"];
      [deleteButton setAction:@selector(deleteSelectedDeviceModels:)];
      [deleteButton setTarget:self];
      [deleteButton setToolTip:@"Delete the selected device models."];
      [deleteButton setImage:[NSImage imageNamed:@"delete_selected_device_model"]];
    }
    return deleteButton;
  }
  else if ([itemIdentifier isEqualToString:@"Copy"])
  {
    if (copyButton == nil)
    {
      copyButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Copy"];
      [copyButton setLabel:@"Copy"];
      [copyButton setAction:@selector(copySelectedDeviceModels:)];
      [copyButton setTarget:self];
      [copyButton setToolTip:@"Copy the selected device models."];
      [copyButton setImage:[NSImage imageNamed:@"copy_selected_device_model"]];
    }
    return copyButton;
  }
  else if ([itemIdentifier isEqualToString:@"Import"])
  {
    if (importButton == nil)
    {
      importButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Import"];
      [importButton setLabel:@"Import..."];
      [importButton setAction:@selector(importDeviceModelsFromFile:)];
      [importButton setTarget:self];
      [importButton setToolTip:@"Import device models from a file."];
      [importButton setImage:[NSImage imageNamed:@"import_device_models"]];
    }
    return importButton;
  }
  else // if ([itemIdentifier isEqualToString:@"Export"])
  {
    if (exportButton == nil)
    {
      exportButton = [[NSToolbarItem alloc] initWithItemIdentifier:@"Export"];
      [exportButton setLabel:@"Export..."];
      [exportButton setAction:@selector(exportSelectedDeviceModelsToFile:)];
      [exportButton setTarget:self];
      [exportButton setToolTip:@"Export the selected device models to file."];
      [exportButton setImage:[NSImage imageNamed:@"export_all_device_models"]];
    }
    return exportButton;
  }
}

@end
