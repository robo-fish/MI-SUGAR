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


@interface MI_DCVoltageSourceElement : MI_CircuitElement
{
}
@end

@interface MI_ACVoltageSourceElement : MI_CircuitElement
{
}
@end

@interface MI_PulseVoltageSourceElement : MI_CircuitElement
{
}
@end

@interface MI_SinusoidalVoltageSourceElement : MI_CircuitElement
{
}
@end

@interface MI_CurrentSourceElement : MI_CircuitElement
{
}
@end

@interface MI_PulseCurrentSourceElement : MI_CircuitElement
{
}
@end

/************************ Linear Dependent Power Sources ********/

@interface MI_VoltageControlledCurrentSource : MI_CircuitElement
{
}
@end

@interface MI_VoltageControlledVoltageSource : MI_CircuitElement
{
}
@end

@interface MI_CurrentControlledCurrentSource : MI_CircuitElement
{
}
@end

@interface MI_CurrentControlledVoltageSource : MI_CircuitElement
{
}
@end

/************************ Non-linear Dependent Power Source ********/

@interface MI_NonlinearDependentSource : MI_CircuitElement
{
}
@end
