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
#import "SugarPlotter.h"
#import "ResultsTable.h"
#import "NyquistPlotController.h"
#include <stdlib.h>
#import "MI_ColorCell.h"
#import "MI_ViewArea.h"
#import "SugarManager.h"

@interface SugarPlotter (Splitter) <NSSplitViewDelegate>
@end

@implementation SugarPlotter
{
  IBOutlet SugarGraphView* plotView;
  IBOutlet NSWindow* plotWindow;
  IBOutlet NSSplitView* sectionsDivider;
  IBOutlet NSPopUpButton* plotChooser;
  IBOutlet NSTextField* xPosition;
  IBOutlet NSTextField* yPosition;
  IBOutlet NSButton* logarithmicX; // in the 'Plot' tab
  IBOutlet NSButton* logarithmicY; // in the 'Plot' tab
  IBOutlet NSButton* logLabelsForLogScale; // in the 'Plot' tab
  IBOutlet NSButton* gridVisibilityButton;
  IBOutlet NSButton* labelVisibilityButton;
  IBOutlet NSTableView* variablesTable;
  IBOutlet NSTableColumn* variableVisibilityColumn;
  IBOutlet NSTableColumn* variableColorColumn;
  IBOutlet NSTextField* scaleField;
  IBOutlet NSTextField* scaleLabel;
  IBOutlet NSButton* scaleToFitButton;
  IBOutlet NSButton* scaleAroundAverageButton;
  IBOutlet NSButtonCell* realPartButton;
  IBOutlet NSButtonCell* imaginaryPartButton;
  IBOutlet NSButtonCell* magnitudeButton;
  IBOutlet NSButton* NyquistPlotButton;
  IBOutlet NSTextField* horizontalGuideValue1;
  IBOutlet NSTextField* horizontalGuideValue2;
  IBOutlet NSTextField* horizontalGuideDelta;
  IBOutlet NSTextField* verticalGuideValue1;
  IBOutlet NSTextField* verticalGuideValue2;
  IBOutlet NSTextField* verticalGuideDelta;
  IBOutlet NSTabView* customizationsCategorizer;
  IBOutlet NSButton* zoomInButton;
  IBOutlet NSButton* zoomOutButton;
  IBOutlet NSTextField* messageLabel;
  IBOutlet NSViewController<NSPrintPanelAccessorizing>* printOptionsViewController;

@private
  NSArray* dataTable;
  NSButtonCell* visibilityButton;
  MI_ColorCell* colorCell;
  NSWindowController* windowController;
  NSMutableArray* zoomHistory;
  NSTabViewItem* previousTab; // used in "auto show guides tab"
}

