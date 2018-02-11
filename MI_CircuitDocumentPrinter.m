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
#import "MI_CircuitDocumentPrinter.h"

static MI_CircuitDocumentPrinter* circuitPrinter = nil;

// the print info collected from the user
static NSPrintInfo* currentInfo = nil;

// the view which is to be printed (NSTextView | MI_SchematicsCanvas)
static NSView* currentTargetView = nil;

// the circuit which is currently prepared for printing
static CircuitDocument* currentCircuit = nil;

// Used to store the dimensions and position of the schematic.
// The size is stored in screen-independent POINTS - not pixels.
// Is modified by user input (move, scale).
// The origin attribute of the NSRect is used to store the position
// of the center point of the box relative to the center of the paper
// (in pixels) and is not the position of the bottom left corner.
static NSRect schematicBoundingBox;

// Used to store the location of the pointer when a dragging action starts.
// This is then used for smooth dragging of the box that represents the schematic.
//static NSPoint dragStartPosition;

// Used for scaling the schematic bounding box
static float scaleFactor = 1.0f;


@implementation MI_CircuitDocumentPrinter

- (instancetype) init
{
    if (circuitPrinter == nil)
    {
        circuitPrinter = [super init];
        circuitPrintOptionsSheet = nil;
        [NSBundle loadNibNamed:@"CircuitPrintSheet.nib"
                         owner:self];
        [circuitPrintOptionsSheet setDefaultButtonCell:[commitButton cell]];
        [schematicSelectionButton setState:NSOnState];
        [netlistSelectionButton setState:NSOffState];
        [analysisResultSelectionButton setState:NSOffState];
    }
    return circuitPrinter;
}


+ (MI_CircuitDocumentPrinter*) sharedPrinter
{
    if (circuitPrinter == nil)
        [[MI_CircuitDocumentPrinter alloc] init];
    return circuitPrinter;
}


- (void) runPrintSheetForCircuit:(CircuitDocument*)circuit
{
    BOOL contentAvailable = NO;
    currentTargetView = nil;
    currentCircuit = circuit;
    scaleFactor = 1.0f;
    // Make a copy of the general print settings (set with "Page Setup...")
    currentInfo = [[NSPrintInfo sharedPrintInfo] copy];
    [currentInfo setOrientation:NSPortraitOrientation]; 
    
    // Checking the circuit content and setting availability options in order of precedence
    if ([[[circuit model] schematic] numberOfElements] > 0)
    {
        currentTargetView = [circuit canvas];
        [schematicSelectionButton setEnabled:YES];
        [schematicSelectionButton setState:NSOnState];
        contentAvailable = YES;

        schematicBoundingBox = [[[circuit model] schematic] boundingBox];
        // convert pixels to points and center the bounding box on the center
        // of the paper area
        NSSize screenSizeInPoints = [[[[NSScreen mainScreen] deviceDescription]
            objectForKey:NSDeviceSize] sizeValue];
        NSSize screenSizeInPixels = [[NSScreen mainScreen] frame].size;
//        NSLog(@"screen pixels: %5.1fx%5.1f\nscreen points:%5.1fx%5.1f", screenSizeInPixels.width,
//            screenSizeInPixels.height, screenSizeInPoints.width, screenSizeInPoints.height);
        float newBoxWidth = schematicBoundingBox.size.width *
            screenSizeInPoints.width / screenSizeInPixels.width;
        float newBoxHeight = schematicBoundingBox.size.height *
            screenSizeInPoints.height / screenSizeInPixels.height;
        schematicBoundingBox.size = NSMakeSize(newBoxWidth, newBoxHeight);
        schematicBoundingBox.origin = NSMakePoint(0,0);
        // Configure the scale adjustment slider
        [schematicScaler setMaxValue:fmin([currentInfo paperSize].width/newBoxWidth, [currentInfo paperSize].height/newBoxHeight)];
        [schematicScaler setMinValue:0.25f];
        [schematicScaler setFloatValue:1.0f];
    }
    else
    {
        [schematicSelectionButton setEnabled:NO];
        [schematicSelectionButton setState:NSOffState];

        schematicBoundingBox = NSMakeRect(0, 0, 0, 0);
    }
    if ([[[circuit netlistEditor] string] length] > 0)
    {
        [netlistSelectionButton setEnabled:YES];
        [netlistSelectionButton setState:!contentAvailable];
        contentAvailable = YES;
    }
    else
    {
        [netlistSelectionButton setEnabled:NO];
        [netlistSelectionButton setState:NSOffState];
    }
    if ([[[circuit analysisResultViewer] string] length] > 0)
    {
        [analysisResultSelectionButton setEnabled:YES];
        [analysisResultSelectionButton setState:!contentAvailable];
        contentAvailable = YES;
    }
    else
    {
        [analysisResultSelectionButton setEnabled:NO];
        [analysisResultSelectionButton setState:NSOffState];
    }
    
    [commitButton setEnabled:contentAvailable];
    
    [NSApp beginSheet:circuitPrintOptionsSheet
       modalForWindow:[[[circuit windowControllers] objectAtIndex:0] window]
        modalDelegate:nil
       didEndSelector:nil
          contextInfo:nil];
}


