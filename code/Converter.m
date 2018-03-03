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
#import "Converter.h"
#import "AnalysisVariable.h"
#import "MI_MiscellaneousElements.h"
#import "MI_NonlinearElements.h"
#import "MI_PowerSourceElements.h"
#import "MI_LinearElements.h"
#import "MI_SubcircuitElement.h"
#import "SugarManager.h"
#import "MI_DeviceModelManager.h"
#import "MI_NodeAssignmentTableItem.h"
#import "MI_SubcircuitDocumentModel.h"

#include <math.h>

NSString* MATHML_PREAMBLE = @"<math xmlns='http://www.w3.org/1998/Math/MathML'>";
NSString* MATHML_ENDING = @"</math>";

#define EPSILON 0.00000000000000000000000000000000001 // for IBM PowerPC 740FX (a.k.a G3 of iBook 2002/2003)

@implementation Converter

+ (NSString*) resultsToMathML:(ResultsTable*)results
{
    NSMutableString* output = [[NSMutableString alloc] initWithCapacity:128];
    
    [output appendFormat:@"%@\n", MATHML_PREAMBLE];
    NSUInteger varLimit = [results numberOfVariables];
    for (int currentVar =  0; currentVar < varLimit; currentVar++)
    {
        AnalysisVariable* avar = [results variableAtIndex:currentVar];
        BOOL const complex = [avar isComplex];
        NSUInteger const numberOfValues = [avar numberOfValuesPerSet];
        [output appendFormat:@"<mrow>\n\t<ci>%@</ci>\n\t<mo>=</mo>\n",
            [Converter convertVariableName:[avar name]
                                  toMathML:YES]];
        
        NSUInteger const setLimit = [avar numberOfSets];
        if (setLimit > 1) [output appendFormat:@"\t<matrix>\n"];
        for (int currentSet =  0; currentSet < setLimit; currentSet++)
        {
            [output appendString: ((setLimit == 1) ? @"\t<vector>\n" : @"\t<matrixrow>\n")];
            for (int currentValue = 0; currentValue < numberOfValues; currentValue++)
            {
                if (complex)
                {
                    MI_ComplexNumber* cn = [avar complexValueAtIndex:currentValue
                                                              forSet:currentSet];
                                            
                    [output appendFormat:@"\t\t<apply><plus/>%@<apply><times/>%@<imaginaryi/></apply></apply>\n",
                            [self convertFloatingPointToMathML:[cn real]],
                            [self convertFloatingPointToMathML:[cn imaginary]]];
                }
                else
                {
                    double val = [avar valueAtIndex:currentValue
                                                forSet:currentSet];
                    [output appendFormat:@"\t\t%@\n", [self convertFloatingPointToMathML:val]];
                }
            }
            [output appendString: ((setLimit == 1) ? @"\t</vector>\n" : @"\t</matrixrow>\n")];
        }
        if (setLimit > 1) [output appendString:@"\t</matrix>\n"];

        [output appendString:@"</mrow>\n"];
    }
    [output appendString:MATHML_ENDING];
    return output;
}


+ (NSString*) convertFloatingPointToMathML:(double)number
{
    int exponent;
    double mantissa;

    if (fabs(number) > 100 || (fabs(number) < 0.01 && number > EPSILON))
    {
        exponent = (int) floor(log10(fabs(number)));
        mantissa = number/ pow(10, exponent);
        if (number < 0)
            mantissa = -mantissa;
        return [NSString stringWithFormat:@"<apply><times/><cn>%1.12f</cn><apply><power/><cn>10</cn><cn>%d</cn></apply></apply>",
            mantissa, exponent];
    }
    else
        return [NSString stringWithFormat:@"<cn>%.12f</cn>", number];
}


+ (NSString*) resultsToMatlab:(ResultsTable*)results
{
    NSUInteger currentVar;
    NSUInteger setLimit;
    int currentValue;
    BOOL complex;
    MI_ComplexNumber* cn;
    AnalysisVariable* avar;
    NSMutableString* output = [[NSMutableString alloc] initWithCapacity:128];
    NSUInteger const varLimit = [results numberOfVariables];
    for (currentVar = 0; currentVar < varLimit; currentVar++)
    {
        avar = [results variableAtIndex:(int)currentVar];
        complex = [avar isComplex];
        NSUInteger const numberOfValues = [avar numberOfValuesPerSet];

        [output appendFormat:@"%@ = [", [Converter convertVariableName:[avar name]
                                                              toMathML:NO]];
        setLimit = [avar numberOfSets];
        for (NSUInteger currentSet = 0; currentSet < setLimit; currentSet++)
        {
                for (currentValue = 0; currentValue < numberOfValues; currentValue++)
                    if (complex)
                    {
                        cn = [avar complexValueAtIndex:currentValue forSet:(int)currentSet];
                        [output appendFormat:@"%.12G + %.12Gi, ", [cn real], [cn imaginary]];
                    }
                    else
                        [output appendFormat:@"%.12G ", [avar valueAtIndex:currentValue forSet:(int)currentSet]];
                if ( currentSet < (setLimit - 1) )
                    [output appendString:@"; "]; // starts new row of the matrix
        }
        [output appendString:@"];\n"];
    }
    return output;
}


