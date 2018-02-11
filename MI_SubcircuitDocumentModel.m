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

@interface MI_SubcircuitDocumentModel ()
@property (readwrite) NSDictionary<NSString*,NSString*>* pinMap;
@end

@implementation MI_SubcircuitDocumentModel
{
@private
  NSMutableSet* subcircuitsUsed;

  NSMutableDictionary* deviceModelsUsed;
}

- (instancetype) initWithCircuitDocumentModel:(CircuitDocumentModel*)model
                                       pinMap:(NSDictionary<NSString*,NSString*>*)pinMap
{
  if (self = [super init])
  {
    self.source = model.source;
    self.schematic = model.schematic;
    self.circuitTitle = model.circuitTitle;
    self.pinMap = pinMap;
    self.shape = nil;
  }
  return self;
}


- (NSUInteger) numberOfPins
{
  return [[_pinMap allKeys] count];
}


- (NSString*) nodeNameForPin:(NSString*)portName
{
  return [_pinMap objectForKey:portName];
}


/******************************************************************/

- (id)initWithCoder:(NSCoder *)decoder
{
  if (self = [super initWithCoder:decoder])
  {
    int version = [decoder decodeIntForKey:@"SubcircuitDocumentModelVersion"];
    self.usedDeviceModels = [decoder decodeObjectForKey:@"DeviceModelsUsed"];
    self.usedSubcircuits = [decoder decodeObjectForKey:@"SubcircuitsUsed"];
    self.shape = [decoder decodeObjectForKey:@"SubcircuitShape"];
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
      if (tmp != nil)
      {
        NSArray* keys = [tmp allKeys];
        NSMutableDictionary* tmpResult = [NSMutableDictionary dictionaryWithCapacity:[keys count]];
        for (NSNumber* currentPinNumber in keys)
        {
          [tmpResult setObject:[tmp objectForKey:currentPinNumber]
                        forKey:[NSString stringWithFormat:@"Pin%d", [currentPinNumber intValue]]];
        }
        _pinMap = [[NSDictionary alloc] initWithDictionary:tmpResult];
      }
    }
    else
      _pinMap = [decoder decodeObjectForKey:@"PinMap"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [super encodeWithCoder:encoder];
  [encoder encodeObject:self.pinMap forKey:@"PinMap"];
  [encoder encodeObject:self.usedDeviceModels forKey:@"DeviceModelsUsed"];
  [encoder encodeObject:self.usedSubcircuits forKey:@"SubcircuitsUsed"];
  [encoder encodeObject:self.shape forKey:@"SubcircuitShape"];
  [encoder encodeInt:SUBCIRCUIT_DOCUMENT_MODEL_VERSION forKey:@"SubcircuitDocumentModelVersion"];
}

@end
