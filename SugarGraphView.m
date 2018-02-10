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
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#import "SugarGraphView.h"
#include "common.h"
#include "math.h"

#define MI_SUGAR_DEFAULT_MARGIN 20
#define ZOOM_HANDLE_SIZE 15
#define ZOOM_BAR_SIZE 10
#define PLOT_DESCRIPTION_AREA_HEIGHT 45

/* The ordering of elements in these static arrays is directly related
   to the menu items of the popup buttons in the preference panels. */

int PlotterGridLineWidth[] = { 1, 2, 3 };

int PlotterGraphsLineWidth[] = { 1, 2, 3 };

int PlotterLabelsFontSize[] = { 10, 12, 14, 18 };


@implementation SugarGraphView
{
@private
  NSArray* abscissaValues; // x-axis
  NSUInteger numberOfAbscissaPoints;
  NSString* abscissaLabel;
  NSColor* backgroundColor;
  NSColor* gridColor;

  /* growing array of AnalysisVariable objects */
  NSMutableArray* ordinateVariables; // y-axis variables
  /* growing array of integers which are the lengths of the arrays of ordinate values */
  NSMutableArray* ordinateLengths;
  /* growing array of labels for the ordinate variables */
  NSMutableArray* ordinateLabels;
  /* array of boolean flags that determine whether the corresponding ordinate value is drawn or not */
  NSMutableArray* ordinateVisibilities;
  /* array of NSColors for the graphs */
  NSMutableArray<NSColor*>* ordinateColors;
  /* Growing array with the maximum values of each ordinate variable.
   Used as a drawing hint. */
  NSMutableArray* ordinateMaximumValues;
  /* Growing array with the minimum values of each ordinate variable.
   Used as a drawing hint. */
  NSMutableArray* ordinateMinimumValues;

  BOOL grid;            // indicates if the grid will be drawn or not
  BOOL labels;          // indicates if labels will be drawn or not
  BOOL showPointerPosition;
  BOOL logarithmicAbscissa;    // used to switch the abscissa to logarithmic scale
  BOOL logarithmicOrdinate;    // used to switch the ordinate to logarithmic scale
  double gridWidth, gridHeight;  // the current grid metrics
  double gridMinX, gridMaxX;    // positive and negative grid extensions along the abscissa
  double gridMinY, gridMaxY;    // positive and negative grid extensions along the ordinate
  BOOL didCalculateGridMetrics;  // indicates whether the grid metrics have been calculated already

  id <SugarGraphObserver> observer;
  NSSize currentSize;
  double totalOrdinateMinValue, totalOrdinateMaxValue;  /* maximum/minimum values of all the ordiante variables */
  double abscissaMinValue, abscissaMaxValue;        /* abscissa minimum/maximum values */
  int leftMargin;    /* margin between the drawings and the left edge of the view. */
  int rightMargin;  /* margin between the drawings and the right edge of the view. */
  int topMargin;    /* margin between the drawings and the top edge of the view. */
  int bottomMargin;  /* margin between the drawings and the bottom edge of the view. */
  NSDictionary* labelFontAttributes; // attributes of the font used to draw the labels
  int gridLineWidth;
  int graphsLineWidth;

  double handleLeftPos, // position of the first vertical guide
  handleRightPos, // position of the second vertical guide
  handleTopPos, // position of the first horizontal guide
  handleBottomPos; // position of the second horizontal guide
  BOOL handlesAreActive;
  BOOL firstDrawing;
  enum handleID selectedHandle;
  MI_ViewArea* viewArea; // the view area rectangle in value space

  BOOL logLabelsForLogScale; // Indicates that the axis labels should be in logarithmic scale, too, whenever the axes are in logarithmic scale
  NSString* plotDescription; // is nil a plot description should not be printed

#ifdef GRAPHVIEW_WITH_TOOLTIP
  NSToolTipTag tooltip;
#endif
}

- (id)initWithFrame:(NSRect)frame
{
  if (self = [super initWithFrame:frame])
  {
    grid = YES;
    numberOfAbscissaPoints = 0;
    topMargin = bottomMargin = rightMargin = leftMargin = MI_SUGAR_DEFAULT_MARGIN; /* default margin */
    totalOrdinateMinValue = 0.0;
    totalOrdinateMaxValue = 100.0;
    abscissaMinValue = 0.0;
    abscissaMaxValue = 100.0;
    abscissaLabel = nil;
    abscissaValues = nil;
    observer = nil;
    viewArea = nil;
    ordinateVariables = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateLengths = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateLabels = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateColors = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateVisibilities = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateMaximumValues = [[NSMutableArray arrayWithCapacity:3] retain];
    ordinateMinimumValues = [[NSMutableArray arrayWithCapacity:3] retain];
    currentSize = [self bounds].size;
    gridColor = [[NSColor  colorWithDeviceWhite:0.5f
                                          alpha:1.0f] retain];
    backgroundColor = nil;
    gridLineWidth = 1;
    graphsLineWidth = 1;
    gridHeight = gridWidth = gridMinX = gridMaxX = gridMinY = gridMaxY = 0.0;
    //didCalculateGridMetrics = NO;
    logarithmicAbscissa = NO;
    logarithmicOrdinate = NO;
    labels = YES;
    logLabelsForLogScale = [[[NSUserDefaults standardUserDefaults]
        objectForKey:MISUGAR_PLOTTER_HAS_LOG_LABELS_FOR_LOG_SCALE] boolValue];
    /*
    labelFontAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        [NSFont fontWithName:@"Helvetica-Regular" size:10], NSFontAttributeName,
        [NSColor colorWithDeviceWhite:0.5f alpha:1.0f], NSForegroundColorAttributeName,
        NULL] retain];
     */
    handlesAreActive = NO;
    plotDescription = nil;

#ifdef GRAPHVIEW_WITH_TOOLTIP
    showPointerPosition = YES;
#endif
  }
  return self;
}


