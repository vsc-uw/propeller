{{┌──────────────────────────────────────────┐
  │ Wrapper for I2C routines                 │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2015 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
}}
OBJ
  I2C_PASM    : "I2C PASM driver v1.8od"                ' I2C driver written in PASM with a SPIN handler
  I2C_PASM_pp : "I2C PASM driver v1.8pp"
  I2C_SPIN    : "I2C Spin driver v1.4od"                ' I2C driver written entirely in SPIN, runs in same cog as calling object
  I2C_SPIN_pp : "I2C Spin driver v1.4pp"                ' Spin-based driver that does not require pull-up resistors on SCL or SDA
  I2C_slave   : "I2C slave v1.2"                        ' I2C slave object written in PASM
  I2C_multi   : "I2C Multimaster driver v2.1.6"         ' I2C driver capable of sharing the bus with other masters - provided those other masters are also capable of sharing
  Poller      : "I2C poller"                            ' Displays the address of every device on the I2C bus
  Slave       : "I2C slave demo"                           
  EEPROM      : "EEPROM demo"
  Clock       : "DS1307 RTC demo"
  Altimeter   : "Altimeter demo"
  Gyro        : "Gyroscope demo"
  BMP085      : "BMP085 demo"
  Compass     : "HMC5883L demo"

PUB blank

DAT                     
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