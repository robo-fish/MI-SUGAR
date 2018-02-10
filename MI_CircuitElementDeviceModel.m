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
#import "MI_CircuitElementDeviceModel.h"

@implementation MI_CircuitElementDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super init])
    {
        modelName = [[NSMutableString alloc] initWithCapacity:[theName length]];
        [modelName setString:theName];
        parameters = [[NSMutableString alloc] initWithCapacity:100];
        MI_version = MI_SUGAR_CIRCUIT_ELEMENT_DEVICE_MODEL_VERSION;
    }
    return self;
}

// Overrides NSObject's object comparison method.
// Two device models are equal if their names are equal.
// This is exploited in NSArray and NSDictionary methods.
- (BOOL) isEqual:(id)anObject
{
    return [anObject isKindOfClass:[MI_CircuitElementDeviceModel class]] &&
        [[(MI_CircuitElementDeviceModel*)anObject modelName] isEqualToString:[self modelName]];
}

- (NSString*) modelName
{
    return [NSString stringWithString:modelName];
}

- (MI_DeviceModelType) type
{
    return NO_DEVICE_MODEL_TYPE;
}

- (void) setModelName:(NSString*)newName
{
    [modelName setString:newName];
}

- (NSString*) deviceParameters
{
    return [NSString stringWithString:parameters];
}

- (void) setDeviceParameters:(NSString*)newParameters
{
    [parameters setString:newParameters];
}

/************ Copying and Archiving protocol implementations ********/

- (id)initWithCoder:(NSCoder *)decoder
{
    if (self = [super init])
    {
        parameters = [[decoder decodeObjectForKey:@"Parameters"] retain];
        modelName = [[decoder decodeObjectForKey:@"ModelName"] retain];
        MI_version = MI_SUGAR_CIRCUIT_ELEMENT_DEVICE_MODEL_VERSION;
    }
    return self;
}


- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:parameters
                   forKey:@"Parameters"];
    [encoder encodeObject:modelName
                   forKey:@"ModelName"];
    [encoder encodeInt:MI_version
                forKey:@"Version"];
}


- (id) copyWithZone:(NSZone*) zone
{
    MI_CircuitElementDeviceModel* myCopy =
        [[[self class] allocWithZone:zone] initWithName:[self modelName]];
    [myCopy setDeviceParameters:[self deviceParameters]];
    return myCopy;
}

- (id) mutableCopyWithZone:(NSZone*) zone
{
    return [self copyWithZone:(NSZone*) zone];
}

/******************************************* Conversion to SugarML ***/

- (NSString*) toSugarMLWithIndentation:(NSString*)indent
                  indentationIncrement:(NSString*)increment
{
    return nil;
}

/**********************************************/

- (void) dealloc
{
    [modelName release];
    [parameters release];
    [super dealloc];
}

@end


/****************************************************** DEFAULT DIODE *****/
@implementation MI_DiodeDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[[[[
            @"+ IS = 1.0e-14     RS = 0         N = 1   \n" stringByAppendingString:
            @"+ TT = 0          CJO = 0        VJ = 0.6 \n" ] stringByAppendingString:
            @"+  M = 0.5         EG = 1.11    XTI = 3.0 \n" ] stringByAppendingString:
            @"+ KF = 0           AF = 1        FC = 0.5\n"] stringByAppendingString:
            @"+ BV = 1E4        IBV = 1E-3   TNOM = 27\n"]
        ];
    }
    return self;
}

- (MI_DeviceModelType) type
{
    return DIODE_DEVICE_MODEL_TYPE;
}

@end