- (instancetype) initWithPlottingData:(NSArray*)plotData
{
  if (self = [super init])
  {
    int i;
    dataTable = plotData;
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    previousTab = nil;

    [[NSBundle mainBundle] loadNibNamed:@"PlotWindow" owner:self topLevelObjects:nil];

    // Build the entries of the analysis type chooser popup button
    [plotChooser removeAllItems];
    for (i = 0; i < (int)[dataTable count]; i++)
    {
      [plotChooser addItemWithTitle:[[dataTable objectAtIndex:i] name]];
    }

    [self _setAnalysis:0];

    [plotWindow setTitle:[@"Plot - " stringByAppendingString:[[dataTable objectAtIndex:0] title]]];

    [plotView setObserver:self];
    [plotWindow setFrameUsingName:MISUGAR_PLOTTER_WINDOW_FRAME];
    [plotWindow setDelegate:self];

    visibilityButton = [[NSButtonCell alloc] init];
    [visibilityButton setButtonType:NSSwitchButton];
    [visibilityButton setTarget:self];
    [visibilityButton setAction:@selector(toggleVisibility:)];
    [variableVisibilityColumn setDataCell:visibilityButton];
    [variablesTable setRowHeight:22.0f];
    colorCell = [[MI_ColorCell alloc] init];
    [colorCell setTarget:self];
    [colorCell setAction:@selector(changeGraphColor:)];
    [variableColorColumn setDataCell:colorCell];

    zoomHistory = [[NSMutableArray alloc] initWithCapacity:5];

    if ([[defs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS] boolValue])
    {
      [logLabelsForLogScale setState:
        ([[defs objectForKey:MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE] boolValue] ? NSOnState : NSOffState)];
      [gridVisibilityButton setState:
        ([[defs objectForKey:MISUGAR_PLOTTER_SHOWS_GRID] boolValue] ? NSOnState : NSOffState)];
      [labelVisibilityButton setState:
        ([[defs objectForKey:MISUGAR_PLOTTER_SHOWS_LABELS] boolValue] ? NSOnState : NSOffState)];
      [logarithmicX setState:
        ( ([plotView minimumAbscissaValue] > 0.0) &&
          ([plotView maximumAbscissaValue] > 0.0) &&
          [[defs objectForKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ABSCISSA] boolValue] ? NSOnState : NSOffState)];
      [logarithmicY setState:
        ( ([plotView minimumOrdinateValue] > 0.0) &&
          ([plotView maximumOrdinateValue] > 0.0) &&
          [[defs objectForKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ORDINATE] boolValue] ? NSOnState : NSOffState)];
    }
    else
    {
      [gridVisibilityButton setState:NSOnState];
      [labelVisibilityButton setState:NSOnState];
      [logarithmicX setState:NSOffState];
      [logarithmicY setState:NSOffState];
      [logLabelsForLogScale setState:NSOffState];
    }
    [plotView showGrid:([gridVisibilityButton state] == NSOnState)];
    [plotView showLabels:([labelVisibilityButton state] == NSOnState)];
    [plotView showLogarithmicAbscissa:([logarithmicX state] == NSOnState)];
    [plotView showLogarithmicOrdinate:([logarithmicY state] == NSOnState)];
    [plotView setShowLogLabelsForLogScale:([logLabelsForLogScale state] == NSOnState)];

    [sectionsDivider setHoldingPriority:NSLayoutPriorityDefaultLow forSubviewAtIndex:0];
    [sectionsDivider setHoldingPriority:NSLayoutPriorityRequired forSubviewAtIndex:1];

    [plotWindow makeKeyAndOrderFront:self];
  }
  return self;
}


- (IBAction) selectAnalysisType:(id)sender
{
  [self _setAnalysis:[plotChooser indexOfSelectedItem]];
}


- (void) _setAnalysis:(NSInteger)analysisIndex
{
    int j;
    NSUInteger const num = [plotView numberOfOrdinateVariables];
    NSArray* visibilitiesArray = nil;
    AnalysisVariable* firstVariable;
    ResultsTable* selected;
    
    if (num > 0)
    {
      NSNumber* visibilities[num];
      // Store the visibility info of the active plot
      for (j = 0; j < num; j++)
      {
        visibilities[j] = [NSNumber numberWithBool:![plotView isHidden:j]];
      }
      visibilitiesArray = [NSArray arrayWithObjects:visibilities count:num];
    }

    [plotView removeAll];
    // Fill the graph widget with data from the selected ResultsTable
    selected = [dataTable objectAtIndex:analysisIndex];
    // The first variable contains the abscissa values
    firstVariable = [selected variableAtIndex:0];
    [plotView setAbscissa:firstVariable
                     name:[firstVariable name]];

    for (j = 1; j < [selected numberOfVariables]; j++)
    {
        [plotView addOrdinate:[selected variableAtIndex:j]
                         name:[[selected variableAtIndex:j] name]
                        color:/*[NSColor colorWithDeviceRed:(j % 3) / 4.5f
                                                    green:((2 * j + 1) % 8) / 12.0f
                                                     blue:((j + 2) % 6) / 10.0f
                                                    alpha:1.0f]*/
            [NSColor colorWithDeviceHue:(double)random()/(double)RAND_MAX
                             saturation:1.0f
                             brightness:([[plotView backgroundColor] brightnessComponent] < 0.5f) ? 0.9f : 0.4f
                                  alpha:1.0f]];
    }

    if (num > 0)
    {
        for (j = 0; j < num; j++)
            if (![[visibilitiesArray objectAtIndex:j] boolValue])
                [plotView hideVariable:j];
    }

    [plotView setNeedsDisplay:YES];
    [variablesTable reloadData];
}


