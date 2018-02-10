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
#import "MI_NamedArray.h"

static MI_DeviceModelManager* sharedDeviceModelManager = nil;

NSString* MISUGAR_DEVICE_MODELS_PANEL_FRAME = @"DeviceModelsPanelFrame";

// Since the user is not allowed to change the path of the device models file
// we can put the path into a static variable which remains valid until the
// application exits.
static NSString* deviceModelsFilePath = nil;


@implementation MI_DeviceModelManager

- (id) init
{
    if (sharedDeviceModelManager == nil)
    {
        sharedDeviceModelManager = [super init];
        deviceModelPanel = nil;
        copyButton = nil;
        deleteButton = nil;
        importButton = nil;
        
        // Construct the device model library structure
        int g;
        deviceModels = [[NSMutableDictionary alloc] initWithCapacity:6];
        for (g = FIRST_DEVICE_MODEL_TYPE; g <= LAST_DEVICE_MODEL_TYPE; g++)
            [deviceModels setObject:[NSMutableArray arrayWithCapacity:3]
                             forKey:[NSNumber numberWithInt:g]];

        // Load the device models from the dedicated library file
        BOOL isDir;
        NSFileManager* fm = [NSFileManager defaultManager];
        
        // Check if the generic application support folder exists - create if necessary
        NSString* supportFolder = [[SugarManager supportFolder] stringByDeletingLastPathComponent];
        if (![fm fileExistsAtPath:supportFolder isDirectory:&isDir] || !isDir)
            [fm createDirectoryAtPath:supportFolder attributes:nil];
        // Check if MI-SUGAR's folder in the application support folder exists
        supportFolder = [SugarManager supportFolder];
        if (![fm fileExistsAtPath:supportFolder isDirectory:&isDir])
            [fm createDirectoryAtPath:supportFolder attributes:nil];
        else if (!isDir)
        {
            // rename the existing file
            [fm movePath:supportFolder
                  toPath:[NSHomeDirectory() stringByAppendingString:@"/.Trash"]
                 handler:nil];
            [fm createDirectoryAtPath:supportFolder attributes:nil];
        }
        // Check if the device model library file exists
        deviceModelsFilePath = [[supportFolder stringByAppendingString:@"/Device Models"] retain];
        if ( [fm fileExistsAtPath:deviceModelsFilePath isDirectory:&isDir] )
        {
            if (isDir)
            {
                // What? This file is not supposed to be a directory.
                [fm movePath:supportFolder
                      toPath:[NSHomeDirectory() stringByAppendingString:@"/.Trash"]
                     handler:nil];
            }
            else
            {
                // Unarchive the device models
            NS_DURING
                NSKeyedUnarchiver* unarchiver =
                    [[NSKeyedUnarchiver alloc] initForReadingWithData:
                        [NSData dataWithContentsOfFile:deviceModelsFilePath]];
                id myModels = [unarchiver decodeObjectForKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
                if (myModels != nil && [myModels isKindOfClass:[NSArray class]])
                {
                    NSEnumerator* modelEnum = [myModels objectEnumerator];
                    MI_CircuitElementDeviceModel* currentModel;
                    while (currentModel = [modelEnum nextObject])
                        [self addModel:currentModel];
                }
                [unarchiver finishDecoding];
                [unarchiver release];
            NS_HANDLER
                if (NSRunAlertPanel(@"Corrupt device models file!",
                    @"The content of your device models library can not be read!",
                    @"Back up", @"Delete", nil) == NSOKButton)
                    // backup old file
                    [fm movePath:deviceModelsFilePath
                          toPath:[supportFolder stringByAppendingString:@"/Corrupt Device Models File"]
                         handler:nil];
                else
                    // delete old file
                    [fm removeFileAtPath:deviceModelsFilePath
                                 handler:nil];                                            
            NS_ENDHANDLER
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
            NSEnumerator* modelEnum = [legacyModels objectEnumerator];
            MI_CircuitElementDeviceModel* currentModel;
            while (currentModel = [modelEnum nextObject])
            {
                // Check if this is one of the old specialized MOS models
                if ([currentModel type] == MOS_DEVICE_MODEL_TYPE)
                {
                    // Deprecate and create a generic MOS model instead
                    MI_MOSDeviceModel* mosModel =
                        [[MI_MOSDeviceModel alloc] initWithName:[currentModel modelName]];
                    [mosModel setDeviceParameters:[currentModel deviceParameters]];
                    [self addModel:mosModel];
                }
                else
                    [self addModel:currentModel];
            }
            // Set the legacy device models array in the user preference to empty.
            [[NSUserDefaults standardUserDefaults]
                setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray array]]
                   forKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
        }
        
        // Make sure the default device models are included.
        NSEnumerator *e;
        NSMutableArray *currentArray;
        MI_CircuitElementDeviceModel *currentModel;
        int p;
        BOOL foundDefault;
        for (p = FIRST_DEVICE_MODEL_TYPE; p <= LAST_DEVICE_MODEL_TYPE; p++)
        {
            currentArray = [deviceModels objectForKey:[NSNumber numberWithInt:p]];
            if (currentArray == nil)
            {
                currentArray = [NSMutableArray arrayWithCapacity:3];
                [deviceModels setObject:currentArray
                                 forKey:[NSNumber numberWithInt:p]];                
            }
            e = [currentArray objectEnumerator];
            foundDefault = NO;
            while (currentModel = [e nextObject])
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
                    case DIODE_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_DiodeDeviceModel alloc] initWithName:@"DefaultDiode"]; break;
                    case BJT_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_BJTDeviceModel alloc] initWithName:@"DefaultBJT"]; break;
                    case JFET_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_JFETDeviceModel alloc] initWithName:@"DefaultJFET"]; break;
                    case MOS_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_MOSDeviceModel alloc] initWithName:@"DefaultMOSFET"]; break;
                    case SWITCH_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_SwitchDeviceModel alloc] initWithName:@"DefaultSwitch"]; break;
                    case TRANSMISSION_LINE_DEVICE_MODEL_TYPE:
                        currentModel = [[MI_TransmissionLineDeviceModel alloc] initWithName:@"DefaultTransmissionLine"]; break;
                    default:
                        currentModel = nil;
                }
                if (currentModel != nil)
                    [currentArray addObject:currentModel];
            }
        }
    }
    return sharedDeviceModelManager;
}