/****************************************************** DEFAULT BJT *****/
@implementation MI_BJTDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[[[[[[[[[[[[
            @"+ ISE = 0.            XTF = 1.0\n"       stringByAppendingString:
            @"+ CJS = 0.            VJS = 0.50000       PTF = 0.\n"        ] stringByAppendingString:
            @"+ MJS = 0.            EG  = 1.10000       AF  = 1.\n"        ] stringByAppendingString:
            @"+ ITF = 0.50000       VTF = 1.00000       BR  = 40.00000\n"      ] stringByAppendingString:
            @"+  IS = 1.6339e-14    VAF = 103.40529\n"                      ] stringByAppendingString:
            @"+ VAR = 17.77498      IKF = 1.00000\n"                      ] stringByAppendingString:
            @"+  NE = 1.31919       IKR = 1.00000       ISC =   3.6856e-13\n"] stringByAppendingString:
            @"+  NC = 1.10024       IRB = 4.3646e-05    NF  =   1.00531\n"   ] stringByAppendingString:
            @"+  NR = 1.00688       RBM = 1.0000e-02    RB  =  71.82988\n"   ] stringByAppendingString:
            @"+  RC = 0.42753       RE  = 3.0503e-03    MJE =   0.32339\n"   ] stringByAppendingString:
            @"+ MJC = 0.34700       VJE = 0.67373       VJC =   0.47372\n"   ] stringByAppendingString:
            @"+  TF = 9.693e-10     TR  = 380.00e-9     CJE =   2.6734e-11\n"] stringByAppendingString:
            @"+ CJC = 1.4040e-11    FC  = 0.95000      XCJC =   0.94518\n"]
        ];
    }
    return self;
}

- (MI_DeviceModelType) type
{
    return BJT_DEVICE_MODEL_TYPE;
}

@end

/****************************************************** DEFAULT JFET *****/
@implementation MI_JFETDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[[[[
            @"+  VTO = -2.0     BETA = 1.0E-4    LAMBDA = 0.0\n" stringByAppendingString:
            @"+   RD = 0          RS = 0            CGS = 0.0\n"] stringByAppendingString:
            @"+  CGD = 0          PB = 1             IS = 1.0E-14\n"] stringByAppendingString:
            @"+   KF = 0          AF = 1             FC = 0.5\n"] stringByAppendingString:
            @"+ TNOM = 27\n"]
        ];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return JFET_DEVICE_MODEL_TYPE;
}

@end

/****************************************************** DEFAULT MOS *****/
@implementation MI_MOSDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:@"* BSIM3 with default parameters\n+ level = 8\n"];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return MOS_DEVICE_MODEL_TYPE;
}

@end


/****************************************************** DEPRECATED BSIM3 MOS *****/
@implementation MI_BSIM3_MOSDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:@"* BSIM3 with default parameters\n+ level = 8\n"];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return MOS_DEVICE_MODEL_TYPE;
}

@end


