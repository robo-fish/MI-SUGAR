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
#import <Foundation/Foundation.h>

#define MI_SUGAR_CIRCUIT_ELEMENT_DEVICE_MODEL_VERSION 2

// version 1 -> MI-SUGAR 0.5.2
// version 2 -> MI-SUGAR 0.5.4  -- adds deviceType:


// Used both in circuit element and device model classes to indicate
// the type of device model which is used.
typedef NS_ENUM(NSInteger,MI_DeviceModelType)
{
  MI_DeviceModelTypeNone               = -1,
  MI_DeviceModelTypeFirst              = 0,

  MI_DeviceModelTypeDiode              = 0,
  MI_DeviceModelTypeBJT                = 1,
  MI_DeviceModelTypeJFET               = 2,
  MI_DeviceModelTypeMOSFET             = 3,
  MI_DeviceModelTypeSwitch             = 4,
  MI_DeviceModelTypeTransmissionLine   = 5,

  MI_DeviceModelTypeLast               = 5
};


@interface MI_CircuitElementDeviceModel : NSObject
    <NSCopying, NSMutableCopying, NSCoding, MI_SugarML>
{
  int MI_version; // version of the class
}
- (instancetype) initWithName:(NSString*)theName;
@property (copy) NSString* modelName;
@property (copy) NSString* deviceParameters;

// name of the type of device which this model applies to
// must be overriden by subclasses
- (MI_DeviceModelType) type;

@end


@interface MI_DiodeDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

@interface MI_BJTDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

@interface MI_JFETDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

// since 0.5.4
@interface MI_MOSDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

// Legacy class - deprecated as of 0.5.4
@interface MI_BSIM3_MOSDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

// Legacy class - deprecated as of 0.5.4
@interface MI_BSIM4_NMOSDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

// Legacy class - deprecated as of 0.5.4
@interface MI_BSIM4_PMOSDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

@interface MI_SwitchDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

@interface MI_TransmissionLineDeviceModel : MI_CircuitElementDeviceModel
{
}
@end

