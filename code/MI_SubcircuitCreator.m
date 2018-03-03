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
#import "MI_SubcircuitCreator.h"
#import "SugarManager.h"
#import "MI_SchematicElement.h"
#import "Converter.h"
#import "MI_DIPShape.h"
#import "MI_SESDLParser.h"

static MI_SubcircuitCreator* theCreator = nil;

@interface MI_SubcircuitCreator () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation MI_SubcircuitCreator
{
  IBOutlet NSTableView* pinAssignmentTable;       // displays the pin to node assignment matrix
  IBOutlet NSTableColumn* nodeNameColumn;         // will be populated with popup button cells
  IBOutlet NSTextField* subcircuitNameField;      // for entering the name of the subcircuit
  IBOutlet NSTextField* subcircuitNamespaceField; // for entering the namespace of the subcircuit
  IBOutlet NSTextField* revisionField;            // for entering the revision of the subcircuit
  IBOutlet NSWindow* creatorSheet;                // the panel which contains the widgets
  IBOutlet NSPopUpButton* pinChooser;             // presents choice of number of pins
  IBOutlet NSButton* createButton;                // user presses this button to finalize creation
  IBOutlet MI_ShapePreviewer* shapePreviewer;
  IBOutlet NSButton* dipShapeSelectionButton;
  IBOutlet NSButton* customShapeSelectionButton;
  IBOutlet NSButton* customShapeFileBrowseButton;
  BOOL usesCustomShape;
  NSPopUpButtonCell* nodeNameChooser;             // cell object in the node name column
  NSInteger _numberOfConnectionPoints;            // the number of pins of the selected shape
  CircuitDocument* currentDoc;
  NSMutableDictionary* pinMapping;                // maps external port names to internal node names
  NSMutableArray* customShapeConnectionPointNames;
}

- (instancetype) init
{
  if (theCreator == nil)
  {
    theCreator = [super init];
    [[NSBundle mainBundle] loadNibNamed:@"SubcircuitCreationSheet" owner:self topLevelObjects:nil];
    [pinAssignmentTable setDataSource:self];
    [pinAssignmentTable setDelegate:self];
    nodeNameChooser = [[NSPopUpButtonCell alloc] init];
    [nodeNameChooser setBordered:NO];
    [nodeNameChooser setTarget:self];
    [nodeNameChooser setAction:@selector(setNodeNameForPin:)];
    [nodeNameColumn setDataCell:nodeNameChooser];
    [creatorSheet setDefaultButtonCell:[createButton cell]];
    pinMapping = [[NSMutableDictionary alloc] initWithCapacity:6];
    customShapeConnectionPointNames = [[NSMutableArray alloc] initWithCapacity:4];
    currentDoc = nil;
    usesCustomShape = NO;
  }
  return theCreator;
}


+ (MI_SubcircuitCreator*) sharedCreator
{
  if (theCreator == nil)
  {
    theCreator = [[MI_SubcircuitCreator alloc] init];
  }
  return theCreator;
}


- (void) createSubcircuitForCircuitDocument:(CircuitDocument*)doc
{
  currentDoc = doc;
  [pinChooser selectItemWithTitle:@"6"]; // default number of pins
  [self setNumberOfConnectionPoints:6];
  [self selectShapeType:dipShapeSelectionButton];
  [shapePreviewer setShape:[[MI_DIPShape alloc] initWithNumberOfPins:6]];
  [self resetPinMapping];
  // add names from the schematic to the node name chooser button
  NSEnumerator* elementEnum = [[[doc model] schematic] elementEnumerator];
  MI_SchematicElement* element;
  NSMenu* chooserMenu = [[NSMenu alloc] initWithTitle:@""];
  NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"" action:@selector(setNodeNameForPin:) keyEquivalent:@""];
  [item setTarget:self];
  [chooserMenu addItem:item];
  while (element = [elementEnum nextObject])
  {
    if ([element conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)] &&
        [[element label] length] > 0)
    {
      item = [[NSMenuItem alloc] initWithTitle:[element label] action:@selector(setNodeNameForPin:) keyEquivalent:@""];
      [item setTarget:self];
      [chooserMenu addItem:item];
    }
  }
  [nodeNameChooser setMenu:chooserMenu];
  [pinAssignmentTable reloadData];
  NSWindow* window = [[[doc windowControllers] objectAtIndex:0] window];
  [window beginSheet:creatorSheet completionHandler:^(NSModalResponse returnCode) {
    /* do nothing */
  }];
}


- (IBAction) finishUserInput:(id)sender
{
    if (sender == createButton)
    {
        // Check validity of values
        if ([[subcircuitNameField stringValue] length] == 0)
        {
            NSBeep();
            return;
        }
        // convert model
        MI_SubcircuitDocumentModel* subckt =
            [[MI_SubcircuitDocumentModel alloc]
                initWithCircuitDocumentModel:[currentDoc model]
                                      pinMap:pinMapping];
        [subckt setCircuitName:[subcircuitNameField stringValue]];
        [subckt setCircuitNamespace:[subcircuitNamespaceField stringValue]];
        [subckt setRevision:[revisionField stringValue]];
        // capture the schematic
        [subckt setSource: [NSString stringWithFormat:@"* %@\n%@",
            [[NSDate date] description],
            [Converter schematicToNetlist:subckt]]];
        // Create the default shape
        if (usesCustomShape)
        {
            [subckt setShape:[[shapePreviewer shape] copy]];
        }
        else
        {
            MI_DIPShape* defaultShape =
                [[MI_DIPShape alloc] initWithNumberOfPins:_numberOfConnectionPoints];
            [defaultShape setName:[subckt circuitName]];
            [subckt setShape:defaultShape];
        }
        // save to library directory
        [[[SugarManager sharedManager] subcircuitLibraryManager]
            addSubcircuitToLibrary:subckt
                              show:YES];
    }
    [NSApp endSheet:creatorSheet];
    [creatorSheet orderOut:self];
    currentDoc = nil;
}