- (void) awakeFromNib
{
    NSNotificationCenter* notifCenter = [NSNotificationCenter defaultCenter];
    [self setPostsBoundsChangedNotifications:YES];
    [notifCenter addObserver:self
                    selector:@selector(resizeGraph:)
                        name:@"NSViewBoundsDidChangeNotification"
                      object:self];
    [self setPostsFrameChangedNotifications:YES];
    [notifCenter addObserver:self
                    selector:@selector(resizeGraph:)
                        name:@"NSViewFrameDidChangeNotification"
                      object:self];
    [self resizeGraph:nil];
    [notifCenter addObserver:self
                    selector:@selector(changeSettings:)
                        name:MISUGAR_PLOTTER_LABEL_FONT_CHANGE_NOTIFICATION
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(changeSettings:)
                        name:MISUGAR_PLOTTER_GRAPHS_LINE_WIDTH_CHANGE_NOTIFICATION
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(changeSettings:)
                        name:MISUGAR_PLOTTER_GRID_LINE_WIDTH_CHANGE_NOTIFICATION
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(changeSettings:)
                        name:MISUGAR_PLOTTER_GRID_COLOR_CHANGE_NOTIFICATION
                      object:nil];
    [notifCenter addObserver:self
                    selector:@selector(changeSettings:)
                        name:MISUGAR_PLOTTER_BACKGROUND_CHANGE_NOTIFICATION
                      object:nil];
    // Set plotter user preferences
    [self setPreferences];
}


- (int) xValueToView:(double)xValue
{
    double multiplier;
    double xMin = [viewArea minX];
    double xMax = [viewArea maxX];

    if (logarithmicAbscissa)
        multiplier = (log10(xValue) - log10(xMin)) / (log10(xMax) - log10(xMin));
    else
        multiplier = (xValue - xMin) / (xMax - xMin);
    
    return (int)(leftMargin + ((currentSize.width - leftMargin - rightMargin) * multiplier));
}


- (int) yValueToView:(double)yValue
{
    double multiplier;
    double yMin = [viewArea minY];
    double yMax = [viewArea maxY];

    if (logarithmicOrdinate)
        multiplier = (log10(yValue) - log10(yMin)) / (log10(yMax) - log10(yMin));
    else
        multiplier = (yValue - yMin) / (yMax - yMin);

    return (int)(bottomMargin + (currentSize.height - bottomMargin - topMargin) * multiplier);
}


- (NSPoint) viewToValue:(NSPoint)viewPoint
{
    double xPoint, yPoint;
    double xMin = [viewArea minX];
    double xMax = [viewArea maxX];
    double yMin = [viewArea minY];
    double yMax = [viewArea maxY];

    if (logarithmicAbscissa)
        xPoint = pow(10, ((viewPoint.x - leftMargin) * (log10(xMax) - log10(xMin)) /
            (currentSize.width - leftMargin - rightMargin)) + log10(xMin));
    else
        xPoint = ((viewPoint.x - leftMargin) * (xMax - xMin) /
            (currentSize.width - leftMargin - rightMargin)) + xMin;

    if (logarithmicOrdinate)
        yPoint = pow(10, ((viewPoint.y - bottomMargin) * (log10(yMax) - log10(yMin)) /
            (currentSize.height - bottomMargin - topMargin)) + log10(yMin));
    else
        yPoint = ((viewPoint.y - bottomMargin) * (yMax - yMin) /
            (currentSize.height - bottomMargin - topMargin)) + yMin;

    return NSMakePoint(xPoint, yPoint);
}


- (MI_ViewArea*) viewArea { return viewArea; }


- (void) setViewArea:(MI_ViewArea*)v_area
{
    //double y;
    MI_ViewArea* varea =
        [[MI_ViewArea alloc] initWithMinX:[v_area minX]
                                     maxX:[v_area maxX]
                                     minY:[v_area minY]
                                     maxY:[v_area maxY]];
    [viewArea release];
    viewArea = varea;
    // Check if the view area is flipped, i.e., min > max
    if ([viewArea minX] > [viewArea maxX])
    {
        double tmp = [viewArea maxX];
        [viewArea setMaxX:[viewArea minX]];
        [viewArea setMinX:tmp];
    }
    if ([viewArea minY] > [viewArea maxY])
    {
        double tmp = [viewArea maxY];
        [viewArea setMaxY:[viewArea minY]];
        [viewArea setMinY:tmp];
    }
    // Check if the abscissa is beyond bounds
    if ([viewArea minX] <= abscissaMinValue) [viewArea setMinX:abscissaMinValue];
    if ([viewArea maxX] >= abscissaMaxValue) [viewArea setMaxX:abscissaMaxValue];
    // Check if ordinate min equals max, which causes ugly plots
    if ([viewArea minY] == [viewArea maxY])
    {
        if ([viewArea minY] == 0.0)
        {
            [viewArea setMaxY:1e-6];
            [viewArea setMinY:-1e-6];
        }
        else
        {
            [viewArea setMaxY:([viewArea maxY] * 1.2)];
            [viewArea setMinY:([viewArea minY] * 0.8)];
        }
    }
    didCalculateGridMetrics = NO;
    firstDrawing = YES;
    [self setNeedsDisplay:YES];
}


