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
{
@private
  NSString* _elementID;
  NSString* _connectionPointName;
}

- (instancetype) initWithElement:(NSString*)identifier connectionPoint:(NSString*)pointName
{
  if (self = [super init])
  {
    _elementID = identifier;
    _connectionPointName = pointName;
    _node = -1; // means it's initally unassigned
    _nodeName = nil;
  }
  return self;
}

- (NSString*) elementID
{
  return _elementID;
}

- (NSString*) pointName
{
  return _connectionPointName;
}

/**** NSCoding implementation ***************************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super init])
  {
    _elementID = [decoder decodeObjectForKey:@"ElementID"];
    _connectionPointName = [decoder decodeObjectForKey:@"ConnectionPointName"];
    _node = [decoder decodeIntForKey:@"NodeNumber"];
    _nodeName = [decoder decodeObjectForKey:@"NodeName"];
  }
  return self;
}        

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:_elementID forKey:@"ElementID"];
  [encoder encodeObject:_connectionPointName forKey:@"ConnectionPointName"];
  [encoder encodeInt:_node forKey:@"NodeNumber"];
  [encoder encodeObject:_nodeName forKey:@"NodeName"];
}


@end