- (IBAction) setNumberOfDIPPins:(id)sender
{
    if (usesCustomShape)
        return;
    int numberOfPins = [[[pinChooser selectedItem] title] intValue];
    [self setNumberOfConnectionPoints:numberOfPins];
    [shapePreviewer setShape:[[MI_DIPShape alloc] initWithNumberOfPins:numberOfPins]];
    [shapePreviewer setNeedsDisplay:YES];
}


- (void) setNumberOfConnectionPoints:(NSInteger)number
{
    _numberOfConnectionPoints = number;
    [self resetPinMapping];
    [pinAssignmentTable reloadData];
}


- (IBAction) loadShapeDefinitionFile:(id)sender
{
  NSOpenPanel* op = [NSOpenPanel openPanel];
  op.canChooseDirectories = NO;
  op.canChooseFiles = YES;
  op.allowsMultipleSelection = NO;
  op.title = @"Choose a shape definition file.";
  op.extensionHidden = NO;
  op.canSelectHiddenExtension = NO;
  op.allowedFileTypes = @[@"xml", @"sesdl"];
  [op beginSheetModalForWindow:creatorSheet completionHandler:^(NSModalResponse result) {
    if (result == NSModalResponseOK)
    {
      NSString* filePath = [[[op URLs] firstObject] path];
      if (filePath != nil)
      {
        MI_Shape* s = [MI_SESDLParser parseSESDL:filePath];
        [shapePreviewer setShape:s];
        [shapePreviewer setNeedsDisplay:YES];
        [self setNumberOfConnectionPoints:[[s connectionPoints] count]];
        [customShapeConnectionPointNames setArray:[[[s connectionPoints] allKeys] copy]];
        [self resetPinMapping];
      }
    }
  }];
}


/* Called when the user finishes selecting a file in NSOpenPanel */
- (void)openPanelDidEnd:(NSOpenPanel*)sheet
             returnCode:(int)returnCode
            contextInfo:(void*)contextInfo
{
}


- (void) resetPinMapping
{
    int i;
    // clear assignment map
    [pinMapping removeAllObjects];
    // Fill the pin map 
    if (usesCustomShape && [shapePreviewer shape] &&
        [customShapeConnectionPointNames count])
    {
        NSEnumerator* portEnum = [customShapeConnectionPointNames objectEnumerator];
        NSString* tmp;
        while (tmp = [portEnum nextObject])
        {
            [pinMapping setObject:@""
                           forKey:tmp];
        }
    }
    else
    {
        for (i = 1; i <= _numberOfConnectionPoints; i++)
        {
            [pinMapping setObject:@""
                           forKey:[NSString stringWithFormat:@"Pin%d", i]];
        }
    }
    [pinAssignmentTable reloadData];
}


- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return _numberOfConnectionPoints;
}


- (id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
             row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"pin"])
    {
        return [[[pinMapping allKeys]
            sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                objectAtIndex:rowIndex];
    }
    else
        return [aTableColumn dataCellForRow:rowIndex];
}


/* NSTableView delegate method implementation */
- (void)tableView:(NSTableView*)aTableView
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(NSInteger)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"node"])
    {
        [((NSPopUpButtonCell*)aCell) selectItemWithTitle:
            [pinMapping objectForKey:[[[pinMapping allKeys]
                sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                    objectAtIndex:rowIndex]
            ]
        ];
    }
}


- (IBAction) setNodeNameForPin:(id)sender
{
    [pinMapping setObject:[sender title]
                   forKey:[[[pinMapping allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                        objectAtIndex:[pinAssignmentTable selectedRow]]];
    //[pinAssignmentTable reloadData];
}


- (IBAction) selectShapeType:(id)sender
{
    [sender setState:NSOnState];
    if (sender == dipShapeSelectionButton)
    {
        [customShapeSelectionButton setState:NSOffState];
        [shapePreviewer setShape: [[MI_DIPShape alloc] initWithNumberOfPins:_numberOfConnectionPoints]];
        usesCustomShape = NO;
        [self setNumberOfConnectionPoints:[[[pinChooser selectedItem] title] intValue]];
        [customShapeFileBrowseButton setEnabled:NO];
        [pinChooser setEnabled:YES];
    }
    else
    {
        [dipShapeSelectionButton setState:NSOffState];
        [shapePreviewer setShape:nil];
        [self setNumberOfConnectionPoints:0];
        usesCustomShape = YES;
        [customShapeFileBrowseButton setEnabled:YES];
        [pinChooser setEnabled:NO];
    }
    [shapePreviewer setNeedsDisplay:YES];
}


@end
