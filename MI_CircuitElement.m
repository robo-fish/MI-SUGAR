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
#import "MI_CircuitElement.h"

@implementation MI_CircuitElement

- (instancetype) initWithSize:(NSSize)size;
{
  if (self = [super initWithSize:size])
  {
    _parameters = [[NSMutableDictionary<NSString*,NSString*> alloc] init];
  }
  return self;
}

- (instancetype) init
{
  assert(!"This initializer should not be called.");
}

- (NSString*) quickInfo
{
  /* Overrides parent method by returning the parameter that best gives
  information about the device. For example the resistance value of a
  resistor. Returns nil if there is no suitable value. */
  if ( (self.parameters == nil) || ([self.parameters count] != 1) )
      return nil;
  else
      return [[self.parameters allValues] objectAtIndex:0];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return MI_DeviceModelTypeNone;
}


/******************** NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    self.parameters = [decoder decodeObjectForKey:@"Parameters"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeObject:self.parameters forKey:@"Parameters"];
}

/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
  MI_CircuitElement* myCopy = [super copyWithZone:zone];
  myCopy.parameters = self.parameters;
  return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
  return [self copyWithZone:zone];
}


@end