- (void) drawRect:(NSRect)rect
{
    int i, j, k;
    NSSize tmpSize; // used to temporarily store the size of the on-screen plotting area when printing
    tmpSize.width = 0;
    tmpSize.height = 0;

    if ([ordinateVariables count] == 0)
        return;

    // Are we printing on paper or drawing to screen?
    if (![[NSGraphicsContext currentContext] isDrawingToScreen])
    {
        tmpSize = currentSize;
        currentSize = rect.size;
    }
    // NOTE: The order in which the components are drawn is important.
    
    /* Draw background */
    [backgroundColor set];
    NSRectFill(rect);

    if (!viewArea)
        [self setViewArea:
            [[[MI_ViewArea alloc] initWithMinX:abscissaMinValue
                                          maxX:abscissaMaxValue
                                          minY:totalOrdinateMinValue
                                          maxY:totalOrdinateMaxValue] autorelease]];
    
    if (!didCalculateGridMetrics)
        [self calculateGridMetrics];

    /* Draw labels */
    if (labels)
    {
        if (!labelFontAttributes)
            [self setPreferences];
        [self drawLabels];
    }

    /* Draw frame */
    [[NSColor colorWithDeviceRed:0.3 green:0.3 blue:0.3 alpha:1.0] set];
    [NSBezierPath strokeRect:NSMakeRect(leftMargin - 1, bottomMargin - 1,
        currentSize.width - rightMargin - leftMargin + 2, currentSize.height - topMargin - bottomMargin + 2)];

    /* Clip plot area */
    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:NSMakeRect(leftMargin - 1, bottomMargin - 1,
        currentSize.width - rightMargin - leftMargin + 2, currentSize.height - topMargin - bottomMargin + 2)];
    
    /* Draw grid */
    if (grid)
        [self drawGrid];

    /* Draw the visible variables */
    NS_DURING
    for (i = 0; i < [ordinateVariables count]; i++)
    {
        AnalysisVariable* currentVar = [[ordinateVariables objectAtIndex:i] retain];
        double scale = [currentVar scaleFactor];
        if (![[ordinateVisibilities objectAtIndex:i] boolValue])
            continue;
        if ([currentVar isScalingAroundAverage])
        {
            double average = [currentVar averageValue];

            for (k = 0; k < [[ordinateVariables objectAtIndex:i] numberOfSets]; k++)
            {
                NSBezierPath* ordinatePath = [NSBezierPath bezierPath];
                [ordinatePath setLineWidth:graphsLineWidth];
                [[ordinateColors objectAtIndex:i] set];
                [ordinatePath moveToPoint:NSMakePoint(
                    [self xValueToView:[[abscissaValues objectAtIndex:0] doubleValue]],
                    [self yValueToView:(average + scale * ([currentVar valueAtIndex:0
                                                                            forSet:k] - average))])];
                for (j = 1; j < numberOfAbscissaPoints; j++)
                    [ordinatePath lineToPoint:NSMakePoint(
                        [self xValueToView:[[abscissaValues objectAtIndex:j] doubleValue]],
                        [self yValueToView:(average + scale * ([currentVar valueAtIndex:j
                                                                                 forSet:k] - average))])];

                [ordinatePath stroke];
            }
        }
        else
        {
            for (k = 0; k < [[ordinateVariables objectAtIndex:i] numberOfSets]; k++)
            {
                NSBezierPath* ordinatePath = [NSBezierPath bezierPath];
                [ordinatePath setLineWidth:graphsLineWidth];
                [[ordinateColors objectAtIndex:i] set];
                [ordinatePath moveToPoint:NSMakePoint(
                    [self xValueToView:[[abscissaValues objectAtIndex:0] doubleValue]],
                    [self yValueToView:(scale * [currentVar valueAtIndex:0
                                                                  forSet:k])])
                ];
                for (j = 1; j < numberOfAbscissaPoints; j++)
                {
                    [ordinatePath lineToPoint:NSMakePoint(
                        [self xValueToView:[[abscissaValues objectAtIndex:j] doubleValue]],
                        [self yValueToView:(scale * [currentVar valueAtIndex:j
                                                                      forSet:k])])
                    ];
                }
                [ordinatePath stroke];
            }
        }
        [currentVar release];
    }
    NS_HANDLER
        if ([[localException name] isEqualToString:@"MISUGARIndexException"])
            NSLog(@"Invalid set index while accessing value of analysis variable!");
    NS_ENDHANDLER

    // Disable clipping
    [NSGraphicsContext restoreGraphicsState];

    // Draw the region delimiter handles if drawing to screen
    if ([[NSGraphicsContext currentContext] isDrawingToScreen])
        [self drawHandles];
    else // printing
    {
        if (plotDescription != nil)
        {
            // print circuit name
            [plotDescription drawAtPoint:NSMakePoint(leftMargin, 2)
                          withAttributes:labelFontAttributes];
            bottomMargin -= PLOT_DESCRIPTION_AREA_HEIGHT;
        }
        currentSize = tmpSize;
    }
    
    firstDrawing = NO;
}


- (void) drawGrid
{
    int drawPos;
    double currentPos = 0.0f; // the current drawing position
    double basePos = 0.0f; // needed to draw uneven logarithmic-scale grid lines corresponding to the even linear-scale grid
    int multiplier = 0; // needed for calculating positions of the logarithmic-scale grid lines
    NSBezierPath* gridPath = [NSBezierPath bezierPath];

    [gridPath setLineWidth:gridLineWidth];
    [gridColor set];
    
    // Draw the vertical grid lines
    if (logarithmicAbscissa)
    {
        if ( ([viewArea maxX] > 0.0) && ([viewArea minX] > 0.0) )
        {
            basePos = pow(10, floor(log10([viewArea maxX])));
            multiplier = (int) floor([viewArea maxX] / basePos);
            currentPos = multiplier * basePos;
            while (currentPos > [viewArea minX]) // not >= because if maxX == minX  and width == 0 then infinite loop
            {
                drawPos = [self xValueToView:currentPos];
                [gridPath moveToPoint:NSMakePoint(drawPos, bottomMargin)];
                [gridPath lineToPoint:NSMakePoint(drawPos, currentSize.height - topMargin)];
                if (--multiplier == 0)
                {
                    basePos /= 10.0;
                    multiplier = 9;
                }
                currentPos = multiplier * basePos;
            }
        }
    }
    else
    {
        currentPos = gridMaxX;
        while (currentPos > gridMinX)  // not >= because if maxX == minX and width == 0 then infinite loop
        {
            drawPos = [self xValueToView:currentPos];
            [gridPath moveToPoint:NSMakePoint(drawPos, bottomMargin)];
            [gridPath lineToPoint:NSMakePoint(drawPos, currentSize.height - topMargin)];
            currentPos -= gridWidth;
        }
    }
    // Draw the horizontal grid lines
    if (logarithmicOrdinate)
    {
        if ( ([viewArea maxY] > 0.0) && ([viewArea minY] > 0.0) )
        {
            basePos = pow(10, floor(log10([viewArea maxY])));
            multiplier = (int) floor([viewArea maxY] / basePos);
            currentPos = multiplier * basePos;
            while (currentPos > [viewArea minY]) // not >= because if maxY == minY and height == 0 then infinite loop
            {
                drawPos = [self yValueToView:currentPos];
                [gridPath moveToPoint:NSMakePoint(leftMargin, drawPos)];
                [gridPath lineToPoint:NSMakePoint(currentSize.width - rightMargin, drawPos)];
                if (--multiplier == 0)
                {
                    basePos /= 10.0;
                    multiplier = 9;
                }
                currentPos = multiplier * basePos;
            }
        }
    }
    else
    {
        currentPos = gridMaxY;
        while (currentPos > gridMinY) // not >= because if maxY == minY and height == 0 then infinite loop
        {
            drawPos = [self yValueToView:currentPos];
            [gridPath moveToPoint:NSMakePoint(leftMargin, drawPos)];
            [gridPath lineToPoint:NSMakePoint(currentSize.width - rightMargin, drawPos)];
            currentPos -= gridHeight;
        }
    }
    [gridPath stroke];
}


