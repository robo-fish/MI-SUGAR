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


@implementation MI_SubcircuitCreator

- (instancetype) init
{
    if (theCreator == nil)
    {
        // load nib file
        theCreator = [super init];
        [NSBundle loadNibNamed:@"SubcircuitCreationSheet.nib"
                         owner:self];
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
        [[MI_SubcircuitCreator alloc] init];
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
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@""
                                                  action:@selector(setNodeNameForPin:)
                                           keyEquivalent:@""];
    [item setTarget:self];
    [chooserMenu addItem:item];
    while (element = [elementEnum nextObject])
    {
        if ([element conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)] &&
            [[element label] length] > 0)
        {
            item = [[NSMenuItem alloc] initWithTitle:[element label]
                                              action:@selector(setNodeNameForPin:)
                                       keyEquivalent:@""];
            [item setTarget:self];
            [chooserMenu addItem:item];
        }
    }
    [nodeNameChooser setMenu:chooserMenu];
    [pinAssignmentTable reloadData];
    [NSApp beginSheet:creatorSheet
       modalForWindow:[[[doc windowControllers] objectAtIndex:0] window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
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
                [[MI_DIPShape alloc] initWithNumberOfPins:numberOfConnectionPoints];
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


- (void) setNumberOfConnectionPoints:(int)number
{
    numberOfConnectionPoints = number;
    [self resetPinMapping];
    [pinAssignmentTable reloadData];
}


- (IBAction) loadShapeDefinitionFile:(id)sender
{
    NSOpenPanel* op = [NSOpenPanel openPanel];
    [op setCanChooseDirectories:NO];
    [op setCanChooseFiles:YES];
    [op setAllowsMultipleSelection:NO];
    [op setTitle:@"Choose a shape definition file."];
    [op setExtensionHidden:NO];
    [op setCanSelectHiddenExtension:NO];
    [op setAllowedFileTypes:[NSArray arrayWithObjects:@"xml", @"sesdl", nil]];
    [op beginSheetForDirectory:nil
                          file:nil
                         types:[NSArray arrayWithObjects:@"xml", @"sesdl", nil]
                modalForWindow:creatorSheet
                 modalDelegate:self
                didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                   contextInfo:nil];
}


/* Called when the user finishes selecting a file in NSOpenPanel */
- (void)openPanelDidEnd:(NSOpenPanel*)sheet
             returnCode:(int)returnCode
            contextInfo:(void*)contextInfo
{
    if (returnCode == NSOKButton)
    {
        MI_Shape* s = [MI_SESDLParser parseSESDL:[sheet filename]];
        [shapePreviewer setShape:s];
        [shapePreviewer setNeedsDisplay:YES];
        [self setNumberOfConnectionPoints:[[s connectionPoints] count]];
        [customShapeConnectionPointNames setArray:[[[s connectionPoints] allKeys] copy]];
        [self resetPinMapping];
    }
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
        for (i = 1; i <= numberOfConnectionPoints; i++)
        {
            [pinMapping setObject:@""
                           forKey:[NSString stringWithFormat:@"Pin%d", i]];
        }
    }
    [pinAssignmentTable reloadData];
}


- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return numberOfConnectionPoints;
}


- (id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
             row:(int)rowIndex
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
              row:(int)rowIndex
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
        [shapePreviewer setShape: [[MI_DIPShape alloc] initWithNumberOfPins:numberOfConnectionPoints]];
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