/************* Printing methods *****************/

- (IBAction) printDocument:(id)sender
{
    [self printShowingPrintPanel:YES];
}


- (IBAction) togglePrintPlotDescription:(id)sender
{
    if ([sender state] == NSOnState)
        [plotView setPlotDescription:
            [[plotWindow title] stringByAppendingFormat:@"\n%@",
                [[plotChooser selectedItem] title]]];
    else
        [plotView setPlotDescription:nil];
}


- (void)printShowingPrintPanel:(BOOL)flag
{
  NSPrintOperation* printOp;
  @try
  {
    NSPrintPanel* printPanel = [NSPrintPanel printPanel];
    [printPanel addAccessoryController:printOptionsViewController];
    printOp = [NSPrintOperation printOperationWithView:plotView];
    [printOp setPrintPanel:printPanel];
    [printOp runOperationModalForWindow:plotWindow delegate:nil didRunSelector:nil contextInfo:NULL];
  }
  @catch (NSException* localException)
  {
    NSLog(@"Exception occured: %@", [localException name]);
  }
}
/*
- (void) printOperationDidRun:(NSPrintOperation *)printOperation
                      success:(BOOL)success
                  contextInfo:(void*)info
{
    if (success)
        [plotView print:self];
}
*/


#pragma mark SugarGraphObserver


- (void) processMouseMove:(NSPoint)mousePoint
{
    NSPoint valuePair = [plotView viewToValue:mousePoint];
    [xPosition setStringValue:[NSString stringWithFormat:@"%8.6G", valuePair.x]];
    [yPosition setStringValue:[NSString stringWithFormat:@"%8.6G", valuePair.y]];
}


- (void) processHandleDrag:(enum handleID)selection
                  position:(double)handlePosition
{
  switch(selection)
  {
    case LEFT:
      [verticalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G", handlePosition]];
      [verticalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView rightHandlePosition] - [plotView leftHandlePosition]]];
      break;
    case RIGHT:
      [verticalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G", handlePosition]];
      [verticalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView rightHandlePosition] - [plotView leftHandlePosition]]];
      break;
    case TOP:
      [horizontalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G", handlePosition]];
      [horizontalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView topHandlePosition] - [plotView bottomHandlePosition]]];
      break;
    default:
      [horizontalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G", handlePosition]];
      [horizontalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView topHandlePosition] - [plotView bottomHandlePosition]]];
  }
}


- (void) processHandleGrabbed
{
  // If the controls button is enabled slide open the drawer and select the guides tab
  if ([[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB] boolValue])
  {
    previousTab = [customizationsCategorizer selectedTabViewItem];
    [customizationsCategorizer selectTabViewItemWithIdentifier:@"guides"];
  }
}


- (void) processHandlesReleased
{
  if ([[[NSUserDefaults standardUserDefaults] objectForKey:MISUGAR_PLOTTER_AUTO_SHOW_GUIDES_TAB] boolValue])
  {
    if (previousTab)
      [customizationsCategorizer selectTabViewItem:previousTab];
  }
}


- (void) handlePositionsShouldUpdate
{
  [verticalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView leftHandlePosition]]];
  [verticalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView rightHandlePosition]]];
  [verticalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView rightHandlePosition] - [plotView leftHandlePosition]]];
  [horizontalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView bottomHandlePosition]]];
  [horizontalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView topHandlePosition]]];
  [horizontalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G", [plotView topHandlePosition] - [plotView bottomHandlePosition]]];
}

#pragma mark -

/* NSDrawer delegate method */
- (void)drawerDidOpen:(NSNotification *)notification
{
  [verticalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView leftHandlePosition]]];
  [verticalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView rightHandlePosition]]];
  [verticalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView rightHandlePosition] - [plotView leftHandlePosition]]];
  [horizontalGuideValue1 setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView bottomHandlePosition]]];
  [horizontalGuideValue2 setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView topHandlePosition]]];
  [horizontalGuideDelta setStringValue:[NSString stringWithFormat:@"%8.6G",
    [plotView topHandlePosition] - [plotView bottomHandlePosition]]];
}