- (void) calculateGridMetrics
{
    double dominance, max, order, factor;

    gridMinX = [viewArea minX];
    gridMaxX = [viewArea maxX];
    gridMinY = [viewArea minY];
    gridMaxY = [viewArea maxY];

    if ( (gridMinX == gridMaxX) || (gridMinY == gridMaxY) )
    {
        gridWidth = gridHeight = gridMinX = gridMaxX = gridMinY = gridMaxY = 0.0;
        didCalculateGridMetrics = YES;
        return;
    }

    // Calculate the grid cell width
    dominance = fabs(gridMaxX - gridMinX) / fmax(fabs(gridMinX), fabs(gridMaxX));
    if (dominance < 0.2)
    {
        // The distance between the min and max points is much smaller than their magnitudes
        // Using the distance to calculate the grid width...
        if ( (fabs(gridMaxX - gridMinX) < (fabs(gridMinX) / 100.0)) &&
             (fabs(gridMaxX - gridMinX) < (fabs(gridMaxX) / 100.0)) )
            max = fmax(fabs(gridMaxX), fabs(gridMinX)) / 100.0;
        else
            max = fabs(gridMaxX - gridMinX);
    }
    else
        // The limit values are equally dominant
        // Using the larger one of the two values...
        max = fmax(fabs(gridMinX), fabs(gridMaxX));
    order = pow(10, floor(log10(max)));
    factor = ceil(max / order);
    if (factor <= 2.0)
        gridWidth = order / 5.0;
    else if (factor <= 5.0)
        gridWidth = order / 2.0;
    else
        gridWidth = order;

    // Calculate the grid cell height
    dominance = fabs(gridMaxY - gridMinY) / fmax(fabs(gridMinY), fabs(gridMaxY));
    if (dominance < 0.2)
    {
        // The distance between the min and max points is much smaller than their magnitudes
        // Using the distance to calculate the grid width...
        if ( (fabs(gridMaxY - gridMinY) < (fabs(gridMinY) / 100.0)) &&
             (fabs(gridMaxY - gridMinY) < (fabs(gridMaxY) / 100.0)) )
            max = fmax(fabs(gridMaxY), fabs(gridMinY)) / 100.0;
        else
            max = fabs(gridMaxY - gridMinY);
    }
    else
        // The limit values are equally dominant
        // Using the larger one of the two values...
        max = fmax(fabs(gridMinY), fabs(gridMaxY));
    order = pow(10, floor(log10(max)));
    factor = ceil(max / order);
    if (factor <= 2.0)
        gridHeight = order / 5.0;
    else if (factor <= 5.0)
        gridHeight = order / 2.0;
    else
        gridHeight = order;

    // Calculate grid start and end points
    if (gridMinX != 0.0)
    {
        factor = pow(10, floor(log10(fabs(gridMinX))));
        gridMinX = floor(gridMinX / factor) * factor;
    }
    if (gridMaxX != 0.0)
    {
        factor = pow(10, floor(log10(fabs(gridMaxX))));
        gridMaxX = ceil(gridMaxX / factor) * factor;
    }
    if (gridMinY != 0.0)
    {
        factor = pow(10, floor(log10(fabs(gridMinY))));
        gridMinY = floor(gridMinY / factor) * factor;
    }
    if (gridMaxY != 0.0)
    {
        factor = pow(10, floor(log10(fabs(gridMaxY))));
        gridMaxY = ceil(gridMaxY / factor) * factor;
    }
    
    didCalculateGridMetrics = YES;
}


- (void) drawLabels
{
    NSString *labelXMax, *labelXMin, *labelYMax, *labelYMin;
    // Calculate the label metrics
    if (logLabelsForLogScale && logarithmicAbscissa)
    {
        labelXMax = [NSString stringWithFormat:@"%f", log10([viewArea maxX])];
        labelXMin = [NSString stringWithFormat:@"%f", log10([viewArea minX])];
    }
    else
    {
        labelXMax = [NSString stringWithFormat:@"%4.2G", [viewArea maxX]];
        labelXMin = [NSString stringWithFormat:@"%4.2G", [viewArea minX]];
    }
    if (logLabelsForLogScale && logarithmicOrdinate)
    {
        labelYMax = [NSString stringWithFormat:@"%f", log10([viewArea maxY])];
        labelYMin = [NSString stringWithFormat:@"%f", log10([viewArea minY])];
    }
    else
    {
        labelYMax = [NSString stringWithFormat:@"%4.2G", [viewArea maxY]];
        labelYMin = [NSString stringWithFormat:@"%4.2G", [viewArea minY]];
    }

    bottomMargin = (int)fmaxf([labelXMin sizeWithAttributes:labelFontAttributes].height,
        [labelXMax sizeWithAttributes:labelFontAttributes].height) + 4;
    // Make more room at the bottom if a description has to be printed
    if (![[NSGraphicsContext currentContext] isDrawingToScreen] && (plotDescription != nil))
        bottomMargin += PLOT_DESCRIPTION_AREA_HEIGHT;
    leftMargin = (int)fmaxf([labelYMax sizeWithAttributes:labelFontAttributes].width,
        [labelYMin sizeWithAttributes:labelFontAttributes].width) + 6;
    topMargin = rightMargin = ZOOM_HANDLE_SIZE + 4;

    [labelXMin drawAtPoint:NSMakePoint(leftMargin - 2, bottomMargin - [labelXMin sizeWithAttributes:labelFontAttributes].height - 4)
            withAttributes:labelFontAttributes];
    [labelXMax drawAtPoint:NSMakePoint(currentSize.width - rightMargin - [labelXMax sizeWithAttributes:labelFontAttributes].width + 4,
                                       bottomMargin - [labelXMax sizeWithAttributes:labelFontAttributes].height - 4)
            withAttributes:labelFontAttributes];
    [labelYMin drawAtPoint:NSMakePoint(leftMargin - [labelYMin sizeWithAttributes:labelFontAttributes].width - 3, bottomMargin - 4)
            withAttributes:labelFontAttributes];
    [labelYMax drawAtPoint:NSMakePoint(leftMargin - [labelYMax sizeWithAttributes:labelFontAttributes].width - 3,
                                       currentSize.height - topMargin - [labelYMax sizeWithAttributes:labelFontAttributes].height + 4)
            withAttributes:labelFontAttributes];
}


