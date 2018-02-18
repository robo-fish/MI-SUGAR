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
#import "MI_SubcircuitLibraryManager.h"
#import "MI_DeviceModelManager.h"
#import "SugarManager.h"

// Objects of this class represent the subcircuits.
// The file paths are used to open the subcircuit definition when the user double-clicks the item.
@interface MI_SubcircuitWithFile : NSObject
@property (readonly) MI_SubcircuitElement* subcircuit;
@property (readonly) NSString* file;
- (instancetype) initWithSubcircuit:(MI_SubcircuitElement*)subckt filepath:(NSString*)path;
@end
@implementation MI_SubcircuitWithFile
- (instancetype) initWithSubcircuit:(MI_SubcircuitElement*)subckt filepath:(NSString*)path
{
  if (self = [super init])
  {
    _subcircuit = subckt;
    _file = path;
  }
  return self;
}
@end

@interface MI_NamedArray : NSObject <NSCoding>
@property NSArray<MI_SubcircuitWithFile*>* theArray;
@property NSString* name;
@end

@implementation MI_NamedArray
- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    self.theArray = [decoder decodeObjectForKey:@"Array"];
    self.name = [decoder decodeObjectForKey:@"Name"];
  }
  return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.theArray forKey:@"Array"];
  [encoder encodeObject:self.name forKey:@"Name"];
}
@end

// Stores loaded subcircuit document models and maps
// fully-qualified subcircuit element names to the subcircuit document models.
// Fully qualified means that the namespace is prepended to the subcircuit name.
// If the namespace is not an empty string then a dot (".") will be used to
// separate namespace and name
static NSMutableDictionary* elementDefinitions = nil;

// The named arrays can hold even other named arrays or subcircuit elements
// The items mirror the directory structure of the subcircuit library (aka repository).
static NSMutableArray<MI_SubcircuitWithFile*>* subcircuits = nil;

NSArray<MI_SubcircuitWithFile*>* extractSubcircuitFromSubpath(NSString* path);


// Implements the NSOutlineViewDataSource informal protocol.
// It represents the directory structure beneath the repository root folder.
@implementation MI_SubcircuitLibraryManager