- (IBAction) showLogarithmicGraph:(id)sender
{
  BOOL nonpositiveValues = NO;
  MI_ViewArea* va = [plotView viewArea];
  NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
  if (sender == logarithmicX)
  {
    if ( ([va minX] > 0.0) && ([va maxX] > 0.0) )
    {
      if ([userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS])
          [userdefs setObject:[NSNumber numberWithBool:([logarithmicX state] == NSOnState)]
                      forKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ABSCISSA];
      [plotView showLogarithmicAbscissa:([logarithmicX state] == NSOnState)];
    }
    else
    {
      [plotView showLogarithmicAbscissa:NO];
      nonpositiveValues = YES;
    }
  }
  else if (sender == logarithmicY)
  {
    if ( ([va minY] > 0.0) && ([va maxY] > 0.0) )
    {
      if ([userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS])
      {
        [userdefs setObject:[NSNumber numberWithBool:([logarithmicY state] == NSOnState)]
                   forKey:MISUGAR_PLOTTER_HAS_LOGARITHMIC_ORDINATE];
      }
      [plotView showLogarithmicOrdinate:([logarithmicY state] == NSOnState)];
    }
    else
    {
      [plotView showLogarithmicOrdinate:NO];
      nonpositiveValues = YES;
    }
  }
  if (nonpositiveValues)
  {
    NSAlert* alert = [[NSAlert alloc] init];
    alert.messageText = @"logarithm of nonpositive value";
    alert.informativeText = @"Cannot switch to logarithmic view while nonpositive values are present. Zoom into an appropriate subregion and try again.";
    [alert beginSheetModalForWindow:plotWindow completionHandler:^(NSModalResponse returnCode) {
      // do nothing
    }];
    [sender setState:NSOffState];
  }
}


- (IBAction) toggleVisibility:(id)sender
{
  int const varIndex = (int)[variablesTable selectedRow];
  if ([plotView isHidden:varIndex])
    [plotView showVariable:varIndex];
  else
    [plotView hideVariable:varIndex];
}

#pragma mark Changing the color of a graph

- (IBAction) changeGraphColor:(id)sender
{
  // Show color chooser
  NSColorPanel* cp = [NSColorPanel sharedColorPanel];
  [NSColorPanel setPickerMode:NSColorPanelModeHSB];
  [cp setTarget:self];
  [cp setAction:@selector(acceptNewGraphColor:)];
  [cp makeFirstResponder:nil];
  [cp setDelegate:self];
  [cp setColor:[[variableColorColumn dataCellForRow:[variablesTable selectedRow]] color]];
  [cp makeKeyAndOrderFront:self];
}

- (IBAction) acceptNewGraphColor:(id)sender
{
  if ([variablesTable selectedRow] >= 0)
  {
    [plotView setColor:[[NSColorPanel sharedColorPanel] color] forOrdinate:(int)[variablesTable selectedRow]];
    [variablesTable reloadData];
  }
}

/****************************************************/

- (IBAction) toggleGrid:(id)sender
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    if ([userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS])
        [userdefs setObject:[NSNumber numberWithBool:([gridVisibilityButton state] == NSOnState)]
                     forKey:MISUGAR_PLOTTER_SHOWS_GRID];
    [plotView showGrid:([sender state] == NSOnState)];
}


- (IBAction) toggleLabels:(id)sender
{
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    if ([userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS])
        [userdefs setObject:[NSNumber numberWithBool:([labelVisibilityButton state] == NSOnState)]
                     forKey:MISUGAR_PLOTTER_SHOWS_LABELS];
    [plotView showLabels:([sender state] == NSOnState)];
}