+ (NSString*) convertVariableName:(NSString*)spiceName
                         toMathML:(BOOL)mathml
{
    // Check for paranthesis
    NSMutableString* newName = [NSMutableString stringWithString:spiceName];
    for (int i = (int)[newName length] - 1; i >= 0; i--)
    {
        unichar const currentChar = [newName characterAtIndex:i];
        if ( (currentChar == '#') ||
             (currentChar == '(') ||
             (currentChar == '-') )
            [newName replaceCharactersInRange:NSMakeRange(i, 1)
                                   withString:(mathml ? @"$" : @"_")];
        else if (currentChar == ')')
            [newName deleteCharactersInRange:NSMakeRange(i, 1)];            
    }
    return newName;
}


+ (NSString*) resultsToTabularText:(ResultsTable*)results
{
    NSUInteger currentVar, varLimit;
    NSUInteger currentSet, setLimit;
    int currentValue;
    MI_ComplexNumber* cn;
    AnalysisVariable* avar;
    NSMutableString* output = [[NSMutableString alloc] initWithCapacity:128];
    
    varLimit = [results numberOfVariables];
    setLimit = [[results variableAtIndex:0] numberOfSets];
    NSUInteger const numberOfValues = [[results variableAtIndex:0] numberOfValuesPerSet];

    // First write a header, which lists the names of the variables
    for (currentVar = 0; currentVar < varLimit; currentVar++)
    {
        [output appendString:[[results variableAtIndex:(int)currentVar] name]];
        [output appendString:(currentVar == (varLimit - 1)) ? @"\n" : @"\t"];
    }

    for (currentSet = 0; currentSet < setLimit; currentSet++)
    {
        // Separate sets with newline
        [output appendString:@"\n"];
        
        // Write the values, row by row
        for (currentValue = 0; currentValue < numberOfValues; currentValue++)
        {
            for (currentVar = 0; currentVar < varLimit; currentVar++)
            {
                avar = [results variableAtIndex:(int)currentVar];
                if ([avar isComplex])
                {
                    cn = [avar complexValueAtIndex:currentValue forSet:(int)currentSet];
                    [output appendFormat:@"%g %g", [cn real], [cn imaginary]];
                }
                else
                {
                    [output appendFormat:@"%g", [avar valueAtIndex:currentValue forSet:(int)currentSet]];
                }
                if (currentVar < varLimit - 1)
                    [output appendString:@"\t"];
                else
                    [output appendString:@"\n"];
            }
        }
    }
        
    return output;
}


// Iterative function for collecting all connection points that
// are electrically connected. Used by schematicToNetlistCore().
void collectEquivalentPoints(NSMutableArray* nodeAssignmentSubtable,
                             MI_ElementConnector* connector);

// Iterative function for collecting device models and
// the names of subcircuits used in a subcircuit.
void collectSubcircuitsAndDeviceModels(NSMutableDictionary* modelDB,
                                       NSMutableSet* subcircuitNames,
                                       MI_SubcircuitDocumentModel* subckt);

// convenience function for schematicToNetlist - return value of -1 means not found or not connected
NSString* nodeForConnectionPoint(NSString* connectionPointName, NSString* elementID, NSArray* nodeTable);

enum deviceModelType { D, LTRA, NPN, PNP, NJF, PJF, NMOS, PMOS, SW };

static MI_CircuitSchematic* theCircuit = nil;


