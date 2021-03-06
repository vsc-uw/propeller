{{

┌──────────────────────────────────────────┐
│ Wii Classic Controller Driver Object v1.1│
│ Author: Pat Daderko (DogP)               │               
│ Copyright (c) 2009                       │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘
 
Based on a Wii nunchuck example project from John Abshier, which was based on code originally by João Geada

Note that the right joystick only natively outputs 5 bits, compared to 6 bits of the left joystick, but
this driver shifts the right joystick's data left one bit to make it consistent with the left (but bit 0
will never change).

v1.1 fixed a typo which caused erratic behavior of the right joystick x axis.

The CAL_L_JOY_X, CAL_L_JOY_Y, CAL_R_JOY_X, and CAL_R_JOY_Y are the center values of the joystick.  32 seems
like the nominal value, but varies depending on the controller.  For the right joystick, this is the
calibration value after being shifted to 6 bits as noted above.

Diagram below is showing the pinout looking into the connector (which plugs into the Wii Remote)
 _______ 
| 1 2 3 |
|       |
| 6 5 4 |
|_-----_|

1 - SDA
2 - 
3 - VCC
4 - SCL
5 - 
6 - GND

This is an I2C peripheral, and requires a pullup resistor on the SDA line
If using a prop board with an I2C EEPROM, this can be connected directly to pin 28 (SCL) and pin 29 (SDA)

Digital controller bits:
0: R fully pressed
1: Start
2: Home
3: Select
4: L fully pressed
5: Down
6: Right
7: Up
8: Left
9: ZR
10: x
11: a
12: y
13: b
14: ZL
}}

CON
   Classic_Addr = $A4
   CAL_L_JOY_X = 32
   CAL_L_JOY_Y = 32
   CAL_R_JOY_X = 32
   CAL_R_JOY_Y = 32

OBJ
   i2cObject      : "i2cObject"

VAR
   long joyL_x
   long joyL_y
   long joyR_x
   long joyR_y
   byte shoulder_L
   byte shoulder_R   
   word digital
   long _220uS
   byte i2cSCL, i2cSDA
   
PUB init(_scl, _sda)
   i2cSCL := _scl
   i2cSDA := _sda
   i2cObject.Init(i2cSDA, i2cSCL, false)
   _220uS := clkfreq / 100_000 * 22 
  
PUB readClassic | data[6]
   ''reads all controller data into memory
   i2cObject.writeLocation(Classic_Addr, $F0, $55, 8, 8)
   waitcnt(_220uS+cnt)
   i2cObject.writeLocation(Classic_Addr, $FB, $00, 8, 8)
   waitcnt(_220uS+cnt)
   i2cObject.i2cStart
   i2cObject.i2cWrite(Classic_Addr, 8)
   i2cObject.i2cWrite(0,8)
   i2cObject.i2cStop
   waitcnt(_220uS+cnt)
   i2cObject.i2cStart
   i2cObject.i2cWrite(Classic_Addr|1, 8)
   data[0] := i2cObject.i2cRead(0)
   data[1] := i2cObject.i2cRead(0) 
   data[2] := i2cObject.i2cRead(0) 
   data[3] := i2cObject.i2cRead(0) 
   data[4] := i2cObject.i2cRead(0) 
   data[5] := i2cObject.i2cRead(1)
   i2cObject.i2cStop
   joyL_x := (data[0]&$3F)-CAL_L_JOY_X '6 bits
   joyL_y := (data[1]&$3F)-CAL_L_JOY_Y '6 bits
   joyR_x := (((data[0]>>2)&($30))|((data[1]>>4)&($0c))|((data[2]>>6)&2))-CAL_R_JOY_X 'RX only 5 bits, make 6 bits to be consistent w/ LX
   joyR_y := ((data[2]<<1)&$3E)-CAL_R_JOY_Y 'RY only 5 bits, make 6 bits to be consistent w/ LY
   shoulder_L := ((data[2]>>2)&($18))|(data[3]>>5) '5 bits
   shoulder_R := data[3]&$1F '5 bits
   digital := !((1<<15)|(data[5]<<7)|(data[4]>>1)) 'invert to 0=not pressed, 1=pressed

PUB joyLX
   ''returns left joystick x axis data
   return joyL_x

PUB joyLY
   ''returns left joystick y axis data
   return joyL_y

PUB joyRX
   ''returns right joystick x axis data
   return joyR_x

PUB joyRY
   ''returns right joystick y axis data
   return joyR_y

PUB shoulderL
   ''returns left analog shoulder button value
   return shoulder_L

PUB shoulderR
   ''returns right analog shoulder button value
   return shoulder_R

PUB buttons
   ''returns button data (see table at top for details)
   return digital 
            
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}