- (IBAction) zoomIn:(id)sender
{
  double lHP = [plotView leftHandlePosition];
  double rHP = [plotView rightHandlePosition];
  double bHP = [plotView bottomHandlePosition];
  double tHP = [plotView topHandlePosition];
  MI_ViewArea* newViewArea;

  if (![zoomHistory count])
  {
    //double d;
    newViewArea = [plotView viewArea];
    //d = [newViewArea maxY]; encDouble(&d); [newViewArea setMaxY:d];
    //d = [newViewArea minY]; encDouble(&d); [newViewArea setMinY:d];
    [zoomHistory addObject:[[MI_ViewArea alloc]
        initWithMinX:[newViewArea minX]
                maxX:[newViewArea maxX]
                minY:[newViewArea minY]
                maxY:[newViewArea maxY]]];
  }

  if ( (lHP == rHP) || (bHP == tHP) )
      return; // Empty subregion not allowed
  if (lHP > rHP)
  {
    double swapX = lHP;
    lHP = rHP;
    rHP = swapX;
  }
  if (bHP > tHP)
  {
    double swapY = lHP;
    lHP = rHP;
    rHP = swapY;
  }
  // Zoom only if a subregion is selected
  if ( (lHP > [[plotView viewArea] minX]) || (rHP < [[plotView viewArea] maxX]) ||
       (bHP > [[plotView viewArea] minY]) || (tHP < [[plotView viewArea] maxY]) )
  {
    //encDouble(&bHP);
    //encDouble(&tHP);
    newViewArea = [[MI_ViewArea alloc] initWithMinX:lHP maxX:rHP minY:bHP maxY:tHP];
    [plotView setViewArea:newViewArea];
    [zoomHistory addObject:newViewArea];
  }
}


- (IBAction) zoomOut:(id)sender
{
  if ([zoomHistory count] > 1)
  {
    // Pop last view area from the history and set it in the plot view
    [plotView setViewArea:[zoomHistory objectAtIndex:([zoomHistory count] - 2)]];
    [zoomHistory removeLastObject];
  }
  else
  {
    double x1 = [[plotView viewArea] minX];
    double x2 = [[plotView viewArea] maxX];
    double y1 = [[plotView viewArea] minY];
    double y2 = [[plotView viewArea] maxY];
    MI_ViewArea* newViewArea =
        [[MI_ViewArea alloc] initWithMinX:(x1 - ((x2 - x1) / 3))
                                     maxX:(x2 + ((x2 - x1) / 3))
                                     minY:(y1 - ((y2 - y1) / 3))
                                     maxY:(y2 + ((y2 - y1) / 3))];
    [zoomHistory removeAllObjects];
    [zoomHistory addObject:newViewArea];
    [plotView setViewArea:newViewArea];
  }
}


- (IBAction) showNyquistPlot:(id)sender
{
  AnalysisVariable* var = [[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]] variableAtIndex:(int)([variablesTable selectedRow] + 1)];
  NyquistPlotController* plotController = [[NyquistPlotController alloc] initWithAnalysisVariable:var];
  [plotController show];
}


/* Called when the user clicks on the "scaling around average" button
  in the plot customization view. */
- (IBAction) toggleScaleAroundAverage:(id)sender
{
  AnalysisVariable* anvar = [[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]]
      variableAtIndex:(int)([variablesTable selectedRow] + 1)];
  BOOL const newState = ([sender state] == NSOnState);
  if (newState)
      [anvar calculateAverageValue];
  [anvar setScalingAroundAverage:newState];
}


- (IBAction) toggleLogLabelsForLogScale:(id)sender
{
  NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
  if ([userdefs objectForKey:MISUGAR_PLOTTER_REMEMBERS_SETTINGS])
      [userdefs setObject:[NSNumber numberWithBool:([logLabelsForLogScale state] == NSOnState)]
         forKey:MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE];
  [plotView setShowLogLabelsForLogScale:([logLabelsForLogScale state] == NSOnState)];
}