// Performs the schematic-to-netlist conversion. If the given circuit
// is a subcircuit then the used models and subcircuits are not expanded.
// Otherwise, if the circuit is a plain circuit the models and subcircuit
// definitions used throughout are expanded at the end of the netlist.
NSString* schematicToNetlistCore(CircuitDocumentModel* circuit)
{
    NSMutableString* netlist = [NSMutableString stringWithCapacity:300];            // the result
    NSMutableDictionary* models = [NSMutableDictionary dictionaryWithCapacity:5];   // keys: the device model names, values: the type identifier number
    NSMutableSet* subcircuits = [NSMutableSet setWithCapacity:10];                  // the fully qualified names of the subcircuits used throughout
    NSString* model;
    NSMutableArray* globalNodeTable = [NSMutableArray arrayWithCapacity:100];
    NSMutableArray* equivalentPoints = nil;
    NSEnumerator* elementEnum = [[circuit schematic] elementEnumerator];
    MI_CircuitElement* currentElement = nil;
    NSEnumerator* connectorEnum = [[circuit schematic] connectorEnumerator];
    MI_ElementConnector* currentConnector;
    NSEnumerator* pointEnum = nil;
    MI_ConnectionPoint* currentPoint = nil;
    MI_SchematicElement* collectedElement;
    NSEnumerator *tmpPointEnum1, *tmpPointEnum2;
    MI_NodeAssignmentTableItem *currentItem1, *currentItem2;
    theCircuit = (MI_CircuitSchematic*) [circuit schematic];
    int nodeNumber = 1;
    BOOL foundGround;
    BOOL foundNamedNodeElement; // used in assignment of names instead of node numbers
    NSString* lastNodeElementName = nil; // the name of the last encountered node element with a name
    

    // PREPARATION
    // Construct a table, which shows the node assigned to each connection point
    while (currentElement = [elementEnum nextObject])
    {
        pointEnum = [[currentElement connectionPoints] objectEnumerator];
        while (currentPoint = [pointEnum nextObject])
            [globalNodeTable addObject:[[MI_NodeAssignmentTableItem alloc]
                initWithElement:[currentElement identifier]
                connectionPoint:[currentPoint name]]];
    }

    // Set all connectors to nontraversed
    while (currentConnector = [connectorEnum nextObject])
        [currentConnector setTraversed:NO];

    // ASSIGN NODE NUMBERS
    /* Traverse all connectors, find electrically equivalent points,
        assign node numbers and mark traversed paths */
    connectorEnum = [theCircuit connectorEnumerator];
    equivalentPoints = [[NSMutableArray alloc] initWithCapacity:10];
    while (currentConnector = [connectorEnum nextObject])
    {
        // Check if that connector is already traversed and skip to next connector if that's the case
        if ( [currentConnector hasBeenTraversed] )
            continue;

        // Create temporary table for search results
        [equivalentPoints removeAllObjects];
        foundGround = NO;
        foundNamedNodeElement = NO;
        // Perform iterative network search and collect all electrically equivalent connection points
        collectEquivalentPoints(equivalentPoints, currentConnector);
        // Check if a Ground element is included and if the collection contains a node element with a name
        tmpPointEnum1 = [equivalentPoints objectEnumerator];
        while ( currentItem1 = [tmpPointEnum1 nextObject] )
        {
            collectedElement = [theCircuit elementForIdentifier:[currentItem1 elementID]];
            if ( [collectedElement isKindOfClass:[MI_GroundElement class]] ||
                 [collectedElement isKindOfClass:[MI_PlainGroundElement class]] )
                foundGround = YES;
            if ( [collectedElement conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)] &&
                 [[collectedElement label] length] > 0)
            {
                foundNamedNodeElement = YES;
                lastNodeElementName = [collectedElement label];
            }
        }
        // Pick out those points from the global table which are contained in the equivalent points list
        // For each of these points check if a node number has already been assigned (shouldn't be)
        // Assign either 0 (if ground element was found) or the next unused node number or a node name
        tmpPointEnum2 = [globalNodeTable objectEnumerator];
        while (currentItem2 = [tmpPointEnum2 nextObject])
        {
            tmpPointEnum1 = [equivalentPoints objectEnumerator];
            while ( currentItem1 = [tmpPointEnum1 nextObject] )
            {
                if ([[currentItem1 elementID] isEqualToString:[currentItem2 elementID]] &&
                    [[currentItem1 pointName] isEqualToString:[currentItem2 pointName]] &&
                    ([currentItem2 node] == -1) )
                {
                    if (foundGround)
                        [currentItem2 setNode:0];
                    else if (!foundNamedNodeElement)
                        [currentItem2 setNode:nodeNumber];
                    else
                        [currentItem2 setNodeName:lastNodeElementName];
                }
            }
        }
        if (!foundGround && !foundNamedNodeElement)
            nodeNumber++;
    }
        
    // Set the node assignment table of the circuit so the node numbers can be displayed in the schematic
    [theCircuit setNodeAssignmentTable:globalNodeTable];

    /* DEBUG
    tmpPointEnum1 = [globalNodeTable objectEnumerator];
    while (currentItem1 = [tmpPointEnum1 nextObject])
        [netlist appendFormat:@"%@ %@\t---> %d\n",
            [[theCircuit elementForIdentifier:[currentItem1 elementID]] description],
            [currentItem1 pointName], [currentItem1 node]]];
    */
    
    // CONSTRUCT NETLIST LINES FOR EACH ELEMENT
    /* Skip node elements */
    /* Elements may have different netlist representation styles */
    /* Make a list of all used device models and append model data to end */
    elementEnum = [theCircuit elementEnumerator];
    while (currentElement = [elementEnum nextObject])
    {
        if ([currentElement conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)] ||
            [currentElement conformsToProtocol:@protocol(MI_ElectricallyGroundedElement)] )
            continue;
        if ([currentElement isKindOfClass:[MI_Resistor_US_Element class]] ||
            [currentElement isKindOfClass:[MI_Resistor_IEC_Element class]] ||
            [currentElement isKindOfClass:[MI_Rheostat_US_Element class]] ||
            [currentElement isKindOfClass:[MI_Rheostat_IEC_Element class]])
        {
            if (![[currentElement label] hasPrefix:@"R"])
                [netlist appendString:@"R"];
            [netlist appendFormat:@"%@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"A", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"B", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Resistance"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_Inductor_US_Element class]] ||
                 [currentElement isKindOfClass:[MI_Inductor_IEC_Element class]] )
        {
            if (![[currentElement label] hasPrefix:@"L"])
                [netlist appendString:@"L"];
            [netlist appendFormat:@"%@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"A", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"B", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Inductance"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_CapacitorElement class]] ||
                 [currentElement isKindOfClass:[MI_PolarizedCapacitorElement class]] )
        {
            if (![[currentElement label] hasPrefix:@"C"])
                [netlist appendString:@"C"];
            [netlist appendFormat:@"%@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"A", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"B", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Capacitance"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_Transformer_IEC_Element class]] ||
                 [currentElement isKindOfClass:[MI_Transformer_US_Element class]] )
        {
            float coupling = [[[currentElement parameters] objectForKey:@"Coupling"] floatValue];
            [netlist appendFormat:@"%@ %@ %@ %@\n%@ %@ %@ %@\nK%@ %@ %@ %@\n",
                [[@"L" stringByAppendingString:[currentElement label]] stringByAppendingString:@"1"],
                nodeForConnectionPoint(@"L11", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"L12", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Inductance 1"],
                [[@"L" stringByAppendingString:[currentElement label]] stringByAppendingString:@"2"],
                nodeForConnectionPoint((coupling < 0.0f) ? @"L22" : @"L21", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint((coupling < 0.0f) ? @"L21" : @"L22", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Inductance 2"],
                [currentElement label],
                [[@"L" stringByAppendingString:[currentElement label]] stringByAppendingString:@"1"],
                [[@"L" stringByAppendingString:[currentElement label]] stringByAppendingString:@"2"],
                [[currentElement parameters] objectForKey:@"Coupling"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_TransmissionLineElement class]])
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"O"])
                [netlist appendString:@"O"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"A1", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"A2", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"B1", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"B2", [currentElement identifier], globalNodeTable),
                model
            ];
            [models setObject:[NSNumber numberWithInt:LTRA] forKey:model];
        }
        else if ([currentElement isKindOfClass:[MI_DiodeElement class]] ||
                 [currentElement isKindOfClass:[MI_ZenerDiodeElement class]] ||
                 [currentElement isKindOfClass:[MI_LightEmittingDiodeElement class]] ||
                 [currentElement isKindOfClass:[MI_PhotoDiodeElement class]] )
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"D"])
                [netlist appendString:@"D"];
            [netlist appendFormat:@"%@ %@ %@ %@ ",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                model
            ];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Area Factor"] length] > 0)
                [netlist appendString:[[currentElement parameters] objectForKey:@"Area Factor"]];
            if ([[(NSString*)[[currentElement parameters] objectForKey:@"DC Initial State"] uppercaseString] isEqualToString:@"OFF"])
                [netlist appendString:@" OFF"];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Op. Temperature"] length] > 0)
                [netlist appendFormat:@" TEMP=%@", [[currentElement parameters] objectForKey:@"Op. Temperature"]];
            [netlist appendString:@"\n"];
            [models setObject:[NSNumber numberWithInt:D] forKey:model];
        }
        else if ([currentElement isKindOfClass:[MI_NPNTransistorElement class]] ||
                 [currentElement isKindOfClass:[MI_PNPTransistorElement class]] )
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"Q"])
                [netlist appendString:@"Q"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ ",
                [currentElement label],
                nodeForConnectionPoint(@"Collector", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Base", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Emitter", [currentElement identifier], globalNodeTable),
                model
            ];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Area Factor"] length] > 0)
                [netlist appendString:[[currentElement parameters] objectForKey:@"Area Factor"]];
            if ([[(NSString*)[[currentElement parameters] objectForKey:@"DC Initial State"] uppercaseString] isEqualToString:@"OFF"])
                [netlist appendString:@" OFF"];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Op. Temperature"] length] > 0)
                [netlist appendFormat:@" TEMP=%@", [[currentElement parameters] objectForKey:@"Op. Temperature"]];
            [netlist appendString:@"\n"];
            [models setObject:[NSNumber numberWithInt:([currentElement isKindOfClass:[MI_NPNTransistorElement class]] ? NPN : PNP)] forKey:model];
        }
        else if ([currentElement isKindOfClass:[MI_NJFETTransistorElement class]] ||
                 [currentElement isKindOfClass:[MI_PJFETTransistorElement class]] )
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"J"])
                [netlist appendString:@"J"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ ",
                [currentElement label],
                nodeForConnectionPoint(@"Drain", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Gate", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Source", [currentElement identifier], globalNodeTable),
                model
            ];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Area Factor"] length] > 0)
                [netlist appendString:[[currentElement parameters] objectForKey:@"Area Factor"]];
            if ([[(NSString*)[[currentElement parameters] objectForKey:@"DC Initial State"] uppercaseString] isEqualToString:@"OFF"])
                [netlist appendString:@" OFF"];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"Op. Temperature"] length] > 0)
                [netlist appendFormat:@" TEMP=%@", [[currentElement parameters] objectForKey:@"Op. Temperature"]];
            [netlist appendString:@"\n"];
            [models setObject:[NSNumber numberWithInt:([currentElement isKindOfClass:[MI_NJFETTransistorElement class]]) ? NJF : PJF] forKey:model];
        }
        else if ([currentElement conformsToProtocol:@protocol(MI_MOSFET_Element)])
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"M"])
                [netlist appendString:@"M"];
            NSString* fourthConnector;
            if ([currentElement conformsToProtocol:@protocol(MI_MOSFETWithBulkConnector)])
                fourthConnector = @"Bulk";
            else
                fourthConnector = @"Source";
            [netlist appendFormat:@"%@ %@ %@ %@ %@ %@",
                [currentElement label],
                nodeForConnectionPoint(@"Drain", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Gate", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Source", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(fourthConnector, [currentElement identifier], globalNodeTable),
                model
            ];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"L"] length] > 0)
                [netlist appendFormat:@" L=%@", [[currentElement parameters] objectForKey:@"L"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"W"] length] > 0)
                [netlist appendFormat:@" W=%@", [[currentElement parameters] objectForKey:@"W"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"AD"] length] > 0)
                [netlist appendFormat:@" AD=%@", [[currentElement parameters] objectForKey:@"AD"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"AS"] length] > 0)
                [netlist appendFormat:@" AS=%@", [[currentElement parameters] objectForKey:@"AS"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"PD"] length] > 0)
                [netlist appendFormat:@" PD=%@", [[currentElement parameters] objectForKey:@"PD"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"PS"] length] > 0)
                [netlist appendFormat:@" PS=%@", [[currentElement parameters] objectForKey:@"PS"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"NRD"] length] > 0)
                [netlist appendFormat:@" NRD=%@", [[currentElement parameters] objectForKey:@"NRD"]];
            if ([(NSString*)[[currentElement parameters] objectForKey:@"NRS"] length] > 0)
                [netlist appendFormat:@" NRS=%@", [[currentElement parameters] objectForKey:@"NRS"]];
            // The TEMP option is only valid for level 1, 2 and 3 MOSFETs. We omit it to avoid problems.
            //if ([(NSString*)[[currentElement parameters] objectForKey:@"TEMP"] length] > 0)
            //    [netlist appendFormat:@" TEMP=%@", [[currentElement parameters] objectForKey:@"TEMP"]];
            [netlist appendString:@"\n"];
            [models setObject:[NSNumber numberWithInt:([currentElement conformsToProtocol:@protocol(MI_NMOS_Element)] ? NMOS : PMOS)] forKey:model];
        }
        else if ([currentElement isKindOfClass:[MI_VoltageControlledSwitchElement class]])
        {
            model = [[currentElement parameters] objectForKey:@"Model"];
            assert(model != nil);
            if (![[currentElement label] hasPrefix:@"S"])
                [netlist appendString:@"S"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"Terminal1", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Terminal2", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"ControlPlus", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"ControlMinus", [currentElement identifier], globalNodeTable),
                model,
                [[(NSString*)[[currentElement parameters] objectForKey:@"DC Initial State"] uppercaseString]
                    isEqualToString:@"OFF"] ? @"OFF" : @"ON"
            ];
            [models setObject:[NSNumber numberWithInt:SW] forKey:model];
        }
        else if ([currentElement isKindOfClass:[MI_DCVoltageSourceElement class]])
        {
            if (![[currentElement label] hasPrefix:@"V"])
                [netlist appendString:@"V"];
            [netlist appendFormat:@"%@ %@ %@ DC %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Voltage"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_ACVoltageSourceElement class]])
        {
            if (![[currentElement label] hasPrefix:@"V"])
                [netlist appendString:@"V"];
            [netlist appendFormat:@"%@ %@ %@ AC %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Magnitude"],
                [[currentElement parameters] objectForKey:@"Phase"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_PulseVoltageSourceElement class]] ||
                 [currentElement isKindOfClass:[MI_PulseCurrentSourceElement class]])
        {
            BOOL currentsource = [currentElement isKindOfClass:[MI_PulseCurrentSourceElement class]];
            if (![[currentElement label] hasPrefix:(currentsource ? @"I" : @"V")])
                [netlist appendString:(currentsource ? @"I" : @"V")];
            [netlist appendFormat:@"%@ %@ %@ PULSE(%@ %@ %@ %@ %@ %@ %@)\n",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Initial Value"],
                [[currentElement parameters] objectForKey:@"Pulsed Value"],
                [[currentElement parameters] objectForKey:@"Delay Time"],
                [[currentElement parameters] objectForKey:@"Rise Time"],
                [[currentElement parameters] objectForKey:@"Fall Time"],
                [[currentElement parameters] objectForKey:@"Pulse Width"],
                [[currentElement parameters] objectForKey:@"Period"]
                ];
        }
        else if ([currentElement isKindOfClass:[MI_SinusoidalVoltageSourceElement class]])
        {
            if (![[currentElement label] hasPrefix:@"V"])
                [netlist appendString:@"V"];
            [netlist appendFormat:@"%@ %@ %@ SIN(%@ %@ %@ %@ %@)\n",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Offset"],
                [[currentElement parameters] objectForKey:@"Amplitude"],
                [[currentElement parameters] objectForKey:@"Frequency"],
                [[currentElement parameters] objectForKey:@"Delay"],
                [[currentElement parameters] objectForKey:@"Damping Factor"]
                ];
        }
        else if ([currentElement isKindOfClass:[MI_CurrentSourceElement class]])
        {
            if (![[currentElement label] hasPrefix:@"I"])
                [netlist appendString:@"I"];
            [netlist appendFormat:@"%@ %@ %@ DC %@ AC %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"Anode", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"Cathode", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"DC_Current"],
                [[currentElement parameters] objectForKey:@"AC_Magnitude"],
                [[currentElement parameters] objectForKey:@"AC_Phase"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_VoltageControlledCurrentSource class]])
        {
            if (![[currentElement label] hasPrefix:@"G"])
                [netlist appendString:@"G"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"N+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"N-", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"NC+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"NC-", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Transconductance"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_VoltageControlledVoltageSource class]])
        {
            if (![[currentElement label] hasPrefix:@"E"])
                [netlist appendString:@"E"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"N+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"N-", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"NC+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"NC-", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Gain"]
            ];
        }
        else if ([currentElement isKindOfClass:[MI_CurrentControlledCurrentSource class]])
        {
            if (![[currentElement label] hasPrefix:@"F"])
                [netlist appendString:@"F"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"N+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"N-", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"VNAM"],
                [[currentElement parameters] objectForKey:@"Gain"]
            ];            
        }
        else if ([currentElement isKindOfClass:[MI_CurrentControlledVoltageSource class]])
        {
            if (![[currentElement label] hasPrefix:@"H"])
                [netlist appendString:@"H"];
            [netlist appendFormat:@"%@ %@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"N+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"N-", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"VNAM"],
                [[currentElement parameters] objectForKey:@"Transresistance"]
            ];            
        }
        else if ([currentElement isKindOfClass:[MI_NonlinearDependentSource class]])
        {
            if (![[currentElement label] hasPrefix:@"B"])
                [netlist appendString:@"B"];
            [netlist appendFormat:@"%@ %@ %@ %@\n",
                [currentElement label],
                nodeForConnectionPoint(@"N+", [currentElement identifier], globalNodeTable),
                nodeForConnectionPoint(@"N-", [currentElement identifier], globalNodeTable),
                [[currentElement parameters] objectForKey:@"Expression"]
            ];            
        }
        else if ([currentElement isKindOfClass:[MI_SubcircuitElement class]])
        {
            MI_SubcircuitElement* cElement = (MI_SubcircuitElement*) currentElement;
            NSDictionary* mapping = [[cElement definition] pinMap];
            NSEnumerator* portNameEnum = [[mapping allKeys] objectEnumerator];
            NSString* currentPortName;
            NSString* connectedNode;
            if (![[cElement label] hasPrefix:@"X"])
                [netlist appendString:@"X"];
            [netlist appendString:[cElement label]];
            while (currentPortName = [portNameEnum nextObject])
            {
                connectedNode = [mapping objectForKey:currentPortName];
                if ([connectedNode length] > 0)
                    [netlist appendFormat:@" %@", nodeForConnectionPoint(
                        currentPortName, [cElement identifier], globalNodeTable)];
            }
            NSString* fullyQualifiedName = [[cElement definition] fullyQualifiedCircuitName];
            [netlist appendFormat:@" %@\n", fullyQualifiedName];
            [subcircuits addObject:fullyQualifiedName];
        }
    }

    
    if ([circuit isKindOfClass:[MI_SubcircuitDocumentModel class]])
    {
        if ([subcircuits count] > 0)
        {
            // Set the list of names of used subcircuits
            [((MI_SubcircuitDocumentModel*) circuit) setUsedSubcircuits:subcircuits];
        }
        if ([models count] > 0)
        {
            // Set the list of used models
            [((MI_SubcircuitDocumentModel*) circuit) setUsedDeviceModels:models];
        }
    }
    else // this is not a subcircuit
    {
        MI_SubcircuitLibraryManager* subcktLib =
            [[SugarManager sharedManager] subcircuitLibraryManager];
        NSEnumerator* subcktEnum = [subcircuits objectEnumerator];
        NSString* currentSubckt;

        // Find the total list of used subcircuits and models
        NSMutableSet* subSubcircuitSet = [NSMutableSet setWithCapacity:10];
        while (currentSubckt = [subcktEnum nextObject])
            collectSubcircuitsAndDeviceModels(models, subSubcircuitSet,
                [subcktLib modelForSubcircuitName:currentSubckt]);
        [subcircuits unionSet:subSubcircuitSet]; // merge top-level subcircuit list with list of sub-subcircuits
        
        // Append all subcircuit definitions to the netlist
        if ([subcircuits count] > 0)
        {
            subcktEnum = [subcircuits objectEnumerator];
            while (currentSubckt = [subcktEnum nextObject])
                [netlist appendString:[[subcktLib modelForSubcircuitName:currentSubckt] source]];
        }
        
        // Append all device models to the netlist
        if ([models count] > 0)
        {
            NSString* deviceParameters;
            NSEnumerator* modelEnum = [models keyEnumerator];
            while (model = [modelEnum nextObject])
            {
                switch ([[models objectForKey:model] intValue])
                {
                    case D: [netlist appendFormat:@".MODEL %@ D (\n", model]; break;
                    case NMOS: [netlist appendFormat:@".MODEL %@ NMOS (\n", model]; break;
                    case PMOS: [netlist appendFormat:@".MODEL %@ PMOS (\n", model]; break;
                    case SW: [netlist appendFormat:@".MODEL %@ SW (\n", model]; break;
                    case NPN: [netlist appendFormat:@".MODEL %@ NPN (\n", model]; break;
                    case PNP: [netlist appendFormat:@".MODEL %@ PNP (\n", model]; break;
                    case NJF: [netlist appendFormat:@".MODEL %@ NJF (\n", model]; break;
                    case PJF: [netlist appendFormat:@".MODEL %@ PJF (\n", model]; break;
                    case LTRA: [netlist appendFormat:@".model %@ LTRA (\n", model]; break;
                }
                deviceParameters = [[MI_DeviceModelManager sharedManager] deviceParametersForModelName:model];
                // Check if the parameter list ends with a newline character
                if (![deviceParameters hasSuffix:@"\n"])
                    deviceParameters = [deviceParameters stringByAppendingString:@"\n"];
                [netlist appendFormat:@"%@+)\n", deviceParameters];
            }
        }
    }
    

    theCircuit = nil;
    return [NSString stringWithString:netlist];
}