/****************************************************** DEPRECATED BSIM4 NMOS *****/
@implementation MI_BSIM4_NMOSDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
            @"* BSIM4 model with example parameters for 65nm process MOSFET\n" stringByAppendingString:
            @"+ level   = 14           version  = 4.3.0       binunit = 1            paramchk= 1\n"] stringByAppendingString:
            @"+ capmod  = 2            igcmod  = 1            igbmod  = 1            geomod  = 1\n"] stringByAppendingString:
            @"+ diomod  = 1            rdsmod  = 0            rbodymod= 1            rgatemod= 1\n"] stringByAppendingString:
            @"+ permod  = 1            acnqsmod= 0            trnqsmod= 0            mobmod  = 0\n"] stringByAppendingString:
            @"+ tnom    = 27           toxe    = 1.7e-9       toxp    = 1e-9         toxm    = 1.7e-9\n"] stringByAppendingString:
            @"+ dtox    = 0            epsrox  = 3.9          wint    = 5e-009       lint    = 1.6e-008\n"] stringByAppendingString:
            @"+ ll      = 0            wl      = 0            lln     = 1            wln     = 1\n"] stringByAppendingString:
            @"+ lw      = 0            ww      = 0            lwn     = 1            wwn     = 1\n"] stringByAppendingString:
            @"+ lwl     = 0            wwl     = 0            xpart   = 0            toxref  = 1.7e-9\n"] stringByAppendingString:
            @"+ vth0    = 0.22         k1      = 0.43         k2      = 0.01         k3      = 0\n"] stringByAppendingString:
            @"+ k3b     = 0            w0      = 2.5e-006     dvt0    = 3.5          dvt1    = 0.55\n"] stringByAppendingString:
            @"+ dvt2    = -0.032       dvt0w   = 0            dvt1w   = 0            dvt2w   = 0\n"] stringByAppendingString:
            @"+ dsub    = 1            minv    = 0.05         voffl   = 0            dvtp0   = 1.2e-008\n"] stringByAppendingString:
            @"+ dvtp1   = 0.1          lpe0    = 5.75e-008    lpeb    = 2.3e-010     xj      = 2.5e-008\n"] stringByAppendingString:
            @"+ ngate   = 5e+020       ndep    = 2.6e+018     nsd     = 1e+020       phin    = 0\n"] stringByAppendingString:
            @"+ cdsc    = 0.0002       cdscb   = 0            cdscd   = 0            cit     = 0\n"] stringByAppendingString:
            @"+ voff    = -0.15        nfactor = 2            eta0    = 0.24         etab    = 0\n"] stringByAppendingString:
            @"+ vfb     = -0.55        u0      = 0.06         ua      = 1e-010       ub      = 1e-017\n"] stringByAppendingString:
            @"+ uc      = -3e-011      vsat    = 1.2e+005     a0      = 1.5          ags     = 1e-020\n"] stringByAppendingString:
            @"+ a1      = 0            a2      = 1            b0      = -1e-020      b1      = 0\n"] stringByAppendingString:
            @"+ keta    = 0.04         dwg     = 0            dwb     = 0            pclm    = 0.12\n"] stringByAppendingString:
            @"+ pdiblc1 = 0.02         pdiblc2 = 0.02         pdiblcb = -0.005       drout   = 0.5\n"] stringByAppendingString:
            @"+ pvag    = 1e-020       delta   = 0.01         pscbe1  = 8.14e+008    pscbe2  = 1e-007\n"] stringByAppendingString:
            @"+ fprout  = 0.2          pdits   = 0.2          pditsd  = 0.23         pditsl  = 2.3e+006\n"] stringByAppendingString:
            @"+ rsh     = 5            rdsw    = 160          rsw     = 150          rdw     = 150\n"] stringByAppendingString:
            @"+ rdswmin = 0            rdwmin  = 0            rswmin  = 0            prwg    = 0\n"] stringByAppendingString:
            @"+ prwb    = 6.8e-011     wr      = 1            alpha0  = 0.074        alpha1  = 0.005\n"] stringByAppendingString:
            @"+ beta0   = 30           agidl   = 0.0002       bgidl   = 2.1e+009     cgidl   = 0.0002\n"] stringByAppendingString:
            @"+ egidl   = 0.8\n"] stringByAppendingString:
            @"+ aigbacc = 0.012        bigbacc = 0.0028       cigbacc = 0.002\n"] stringByAppendingString:
            @"+ nigbacc = 1            aigbinv = 0.014        bigbinv = 0.004        cigbinv = 0.004\n"] stringByAppendingString:
            @"+ eigbinv = 1.1          nigbinv = 3            aigc    = 0.012        bigc    = 0.0028\n"] stringByAppendingString:
            @"+ cigc    = 0.002        aigsd   = 0.012        bigsd   = 0.0028       cigsd   = 0.002\n"] stringByAppendingString:
            @"+ nigc    = 1            poxedge = 1            pigcd   = 1            ntox    = 1\n"] stringByAppendingString:
            @"+ xrcrg1  = 12           xrcrg2  = 5\n"] stringByAppendingString:
            @"+ cgso    = 5.458e-010   cgdo    = 5.458e-010   cgbo    = 2.56e-011    cgdl    = 2.653e-10\n"] stringByAppendingString:
            @"+ cgsl    = 2.653e-10    ckappas = 0.03         ckappad = 0.03         acde    = 1\n"] stringByAppendingString:
            @"+ moin    = 15           noff    = 0.9          voffcv  = 0.02\n"] stringByAppendingString:
            @"+ kt1     = -0.11        kt1l    = 0            kt2     = 0.022        ute     = -1.5\n"] stringByAppendingString:
            @"+ ua1     = 4.31e-009    ub1     = 7.61e-018    uc1     = -5.6e-011    prt     = 0\n"] stringByAppendingString:
            @"+ at      = 33000\n"] stringByAppendingString:
            @"+ fnoimod = 1            tnoimod = 0\n"] stringByAppendingString:
            @"+ jss     = 0.0001       jsws    = 1e-011       jswgs   = 1e-010       njs     = 1\n"] stringByAppendingString:
            @"+ ijthsfwd= 0.01         ijthsrev= 0.001        bvs     = 10           xjbvs   = 1\n"] stringByAppendingString:
            @"+ jsd     = 0.0001       jswd    = 1e-011       jswgd   = 1e-010       njd     = 1\n"] stringByAppendingString:
            @"+ ijthdfwd= 0.01         ijthdrev= 0.001        bvd     = 10           xjbvd   = 1\n"] stringByAppendingString:
            @"+ pbs     = 1            cjs     = 0.0005       mjs     = 0.5          pbsws   = 1\n"] stringByAppendingString:
            @"+ cjsws   = 5e-010       mjsws   = 0.33         pbswgs  = 1            cjswgs  = 3e-010\n"] stringByAppendingString:
            @"+ mjswgs  = 0.33         pbd     = 1            cjd     = 0.0005       mjd     = 0.5\n"] stringByAppendingString:
            @"+ pbswd   = 1            cjswd   = 5e-010       mjswd   = 0.33         pbswgd  = 1\n"] stringByAppendingString:
            @"+ cjswgd  = 5e-010       mjswgd  = 0.33         tpb     = 0.005        tcj     = 0.001\n"] stringByAppendingString:
            @"+ tpbsw   = 0.005        tcjsw   = 0.001        tpbswg  = 0.005        tcjswg  = 0.001\n"] stringByAppendingString:
            @"+ xtis    = 3            xtid    = 3\n"] stringByAppendingString:
            @"+ dmcg    = 0e-006       dmci    = 0e-006       dmdg    = 0e-006       dmcgt   = 0e-007\n"] stringByAppendingString:
            @"+ dwj     = 0.0e-008     xgw     = 0e-007       xgl     = 0e-008\n"] stringByAppendingString:
            @"+ rshg    = 0.4          gbmin   = 1e-010       rbpb    = 5            rbpd    = 15\n"] stringByAppendingString:
            @"+ rbps    = 15           rbdb    = 15           rbsb    = 15           ngcon   = 1\n"]
            ];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return MOS_DEVICE_MODEL_TYPE;
}

