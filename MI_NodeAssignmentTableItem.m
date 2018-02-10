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

#import "MI_NodeAssignmentTableItem.h"

@implementation MI_NodeAssignmentTableItem

- (id) initWithElement:(NSString*)identifier
       connectionPoint:(NSString*)pointName
{
    if (self = [super init])
    {
        elementID = [identifier retain];
        connectionPointName = [pointName retain];
        nodeNumber = -1; // means it's initally unassigned
        nodeName = nil;
    }
    return self;
}

- (NSString*) elementID
{
    return elementID;
}

- (NSString*) pointName
{
    return connectionPointName;
}

- (int) node
{
    return nodeNumber;
}

- (void) setNode:(int)node
{
    nodeNumber = node;
}

- (NSString*) nodeName
{
    if (nodeName == nil)
        return nil;
    else
        return [NSString stringWithString:nodeName];
}

- (void) setNodeName:(NSString*)name
{
    [name retain];
    [nodeName release];
    nodeName = name;
}

/****************************************************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        elementID = [[decoder decodeObjectForKey:@"ElementID"] retain];
        connectionPointName = [[decoder decodeObjectForKey:@"ConnectionPointName"] retain];
        nodeNumber = [decoder decodeIntForKey:@"NodeNumber"];
        nodeName = [[decoder decodeObjectForKey:@"NodeName"] retain];
    }
    return self;
}        

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:elementID
                   forKey:@"ElementID"];
    [encoder encodeObject:connectionPointName
                   forKey:@"ConnectionPointName"];
    [encoder encodeInt:nodeNumber
                forKey:@"NodeNumber"];
    [encoder encodeObject:nodeName
                   forKey:@"NodeName"];
}

/****************************************************/

- (void) dealloc
{
    [elementID release];
    [connectionPointName release];
    [nodeName release];
    [super dealloc];
}

@end