- (void) drawHandles
{
    NSBezierPath* subregionPath = [NSBezierPath bezierPath];
    int handleLeft, handleRight, handleTop, handleBottom;
    int minX, maxX, minY, maxY;
    
    if (firstDrawing)
    {
        // Set initial handle positions
        handleLeftPos = [viewArea minX];
        handleRightPos = [viewArea maxX];
        handleBottomPos = [viewArea minY];
        handleTopPos = [viewArea maxY];
        [observer handlePositionsShouldUpdate];
    }
    // Convert handle positions to view coordinates
    handleLeft = [self xValueToView:handleLeftPos];
    handleRight = [self xValueToView:handleRightPos];
    handleTop = [self yValueToView:handleTopPos];
    handleBottom = [self yValueToView:handleBottomPos];
    maxX = currentSize.width - rightMargin;
    minX = leftMargin;
    maxY = currentSize.height - topMargin;
    minY = bottomMargin;
    // Draw subregion delimiter lines
    if (handlesAreActive)
    {
        [[NSColor orangeColor] set];
        [subregionPath setLineWidth:gridLineWidth];
        [subregionPath moveToPoint:NSMakePoint(handleLeft, maxY)];
        [subregionPath lineToPoint:NSMakePoint(handleLeft, minY)];
        [subregionPath moveToPoint:NSMakePoint(handleRight, maxY)];
        [subregionPath lineToPoint:NSMakePoint(handleRight, minY)];
        [subregionPath moveToPoint:NSMakePoint(minX, handleTop)];
        [subregionPath lineToPoint:NSMakePoint(maxX, handleTop)];
        [subregionPath moveToPoint:NSMakePoint(minX, handleBottom)];
        [subregionPath lineToPoint:NSMakePoint(maxX, handleBottom)];
        [subregionPath stroke];
        [NSBezierPath fillRect:NSMakeRect(handleLeft - 1, maxY + 2, handleRight - handleLeft + 2, ZOOM_BAR_SIZE + 1)];
        [NSBezierPath fillRect:NSMakeRect(maxX + 2, handleBottom - 1, ZOOM_BAR_SIZE + 1, handleTop - handleBottom + 2)];
    }
    else
    {
        float br = [backgroundColor brightnessComponent];
        if (br > 0.8f)
            [[NSColor colorWithDeviceWhite:(br * 0.9f) alpha:1.0f] set];
        else if (br < 0.4f)
            [[NSColor colorWithDeviceWhite:0.48f alpha:1.0f] set];
        else if (br < 0.7f)
            [[NSColor colorWithDeviceWhite:(br * 1.2f) alpha:1.0f] set];
        else
            [[NSColor colorWithDeviceWhite:(br * 0.8f) alpha:1.0f] set];
        [NSBezierPath fillRect:NSMakeRect(handleLeft - 1, maxY + 2, handleRight - handleLeft + 2, ZOOM_BAR_SIZE + 1)];
        [NSBezierPath fillRect:NSMakeRect(maxX + 2, handleBottom - 1, ZOOM_BAR_SIZE + 1, handleTop - handleBottom + 2)];
    }
}


- (void) resizeGraph:(NSNotification*)notif
{
    currentSize = [self bounds].size;
    didCalculateGridMetrics = NO;
#ifdef GRAPHVIEW_WITH_TOOLTIP
    [self removeToolTip:tooltip];
    tooltip = [self addToolTipRect:NSMakeRect(margin, margin,
        currentSize.width - 2 * margin, currentSize.height - 2 * margin)
                             owner:self
                          userData:nil];
#endif
    [self setNeedsDisplay:YES];
}


- (void) changeSettings:(NSNotification*)notification
{
    [self setPreferences];
    [self setNeedsDisplay:YES];
}


- (void) setPreferences
{
    int labelFontSize;
    NSColor* labelColor;
    NSUserDefaults* userdefs = [NSUserDefaults standardUserDefaults];
    
    gridLineWidth = PlotterGridLineWidth[(int) [[userdefs objectForKey:MISUGAR_PLOT_GRID_LINE_WIDTH] charValue]];
    graphsLineWidth = PlotterGraphsLineWidth[(int) [[userdefs objectForKey:MISUGAR_PLOT_GRAPHS_LINE_WIDTH] charValue]];
    labelFontSize = PlotterLabelsFontSize[(int) [[userdefs objectForKey:MISUGAR_PLOT_LABELS_FONT_SIZE] charValue]];
    [backgroundColor release];
    backgroundColor = [[NSKeyedUnarchiver unarchiveObjectWithData:[userdefs objectForKey:MISUGAR_PLOTTER_BACKGROUND_COLOR]] retain];
    gridColor = [[NSKeyedUnarchiver unarchiveObjectWithData:[userdefs objectForKey:MISUGAR_PLOTTER_GRID_COLOR]] retain];
    // Choose the label color so that it contrasts nicely with the background
    labelColor = ([backgroundColor brightnessComponent] > 0.5) ? [[NSColor blackColor] retain] : [[NSColor whiteColor] retain];
    
    [labelFontAttributes release];
    labelFontAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
        /* [[NSFont fontWithName:@"Helvetica-Regular"
                            size:labelFontSize] retain] */
        [NSFont systemFontOfSize:labelFontSize], NSFontAttributeName,
        labelColor, NSForegroundColorAttributeName,
        NULL] retain];
}


