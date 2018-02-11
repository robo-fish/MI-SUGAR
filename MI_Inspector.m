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
#import "MI_Inspector.h"
#import "MI_SchematicElement.h"
#import "MI_CircuitElement.h"
#import "MI_SubcircuitElement.h"
#import "CircuitDocument.h"
#import "MI_CircuitElementDeviceModel.h"
#import "SugarManager.h"
#import "MI_DeviceModelManager.h"
#import "MI_TextElement.h"

@implementation MI_ClickThroughTextField
- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent { return YES; }
@end
@implementation MI_ClickThroughTableView
- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent { return YES; }
@end

// stores the index of the row of the circuit element inspection table
// whose parameter column equals "Model". -1 means that the inspected
// element has no parameter named "Model".
static NSInteger modelParameterRowIndex = -1;
// the popup button to be presented as the "Model" parameter's value
static NSPopUpButtonCell* deviceModelChooser = nil;
// the table column implementation whic enables the "Model"-awareness
@implementation MI_DeviceModelAwareInspectionTableColumn
- (id)dataCellForRow:(NSInteger)row
{
    if ( (modelParameterRowIndex >= 0) && (row == modelParameterRowIndex) )
        return deviceModelChooser;
    else
        return [super dataCellForRow:row];
}
@end


NSString* MISUGAR_INFO_PANEL_FRAME = @"InfoPanelFrame";

static MI_Inspector* sharedInspectorInstance = nil;

@interface MI_Inspector () <NSTableViewDataSource, NSTableViewDelegate>
@end

@implementation MI_Inspector

- (instancetype) init
{
    if (sharedInspectorInstance == nil)
    {
        sharedInspectorInstance = [super init];
        inspectedElement = nil;
        editedElement = nil;
        currentInspectionView = nil;
        deviceModelChooser = [[NSPopUpButtonCell alloc] initTextCell:@""
                                                           pullsDown:NO];
        [deviceModelChooser setBordered:NO];
        [deviceModelChooser setPreferredEdge:NSMinXEdge];
        
        // Prepare info panel
        float alpha = [[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_INFO_PANEL_ALPHA] floatValue];
        [[NSBundle mainBundle] loadNibNamed:@"SchematicElementInfoPanel" owner:self topLevelObjects:nil];

        [infoPanel setDelegate:self];
        //[infoPanel setBecomesKeyOnlyIfNeeded:YES]; - not good
        [infoPanel setFloatingPanel:YES];
        [infoPanel setAlphaValue:alpha];
        [infoPanelTransparencyAdjustment setFloatValue:alpha];
        //[infoPanel setMovableByWindowBackground:YES];
        [infoPanel setFrameUsingName:MISUGAR_INFO_PANEL_FRAME];
        
        // Configure the common views
        [labelField setEditable:NO];
        [labelField setAllowsEditingTextAttributes:NO];
        [commentArea setEditable:NO];
        [[commentArea enclosingScrollView] setAutohidesScrollers:YES];
        [labelPositionChooser setTarget:self];
        [labelPositionChooser setAction:@selector(setLabelPosition:)];
        [labelPositionChooser setToolTip:@"Set label position of element"];
                
        // Configure the inspection views...
        //
        // for MI_CircuitElement objects
        [circuitElementInspectionView setIntercellSpacing:NSMakeSize(0.0f, 0.0f)];
        [circuitElementInspectionView setDataSource:self];
        [circuitElementInspectionView setDelegate:self];
        [[circuitElementInspectionView enclosingScrollView] setAutohidesScrollers:YES];
        //
        // for MI_SubcircuitElement objects
        [subcircuitElementInspectionView setIntercellSpacing:NSMakeSize(0.0f, 0.0f)];
        [subcircuitElementInspectionView setDataSource:self];
        [subcircuitElementInspectionView setDelegate:self];
        //
        [subcircuitElementInspectionView setUsesAlternatingRowBackgroundColors:YES];
        [[subcircuitElementInspectionView enclosingScrollView] setAutohidesScrollers:YES];
        
        // Populate the tab view that's used to switch inspection views
        [inspectionViewContainer selectTabViewItemWithIdentifier:@"circuit"];
    }
    return sharedInspectorInstance;
}