- (instancetype) initWithChooserView:(MI_SchematicElementChooser*)theChooser
                           tableView:(NSOutlineView*)theTable
                       namespaceView:(NSTextField*)nsField
{
    if (self = [super init])
    {
        NSFileManager* fm = [NSFileManager defaultManager];
        chooser = theChooser;       // not retained because it's provided by a NIB file
        table = theTable;           // also not retained on purpose
        namespaceField = nsField;   // also not retained
        subcircuits = [[NSMutableArray alloc] initWithCapacity:10];
        elementDefinitions = [[NSMutableDictionary alloc] initWithCapacity:10];
                
        // Check if the subcircuit library directory exists.
        NSString* repositoryPath = [[NSUserDefaults standardUserDefaults]
            objectForKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
        if (![self validateLibraryFolder:repositoryPath warnUser:NO])
        {
            repositoryPath = [MI_SubcircuitLibraryManager defaultSubcircuitLibraryPath];
            [[NSUserDefaults standardUserDefaults]
                setObject:repositoryPath
                   forKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
        }
        
        // Check if the subcircuit folder is the default one.
        // If so, we are responsible of making sure that folder exists.
        if ([repositoryPath isEqualToString:
                [MI_SubcircuitLibraryManager defaultSubcircuitLibraryPath]])
        {
            NSString* misugarSupportFolder = [SugarManager supportFolder];
            NSString* repositoryTree = [misugarSupportFolder stringByDeletingLastPathComponent];
            BOOL isDirectory;
            if (![fm fileExistsAtPath:repositoryTree isDirectory:&isDirectory])
            {
              [fm createDirectoryAtPath:repositoryTree withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            if (![fm fileExistsAtPath:misugarSupportFolder isDirectory:&isDirectory])
            {
              [fm createDirectoryAtPath:misugarSupportFolder withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            repositoryTree = [misugarSupportFolder stringByAppendingString:@"/Subcircuits"];
            if (![fm fileExistsAtPath:repositoryTree
                          isDirectory:&isDirectory])
            {
                if (!isDirectory) // Well, that would be really strange!
                {
                  [fm removeItemAtPath:repositoryTree error:NULL];
                }
                // Repository does not exist. Create it.
                [fm createDirectoryAtPath:repositoryTree withIntermediateDirectories:YES attributes:nil error:NULL];
                // Download available subcircuits from MacInit.
                // [self synchronizeWithOnlineLibrary];
            }
        }
        else if ([repositoryPath isEqualToString:[NSHomeDirectory() stringByAppendingString:
                                                  @"/Library/Application Support/MI-SUGAR/Subcircuits"]])
        {
            // This case has most likely occured because the user does not use an
            // English version of Mac OS X and has upgraded from version 0.5.3
            // in which the default subcircuits folder was not at a localized path.
            // We will quietly move the subcircuit folder to the localized path
            [fm moveItemAtPath:repositoryPath toPath:[SugarManager supportFolder] error:NULL];
            [[NSUserDefaults standardUserDefaults] setObject:[MI_SubcircuitLibraryManager defaultSubcircuitLibraryPath] forKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
        }
        
        [self refreshAll];        
    }
    return self;
}


- (BOOL) addSubcircuitToLibrary:(MI_SubcircuitDocumentModel*)definition
                           show:(BOOL)openDocument
{
    NSString* repositoryPath = [[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
    if (![self validateLibraryFolder:repositoryPath
                            warnUser:YES])
        return NO;
    // Archive the given subcircuit model in the repository
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver =
        [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[NSNumber numberWithInt:MISUGAR_DOCUMENT_VERSION]
                    forKey:@"Version"];
    [archiver encodeObject:definition
                    forKey:@"MI-SUGAR Document Model"];
    [archiver encodeObject:[definition circuitDeviceModels]
                    forKey:@"MI-SUGAR Circuit Device Models"];
    [archiver finishEncoding];
    NSString* targetFile = [NSString stringWithFormat:@"%@/%@.subckt.sugar", repositoryPath, [definition circuitName]];
    if (![data writeToFile:targetFile atomically:YES])
    {
      return NO;
    }
    // Refresh display and select the new item
    [self refreshList];
    for (long n = [table numberOfRows] - 1; n >= 0; n--)
    {
        id item = [table itemAtRow:n];
        if ([item isKindOfClass:[MI_SubcircuitWithFile class]] &&
            [[[[((MI_SubcircuitWithFile*)item) subcircuit] definition] fullyQualifiedCircuitName]
                isEqualToString:[definition fullyQualifiedCircuitName]])
        {
            [self displaySubcircuitElement:[((MI_SubcircuitWithFile*)item) subcircuit]];
            [table selectRowIndexes:[NSIndexSet indexSetWithIndex:n] byExtendingSelection:NO];
            break;
        }
    }
    if (openDocument)
    {
      // automatically open the new subcircuit's definition
      [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[[NSURL alloc] initFileURLWithPath:targetFile]  display:YES completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
        /* nothing */
      }];
    }
    return YES;
}


- (void) synchronizeWithOnlineLibrary
{
    // Connect to online library
    [namespaceField setStringValue:@"connecting..."];
    // Authenticate
    [namespaceField setStringValue:@"logging in"];
    // Get new subcircuits
    [namespaceField setStringValue:@"syncing..."];
    // Finish
    [namespaceField setStringValue:@""];
}


/******************   NSOutlineViewDataSource protocol implementations  ***/

- (id) outlineView:(NSOutlineView *)outlineView
             child:(NSInteger)index
            ofItem:(id)item
{
    if (item == nil)
    {
        return [subcircuits count] ? [subcircuits objectAtIndex:index] : @"[ empty ]";
    }
    else if ([item isKindOfClass:[MI_NamedArray class]])
        return [[item array] objectAtIndex:index];
    else
        return nil;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [subcircuits count] ? [item isKindOfClass:[MI_NamedArray class]] : NO;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
        return [subcircuits count] ? [subcircuits count] : 1;
    else if ([item isKindOfClass:[MI_NamedArray class]])
        return [[item array] count];
    else
        return 0;
}

- (id) outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            byItem:(id)item
{
    if ([subcircuits count] == 0)
        return @"[ empty ]";
    if ([item isKindOfClass:[MI_NamedArray class]])
        return [item name];
    else if ([item isKindOfClass:[MI_SubcircuitWithFile class]])
        return [[item subcircuit] name];
    else
        return nil;
}

/************************ NSOutlineView delegate method implementations ****/

//  Sets foreground text color of cells
- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(id)cell
     forTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    if ([item isKindOfClass:[MI_NamedArray class]])
        [((NSTextFieldCell*)cell) setTextColor:
            [NSColor colorWithDeviceRed:0.5f
                                  green:0.6f
                                   blue:0.5f
                                  alpha:1.0f]];
    else
        [((NSTextFieldCell*)cell) setTextColor:
            [NSColor colorWithDeviceRed:0.1f
                                  green:0.1f
                                   blue:0.2f
                                  alpha:1.0f]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   shouldSelectItem:(id)item
{
    return [subcircuits count] ? [item isKindOfClass:[MI_SubcircuitWithFile class]] : NO;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView
shouldEditTableColumn:(NSTableColumn *)tableColumn
                item:(id)item
{
    return NO;
}

/***************************************************************************/

- (void) refreshList
{
    // Clear display
    [self displaySubcircuitElement:nil];
    // Delete all accumulated data
    [subcircuits removeAllObjects];
    [elementDefinitions removeAllObjects];
    // Create table data based on file names in the library directory.
    NSString* rootFolder = [[NSUserDefaults standardUserDefaults]
        objectForKey:MISUGAR_SUBCIRCUIT_LIBRARY_FOLDER];
    [subcircuits setArray:extractSubcircuitFromSubpath(rootFolder)];
    // refresh table
    if ([subcircuits count] == 0)
    {
        [table setAllowsEmptySelection:YES];
        [table deselectAll:self];
    }
    else
        [table setAllowsEmptySelection:NO];
    [table reloadData];
}


- (void) refreshAll
{
    [self displaySubcircuitElement:nil];
    [self refreshList];
    // Display the first subcircuit element from the top of the list.
    if ([subcircuits count] &&
        [[subcircuits objectAtIndex:0] isKindOfClass:[MI_SubcircuitWithFile class]])
    {
        [self displaySubcircuitElement:[[subcircuits objectAtIndex:0] subcircuit]];
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
    else
    {
        [table setAllowsEmptySelection:YES];
        [table deselectAll:self];
        if ([subcircuits count])
            [table setAllowsEmptySelection:NO];
    }
}


- (MI_SubcircuitDocumentModel*) modelForSubcircuitName:(NSString*)name
{
    return [elementDefinitions objectForKey:name];
}


- (IBAction) showDefinitionOfSelectedSubcircuit:(id)sender
{
    if (table == nil)
        return;
    id item = [table itemAtRow:[table clickedRow]];
    if ([item isKindOfClass:[MI_SubcircuitWithFile class]])
    {
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[item file]] display:YES
      completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
        // do nothing
      }];
    }
}


+ (NSString*) defaultSubcircuitLibraryPath
{
    return [[SugarManager supportFolder] stringByAppendingString:@"/Subcircuits"];
}


- (BOOL) validateLibraryFolder:(NSString*)folderPath
                      warnUser:(BOOL)warn
{
    BOOL isDir;
    if (folderPath == nil
        || ![[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDir]
        || !isDir)
    {
        if (warn)
        {
          NSAlert* alert = [[NSAlert alloc] init];
          alert.messageText = @"MI-SUGAR Error";
          alert.informativeText = @"The subcircuit library folder is not valid.";
          [alert runModal];
        }
        return NO;
    }
    return YES;
}


// NSOutlineView delegate method to respond to item selection events
- (void) outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    id selected = [[aNotification object] itemAtRow:[[aNotification object] selectedRow]];
    if ([selected isKindOfClass:[MI_SubcircuitWithFile class]])
        [self displaySubcircuitElement:[selected subcircuit]];
}


- (void) displaySubcircuitElement:(MI_SubcircuitElement*)element
{
    [chooser setSchematicElement:element];
    if (element && [element elementNamespace] && [[element elementNamespace] length])
        [namespaceField setStringValue:[element elementNamespace]];
    else
        [namespaceField setStringValue:@""];
}

@end


// Iterative method which creates a list of MI_SubcircuitElement objects
// found at the given path, where sublist elements are inserted for subpaths.
NSArray<MI_SubcircuitWithFile*>* extractSubcircuitFromSubpath(NSString* path)
{
  // First, Get all files in the repository folder, including subfolders
  NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
  NSMutableArray<MI_SubcircuitWithFile*>* result = [NSMutableArray arrayWithCapacity:10];
  // Now build a list where directories are sublists
  // and subcircuit elements are items
  MI_SubcircuitElement* element;
  MI_SubcircuitWithFile* tableItem;

  for (NSString* fileName in files)
  {
    NSString* filePath = [path stringByAppendingPathComponent:fileName];
    if ([[[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:NULL]
            objectForKey:NSFileType] isEqualToString:NSFileTypeDirectory])
    {
      // recursing into sub-directory
      [result addObjectsFromArray:extractSubcircuitFromSubpath(filePath)];
    }
    else
    {
      // Deserialize the sugar files
      MI_SubcircuitDocumentModel* newModel = nil;
      int fileVersion;
      NSArray* deviceModels = nil;
      @try
      {
        NSData* data = [NSData dataWithContentsOfFile:filePath];
        if (data == nil)
            continue;
        NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        fileVersion = [[unarchiver decodeObjectForKey:@"Version"] intValue];
        newModel = [unarchiver decodeObjectForKey:@"MI-SUGAR Document Model"];
        deviceModels = [unarchiver decodeObjectForKey:@"MI-SUGAR Circuit Device Models"];
        [unarchiver finishDecoding];
      }
      @catch (id)
      {
        continue; // skip this file
      }
      if (newModel != nil && [newModel isKindOfClass:[MI_SubcircuitDocumentModel class]])
      {
        MI_SubcircuitDocumentModel* subcircuitModel = (MI_SubcircuitDocumentModel*)newModel;
        // Add the definition of the subcircuit to the database
        NSString* fullyQualifiedName = [subcircuitModel fullyQualifiedCircuitName];
        if (![elementDefinitions objectForKey:fullyQualifiedName])
        {
          [elementDefinitions setObject:newModel forKey:fullyQualifiedName];
        }
        // If the opened file includes new device models they must be added to the local repository
        if (deviceModels != nil)
        {
          [[MI_DeviceModelManager sharedManager] importDeviceModels:deviceModels];
        }
        // create MI_SubcircuitElement object
        element = [[MI_SubcircuitElement alloc] initWithDefinition:newModel];
        // add them to the list
        tableItem = [[MI_SubcircuitWithFile alloc] initWithSubcircuit:element
                                                             filepath:filePath];
        [result addObject:tableItem];
      }
    } // else
  }
  return result;
}
