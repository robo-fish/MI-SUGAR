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

- (id) init
{
    if (self = [super init])
    {
        parameters = [[NSMutableDictionary alloc] initWithCapacity:3];
    }
    return self;
}


- (NSMutableDictionary*) parameters
{
    return parameters;
}


- (void) setParameters:(NSMutableDictionary*)newParameters
{
    [newParameters retain];
    [parameters release];
    parameters = newParameters;
}


- (NSString*) quickInfo
{
    /* Overrides parent method by returning the parameter that best gives
    information about the device. For example the resistance value of a
    resistor. Returns nil if there is no suitable value. */
    if ( (parameters == nil) || ([parameters count] != 1) )
        return nil;
    else
        return (NSString*)[[parameters allValues] objectAtIndex:0];
}


- (MI_DeviceModelType) usedDeviceModelType
{
    return NO_DEVICE_MODEL_TYPE;
}


/******************** NSCoding methods *******************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        parameters = [[decoder decodeObjectForKey:@"Parameters"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:parameters
                   forKey:@"Parameters"];
}

/******************* NSCopying protocol implementation ******************/

- (id) copyWithZone:(NSZone*) zone
{
    MI_CircuitElement* myCopy = [super copyWithZone:zone];
    myCopy->parameters = nil;
    [myCopy setParameters:[[parameters mutableCopy] autorelease]];
    return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
    return [self copyWithZone:zone];
}

/**************************************************************************/

- (void) dealloc
{
    [parameters release];
    [super dealloc];
}

@end