/* Called when the user clicks on the "Scale to Fit" button. */
- (IBAction) scaleToFit:(id)sender
{
  double average, maxVar, minVar, maxView, minView, fittingScale;
  AnalysisVariable* var = [[dataTable objectAtIndex:
      [plotChooser indexOfSelectedItem]] variableAtIndex:
          (int)([variablesTable selectedRow] + 1)];
  MI_ViewArea* plotArea = [plotView viewArea];
  // Find and set the scale factor that makes the graph fit into the view
  [var findMinMax];
  [var calculateAverageValue];
  maxVar = [var maximum];
  minVar = [var minimum];
  maxView = [plotArea maxY];
  minView = [plotArea minY];
  average = [var isScalingAroundAverage] ? [var averageValue] : 0.0;

  fittingScale = 1.0;
  if ((minVar == maxVar) && (minVar == average))
  {
    // flat line - needs special care
    if (average == 0.0)
      return; // nothing to do
    if ((maxView / average) < 0.0)
      fittingScale = minView / average;
    else
      fittingScale = maxView / average;
  }
  else
  {
    if ( ((minView - average) / (minVar - average)) < 0.0 ) // opposite signs
      fittingScale = (maxView - average) / (maxVar - average);
    else if ( ((maxView - average) / (maxVar - average)) < 0.0 ) // opposite signs
      fittingScale = (minView - average) / (minVar - average);
    else if ((minView == average) && (maxView != average))
      fittingScale = (maxView - average) / (maxVar - average);
    else if ((maxView == average) && (minView != average))
      fittingScale = (minView - average) / (minVar - average);
    else
      fittingScale = fmin( (maxView - average) / (maxVar - average),
                           (minView - average) / (minVar - average) );
  }
  [var setScaleFactor:fittingScale];
  [scaleField setStringValue:[NSString stringWithFormat:@"%7.5G", fittingScale]];
  [plotView setNeedsDisplay:YES];
}


- (IBAction) setComplexNumberRepresentation:(id)sender
{
  AnalysisVariable* var = [[dataTable objectAtIndex:
    [plotChooser indexOfSelectedItem]] variableAtIndex:
    (int)([variablesTable selectedRow] + 1)];
  if ([sender selectedCell] == realPartButton)
    [var setFloatRepresentation:REAL];
  else if ([sender selectedCell] == imaginaryPartButton)
    [var setFloatRepresentation:IMAGINARY];
  else if ([sender selectedCell] == magnitudeButton)
    [var setFloatRepresentation:MAGNITUDE];
  [plotView setNeedsDisplay:YES];
}


/* NSTableDataSource protocol implementation */
- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
  return [[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]] numberOfVariables] - 1;
}


/* NSTableDataSource protocol implementation */
- (id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
             row:(int)rowIndex
{
  if ([[aTableColumn identifier] isEqualToString:@"state"])
    return [aTableColumn dataCell];
  else if ([[aTableColumn identifier] isEqualToString:@"color"])
    return [aTableColumn dataCell];
  else /*if ([[aTableColumn identifier] isEqualToString:@"variable"])*/
  {
    NSString* name = [[[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]] variableAtIndex:(rowIndex + 1)] name];
    return [[NSAttributedString alloc] initWithString:name attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:14.0]}];
  }
}


/* Example code for how to edit a cell
- (void)tableView:(NSTableView *)aTableView
   setObjectValue:anObject
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"scale"] &&
        [anObject respondsToSelector:@selector(doubleValue)])
    {
        [[[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]] variableAtIndex:(rowIndex + 1)] setScaleFactor:[anObject doubleValue]];
        [plotView setNeedsDisplay:YES];
    }
}
*/

#pragma mark NSTableViewDelegate

- (void)tableView:(NSTableView*)aTableView
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn*)aTableColumn
              row:(NSInteger)rowIndex
{
  if ([[aTableColumn identifier] isEqualToString:@"state"])
  {
    if ([plotView isHidden:rowIndex])
      [aCell setState:NSOffState];
    else
      [aCell setState:NSOnState];
  }
  if ([[aTableColumn identifier] isEqualToString:@"color"])
  {
    [aCell setColor:[[plotView colorOfOrdinateAtIndex:rowIndex] copy]];
  }
}


- (BOOL) tableView:(NSTableView *)aTableView
shouldEditTableColumn:(NSTableColumn*)aTableColumn
               row:(int)rowIndex
{
  return NO;
}


#pragma mark NSWindowDelegate