- (void) setAbscissa:(AnalysisVariable*)variable
                name:(NSString*)label
{
    //int i;
    if ([variable valuesOfSet:0] == nil) return;
    [variable retain];
    if (abscissaValues) [abscissaValues release];
    abscissaValues = [[variable valuesOfSet:0] retain];
    numberOfAbscissaPoints = [abscissaValues count];
    [label retain];
    if (abscissaLabel) [abscissaLabel release];
    abscissaLabel = label;
    abscissaMinValue = [[abscissaValues objectAtIndex:0] doubleValue];
    abscissaMaxValue = [[abscissaValues objectAtIndex:(numberOfAbscissaPoints - 1)] doubleValue];
    if (abscissaMinValue > abscissaMaxValue)
    {
        double tmp = abscissaMaxValue;
        abscissaMaxValue = abscissaMinValue;
        abscissaMinValue = tmp;
    }
    /*
    for (i = 1; i < numberOfAbscissaPoints; i++)
    {
        if ( abscissaMaxValue < [[abscissaValues objectAtIndex:i] doubleValue])
            abscissaMaxValue = [[abscissaValues objectAtIndex:i] doubleValue];
        else if ( abscissaMinValue > [[abscissaValues objectAtIndex:i] doubleValue] )
            abscissaMinValue = [[abscissaValues objectAtIndex:i] doubleValue];
    }
    */
    /*
    fprintf(stderr, "abscissa values:\n");
    for (i = 0; i < numberOfAbscissaPoints; i++)
        fprintf(stderr, "%03d - %5.3f\n", i, [[abscissaValues objectAtIndex:i] doubleValue]);
    */
    didCalculateGridMetrics = NO;
    firstDrawing = YES;
    [viewArea release];
    viewArea = nil;
}


- (void) addOrdinate:(AnalysisVariable*)variable
                name:(NSString*)label
               color:(NSColor*)color
{
    double max, min, current;

    [ordinateVariables addObject:variable];
    [ordinateLabels addObject:label];
    if (color) [ordinateColors addObject:color];
    else [ordinateColors addObject:[NSColor blackColor]];
    [ordinateLengths addObject:[NSNumber numberWithInteger:[variable numberOfValuesPerSet]]];
    [ordinateVisibilities addObject:[NSNumber numberWithBool:YES]];
    if ([variable numberOfSets])
    {
        // Calculate and store the maximum and minimum values
        min = max = [variable valueAtIndex:0 forSet:0];
        for (int j = (int)[variable numberOfSets] - 1; j >= 0; j--)
            for (int i = (int)[variable numberOfValuesPerSet] - 1; i >= 0; i--)
            {
                current = [variable valueAtIndex:i forSet:j];
                if (max <  current)
                    max = current;
                else if (min > current)
                    min = current;
            }
        [ordinateMaximumValues addObject:[NSNumber numberWithDouble:max]];
        [ordinateMinimumValues addObject:[NSNumber numberWithDouble:min]];
        if ((totalOrdinateMaxValue < max) || ([ordinateMaximumValues count] == 1))
            totalOrdinateMaxValue = max;
        if ((totalOrdinateMinValue > min) || ([ordinateMinimumValues count] == 1))
            totalOrdinateMinValue = min;
    }
    didCalculateGridMetrics = NO;
    [viewArea release];
    viewArea = nil;
}


- (NSColor*) colorOfOrdinateAtIndex:(int)index
{
    if ((index >= 0) && (index < [ordinateColors count]))
        return [ordinateColors objectAtIndex:index];
    else
        return nil;
}


- (void) setColor:(NSColor*)newColor
      forOrdinate:(int)ordinateIndex
{
    if ((ordinateIndex >= 0) && (ordinateIndex < [ordinateColors count]))
    {
        [ordinateColors replaceObjectAtIndex:ordinateIndex
                                withObject:newColor];
        [self setNeedsDisplay:YES];
    }
}


- (void) showVariable:(int)index
{
    [ordinateVisibilities replaceObjectAtIndex:index
                                    withObject:[NSNumber numberWithBool:YES]];
    [self setNeedsDisplay:YES];
}


- (void) hideVariable:(int)index
{
    [ordinateVisibilities replaceObjectAtIndex:index
                                    withObject:[NSNumber numberWithBool:NO]];
    [self setNeedsDisplay:YES];
}


- (void) showAll
{
    int j;
    for (j = [ordinateVisibilities count] - 1; j >= 0; j--)
        [ordinateVisibilities replaceObjectAtIndex:j
                                        withObject:[NSNumber numberWithBool:YES]];
    [self setNeedsDisplay:YES];
}


- (void) hideAll
{
    int j;
    for (j = [ordinateVisibilities count] - 1; j >= 0; j--)
        [ordinateVisibilities replaceObjectAtIndex:j
                                        withObject:[NSNumber numberWithBool:NO]];
    [self setNeedsDisplay:YES];
}


- (BOOL) isHidden:(int)index
{
    if (index > -1 && index < [ordinateVisibilities count])
        return ![[ordinateVisibilities objectAtIndex:index] boolValue];
    else
        return NO;
}


- (void) showLogarithmicAbscissa:(BOOL)logarithmic
{
    logarithmicAbscissa = logarithmic;
    didCalculateGridMetrics = NO;
    firstDrawing = YES;
    [self setNeedsDisplay:YES];
}


