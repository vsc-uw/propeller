{{ unistep_simple.spin
┌──────────────────────────────────────────┬─────────────┬───────────────────┬───────────────┐
│ Unipolar 5-wire stepper motor driver v1.0│ BR          │ (C)2018           │  14 Oct 2018  │
├──────────────────────────────────────────┴─────────────┴───────────────────┴───────────────┤
│                                                                                            │
│ A simple 5-wire 4-pole unipolar stepper motor driver.                                      │
│                                                                                            │
│ Notes:                                                                                     │
│ •This object is set up to drive these cheap $3 Erco ebay steppers (28BYJ48 5V):            │
│    https://forums.parallax.com/discussion/141149/3-stepper-motor-board                     │
│ •Only supports constant speed moves.                                                       │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
DEVICE PINOUT & REFERENCE CIRCUIT

cheap ebay 5V 28BYJ48 stepper motors with ULN2003 driver board
                      ┌─────────────────┐               
          basepin   │IN1     ┌─┐    │ to motor  
          basepin+1 │IN2     │U│      │ to motor        
          basepin+2 │IN3     │L│    │ to motor        
          basepin+3 │IN4     │N│      │ to motor        
      no connection │IN5     └─┘    │ to motor        
      no connection │IN6       j1     │     
      no connection │IN7  • • •-•   │         
                      └─────────────────┘      
                             
                          GND 5V        j1 = jumper across pins for flyback diode
}}
dat
full    long  %0011_0110_1100_1001_0011_0110_1100_1001              ' full step - max torque
half    long  %0001_0011_0010_0110_0100_1100_1000_1001              ' half step - max precision
wave    long  %0001_0010_0100_1000_0001_0010_0100_1000              ' wave step - max speed?

basePin long 0
mode    long 0                                                
ticks   long 0                                                      'clock ticks between steps


pub init(_basePin, _mode, _speed)
''initialize unipolar stepper motor driver
''basePin = block of 4 contiguous pins, lowest pin # is base
''mode = stepper waveform to use (full=0, half=1, wave=2)
''speed = step speed, steps/sec

basepin := _basepin
mode := long[@full][_mode]
ticks := clkfreq/_speed

outa[basepin..basepin+3]:= mode & %1111
dira[basepin..basepin+3]~~


pub stop
''release stepper motor pins

outa[basepin..basepin+3]~
dira[basepin..basepin+3]~~
mode:=0


pub coast
''de-energize stepper motor coils

outa[basepin..basepin+3]~


pub SetSpeed(stepsPerSec)
''set stepper motor speed, StepsPerSec; 0 or negative numbers are ignored

  if stepsPerSec < 1
    return
  ticks := clkfreq/stepsPerSec
'  ticks := minTicks #> ticks


pub SetMode(stepPattern)|tmp
''set step mode (full=0, half=1, wave=2)

  tmp := 0 #> stepPattern <# 2
  mode := long[@full][tmp]


pub UniStep(steps)
''move stepper at a uniform speed for the specified number of steps
''steps = number of steps to take (use steps < 0 for reverse)

  repeat ||(steps)
    if steps >0
      mode ->= 4
    elseif steps <0
      mode <-= 4
    outa[basepin..basepin+3]:= mode & %1111
    waitcnt(ticks+cnt)


DAT
{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  