- (IBAction) commit:(id)sender
{
    [NSApp endSheet:circuitPrintOptionsSheet];
    [circuitPrintOptionsSheet orderOut:self];
    if (sender == commitButton)
    {
        if ([schematicSelectionButton state] == NSOnState)
        {
            [[currentCircuit canvas] setPrintScale:
                (scaleFactor * [[NSScreen mainScreen] frame].size.width /
                 [[[[NSScreen mainScreen] deviceDescription] objectForKey:NSDeviceSize] sizeValue].width)];
        }
        else if ([netlistSelectionButton state] == NSOnState)
        {
            [currentInfo setVerticallyCentered:NO];
        }
        else // if ([analysisResultSelectionButton state] == NSOnState)
        {
            [currentInfo setVerticallyCentered:NO];
        }
        
        NSPrintOperation *op =
            [NSPrintOperation printOperationWithView:currentTargetView
                                           printInfo:currentInfo];
        [op setShowPanels:YES];
        // Add accessory view to print panel, if needed
        
        [op runOperationModalForWindow:[[[currentCircuit windowControllers] objectAtIndex:0] window]
                              delegate:nil
                        didRunSelector:nil
                           contextInfo:NULL];
    }
    currentInfo = nil;
}


- (IBAction) selectViewForPrinting:(id)sender
{
    [sender setState:NSOnState];
    if (sender == schematicSelectionButton)
    {
        [netlistSelectionButton setState:NSOffState];
        [analysisResultSelectionButton setState:NSOffState];
        currentTargetView = [currentCircuit canvas];
    }
    else if (sender == netlistSelectionButton)
    {
        [analysisResultSelectionButton setState:NSOffState];
        [schematicSelectionButton setState:NSOffState];
        currentTargetView = [currentCircuit netlistEditor];
    }
    else // if (sender == analysisResultSelectionButton)
    {
        [netlistSelectionButton setState:NSOffState];
        [schematicSelectionButton setState:NSOffState];
        currentTargetView = [currentCircuit analysisResultViewer];
    }
}


- (IBAction) selectPortraitOrLandscape:(id)sender
{
    if ([[[sender selectedCell] title] isEqualToString:@"Landscape"])
        [currentInfo setOrientation:NSLandscapeOrientation];
    else
        [currentInfo setOrientation:NSPortraitOrientation];
    [previewer setNeedsDisplay:YES];
    [schematicScaler setMaxValue:fmin([currentInfo paperSize].width/schematicBoundingBox.size.width,
                                      [currentInfo paperSize].height/schematicBoundingBox.size.height)];
    [schematicScaler setFloatValue:fmin(scaleFactor, [schematicScaler maxValue])];
}


- (IBAction) setScaleOfSchematic:(id)sender
{
    scaleFactor = [schematicScaler floatValue];
    [previewer setNeedsDisplay:YES];
}

@end

/*************************************************************************/

@implementation MI_CircuitPrintPreview