- (void) showLogarithmicOrdinate:(BOOL)logarithmic
{
    logarithmicOrdinate = logarithmic;
    didCalculateGridMetrics = NO;
    firstDrawing = YES;
    [self setNeedsDisplay:YES];
}


- (void) setShowLogLabelsForLogScale:(BOOL)logLabels
{
    logLabelsForLogScale = logLabels;
    if (logarithmicAbscissa || logarithmicOrdinate)
        [self setNeedsDisplay:YES];
}


- (void) showGrid:(BOOL)gridOn
{
    grid = gridOn;
    [self setNeedsDisplay:YES];
}


- (void) showLabels:(BOOL)labelsOn
{
    labels = labelsOn;
    if (!labels)
        leftMargin = rightMargin = topMargin = bottomMargin = MI_SUGAR_DEFAULT_MARGIN;
    [self setNeedsDisplay:YES];
}


- (void) setGridColor:(NSColor*)color
{
    [color retain];
    if (gridColor) [gridColor release];
    gridColor = color;
    [self setNeedsDisplay:YES];
}


- (int) leftMargin
{
    return leftMargin;
}


- (int) rightMargin
{
    return rightMargin;
}


- (int) topMargin
{
    return topMargin;
}


- (int) bottomMargin
{
    return bottomMargin;
}


- (void) setBackgroundColor:(NSColor*)color
{
    if (backgroundColor) [backgroundColor release];
    backgroundColor = [color retain];
    [self setNeedsDisplay:YES];
}


- (NSColor*) backgroundColor
{
    return backgroundColor;
}


#ifdef GRAPHVIEW_WITH_TOOLTIP
- (void) setShowsPointerPosition:(BOOL)showPos
{
    showPointerPosition = showPos;
    [self removeToolTip:tooltip];
    tooltip = [self addToolTipRect:NSMakeRect(margin, margin,
        currentSize.width - 2 * margin, currentSize.height - 2 * margin)
                             owner:self
                          userData:nil];
}


- (NSString*) view:(NSView*)view
  stringForToolTip:(NSToolTipTag)tag
             point:(NSPoint)point
          userData:(void *)userData
{
    if (showPointerPosition && ((view != self) || (tag != tooltip)))
    {
        NSPoint vals = [self viewToValue:point];
        return [NSString stringWithFormat:@"%6.4f, %6.4f", vals.x, vals.y];
    }
    else return nil;
}
#endif


- (int) numberOfOrdinateVariables
{
    return [ordinateVariables count];
}


- (double) minimumOrdinateValue { return fmin(handleTopPos, handleBottomPos); }
- (double) maximumOrdinateValue { return fmax(handleTopPos, handleBottomPos); }
- (double) minimumAbscissaValue { return abscissaMinValue; }
- (double) maximumAbscissaValue { return abscissaMaxValue; }


- (void) removeAll
{
    [abscissaLabel release];
    abscissaLabel = nil;
    [abscissaValues release];
    abscissaValues = nil;
    numberOfAbscissaPoints = 0;
    [ordinateVariables removeAllObjects];
    [ordinateLengths removeAllObjects];
    [ordinateVisibilities removeAllObjects];
    [ordinateLabels removeAllObjects];
    [ordinateMaximumValues removeAllObjects];
    [ordinateMinimumValues removeAllObjects];
    [ordinateColors removeAllObjects];
}


- (void) mouseMoved:(NSEvent*)theEvent
{
    // Notify the MI_CoordinateObserver2D object
    if (observer && !handlesAreActive)
    {
        NSPoint mousePosition = [self convertPoint:[theEvent locationInWindow]
                                          fromView:nil];
        NSRect validRegion = [self bounds];
        validRegion.size =
            NSMakeSize(validRegion.size.width - leftMargin - rightMargin,
                       validRegion.size.height - topMargin - bottomMargin);
        validRegion.origin = NSMakePoint(validRegion.origin.x + leftMargin,
                                         validRegion.origin.y + bottomMargin);
        if ([self mouse:mousePosition
                 inRect:validRegion])
            [observer processMouseMove:mousePosition];
    }
}


- (void) mouseDown:(NSEvent*)theEvent
{
    NSPoint mousePosition = [self convertPoint:[theEvent locationInWindow]
                                      fromView:nil];
    NSRect leftHandleRegion, rightHandleRegion, topHandleRegion, bottomHandleRegion;
    handlesAreActive = YES;

    leftHandleRegion.size = NSMakeSize(ZOOM_HANDLE_SIZE, ZOOM_HANDLE_SIZE);
    leftHandleRegion.origin = NSMakePoint([self xValueToView:handleLeftPos] - ZOOM_HANDLE_SIZE/2, [self bounds].size.height - topMargin);
    if ([self mouse:mousePosition
             inRect:leftHandleRegion])
    {
        selectedHandle = LEFT;
    }
    else
    {
        rightHandleRegion.size = leftHandleRegion.size;
        rightHandleRegion.origin =
            NSMakePoint([self xValueToView:handleRightPos] - ZOOM_HANDLE_SIZE/2, [self bounds].size.height - topMargin);
        if ([self mouse:mousePosition
                 inRect:rightHandleRegion])
        {
            selectedHandle = RIGHT;
        }
        else
        {
            topHandleRegion.size = leftHandleRegion.size;
            topHandleRegion.origin =
                NSMakePoint([self bounds].size.width - rightMargin, [self yValueToView:handleTopPos] - ZOOM_HANDLE_SIZE/2);
            if ([self mouse:mousePosition
                     inRect:topHandleRegion])
            {
                selectedHandle = TOP;
            }
            else
            {
                bottomHandleRegion.size = leftHandleRegion.size;
                bottomHandleRegion.origin =
                    NSMakePoint( [self bounds].size.width - rightMargin, [self yValueToView:handleBottomPos] - ZOOM_HANDLE_SIZE/2);
                if ([self mouse:mousePosition
                         inRect:bottomHandleRegion])
                {
                    selectedHandle = BOTTOM;
                }
                else
                    handlesAreActive = NO;
            }
        }
    }
    if (handlesAreActive)
    {
        [self setNeedsDisplay:YES];
        [observer processHandleGrabbed];
    }
}


