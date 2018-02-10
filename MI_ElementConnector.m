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
#import <Cocoa/Cocoa.h>
#import "MI_ElementConnector.h"

@implementation MI_ElementConnector

- (id) init
{
  if (self = [super init])
  {
    startPointName = @"";
    endPointName = @"";
    startElementID = @"";
    endElementID = @"";
    route = NULL;
    numberOfRoutePoints = 0;
    needsRouting = NO;
    isHighlighted = NO;
  }
  return self;
}


- (void) dealloc
{
  if (route)
  {
    free(route);
  }
  [startPointName release];
  [endPointName release];
  [startElementID release];
  [endElementID release];
  [super dealloc];
}


- (NSString*) startElementID { return [NSString stringWithString:startElementID]; }

- (NSString*) endElementID { return [NSString stringWithString:endElementID]; }

- (NSString*) startPointName { return [NSString stringWithString:startPointName]; }

- (NSString*) endPointName { return [NSString stringWithString:endPointName]; }

- (void) setStartElementID:(NSString*)newStartElementID
{
    [newStartElementID retain];
    [startElementID release];
    startElementID = newStartElementID;
}

- (void) setEndElementID:(NSString*)newEndElementID
{
    [newEndElementID retain];
    [endElementID release];
    endElementID = newEndElementID;
}

- (void) setStartPointName:(NSString*)newStartPointName
{
    [newStartPointName retain];
    [startPointName release];
    startPointName = newStartPointName;
}

- (void) setEndPointName:(NSString*)newEndPointName
{
    [newEndPointName retain];
    [endPointName release];
    endPointName = newEndPointName;
}


- (void) setRoute:(NSPoint*)newRoute
   numberOfPoints:(unsigned)numOfPoints
{
    /*fprintf(stderr, "point 1: (%f,%f), point 2: (%f,%f)\n",
        newRoute[0].x, newRoute[0].y, newRoute[1].x, newRoute[1].y);*/
    if (route) free(route);
    route = newRoute;
    numberOfRoutePoints = numOfPoints;
    needsRouting = NO;
}


- (NSPoint*) route
{
    return route;
}


- (int) numberOfRoutePoints
{
    return numberOfRoutePoints;
}


- (void) setNeedsRouting:(BOOL)doesNeedRouting
{
    needsRouting = doesNeedRouting;
}

- (BOOL) needsRouting
{
    return needsRouting;
}


- (void) setHighlighted:(BOOL)highlighted
{
    isHighlighted = highlighted;
}


- (BOOL) hasBeenTraversed
{
    return hasBeenTraversed;
}


- (void) setTraversed:(BOOL)traversed
{
    hasBeenTraversed = traversed;
}


- (void) draw
{
    if (numberOfRoutePoints > 1)
    {
        int step;
        NSBezierPath* bp = [NSBezierPath bezierPath];

        if ([NSGraphicsContext currentContextDrawingToScreen])
        {
            if (isHighlighted)
                [[NSColor redColor] set];
            else
                [[NSColor grayColor] set];
        }
        else
            [[NSColor blackColor] set]; // for beautiful printouts :)
            
        [bp moveToPoint:*route];
        for (step = 1; step < numberOfRoutePoints; step++)
            [bp lineToPoint:route[step]];
        [bp stroke];
    }
}


- (NSString*) shapeToSVG
{
  return [NSString stringWithFormat:
    @"<polyline points=\"%g,%g %g,%g %g,%g\" fill=\"none\" stroke=\"black\" stroke-width=\"1\"/>",
    route[0].x, route[0].y, route[1].x, route[1].y, route[2].x, route[2].y];
}


/*************************** NSCopying implementation ****************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_ElementConnector* myCopy = [[[self class] allocWithZone:zone] init];
  [myCopy setStartElementID:[self startElementID]];
  [myCopy setStartPointName:[self startPointName]];
  [myCopy setEndElementID:[self endElementID]];
  [myCopy setEndPointName:[self endPointName]];
  // Copy route
  NSPoint* newRoute = (NSPoint*) malloc(numberOfRoutePoints * sizeof(NSPoint));
  memcpy(newRoute, route, numberOfRoutePoints * sizeof(NSPoint));
  [myCopy setRoute:newRoute numberOfPoints:numberOfRoutePoints];
  [myCopy setNeedsRouting:YES];
  [myCopy setHighlighted:NO];
  return myCopy;
}

//MARK: NSCoding methods

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    startElementID = [decoder decodeObjectForKey:@"StartElementID"];
    startPointName = [decoder decodeObjectForKey:@"StartPointName"];
    endElementID = [decoder decodeObjectForKey:@"EndElementID"];
    endPointName = [decoder decodeObjectForKey:@"EndPointName"];
    if ([startElementID length] == 0) startElementID = nil; else [startElementID retain];
    if ([startPointName length] == 0) startPointName = nil; else [startPointName retain];
    if ([endElementID length] == 0) endElementID = nil; else [endElementID retain];
    if ([endPointName length] == 0) endPointName = nil; else [endPointName retain];

    numberOfRoutePoints = [decoder decodeIntForKey:@"NumberOfRoutePoints"];
    NSUInteger const length = numberOfRoutePoints * sizeof(NSPoint);
    route = (NSPoint*) malloc(length);
    [[decoder decodeObjectForKey:@"RouteData"] getBytes:route length:length];

    needsRouting = YES;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  if (startElementID == nil) startElementID = @"";
  if (startPointName == nil) startPointName = @"";
  if (endElementID == nil) endElementID = @"";
  if (endPointName == nil) endPointName = @"";

  [encoder encodeObject:startElementID forKey:@"StartElementID"];
  [encoder encodeObject:startPointName forKey:@"StartPointName"];
  [encoder encodeObject:endElementID forKey:@"EndElementID"];
  [encoder encodeObject:endPointName forKey:@"EndPointName"];
  [encoder encodeInt:numberOfRoutePoints forKey:@"NumberOfRoutePoints"];
  NSData* data = [NSData dataWithBytes:route length:numberOfRoutePoints * sizeof(NSPoint)];
  [encoder encodeObject:data forKey:@"RouteData"];
}

@end