- (void) drawRect:(NSRect)rect
{
    [[NSColor windowBackgroundColor] set];
    [NSBezierPath fillRect:rect];
    // Draw paper
    [[NSColor whiteColor] set];
    NSRect paperRect;
    float widthHeightRatio = [currentInfo paperSize].width / [currentInfo paperSize].height;
    if (currentInfo && ([currentInfo orientation] == NSLandscapeOrientation))
    {
        // Landscape
        paperRect.size.height = rect.size.width / widthHeightRatio;
        paperRect.size.width = rect.size.width;
        paperRect.origin.x = rect.origin.x;
        paperRect.origin.y = rect.origin.y + (rect.size.height - paperRect.size.height)/2;
    }
    else
    {
        // Portrait
        paperRect.size.height = rect.size.height;
        paperRect.size.width = rect.size.height * widthHeightRatio;
        paperRect.origin.x = rect.origin.x + (rect.size.width - paperRect.size.width)/2;
        paperRect.origin.y = rect.origin.y;
    }
    [NSBezierPath fillRect:NSInsetRect(paperRect, 1, 1)];
    // Draw frame and margin indicator
    [[NSColor grayColor] set];
    [NSBezierPath strokeRect:paperRect];
    float topMargin = [currentInfo topMargin] / [currentInfo paperSize].height * paperRect.size.height;
    float bottomMargin = [currentInfo bottomMargin] / [currentInfo paperSize].height * paperRect.size.height;
    float leftMargin = [currentInfo leftMargin] / [currentInfo paperSize].width * paperRect.size.width;
    float rightMargin = [currentInfo rightMargin] / [currentInfo paperSize].width * paperRect.size.width;
    NSBezierPath* marginPath = [NSBezierPath bezierPath];
    const float dashPattern[] = {3.0f, 3.0f};
    [marginPath setLineDash:dashPattern
                      count:1
                      phase:0.0f];
    [marginPath appendBezierPathWithRect:NSMakeRect(paperRect.origin.x + leftMargin,
        paperRect.origin.y + bottomMargin, paperRect.size.width - leftMargin - rightMargin,
        paperRect.size.height - bottomMargin - topMargin)];
    [marginPath stroke];
    // Draw schematic bounding box
    [[NSColor redColor] set];
    float pointToViewScaleX = scaleFactor * paperRect.size.width / [currentInfo paperSize].width;
    float pointToViewScaleY = scaleFactor * paperRect.size.height / [currentInfo paperSize].height;
    [NSBezierPath fillRect:
        NSMakeRect(rect.size.width/2 + schematicBoundingBox.origin.x - pointToViewScaleX * schematicBoundingBox.size.width/2,
                   rect.size.height/2 + schematicBoundingBox.origin.y - pointToViewScaleY * schematicBoundingBox.size.height/2,
                   pointToViewScaleX * schematicBoundingBox.size.width,
                   pointToViewScaleY * schematicBoundingBox.size.height)];
    /* Not needed anymore because schematic positioning is disabled
    // Draw box center point
    [[NSColor whiteColor] set];
    [[NSBezierPath bezierPathWithOvalInRect:
        NSMakeRect(rect.size.width/2 + schematicBoundingBox.origin.x - 2,
                   rect.size.height/2 + schematicBoundingBox.origin.y - 2, 4, 4)] fill];
    // Draw red center lines that help positioning
    [[NSColor colorWithDeviceRed:1.0f green:0.5f blue:0.5f alpha:1.0f] set];
    NSBezierPath* centerLines = [NSBezierPath bezierPath];
    [centerLines moveToPoint:NSMakePoint(paperRect.origin.x,
        paperRect.origin.y + paperRect.size.height/2)];
    [centerLines lineToPoint:NSMakePoint(paperRect.origin.x + paperRect.size.width,
        paperRect.origin.y + paperRect.size.height/2)];
    [centerLines moveToPoint:NSMakePoint(paperRect.origin.x + paperRect.size.width/2,
        paperRect.origin.y)];
    [centerLines lineToPoint:NSMakePoint(paperRect.origin.x + paperRect.size.width/2,
        paperRect.origin.y + paperRect.size.height)];
    [centerLines stroke];
    */
}

/* Schematic positioning is too complicated
- (void) mouseDown:(NSEvent*)event
{
    // convert event coordinates to local coordinates
    isDragging = YES;
    dragStartPosition = [self convertPoint:[event locationInWindow]
                                  fromView:nil];
}


- (void) mouseUp:(NSEvent*)event
{
    isDragging = NO;
}


- (void) mouseDragged:(NSEvent*)event
{
    if (isDragging)
    {
        // change the center point position
        NSPoint dragPosition = [self convertPoint:[event locationInWindow]
                                         fromView:nil];
        schematicBoundingBox.origin =
            NSMakePoint(dragPosition.x - dragStartPosition.x + schematicBoundingBox.origin.x,
                        dragPosition.y - dragStartPosition.y + schematicBoundingBox.origin.y);
        dragStartPosition = dragPosition;
        [self setNeedsDisplay:YES];
    }
}
*/

@end