- (BOOL) windowShouldClose:(id)sender
{
  [plotWindow saveFrameUsingName:MISUGAR_PLOTTER_WINDOW_FRAME];
  return YES;
}


- (void) windowWillClose:(NSNotification *)aNotification
{
  id p = [aNotification object];
  if ([p isKindOfClass:[NSColorPanel class]] || [p isKindOfClass:[NSFontPanel class]])
  {
    [p setTarget:nil];
  }
//  else if ([p isKindOfClass:[NSWindow class]])
//    [self release];
}


#pragma mark -


/* Called when the user has manually set the scale factor of the selected variable */
- (void) controlTextDidEndEditing:(NSNotification*)aNotification
{
  double factor = [[scaleField stringValue] doubleValue];
  if (factor != 0.0)
  {
    [[[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]]
      variableAtIndex:(int)([variablesTable selectedRow] + 1)] setScaleFactor:factor];
    [plotView setNeedsDisplay:YES];
  }
}



/* Called after the selection in the variables table has changed. */
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
  if ([variablesTable selectedRow] == -1)
  {
    scaleToFitButton.enabled = NO;
    scaleField.stringValue = @"";
    scaleField.enabled = NO;
    scaleAroundAverageButton.enabled = NO;
    [scaleLabel setTextColor:[NSColor grayColor]];
    realPartButton.enabled = NO;
    imaginaryPartButton.enabled = NO;
    magnitudeButton.enabled = NO;
    NyquistPlotButton.enabled = NO;
  }
  else
  {
    scaleToFitButton.enabled = YES;
    scaleField.enabled = YES;
    scaleAroundAverageButton.enabled = YES;
    scaleLabel.textColor = [NSColor blackColor];
    AnalysisVariable* var = [[dataTable objectAtIndex:[plotChooser indexOfSelectedItem]] variableAtIndex:(int)([variablesTable selectedRow] + 1)];
    scaleField.stringValue = [NSString stringWithFormat:@"%7.5e", [var scaleFactor]];
    scaleAroundAverageButton.state = [var isScalingAroundAverage] ? NSOnState : NSOffState;
    if ([var isComplex])
    {
      realPartButton.enabled = YES;
      imaginaryPartButton.enabled = YES;
      magnitudeButton.enabled = YES;
      NyquistPlotButton.enabled = YES;
      if ([var floatRepresentation] == MAGNITUDE)
        [magnitudeButton setState:NSOnState];
      else if ([var floatRepresentation] == REAL)
        [realPartButton setState:NSOnState];
      else if ([var floatRepresentation] == IMAGINARY)
        [imaginaryPartButton setState:NSOnState];
    }
    else
    {
      realPartButton.enabled = NO;
      imaginaryPartButton.enabled = NO;
      magnitudeButton.enabled = NO;
      NyquistPlotButton.enabled = NO;
    }
  }
}


- (NSWindow*) window
{
  return plotWindow;
}


- (void) setWindowController:(NSWindowController*)controller
{
  windowController = controller;
}


- (BOOL) validateMenuItem:(NSMenuItem*) item
{
  return [[SugarManager sharedManager] validateMenuItem:item];
}


- (void) dealloc
{
  variablesTable.dataSource = nil;
  dataTable = nil;
}

@end


@interface SugarPlotterPrintOptionsViewController : NSViewController <NSPrintPanelAccessorizing>
@end

@implementation SugarPlotterPrintOptionsViewController
- (NSArray<NSDictionary<NSPrintPanelAccessorySummaryKey,NSString *> *> *)localizedSummaryItems
{
  return nil;
}
@end


@implementation SugarPlotter (Splitter)

- (BOOL) splitView:(NSSplitView*)splitView canCollapseSubview:(NSView*)subview
{
  return subview == [[splitView arrangedSubviews] objectAtIndex:1];
}

- (BOOL) splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
  return subview == [[splitView arrangedSubviews] objectAtIndex:1];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
  return [splitView frame].size.width - 280.0;
}

- (CGFloat) splitView:(NSSplitView*)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
  return [splitView frame].size.width - 180.0;
}

@end