+ (MI_DeviceModelManager*) sharedManager
{
    if (sharedDeviceModelManager == nil)
        [[MI_DeviceModelManager alloc] init];
    return sharedDeviceModelManager;
}


- (void) showPanel
{
    if (deviceModelPanel == nil)
    {
        // Load device models
        [NSBundle loadNibNamed:@"SchematicDeviceModelsPanel"
                         owner:self];
        
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
        [deviceModelPanel setToolbar:[toolbar autorelease]];
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
    for (m = FIRST_DEVICE_MODEL_TYPE; m <= LAST_DEVICE_MODEL_TYPE; m++)
        [all addObjectsFromArray:[deviceModels objectForKey:[NSNumber numberWithInt:m]]];
    // Save to file
    if (deviceModelsFilePath != nil)
        [self dumpModels:all
                  toFile:deviceModelsFilePath];
}


- (NSString*) deviceParametersForModelName:(NSString*)name
{
    int x;
    NSEnumerator* modelEnum;
    MI_CircuitElementDeviceModel* model;
    for (x = FIRST_DEVICE_MODEL_TYPE; x <= LAST_DEVICE_MODEL_TYPE; x++)
    {
        modelEnum = [[deviceModels objectForKey:[NSNumber numberWithInt:x]] objectEnumerator];
        while (model = [modelEnum nextObject])
        {
            if ([[model modelName] isEqualToString:name])
                return [model deviceParameters];
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
    NSMutableArray* modelTypeArray =
        [deviceModels objectForKey:[NSNumber numberWithInt:[newModel type]]];
    if (modelTypeArray != nil && ![modelTypeArray containsObject:newModel])
        [modelTypeArray addObject:newModel];
}


- (BOOL) addModelsFromFile:(NSString*)filePath
{
    BOOL success = YES;
NS_DURING
    NSKeyedUnarchiver* unarchiver =
    [[NSKeyedUnarchiver alloc] initForReadingWithData:
        [NSData dataWithContentsOfFile:filePath]];
    id imported = [unarchiver decodeObjectForKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    if ( (imported != nil) && [imported isKindOfClass:[NSArray class]] )
    {
        NSEnumerator* importedModelsEnum = [imported objectEnumerator];
        MI_CircuitElementDeviceModel* currentModel;
        while (currentModel = [importedModelsEnum nextObject])
            [self addModel:currentModel];
    }
    else
        success = NO;
    [unarchiver finishDecoding];
    [unarchiver release];
NS_HANDLER
    success = NO;
NS_ENDHANDLER
    return success;
}


- (BOOL) dumpModels:(NSArray*)models
             toFile:(NSString*)filePath
{
    // Using standard Mac OS X binary archiving
    BOOL success = YES;
    NSMutableData* data = [NSMutableData data];

NS_DURING
    NSKeyedArchiver* archiver =
        [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:models
                    forKey:MISUGAR_CIRCUIT_DEVICE_MODELS];
    [archiver finishEncoding];
    success = [data writeToFile:filePath
                     atomically:YES];
    [archiver release];
NS_HANDLER
    success = NO;
NS_ENDHANDLER

    return success;
}


- (NSArray*) modelsForType:(MI_DeviceModelType)modeltype
{
    return [NSArray arrayWithArray:
        [deviceModels objectForKey:[NSNumber numberWithInt:modeltype]]];
}


- (MI_CircuitElementDeviceModel*) modelForName:(NSString*)modelName
{
    int t;
    NSEnumerator* modelEnum;
    MI_CircuitElementDeviceModel* currentModel;
    for (t = FIRST_DEVICE_MODEL_TYPE; t <= LAST_DEVICE_MODEL_TYPE; t++)
    {
        modelEnum = [[deviceModels objectForKey:[NSNumber numberWithInt:t]] objectEnumerator];
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
        NSBeep();
    else
    {
        int k;
        for (k = [selection lastIndex]; k >= 0; k--)
            if ([selection containsIndex:k])
            {
                // Get the type of the target model
                id target = [modelTree itemAtRow:k];
                if ([target isKindOfClass:[MI_CircuitElementDeviceModel class]] &&
                    ![[target modelName] hasPrefix:@"Default"])
                {
                    [[deviceModels objectForKey:[NSNumber numberWithInt:
                        [(MI_CircuitElementDeviceModel*)target type]]] removeObject:target];
                }
            }
        [modelTree deselectAll:self];
        [modelTree reloadData];
    }
}


- (IBAction) copySelectedDeviceModels:(id)sender
{
    MI_CircuitElementDeviceModel* tmpModel = nil;
    NSIndexSet* selection = [modelTree selectedRowIndexes];
    if ([selection count] <= 0)
        NSBeep();
    else
    {
        int k;
        for (k = [selection lastIndex]; k >= 0; k--)
            if ([selection containsIndex:k])
            {
                id target = [modelTree itemAtRow:k];
                if ([target isKindOfClass:[MI_CircuitElementDeviceModel class]])
                {
                    tmpModel = [target mutableCopy];
                    [tmpModel setModelName:[@"Copy_of_" stringByAppendingString:
                        [tmpModel modelName]]];
                    [self addModel:tmpModel];
                }
            }
        // Refresh tree
        [modelTree deselectAll:self];
        [modelTree reloadData];
        if ([selection count] == 1)
        {
            [modelTree selectRow:[modelTree rowForItem:tmpModel]
                byExtendingSelection:NO];
            [modelTree scrollRowToVisible:[modelTree rowForItem:tmpModel]];
        }
    }
}


- (IBAction) importDeviceModelsFromFile:(id)sender
{
    // prompt for file
    NSOpenPanel* op = [NSOpenPanel openPanel];
    [op setCanChooseFiles:YES];
    [op setCanChooseDirectories:NO];
    [op beginSheetForDirectory:[SugarManager supportFolder]
                          file:nil
                         types:nil
                modalForWindow:deviceModelPanel
                 modalDelegate:self
                didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                   contextInfo:@"import"];
}


- (IBAction) exportSelectedDeviceModelsToFile:(id)sender
{
    if ([[modelTree selectedRowIndexes] count] > 0)
    {
        // prompt for file
        NSSavePanel* sp = [NSSavePanel savePanel];
        [sp setCanCreateDirectories:YES];
        [sp beginSheetForDirectory:[SugarManager supportFolder]
                              file:nil
                    modalForWindow:deviceModelPanel
                     modalDelegate:self
                    didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo:@"export"];
    }
    else
        NSBeep();
}


// Called when user has finished selecting a file in NSOpenPanel
// Performs the actual export/import tasks
- (void) openPanelDidEnd:(NSOpenPanel*)sheet
              returnCode:(int)returnCode
             contextInfo:(void*)contextInfo
{
    if (returnCode != NSModalResponseOK)
        return;
    if ([(id)contextInfo isKindOfClass:[NSString class]])
    {
        if ([(NSString*)contextInfo isEqualToString:@"export"])
        {
            // get the selected models
            int k;
            NSIndexSet* indices = [modelTree selectedRowIndexes];
            if ([indices count] > 0)
            {
                NSMutableArray* selection = [NSMutableArray arrayWithCapacity:[indices count]];
                for (k = [indices lastIndex]; k >= 0; k--)
                    if ( [indices containsIndex:k] &&
                         [[modelTree itemAtRow:k] isKindOfClass:[MI_CircuitElementDeviceModel class]] )
                        [selection addObject:[modelTree itemAtRow:k]];
                // archive all device models to the selected file
                NSString* filePath = [[sheet URL] path];
                if (![self dumpModels:selection toFile:filePath])
                    NSBeginAlertSheet(nil, nil, nil, nil, deviceModelPanel, nil, nil, nil, nil, @"Could not save to file %@!", filePath);
            }
        }
        else
        {
            // unarchive device models from the selected file
            NSString* filePath = [[sheet URL] path];
            if ([self addModelsFromFile:filePath])
                [modelTree reloadData];
            else
                NSBeginAlertSheet(nil, nil, nil, nil, deviceModelPanel, nil, nil, nil, nil, @"Could not import (all) models from file %@!", filePath);
        }
    }
}

/********************************************* Data source and delegate methods ***/

// NSTextView delegate method
// This is called whenever the user modifies the device parameters and values.
- (void) textDidChange:(NSNotification*)aNotification
{
    int n = [modelTree selectedRow];
    if (n > -1)
    {
        id selection = [modelTree itemAtRow:n];
        if ([selection isKindOfClass:[MI_CircuitElementDeviceModel class]])
            [selection setDeviceParameters:[modelParametersArea string]];
    }
    else
        NSBeep();
}


// NSOutlineView delegate method to respond to item selection events
- (void) outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    int n = [modelTree selectedRow];
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


- (BOOL) outlineView:(NSOutlineView *)outlineView
    shouldSelectItem:(id)item
{
    if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
        return YES;
    else
        return NO;
}


- (BOOL) outlineView:(NSOutlineView *)outlineView
shouldEditTableColumn:(NSTableColumn *)tableColumn
                item:(id)item
{
    if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
        return ![[item modelName] hasPrefix:@"Default"];
    else
        return NO;
}


- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(id)aCell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    if ( [item isKindOfClass:[MI_CircuitElementDeviceModel class]] )
    {
        [aCell setTextColor:[NSColor colorWithDeviceRed:(0.0f)
                                                  green:(0.0f)
                                                   blue:(0.3f)
                                                  alpha:1.0f]];
    }
    else
    {
        [aCell setTextColor:[NSColor colorWithDeviceRed:(75.0f/255.0f)
                                                  green:(99.0f/255.0f)
                                                   blue:(84.0f/255.0f)
                                                  alpha:1.0f]];
    }
}


- (id) outlineView:(NSOutlineView *)outlineView
             child:(int)index
            ofItem:(id)item
{
    if (item == nil &&
        index >= FIRST_DEVICE_MODEL_TYPE &&
        index <= LAST_DEVICE_MODEL_TYPE)
    {
        // return a child of the root level - a device model type array
        NSEnumerator* numberEnum = [deviceModels keyEnumerator];
        NSNumber* a;
        while (a = [numberEnum nextObject])
            if ([a intValue] == index)
                return a;
        return nil;
    }
    else if ([item isKindOfClass:[NSNumber class]])
        // return the child of a device model type arrays - a device model
        return [[deviceModels objectForKey:item] objectAtIndex:index];
    else
        return nil;
}


- (id) outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            byItem:(id)item
{
    if ([item isKindOfClass:[MI_CircuitElementDeviceModel class]])
        return [item modelName];
    else //if ([item isKindOfClass:[NSNumber class]])
    {
        switch ([((NSNumber*)item) intValue])
        {
            case DIODE_DEVICE_MODEL_TYPE:   return @"Diodes"; break;
            case BJT_DEVICE_MODEL_TYPE:     return @"BJTs"; break;
            case JFET_DEVICE_MODEL_TYPE:    return @"JFETs"; break;
            case MOS_DEVICE_MODEL_TYPE:     return @"MOSFETs"; break;
            case SWITCH_DEVICE_MODEL_TYPE:  return @"Switches"; break;
            case TRANSMISSION_LINE_DEVICE_MODEL_TYPE: return @"Transmission Lines"; break;
            default: return nil;
        }
    }
}


- (int) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
        return [deviceModels count];
    else if ([item isKindOfClass:[NSNumber class]])
        return [[deviceModels objectForKey:item] count];
    else
        return 0;
}


- (BOOL) outlineView:(NSOutlineView *)outlineView
    isItemExpandable:(id)item
{
    return [item isKindOfClass:[NSNumber class]];
}


- (void) outlineView:(NSOutlineView *)outlineView
      setObjectValue:(id)anObject
      forTableColumn:(NSTableColumn *)tableColumn
              byItem:(id)item
{
    if ([anObject isKindOfClass:[NSString class]] &&
        [item isKindOfClass:[MI_CircuitElementDeviceModel class]])
    {
        // Remove whitespace characters, if any
        NSMutableString* filtered = [NSMutableString stringWithCapacity:[(NSString*)anObject length]];
        [filtered setString:anObject];
        NSRange r;
        while ((r = [filtered rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]]).location != NSNotFound)
            [filtered deleteCharactersInRange:r];
        if ([filtered hasPrefix:@"Default"])
            [filtered replaceCharactersInRange:NSMakeRange(0, 7)
                                    withString:@"Custom"];
        [[modelTree itemAtRow:[modelTree selectedRow]] setModelName:[NSString stringWithString:filtered]];
    }    
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

/******************************** Toolbar delegate methods **************/

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

/**********************************************************************************/

- (void) dealloc
{
    // save panel geometry
    if (deviceModelPanel != nil)
        [deviceModelPanel saveFrameUsingName:MISUGAR_DEVICE_MODELS_PANEL_FRAME];
    // save device models
    [self saveModels];
    [deviceModelsFilePath release];
    deviceModelsFilePath = nil;
    [deviceModels release];
    sharedDeviceModelManager = nil;
    [modelTree setDelegate:nil];
    [super dealloc];
}

@end