@end

/****************************************************** DEPRECATED DEFAULT PMOS *****/
@implementation MI_BSIM4_PMOSDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[
            @"* BSIM4 model with example parameters for 65nm process MOSFET\n" stringByAppendingString:
            @"+ level  = 14           version  = 4.3.0        binunit = 1            paramchk= 1\n"] stringByAppendingString:
            @"+ capmod  = 2            igcmod  = 1            igbmod  = 1            geomod  = 1\n"] stringByAppendingString:
            @"+ diomod  = 1            rdsmod  = 0            rbodymod= 1            rgatemod= 1\n"] stringByAppendingString:
            @"+ permod  = 1            acnqsmod= 0            trnqsmod= 0            mobmod  = 0\n"] stringByAppendingString:
            @"+ tnom    = 27           toxe    = 1.7e-009     toxp    = 1e-009       toxm    = 1.7e-009\n"] stringByAppendingString:
            @"+ dtox    = 0            epsrox  = 3.9          wint    = 5e-009       lint    = 1.6e-008\n"] stringByAppendingString:
            @"+ ll      = 0            wl      = 0            lln     = 1            wln     = 1\n"] stringByAppendingString:
            @"+ lw      = 0            ww      = 0            lwn     = 1            wwn     = 1\n"] stringByAppendingString:
            @"+ lwl     = 0            wwl     = 0            xpart   = 0            toxref  = 1.7e-009\n"] stringByAppendingString:
            @"+ vth0    = -0.22        k1      = 0.43         k2      = -0.01        k3      = 0\n"] stringByAppendingString:
            @"+ k3b     = 0            w0      = 2.5e-006     dvt0    = 3.68         dvt1    = 0.53\n"] stringByAppendingString:
            @"+ dvt2    = -0.032       dvt0w   = 0            dvt1w   = 0            dvt2w   = 0\n"] stringByAppendingString:
            @"+ dsub    = 0.8          minv    = 0.05         voffl   = 0            dvtp0   = 1e-008\n"] stringByAppendingString:
            @"+ dvtp1   = 0.05         lpe0    = 5.75e-008    lpeb    = 2.3e-010     xj      = 2.5e-008\n"] stringByAppendingString:
            @"+ ngate   = 5e+020       ndep    = 2.6e+018     nsd     = 1e+020       phin    = 0\n"] stringByAppendingString:
            @"+ cdsc    = 0.000258     cdscb   = 0            cdscd   = 6.1e-008     cit     = 0\n"] stringByAppendingString:
            @"+ voff    = -0.15        nfactor = 2            eta0    = 0.2          etab    = 0\n"] stringByAppendingString:
            @"+ vfb     = 0.55         u0      = 0.014        ua      = 1.8e-009     ub      = 6e-018\n"] stringByAppendingString:
            @"+ uc      = -3e-011      vsat    = 90000        a0      = 1.2          ags     = 1e-020\n"] stringByAppendingString:
            @"+ a1      = 0            a2      = 1            b0      = -1e-020      b1      = 0\n"] stringByAppendingString:
            @"+ keta    = -0.047       dwg     = 0            dwb     = 0            pclm    = 0.55\n"] stringByAppendingString:
            @"+ pdiblc1 = 0.12         pdiblc2 = 0.0075       pdiblcb = 3.4e-008     drout   = 0.56\n"] stringByAppendingString:
            @"+ pvag    = 1e-020       delta   = 0.014        pscbe1  = 8.14e+008    pscbe2  = 9.58e-007\n"] stringByAppendingString:
            @"+ fprout  = 0.2          pdits   = 0.2          pditsd  = 0.23         pditsl  = 2.3e+006\n"] stringByAppendingString:
            @"+ rsh     = 5            rdsw    = 280          rsw     = 160          rdw     = 160\n"] stringByAppendingString:
            @"+ rdswmin = 0            rdwmin  = 0            rswmin  = 0            prwg    = 3.22e-008\n"] stringByAppendingString:
            @"+ prwb    = 6.8e-011     wr      = 1            alpha0  = 0.074        alpha1  = 0.005\n"] stringByAppendingString:
            @"+ beta0   = 30           agidl   = 0.0002       bgidl   = 2.1e+009     cgidl   = 0.0002\n"] stringByAppendingString:
            @"+ egidl   = 0.8\n"] stringByAppendingString:
            @"+ aigbacc = 0.012        bigbacc = 0.0028       cigbacc = 0.002\n"] stringByAppendingString:
            @"+ nigbacc = 1            aigbinv = 0.014        bigbinv = 0.004        cigbinv = 0.004\n"] stringByAppendingString:
            @"+ eigbinv = 1.1          nigbinv = 3            aigc    = 0.69         bigc    = 0.0012\n"] stringByAppendingString:
            @"+ cigc    = 0.0008       aigsd   = 0.0087       bigsd   = 0.0012       cigsd   = 0.0008\n"] stringByAppendingString:
            @"+ nigc    = 1            poxedge = 1            pigcd   = 1            ntox    = 1\n"] stringByAppendingString:
            @"+ xrcrg1  = 12           xrcrg2  = 5\n"] stringByAppendingString:
            @"+ cgso    = 5.458e-010   cgdo    = 5.458e-010   cgbo    = 2.56e-011    cgdl    = 2.653e-10\n"] stringByAppendingString:
            @"+ cgsl    = 2.653e-10    ckappas = 0.03         ckappad = 0.03         acde    = 1\n"] stringByAppendingString:
            @"+ moin    = 15           noff    = 0.9          voffcv  = 0.02\n"] stringByAppendingString:
            @"+ kt1     = -0.11        kt1l    = 0            kt2     = 0.022        ute     = -1.5\n"] stringByAppendingString:
            @"+ ua1     = 4.31e-009    ub1     = 7.61e-018    uc1     = -5.6e-011    prt     = 0\n"] stringByAppendingString:
            @"+ at      = 33000\n"] stringByAppendingString:
            @"+ fnoimod = 1            tnoimod = 0\n"] stringByAppendingString:
            @"+ jss     = 0.0001       jsws    = 1e-011       jswgs   = 1e-010       njs     = 1\n"] stringByAppendingString:
            @"+ ijthsfwd= 0.01         ijthsrev= 0.001        bvs     = 10           xjbvs   = 1\n"] stringByAppendingString:
            @"+ jsd     = 0.0001       jswd    = 1e-011       jswgd   = 1e-010       njd     = 1\n"] stringByAppendingString:
            @"+ ijthdfwd= 0.01         ijthdrev= 0.001        bvd     = 10           xjbvd   = 1\n"] stringByAppendingString:
            @"+ pbs     = 1            cjs     = 0.0005       mjs     = 0.5          pbsws   = 1\n"] stringByAppendingString:
            @"+ cjsws   = 5e-010       mjsws   = 0.33         pbswgs  = 1            cjswgs  = 3e-010\n"] stringByAppendingString:
            @"+ mjswgs  = 0.33         pbd     = 1            cjd     = 0.0005       mjd     = 0.5\n"] stringByAppendingString:
            @"+ pbswd   = 1            cjswd   = 5e-010       mjswd   = 0.33         pbswgd  = 1\n"] stringByAppendingString:
            @"+ cjswgd  = 5e-010       mjswgd  = 0.33         tpb     = 0.005        tcj     = 0.001\n"] stringByAppendingString:
            @"+ tpbsw   = 0.005        tcjsw   = 0.001        tpbswg  = 0.005        tcjswg  = 0.001\n"] stringByAppendingString:
            @"+ xtis    = 3            xtid    = 3\n"] stringByAppendingString:
            @"+ dmcg    = 0e-006       dmci    = 0e-006       dmdg    = 0e-006       dmcgt   = 0e-007\n"] stringByAppendingString:
            @"+ dwj     = 0.0e-008     xgw     = 0e-007       xgl     = 0e-008\n"] stringByAppendingString:
            @"+ rshg    = 0.4          gbmin   = 1e-010       rbpb    = 5            rbpd    = 15\n"] stringByAppendingString:
            @"+ rbps    = 15           rbdb    = 15           rbsb    = 15           ngcon   = 1   \n"]
            ];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return MOS_DEVICE_MODEL_TYPE;
}

@end

/****************************************************** DEFAULT SWITCH *****/
@implementation MI_SwitchDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[
            @"+ VT = 0.0      IT = 0.0       VH = 0.0     \n" stringByAppendingString:
            @"+ IH = 0.0     RON = 1.0     ROFF = 1.0E+12 \n"]
        ];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return SWITCH_DEVICE_MODEL_TYPE;
}

@end

/******************************************** DEFAULT TRANSMISSION LINE *****/
@implementation MI_TransmissionLineDeviceModel

- (id) initWithName:(NSString*)theName
{
    if (self = [super initWithName:theName])
    {
        [parameters setString:[
            @"+   R = 0        L = 0       G = 0      C = 0\n" stringByAppendingString:
            @"+ LEN = 100    REL = 1     ABS = 1\n"]
        ];
    }
    return self;
}


- (MI_DeviceModelType) type
{
    return TRANSMISSION_LINE_DEVICE_MODEL_TYPE;
}

@end