+ (MI_Inspector*) sharedInspector
{
    if (sharedInspectorInstance == nil)
        sharedInspectorInstance = [[MI_Inspector alloc] init];
    return sharedInspectorInstance;
}


- (void) inspectElement:(NSObject <MI_Inspectable>*)inspectable
{
    if (!inspectable || ![inspectable isKindOfClass:[MI_SchematicElement class]])
    {
        [self reset];
        [inspectionViewContainer setHidden:YES];
        [labelField setEditable:NO];
        [commentArea setEditable:NO];
    }    
    else
    {
        [inspectionViewContainer setHidden:NO];
        inspectedElement = (MI_SchematicElement*) inspectable;
        [labelPositionChooser setDirection:[inspectedElement labelPosition]];
        [labelField setStringValue:[inspectedElement label]];
        [labelField setEditable:YES];
        [elementNameField setStringValue:[inspectedElement name]];
        [commentArea setEditable:YES];
        if ([[inspectedElement comment] length] > 0)
            [commentArea setStringValue:[inspectedElement comment]];
        else
            [commentArea setStringValue:@"[comments]"];


        // Note: The order in which the class type is checked is relevant.
        if ([inspectedElement isKindOfClass:[MI_SubcircuitElement class]])
        {
            MI_SubcircuitElement* subckt = (MI_SubcircuitElement*) inspectedElement;
            [inspectionViewContainer selectTabViewItemWithIdentifier:@"subcircuit"];
            [subcircuitElementInspectionView reloadData];
            [subcircuitNamespaceField setStringValue:[[subckt definition] circuitNamespace]];
            [revisionField setStringValue:[[subckt definition] revision]];
        }
        else if ([inspectedElement isKindOfClass:[MI_CircuitElement class]])
        {
            MI_CircuitElement* cElement = (MI_CircuitElement*) inspectedElement;
            [inspectionViewContainer selectTabViewItemWithIdentifier:@"circuit"];
            /* Finish editing before refreshing the table
            if ([circuitElementInspectionView editedRow] != -1)
                [[[circuitElementInspectionView tableColumnWithIdentifier:@"value"] dataCellForRow:
                    [circuitElementInspectionView editedRow]] endEditing:nil];
            */
            NSString* usedModel = [[cElement parameters] objectForKey:@"Model"];
            if (usedModel != nil)
            {
                [deviceModelChooser removeAllItems];
                if ([cElement usedDeviceModelType] != MI_DeviceModelTypeNone)
                {
                    NSArray* choices = [[MI_DeviceModelManager sharedManager]
                        modelsForType:[cElement usedDeviceModelType]];
                    if (choices)
                    {
                        NSEnumerator* modelEnum = [choices objectEnumerator];
                        MI_CircuitElementDeviceModel* currentModel;
                        NSMenu* chooserMenu = [[NSMenu alloc] initWithTitle:@""];
                        NSMenuItem* item;
                        while (currentModel = [modelEnum nextObject])
                        {
                            item = [[NSMenuItem alloc] initWithTitle:[currentModel modelName]
                                                              action:@selector(assignNewModel:)
                                                       keyEquivalent:@""];
                            [item setTarget:self];
                            [chooserMenu addItem:item];
                        }
                        [deviceModelChooser setMenu:chooserMenu];
                        [deviceModelChooser selectItemWithTitle:usedModel];
                    }
                }
                modelParameterRowIndex = [[[[cElement parameters] allKeys]
                    sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                        indexOfObject:@"Model"];
            }
            else
                modelParameterRowIndex = -1;
            
            [circuitElementInspectionView reloadData];
        }
        else if ([inspectedElement isKindOfClass:[MI_TextElement class]])
        {
            MI_TextElement* tElement = (MI_TextElement*) inspectedElement;
            [inspectionViewContainer selectTabViewItemWithIdentifier:@"text"];
            [textColorChooser setColor:[tElement color]];
            [textFontChooser setTitle:[NSString stringWithFormat:@"%@ - %g",
                [[tElement font] fontName], [[tElement font] pointSize]]];
            [textFrameSetter setState:([tElement drawsFrame] ? NSOnState : NSOffState)];
            [infoPanel makeFirstResponder:textFontChooser];
        }
    }
}


- (void) inspectElements:(NSArray*)elements
{
    if ([elements count] == 1)
        [self inspectElement:[elements objectAtIndex:0]];
    else
    {
        inspectedElement = editedElement = nil;
    }
}


- (void) reset
{
    inspectedElement = nil;
    [labelField setStringValue:@""];
    [elementNameField setStringValue:@""];
    
    [subcircuitElementInspectionView reloadData];
    [circuitElementInspectionView reloadData];
    [subcircuitNamespaceField setStringValue:@""];
    [revisionField setStringValue:@""];
    [commentArea setStringValue:@""];
}


- (void) showInfoPanel
{
    [infoPanel orderFront:self];
}
- (void) hideInfoPanel
{
    [infoPanel orderOut:self];
}
- (void) toggleInfoPanel
{
    if ([infoPanel isVisible])
        [self hideInfoPanel];
    else
        [self showInfoPanel];
}


/************************************* Data source and delegate methods *********/

/* Schematic element parameter table data source and delegate methods */
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    // Since subcircuits are subclasses of circuits the order is relevant.
    if (aTableView == subcircuitElementInspectionView &&
        [inspectedElement isKindOfClass:[MI_SubcircuitElement class]])
        return [[[(MI_SubcircuitElement*)inspectedElement definition] pinMap] count];
    else if (aTableView == circuitElementInspectionView &&
        [inspectedElement isKindOfClass:[MI_CircuitElement class]])
        return [[((MI_CircuitElement*)inspectedElement) parameters] count];
    else
        return 0;
}


