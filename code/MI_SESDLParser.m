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
#import "MI_SESDLParser.h"
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>
#include <libxml/tree.h>
#import "MI_ConnectionPoint.h"

//#define SESDL_DEBUG

@implementation MI_SESDLParser

// Uses libXML2 to parse the given SESDL file
+ (MI_PathShape*) parseSESDL:(NSString*)sesdlFile
{
    xmlNode *root, *currentNode;
    MI_PathShape* shape = nil;
    float shapeWidth = 0.0f, shapeHeight = 0.0f;
    NSMutableDictionary* pointMap = nil;
    NSMutableArray* filledPaths = nil;
    NSMutableArray* outlinePaths = nil;
    NSString* svgEquivalent = @"";
    //xmlChar *fieldLength, *alternateName;
    xmlDocPtr doc;
    
    doc = xmlParseFile([sesdlFile cStringUsingEncoding:NSASCIIStringEncoding]);
    
    if (doc == NULL)
    {
        NSLog(@"Error: Could not parse file %@. If it exists it's not in a valid XML format.", sesdlFile);
        goto cleanup;
    }

    root = NULL;
    root = xmlDocGetRootElement(doc);
    
    if ( !root || !root->name )
    {
        NSLog(@"Error: Document root does not exist or has no name");
        goto cleanup;
    }
    else
    {
#ifdef SESDL_DEBUG
        fprintf(stderr, root->name);
        fprintf(stderr, "\nshape name = %s\n", xmlGetProp(root,"name"));
#endif
        svgEquivalent = [NSString stringWithFormat:@"<!-- custom subcircuit shape: %s -->",
            xmlGetProp(root, (xmlChar*)"name")];
    }

    BOOL foundConnectionPoints = NO;
    BOOL extractedShape = NO;
    for(currentNode = root->children; currentNode != NULL; currentNode = currentNode->next)
    {
        // Extract connection points from the first set of connection points in the file
        if ( !foundConnectionPoints && xmlStrEqual(currentNode->name, (xmlChar*)"connection-points") )
        {
            foundConnectionPoints = YES;
            pointMap = [NSMutableDictionary dictionaryWithCapacity:5];
            xmlNode* currentConnectionPoint;
            float posX, posY;
            NSString* pointName;
            for (currentConnectionPoint = currentNode->children; currentConnectionPoint != NULL; currentConnectionPoint = currentConnectionPoint->next)
            {
                if ( xmlStrEqual(currentConnectionPoint->name, (xmlChar*)"connection-point") )
                {
                    pointName = [NSString stringWithCString:(char*)xmlGetProp(currentConnectionPoint, (xmlChar*)"name") encoding:NSASCIIStringEncoding];
                    posX = atof((char*)xmlGetProp(currentConnectionPoint, (xmlChar*)"x"));
                    posY = atof((char*)xmlGetProp(currentConnectionPoint, (xmlChar*)"y"));
#ifdef SESDL_DEBUG
                    NSLog(@"%@, x=%g, y=%g", pointName, posX, posY);
#endif
                    [pointMap setObject:[[MI_ConnectionPoint alloc] initWithPosition:NSMakePoint(posX, posY)
                                                                                 size:NSMakeSize(6.0f, 6.0f)
                                                                                 name:pointName]
                                 forKey:pointName];
                }
            }
        }
        
        // Extract shape information
        if (!extractedShape && xmlStrEqual(currentNode->name, (xmlChar*)"shape"))
        {
            xmlNode* currentPath;
            NSString* pathDefinition;
            NSString* svgPath;
            BOOL isClosedPath;
            BOOL isFilledPath;
            NSBezierPath* bp;
            if (!xmlGetProp(currentNode, (xmlChar*)"width") || !(xmlGetProp(currentNode, (xmlChar*)"height")))
            {
                NSLog(@"Error: Shape width and/or height invalid or not specified.");
                goto cleanup;
            }
            else
            {
                shapeWidth = atof((char*)xmlGetProp(currentNode, (xmlChar*)"width" ));
                shapeHeight = atof((char*)xmlGetProp(currentNode, (xmlChar*)"height" ));
                if (shapeWidth <= 0 || shapeWidth > MI_SHAPE_MAX_EXTENT ||
                    shapeHeight <= 0 || shapeHeight > MI_SHAPE_MAX_EXTENT)
                {
                    NSLog(@"Invalid shape size.");
                    goto cleanup;
                }
            }
            NSCharacterSet* pathCommandCharacters = [NSCharacterSet characterSetWithCharactersInString:@"mMvVhHlLzcCaA"];
            NSCharacterSet* whitespaceCharacters = [NSCharacterSet whitespaceCharacterSet];
            filledPaths = [NSMutableArray arrayWithCapacity:3];
            outlinePaths = [NSMutableArray arrayWithCapacity:3];
            for (currentPath = currentNode->children; currentPath != NULL; currentPath = currentPath->next)
            {
                if (xmlStrEqual(currentPath->name, (xmlChar*)"path"))
                {
                    // Parse path definition
                    pathDefinition = [NSString stringWithCString:(char*)xmlGetProp(currentPath, (xmlChar*)"d") encoding:NSASCIIStringEncoding];
#ifdef SESDL_DEBUG
                    NSLog(@"Processing path definition \"%@\"", pathDefinition);
#endif
                    pathDefinition = [pathDefinition stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    svgPath = [NSString stringWithString:pathDefinition];
                    isClosedPath = [pathDefinition hasSuffix:@" z"];
                    if (isClosedPath)
                    {
                        pathDefinition = [pathDefinition substringToIndex:([pathDefinition length] - 2)];
                        pathDefinition = [pathDefinition stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    }
                    xmlChar* filledAttribute = xmlGetProp(currentPath, (xmlChar*)"filled");
                    isFilledPath = ( filledAttribute && xmlStrEqual(filledAttribute, (xmlChar*)"true") ) ? YES : NO;
                    bp = [NSBezierPath bezierPath];
                    
                    // Dissect the path definition and execute the parsed commands
                    char currentChar;
                    NSRange rng;
                    BOOL absoluteMove = NO;
                    BOOL absoluteVerticalLine = NO;
                    BOOL absoluteHorizontalLine = NO;
                    BOOL absoluteLineTo = NO;
                    BOOL absoluteCurve = NO;
                    BOOL absoluteArc = NO;
                    //
                    while ([pathDefinition length] > 0)
                    {
                        currentChar = [pathDefinition characterAtIndex:0];
                        if (![pathCommandCharacters characterIsMember:currentChar])
                        {
                            NSLog(@"Invalid path syntax. Unexpected character: %c", currentChar);
                            pathDefinition = [pathDefinition substringFromIndex:1];
                            continue;
                        }
                        switch (currentChar)
                        {
                            // the Move commands
                            case 'M':
                                absoluteMove = YES;
                            case 'm':
                            {
                                float Mx, My; // the coordinates
                                // remove leading M character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                if (rng.location == NSNotFound)
                                {
                                    NSLog(@"incomplete coordinates for move command");
                                    goto cleanup;
                                }
                                Mx = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                // remove the x coordinate
                                pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                if (rng.location == NSNotFound)
                                {
                                    NSLog(@"Note: Unnecessary move command at end of path detected.");
                                    My = [pathDefinition floatValue];
                                    pathDefinition = @"";
                                }
                                else
                                {
                                    My = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the y coordinate
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                    // advance to next path command
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                }
                                if (absoluteMove)
                                    [bp moveToPoint:NSMakePoint(Mx, My)];
                                else
                                    [bp relativeMoveToPoint:NSMakePoint(Mx, My)];
#ifdef SESDL_DEBUG

                                NSLog(@"Moving to %g,%g", Mx, My);
#endif
                                absoluteMove = NO;
                                break;
                            }
                                
                            // The LineTo commands
                            case 'V':
                                absoluteVerticalLine = YES;
                            case 'v':
                            {
                                // remove leading V character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                float distance;
                                if (rng.location == NSNotFound)
                                {
                                    if ([pathDefinition length] == 0)
                                    {
                                        NSLog(@"Missing distance for vertical line command");
                                        goto cleanup;
                                    }
                                    else
                                    {
                                        distance = [pathDefinition floatValue];
                                        pathDefinition = @"";
                                    }
                                }
                                else
                                {
                                    distance = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the distance value
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                    // advance to next path command
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                }
                                if (absoluteVerticalLine)
                                    [bp lineToPoint:NSMakePoint(0, distance)];
                                else
                                    [bp relativeLineToPoint:NSMakePoint(0, distance)];
                                absoluteVerticalLine = NO;
#ifdef SESDL_DEBUG
                                NSLog(@"Vertical line %g", distance);
#endif
                                break;
                            }
                            //
                            case 'H':
                                absoluteHorizontalLine = YES;
                            case 'h':
                            {
                                // remove leading H character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                float distance;
                                if (rng.location == NSNotFound)
                                {
                                    if ([pathDefinition length] == 0)
                                    {
                                        NSLog(@"Missing distance for horizontal line command");
                                        goto cleanup;
                                    }
                                    else
                                    {
                                        distance = [pathDefinition floatValue];
                                        pathDefinition = @"";
                                    }
                                }
                                else
                                {
                                    distance = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the distance value
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];                                    
                                    // advance to next path command
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                }
                                if (absoluteVerticalLine)
                                    [bp lineToPoint:NSMakePoint(distance, 0)];
                                else
                                    [bp relativeLineToPoint:NSMakePoint(distance, 0)];
                                absoluteHorizontalLine = NO;
#ifdef SESDL_DEBUG
                                NSLog(@"Horizontal line %g", distance);
#endif
                                break;
                            }
                            //
                            case 'L':
                                absoluteLineTo = YES;
                            case 'l':
                            {
                                float Lx, Ly; // the coordinates
                                // remove leading L character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                if (rng.location == NSNotFound)
                                {
                                    NSLog(@"incomplete coordinates for line drawing command");
                                    goto cleanup;
                                }
                                Lx = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                // remove the x coordinate
                                pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                // remove all whitespace characters up to the first non-whitespace character
                                while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                    pathDefinition = [pathDefinition substringFromIndex:1];
                                // get the range to the next whitespace characters
                                rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                if (rng.location == NSNotFound)
                                {
                                    Ly = [pathDefinition floatValue];
                                    pathDefinition = @"";
                                }
                                else
                                {
                                    Ly = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the y coordinate
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                    // advance to next path command
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                }
                                if (absoluteLineTo)
                                    [bp lineToPoint:NSMakePoint(Lx, Ly)];
                                else
                                    [bp relativeLineToPoint:NSMakePoint(Lx, Ly)];
                                absoluteLineTo = NO;
#ifdef SESDL_DEBUG
                                NSLog(@"Line to %g,%g", Lx, Ly);
#endif
                                break;
                            }
                            case 'C':
                                absoluteCurve = YES;
                            case 'c':
                            {
                                float points[6]; // control points and end point
                                int m;
                                // remove leading C character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // scan all 6 coordinates
                                for (m = 0; m < 6; m++)
                                {
                                    // remove all whitespace characters up to the first non-whitespace character
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                    // get the range to the next whitespace characters
                                    rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                    if (rng.location == NSNotFound)
                                    {
                                        if (m == 5)
                                        {
                                            points[m] = [pathDefinition floatValue];
                                            pathDefinition = @"";
                                            break;
                                        }
                                        NSLog(@"incomplete coordinates for curve drawing command");
                                        goto cleanup;
                                    }
                                    // read the coordinate component
                                    points[m] = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the read portion from the scanned string
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                }
#ifdef SESDL_DEBUG
                                NSLog(@"Curve to point (%g,%g) with control points (%g,%g) and (%g,%g).",
                                      points[4], points[5], points[0], points[1], points[2], points[3]);
#endif
                                if (absoluteCurve)
                                    [bp curveToPoint:NSMakePoint(points[4], points[5])
                                       controlPoint1:NSMakePoint(points[0], points[1])
                                       controlPoint2:NSMakePoint(points[2], points[3])];
                                else
                                    [bp relativeCurveToPoint:NSMakePoint(points[4], points[5])
                                               controlPoint1:NSMakePoint(points[0], points[1])
                                               controlPoint2:NSMakePoint(points[2], points[3])];
                                absoluteCurve = NO;
                                break;
                            }
                            case 'A':
                                absoluteArc = YES;
                            case 'a':
                            {
                                // The arc implementation does not comply to the SVG specification due to
                                // difficulties in translating it to Cocoa's path drawing commands.
                                // For now the arc can not be elliptic, only circular.
                                // The rotation from the X axis is not executed either.
                                // A proper implementation should convert the parameters to
                                // cubic or quadratic bezier path control points and then call
                                // Cocoa drawing commands.
                                float arcParams[7]; // control points and end point
                                int m;
                                // remove leading A character
                                pathDefinition = [pathDefinition substringFromIndex:1];
                                // scan all 7 parameters
                                for (m = 0; m < 7; m++)
                                {
                                    // remove all whitespace characters up to the first non-whitespace character
                                    while ([pathDefinition rangeOfCharacterFromSet:whitespaceCharacters].location == 0)
                                        pathDefinition = [pathDefinition substringFromIndex:1];
                                    // get the range to the next whitespace characters
                                    rng = [pathDefinition rangeOfCharacterFromSet:whitespaceCharacters];
                                    if (rng.location == NSNotFound)
                                    {
                                        if (m == 6)
                                        {
                                            arcParams[m] = [pathDefinition floatValue];
                                            pathDefinition = @"";
                                            break;
                                        }
                                        NSLog(@"incomplete coordinates for arc drawing command");
                                        goto cleanup;
                                    }
                                    // read the coordinate component
                                    arcParams[m] = [[pathDefinition substringWithRange:NSMakeRange(0, rng.location)] floatValue];
                                    // remove the read portion from the scanned string
                                    pathDefinition = [pathDefinition substringFromIndex:(rng.location + 1)];
                                }
                                NSPoint currentPoint = [bp currentPoint];
                                if (absoluteArc)
                                    [bp appendBezierPathWithArcFromPoint:currentPoint
                                                                 toPoint:NSMakePoint(arcParams[5], arcParams[6])
                                                                  radius:arcParams[0]];
                                else
                                    [bp appendBezierPathWithArcFromPoint:[bp currentPoint]
                                                                 toPoint:NSMakePoint(currentPoint.x + arcParams[5],
                                                                                     currentPoint.y + arcParams[6])
                                                                  radius:arcParams[0]];
                                absoluteArc = NO;
                                break;
                            }                                
                        }
                    }
                    
                    if (isClosedPath)
                        [bp closePath];
                    if (isFilledPath)
                        [filledPaths addObject:bp];
                    else
                        [outlinePaths addObject:bp];
                    svgEquivalent = [svgEquivalent stringByAppendingFormat:@"\n<path stroke=\"black\" fill=\"%@\" stroke-width=\"1\" d=\"%@\"/>",
                                  isFilledPath ? @"black" : @"none", svgPath];
                }
            }
        }
    }
    if (!foundConnectionPoints)
        NSLog(@"Warning: Shape definition %@ does not contain connection points.", sesdlFile);
    
    shape = [[MI_PathShape alloc] initWithSize:NSMakeSize(shapeWidth, shapeHeight)];
    shape.connectionPoints = pointMap;
    shape.outlinePaths = [NSArray arrayWithArray:outlinePaths];
    shape.filledPaths = [NSArray arrayWithArray:filledPaths];
    shape.svgEquivalent = svgEquivalent;
    return shape;

    // The file was not parsed successfully. Clean up the objects.
cleanup:
    NSLog(@"Cleaning up.");
    return nil;
}

@end
