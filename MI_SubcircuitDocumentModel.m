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
#import "MI_SubcircuitDocumentModel.h"

#define SUBCIRCUIT_DOCUMENT_MODEL_VERSION 1
// Version History
// 0 -> up to and including 0.5.6
// 1 -> 0.5.7


@implementation MI_SubcircuitDocumentModel

- (id) initWithCircuitDocumentModel:(CircuitDocumentModel*)model
                             pinMap:(NSDictionary*)pinMap
{
    if (self = [super init])
    {
        [source setString:[model source]];
        [self setSchematic:[model schematic]];
        title = [[model circuitTitle] retain];
        pinToNodeNameMap = [pinMap retain];
        subcircuitsUsed = [[NSMutableSet alloc] initWithCapacity:10];
        deviceModelsUsed = [[NSMutableDictionary alloc] initWithCapacity:10];
        shape = nil;
    }
    return self;
}


- (int) numberOfPins
{
    return [[pinToNodeNameMap allKeys] count];
}


- (NSString*) nodeNameForPin:(NSString*)portName
{
    return [pinToNodeNameMap objectForKey:portName];
}


- (NSDictionary*) pinMap
{
    // Note: The values in the returned dictionary are the originals, not copies.
    return [NSDictionary dictionaryWithDictionary:pinToNodeNameMap];
}


- (NSSet*) subcircuitsUsed
{
    return [NSSet setWithSet:subcircuitsUsed];
}


- (NSDictionary*) deviceModelsUsed
{
    return [NSDictionary dictionaryWithDictionary:deviceModelsUsed];
}


- (void) setUsedSubcircuits:(NSSet*)newUsedSubcircuits
{
    [subcircuitsUsed setSet:newUsedSubcircuits];
}


- (void) setUsedDeviceModels:(NSDictionary*)newUsedDeviceModels
{
    [deviceModelsUsed setDictionary:newUsedDeviceModels];
}


- (MI_Shape*) shape
{
    return shape;
}


- (void) setShape:(MI_Shape*)newShape
{
    [newShape retain];
    [shape release];
    shape = newShape;
}


/******************************************************************/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super initWithCoder:decoder])
    {
        int version = [decoder decodeIntForKey:@"SubcircuitDocumentModelVersion"];
        deviceModelsUsed = [[decoder decodeObjectForKey:@"DeviceModelsUsed"] retain];
        subcircuitsUsed = [[decoder decodeObjectForKey:@"SubcircuitsUsed"] retain];
        shape = [[decoder decodeObjectForKey:@"SubcircuitShape"] retain];
        if (version == 0)
        {
            // For version 0 of this class the pinToNodeNameMap dictionary
            // was mapping NSNumber objects to named nodes because only DIP
            // shaped subcircuits were available and it made sense to use
            // pin numbering. Starting with version 0.5.7 the external ports
            // assigned names, not numbers. This block converts the mapping
            // of old files on the fly by assign the name "PinX" to an
            // external port, where X is the number of the pin.
            NSDictionary* tmp = [decoder decodeObjectForKey:@"PinMap"];
            NSArray* keys = [tmp allKeys];
            NSMutableDictionary* tmpResult = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
            NSEnumerator* keyEnum = [keys objectEnumerator];
            NSNumber* currentPinNumber;
            while (currentPinNumber = [keyEnum nextObject])
            {
                [tmpResult setObject:[tmp objectForKey:currentPinNumber]
                              forKey:[NSString stringWithFormat:@"Pin%d", [currentPinNumber intValue]]];
            }
            pinToNodeNameMap = [[NSDictionary alloc] initWithDictionary:tmpResult];
        }
        else
            pinToNodeNameMap = [[decoder decodeObjectForKey:@"PinMap"] retain];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:pinToNodeNameMap
                   forKey:@"PinMap"];
    [encoder encodeObject:deviceModelsUsed
                   forKey:@"DeviceModelsUsed"];
    [encoder encodeObject:subcircuitsUsed
                   forKey:@"SubcircuitsUsed"];
    [encoder encodeObject:shape
                   forKey:@"SubcircuitShape"];
    [encoder encodeInt:SUBCIRCUIT_DOCUMENT_MODEL_VERSION
                forKey:@"SubcircuitDocumentModelVersion"];
}

/******************************************************************/

- (void) dealloc
{
    [pinToNodeNameMap release];
    [subcircuitsUsed release];
    [deviceModelsUsed release];
    [shape release];
    [super dealloc];
}

@end