+ (NSString*) schematicToNetlist:(CircuitDocumentModel*)circuit
{
    if ([circuit isKindOfClass:[MI_SubcircuitDocumentModel class]])
    {
        MI_SubcircuitDocumentModel* subcircuit = (MI_SubcircuitDocumentModel*) circuit;
        NSMutableString* subcktList = [NSMutableString stringWithCapacity:200];
        NSString* tmp;
        NSEnumerator* portNameEnum = [[[subcircuit pinMap] allKeys] objectEnumerator];
        [subcktList appendFormat:@".SUBCKT %@", [subcircuit fullyQualifiedCircuitName]];
        while (tmp = [portNameEnum nextObject])
        {
            tmp = [[subcircuit pinMap] objectForKey:tmp];
            if ([tmp length] > 0)
                [subcktList appendFormat:@" %@", tmp];
        }
        [subcktList appendString:@"\n"];
        [subcktList appendString:schematicToNetlistCore(subcircuit)];
        [subcktList appendFormat:@".ENDS %@\n", [subcircuit fullyQualifiedCircuitName]];
            
        return [NSString stringWithString:subcktList];
    }
    else
        return schematicToNetlistCore(circuit);
}


@end


void collectEquivalentPoints(NSMutableArray* collectionTable,
                             MI_ElementConnector* connector)
{
    if (![connector hasBeenTraversed])
    {
        MI_SchematicElement* nextElement = nil;
        // Add end point and start point to the given table
        [collectionTable addObject:[[MI_NodeAssignmentTableItem alloc]
            initWithElement:[connector startElementID]
            connectionPoint:[connector startPointName]]];
        [collectionTable addObject:[[MI_NodeAssignmentTableItem alloc]
            initWithElement:[connector endElementID]
            connectionPoint:[connector endPointName]]];
        // Mark connector as traversed
        [connector setTraversed:YES];
    
        for (int i = 0; i < 2; i++)
        {
            nextElement = [theCircuit elementForIdentifier:(i ? [connector startElementID] : [connector endElementID])];

            if ([nextElement conformsToProtocol:@protocol(MI_ElectricallyTransparentElement)])
            {
                // Apply search on all other connection points of the node
                NSEnumerator* pointEnum = [[nextElement connectionPoints] objectEnumerator];
                MI_ConnectionPoint* thePoint;
                while (thePoint = [pointEnum nextObject])
                {
                    MI_ElementConnector* nextConnector =
                        [theCircuit connectorForConnectionPoint:thePoint
                                                    ofElement:nextElement];
                    if (![nextConnector hasBeenTraversed])
                        collectEquivalentPoints(collectionTable, nextConnector);
                }
            }
        } // for
    } // if
}