- (id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
             row:(NSInteger)rowIndex
{
    // Since subcircuits are subclasses of circuits the order is relevant.
    if (aTableView == subcircuitElementInspectionView &&
        [inspectedElement isKindOfClass:[MI_SubcircuitElement class]])
    {
        MI_SubcircuitElement* se = (MI_SubcircuitElement*)inspectedElement;
        id portName = [[[[[se definition] pinMap] allKeys]
                sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
                    objectAtIndex:rowIndex];
        if ([[aTableColumn identifier] isEqualToString:@"pin"])
            return portName;
        else // if ([[aTableColumn identifier] isEqualToString:@"node"])
            return [[[se definition] pinMap] objectForKey:portName];
    }
    else if (aTableView == circuitElementInspectionView &&
        [inspectedElement isKindOfClass:[MI_CircuitElement class]])
    {
        NSDictionary* parameters = [(MI_CircuitElement*)inspectedElement parameters];
        if ([[aTableColumn identifier] isEqualToString:@"value"])
        {
            // Return parameter value
            NSString* key = [[[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:rowIndex];
            if (![key isEqualToString:@"Model"])
                return [parameters objectForKey:key];
            else
                return deviceModelChooser; // the returned object is actually irrelevant
        }
        else
            // Return parameter name
            return [[[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:rowIndex];
    }
    else
        return nil;
}


- (void) tableView:(NSTableView*)aTableView
    setObjectValue:(id)anObject
    forTableColumn:(NSTableColumn*)aTableColumn
               row:(NSInteger)rowIndex
{
    if ( (aTableView == circuitElementInspectionView)
        && [inspectedElement isKindOfClass:[MI_CircuitElement class]] )
    {
        if ([anObject isKindOfClass:[NSString class]])
        {
            NSMutableDictionary* parameters = [((MI_CircuitElement*)editedElement) parameters];
            NSString* key = [[[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:rowIndex];
            NSWindow* documentWindow = [[NSApplication sharedApplication] mainWindow];
            
            if (documentWindow &&
                [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
            {
                [(CircuitDocument*)[documentWindow delegate] createSchematicUndoPointForModificationType:MI_SCHEMATIC_EDIT_PROPERTY_CHANGE];
                
                [parameters setObject:anObject
                               forKey:key];
            
                [[[(CircuitDocument*)[documentWindow delegate] model] schematic] markAsModified:YES];
                [documentWindow setDocumentEdited:YES];
            }
        }
    }
}


- (BOOL)tableView:(NSTableView *)aTableView
shouldEditTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    if (aTableView == circuitElementInspectionView &&
        [inspectedElement isKindOfClass:[MI_CircuitElement class]])
    {
        if ( [[aTableColumn identifier] isEqualToString:@"value"] )
        {
            [[aTableColumn dataCellForRow:rowIndex] setContinuous:YES];
            editedElement = inspectedElement;
            return YES;
        }
    }
    return NO;
}


- (void) tableView:(NSTableView *)aTableView
   willDisplayCell:(id)aCell
    forTableColumn:(NSTableColumn *)aTableColumn
               row:(NSInteger)rowIndex
{
    if ( aTableView == circuitElementInspectionView )
    {
        if ( [[aTableColumn identifier] isEqualToString:@"parameter"] )
        {
            [aCell setDrawsBackground:YES];
            [aCell setBackgroundColor:[NSColor colorWithDeviceRed:(75.0f/255.0f)
                                                            green:(99.0f/255.0f)
                                                             blue:(84.0f/255.0f)
                                                            alpha:1.0f]];
            [aCell setTextColor:[NSColor whiteColor]];
        }
        
        else if ([aCell isKindOfClass:[NSPopUpButtonCell class]])
        {
            [(NSPopUpButtonCell*)aCell selectItemWithTitle:
                [[(MI_CircuitElement*)inspectedElement parameters] objectForKey:@"Model"]];
            [(NSPopUpButtonCell*)aCell synchronizeTitleAndSelectedItem];
        }
        
    }
    else if (aTableView == subcircuitElementInspectionView &&
        [[aTableColumn identifier] isEqualToString:@"pin"])
    {
        [aCell setTextColor:[NSColor colorWithDeviceRed:(75.0f/255.0f)
                                                  green:(99.0f/255.0f)
                                                   blue:(84.0f/255.0f)
                                                  alpha:1.0f]];
    }
}

/*
- (void) tableViewSelectionDidChange:(NSNotification*)aNotification
{
}
*/

// NSTableView delegate method
// Disallows selection of items in the subcircuit port assignment table.
- (BOOL)tableView:(NSTableView *)aTableView
  shouldSelectRow:(NSInteger)rowIndex
{
    if (aTableView == subcircuitElementInspectionView)
        return NO;
    else
        return YES;
}


// Sets the comment of the inspected element as the user types it
- (IBAction) setComment:(id)sender;
{
    if (inspectedElement)
        [inspectedElement setComment:[commentArea stringValue]];
}


// NSFontManager delegate method.
// Performs the actual font change action.
- (void) changeFont:(id)sender
{
    if (inspectedElement && [inspectedElement isKindOfClass:[MI_TextElement class]])
    {
        NSFont *newFont = nil;
        if ([sender isKindOfClass:[NSFontManager class]])
            newFont = [sender convertFont:[(MI_TextElement*)inspectedElement font]];
        if ([sender isKindOfClass:[NSFontPanel class]])
            newFont = [sender panelConvertFont:[(MI_TextElement*)inspectedElement font]];
        [(MI_TextElement*)inspectedElement setFont:newFont];
        [textFontChooser setTitle:[NSString stringWithFormat:@"%@ - %g",
            [newFont fontName], [newFont pointSize]]];
        // update schematic view
        NSWindow* documentWindow = [NSApp mainWindow];
        if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
            [[(CircuitDocument*)[documentWindow delegate] canvas] setNeedsDisplay:YES];
    }
}


- (BOOL) windowShouldClose:(id)sender
{
    if ([sender isKindOfClass:[NSFontPanel class]])
        [self changeFont:sender];
    else
        [self reset];
    return YES;
}

/******************************************************* Action methods ********/

- (IBAction) setLabelOfInspectedElement:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
        CircuitDocument* doc = (CircuitDocument*)[documentWindow delegate];
        [doc createSchematicUndoPointForModificationType:MI_SCHEMATIC_EDIT_PROPERTY_CHANGE];
        [inspectedElement setLabel:[sender stringValue]];
        [[doc canvas] setNeedsDisplay:YES];
        [[[doc model] schematic] markAsModified:YES];
        [documentWindow setDocumentEdited:YES];
    }
    if ([inspectedElement isKindOfClass:[MI_TextElement class]])
        // shift focus to a non-text control
        [infoPanel makeFirstResponder:textFontChooser];
}


- (IBAction) setInfoPanelTransparency:(id)sender
{
    float value = [sender floatValue];
    if (value > 1.0f)
        value = 1.0f;
    else if (value < 0.5f)
        value = 0.5f;
    [infoPanel setAlphaValue:value];
}


- (IBAction) assignNewModel:(id)sender
{
    [[(MI_CircuitElement*)inspectedElement parameters]
        setObject:[sender title]
           forKey:@"Model"];
}


- (IBAction) setTextColor:(id)sender
{
    if (inspectedElement && [inspectedElement isKindOfClass:[MI_TextElement class]])
    {
        [(MI_TextElement*)inspectedElement setColor:[textColorChooser color]];
        NSWindow* documentWindow = [NSApp mainWindow];
        if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
            [[(CircuitDocument*)[documentWindow delegate] canvas] setNeedsDisplay:YES];
    }
}


- (IBAction) setTextFont:(id)sender
{
  if (inspectedElement && [inspectedElement isKindOfClass:[MI_TextElement class]])
  {
    MI_TextElement* te = (MI_TextElement*) inspectedElement;
    NSFontManager* fm = [NSFontManager sharedFontManager];
    NSFontPanel* panel = [fm fontPanel:YES];
    [panel setDelegate:self];
    [panel makeFirstResponder:nil];
    [fm setSelectedFont:[te font] isMultiple:NO];
    [fm orderFrontFontPanel:self];
  }
}


- (IBAction) toggleTextFrame:(id)sender
{
    if (inspectedElement && [inspectedElement isKindOfClass:[MI_TextElement class]])
    {
        [(MI_TextElement*)inspectedElement setDrawsFrame:([textFrameSetter state] == NSOnState)];
        NSWindow* documentWindow = [[NSApplication sharedApplication] mainWindow];
        if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
            [[(CircuitDocument*)[documentWindow delegate] canvas] setNeedsDisplay:YES];
    }
}


- (IBAction) rotateSelectionCCW:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
        [[[(CircuitDocument*)[documentWindow delegate] model] schematic] rotateSelectedElements:90];
        [[(CircuitDocument*)[documentWindow delegate] canvas] setNeedsDisplay:YES];
    }
}


- (IBAction) flipHorizontally:(id)sender
{
    NSWindow* documentWindow = [NSApp mainWindow];
    if (documentWindow &&
        [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
    {
        [[[(CircuitDocument*)[documentWindow delegate] model] schematic] flipSelectedElements:YES];
        [[(CircuitDocument*)[documentWindow delegate] canvas] setNeedsDisplay:YES];
    }
}


- (IBAction) setLabelPosition:(MI_DirectionChooser*)chooser
{
  NSWindow* documentWindow = [NSApp mainWindow];
  if (documentWindow && [[documentWindow delegate] isKindOfClass:[CircuitDocument class]])
  {
    CircuitDocument* document = (CircuitDocument*)[documentWindow delegate];
    NSEnumerator* elementEnum = [[[document model] schematic] selectedElementEnumerator];
    MI_SchematicElement* tmpElement;
    MI_Direction const newDirection = (chooser != nil) ? [chooser selectedDirection] : [labelPositionChooser selectedDirection];
    while (tmpElement = [elementEnum nextObject])
    {
      [tmpElement setLabelPosition:newDirection];
    }
    [[document canvas] setNeedsDisplay:YES];
  }
}

/**************************************************************************/


- (void) dealloc
{
  if (infoPanel != nil)
  {
    [infoPanel saveFrameUsingName:MISUGAR_INFO_PANEL_FRAME];
    [[NSUserDefaults standardUserDefaults]
        setObject:[NSNumber numberWithFloat:[infoPanel alphaValue]]
           forKey:MISUGAR_INFO_PANEL_ALPHA];
    // The next line is needed since the inspector is destroyed before the
    // Info panel. Otherwise delegate events would be sent to invalid objects.
    [infoPanel setDelegate:nil];
  }
}

@end