- (void) mouseDragged:(NSEvent*)theEvent
{
    if ([theEvent modifierFlags] & NSCommandKeyMask)
    {        
        // Creates an image of the schematic and puts it into the pasteboard
        NSSize imageSize = [self frame].size;
        NSImage *plotterImage = [[NSImage alloc] initWithSize:imageSize];
        NSRect imageBox = NSMakeRect(0, 0, imageSize.width, imageSize.height);
        
        [plotterImage lockFocus];
        // Making sure there are no artefacts at the edges
        [backgroundColor set];
        [NSBezierPath fillRect:NSInsetRect(imageBox, -2, -2)];
        // Drawing into the image
        [self drawRect:imageBox];
        [plotterImage unlockFocus];
        
        // Put the image on the pasteboard
        NSPasteboard *dragPboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        [dragPboard declareTypes:[NSArray arrayWithObject:NSTIFFPboardType]
                           owner:self];
        [dragPboard setData:[plotterImage TIFFRepresentation]
                    forType:NSTIFFPboardType];
        // Create a semi-transparent drag image
        NSImage* dragImage = [[NSImage alloc] initWithSize:imageBox.size];
        [dragImage lockFocus];
        [plotterImage dissolveToPoint:NSMakePoint(0,0)
                               fraction:0.8f];
        [dragImage unlockFocus];
        // Drag the image
        [self dragImage:[dragImage autorelease]
                     at:NSMakePoint(imageBox.origin.x, imageBox.origin.y)
                 offset:NSMakeSize(0,0)
                  event:theEvent
             pasteboard:dragPboard
                 source:self
              slideBack:YES];
        
        [plotterImage autorelease];
    }
    else if (handlesAreActive)
    {
        NSPoint mousePos = [self convertPoint:[theEvent locationInWindow]
                                     fromView:nil];
        NSPoint handlePos = [self viewToValue:mousePos];
        NSSize viewSize = [self bounds].size;

        // One of the zoom handles is being dragged
        switch (selectedHandle)
        {
            case LEFT:
                if (mousePos.x < leftMargin)
                    handleLeftPos = [viewArea minX];
                else if (mousePos.x > (viewSize.width - rightMargin))
                    handleLeftPos = [viewArea maxX];
                else
                    handleLeftPos = handlePos.x;
                [observer processHandleDrag:selectedHandle
                                   position:handleLeftPos];
                break;
            case RIGHT:
                if (mousePos.x < leftMargin)
                    handleRightPos = [viewArea minX];
                else if (mousePos.x > (viewSize.width - rightMargin))
                    handleRightPos = [viewArea maxX];
                else
                    handleRightPos = handlePos.x;
                [observer processHandleDrag:selectedHandle
                                   position:handleRightPos];
                break;
            case TOP:
                if (mousePos.y < bottomMargin)
                    handleTopPos = [viewArea minY];
                else if (mousePos.y > (viewSize.height - topMargin))
                    handleTopPos = [viewArea maxY];
                else
                    handleTopPos = handlePos.y;
                [observer processHandleDrag:selectedHandle
                                   position:handleTopPos];
                break;
            default:
                if (mousePos.y < bottomMargin)
                    handleBottomPos = [viewArea minY];
                else if (mousePos.y > (viewSize.height - topMargin))
                    handleBottomPos = [viewArea maxY];
                else
                    handleBottomPos = handlePos.y;
                [observer processHandleDrag:selectedHandle
                                   position:handleBottomPos];
        }
        [self setNeedsDisplay:YES];
    }
}


- (void) mouseUp:(NSEvent*)theEvent
{
    if (handlesAreActive)
    {
        // deactivate the zoom handles
        handlesAreActive = NO;
        [self setNeedsDisplay:YES];
        [observer processHandlesReleased];
    }
}


- (BOOL) acceptsFirstResponder
{
    return YES;
}


- (void) setObserver:(id <SugarGraphObserver>)newObserver
{
    observer = newObserver;
    [[self window] setAcceptsMouseMovedEvents:YES];
}


- (IBAction) copy:(id)sender
{
    NSArray *types = [NSArray arrayWithObject:NSTIFFPboardType];
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:types
               owner:self];
}


- (void) pasteboard:(NSPasteboard *)sender
 provideDataForType:(NSString *)type
{
    // the image type is provided lazily
    if ([type compare:NSTIFFPboardType] == NSOrderedSame)
    {
        NSData *tiffData;
        NSRect bds = [self bounds];
        NSImage *plot = [[NSImage alloc] initWithSize:bds.size];
        [plot lockFocus];
        [self drawRect:bds];
        [plot unlockFocus];
        tiffData = [plot TIFFRepresentationUsingCompression:NSTIFFCompressionLZW
                                                     factor:0.0];
        NS_DURING
            [sender setData:tiffData
                    forType:type];
        NS_HANDLER
            NSLog(@"An exception occurred while trying to paste the plot into the clipboard.");
        NS_ENDHANDLER
        [plot autorelease];
    }
    else
        // put something on to avoid a crash
        [sender setString:@"MI-SUGAR plot image"
                  forType:type];
}


- (void) setPlotDescription:(NSString*)description
{
    [description retain];
    [plotDescription release];
    plotDescription = description;
}


- (double) leftHandlePosition { return handleLeftPos; }
- (double) rightHandlePosition { return handleRightPos; }
- (double) topHandlePosition { return handleTopPos; }
- (double) bottomHandlePosition { return handleBottomPos; }


- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [abscissaLabel release];
    [abscissaValues release];
    [ordinateVariables release];
    [ordinateLengths release];
    [ordinateVisibilities release];
    [ordinateLabels release];
    [ordinateMaximumValues release];
    [ordinateMinimumValues release];
    [ordinateColors release];
    [backgroundColor release];
    [gridColor release];
    [labelFontAttributes release];
    [viewArea release];
    [plotDescription release];
    [super dealloc];
}

@end