void collectSubcircuitsAndDeviceModels(NSMutableDictionary* modelDB,
                                       NSMutableSet* subcircuitNames,
                                       MI_SubcircuitDocumentModel* subckt)
{
    NSEnumerator* setEnum = [[subckt usedSubcircuits] objectEnumerator];
    NSString* subcktName;
    while (subcktName = [setEnum nextObject])
    {
        collectSubcircuitsAndDeviceModels(modelDB, subcircuitNames,
            [[[SugarManager sharedManager] subcircuitLibraryManager] modelForSubcircuitName:subcktName]);
    }
    [subcircuitNames unionSet:[subckt usedSubcircuits]];
    [modelDB addEntriesFromDictionary:[subckt usedDeviceModels]];
}


NSString* nodeForConnectionPoint(NSString* connectionPointName, NSString* elementID, NSArray* nodeTable)
{
    NSEnumerator* nodeEnum = [nodeTable objectEnumerator];
    MI_NodeAssignmentTableItem* item;
    while (item = [nodeEnum nextObject])
    {
        if ([[item elementID] isEqualToString:elementID] &&
            [[item pointName] isEqualToString:connectionPointName])
        {
            if ([item nodeName] != nil)
                return [item nodeName];
            else
                return [NSString stringWithFormat:@"%d", [item node]];
        }
    }
    return @"-1";
}
