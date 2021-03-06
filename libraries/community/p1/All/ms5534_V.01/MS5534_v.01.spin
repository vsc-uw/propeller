{{File:    MS5534_v.01.spin
  Author:  Justin Jordan (J^3)
  Started: 03MAR11
  Updated: 13MAR11

  Description: Interface for the MS5543 pressure/temperature sensor.
               

  Revisions:
}}


VAR

  long  cog
  long  pins[4], words[4], d1, d2, ut1, dT, temp, off, sens, x, press, temp2, press2 
  word  coeffs[6]


PUB start(din, dout, mclk, sclk)
'din  = sensor dout
'dout = sensor din

  stop
  longmove(@pins, @din, 4)
  return cog := cognew(@Init, @pins) + 1 


PUB stop

  if cog
    cogstop(cog~ - 1)


PUB getCoef(num)
'num = coefficient number

  case num

    1: result := (words[0]  >> 1)
    2: result := (((words[2] & $003F) << 6) | (words[3] & $003F)) 
    3: result := (words[3] >> 6)
    4: result := (words[2] >> 6) 
    5: result := ((((words[0] & 1) << 10) | (((words[1]) & $FFC0) >> 6)))
    6: result := (words[1] & $003F)
    
    other: result := false


PUB getD1

  result := d1


PUB getD2

  result := d2
  

PUB getCelsius
'Calibrated temperature to 0.1 degrees C.  25.0 degrees C will be reported as 250

  result := (getTemp - getTemp2)


PUB getMilliBar
'Calibrated pressure to 0.1 milliBar.

  result := (getPress - getPress2)


PRI getUT1 

  result := ut1 := (8*getCoef(5) + 20224)
  

PRI getDt
 
  result := dT := (d2 - getUT1)  

  
PRI getTemp

  result := temp := (200 + (getDt*(getCoef(6) + 50)) ~> 10)   
  

PRI getOFF

  result := off := (getCoef(2)*4 + (((getCoef(4) - 512)*getDt) ~> 12))
  

PRI getSENS

  result := sens := (getCoef(1) + ((getCoef(3)*getDt) ~> 10) + 24576)
  

PRI getX

 result := x := (((getSENS*(d1 - 7168)) ~> 14) - getOFF)
 

PRI getPress
  
  result := press := (((getX*10) ~> 5) + 250*10)


PRI getTemp2 | temp1

  temp1 := getTemp

  case temp1

    (temp1 < 200) : temp2 := ((11*(getCoef(6) + 24))*(200 - temp1)) ~> 20
    
    ((temp1 => 200) and (temp1 =< 450)) : temp2 := 0

    (temp1 > 450) : temp2 := ((3*(getCoef(6) + 24)*(450 - temp1)*(450 - temp1)) ~> 20)

  result := temp2
  

PRI getPress2 | press1, temp1 

  temp1  := getTemp
  press1 := getPress
  
  case temp

    (temp1 < 200) : press2 := ((3*getTemp2*(press1 - 3500)) ~> 14)
    
    ((temp1 => 200) and (temp1 =< 450)) : press2 := 0

    (temp1 > 450) : press2 := (getTemp2*(press1 - 10000)) ~> 13

  result := press2


DAT
'--------------------------------------------------------------------------------------------------
'-- Initialize Cog
'--------------------------------------------------------------------------------------------------

                        org     0

Init                    mov     t0, par                         'Get address of din
                        rdlong  din_pin,  t0                    'Store din pin#
                        
                        add     t0, #4                          'Get address of dout
                        rdlong  dout_pin, t0                    'Store dout pin#
                        
                        add     t0, #4                          'Get address of mclk
                        rdlong  mclk_pin, t0                    'Store mclk pin#

                        add     t0, #4                          'Get address of sclk
                        rdlong  sclk_pin, t0                    'Store sclk pin#    
                        
                        call    #SetPinDirs
                        
                        movs    ctra, mclk_pin                  'Sets up, and starts MCLK
                        mov     frqa, frq_A
                        movi    ctra, #%000100_000 

                        call    #Reset_Sensor

                        mov     t0, word1_Seq                   'load correct sequence
                        call    #Get_CalWord
                        mov     t0, par                         
                        add     t0, #16                         'Get right address for word
                        wrlong  t2, t0                          'Pass data to hub

                        mov     t0, word2_Seq                   'load correct sequence
                        call    #Get_CalWord
                        mov     t0, par                         
                        add     t0, #20                         'Get right address for word
                        wrlong  t2, t0                          'Pass data to hub
                       
                        mov     t0, word3_Seq                   'load correct sequence
                        call    #Get_CalWord
                        mov     t0, par                         
                        add     t0, #24                         'Get right address for word
                        wrlong  t2, t0                          'Pass data to hub
                        
                        mov     t0, word4_Seq                   'load correct sequence
                        call    #Get_CalWord
                        mov     t0, par                         
                        add     t0, #28                         'Get right address for word
                        wrlong  t2, t0                          'Pass data to hub

                        mov     pause, cnt
                        add     pause, sysTicks            
                        
'--------------------------------------------------------------------------------------------------
'-- Main Loop
'--------------------------------------------------------------------------------------------------
                       
Main                    waitcnt pause, sysTicks

                        call    #Reset_Sensor    

                        mov     t0, pressureSeq                  'load correct sequence
                        call    #Get_Data
                        mov     t0, par                         
                        add     t0, #32                          'Get right address for word
                        wrlong  t2, t0                           'Pass data to hub 
                        
                        mov     t0, tempSeq                      'load correct sequence
                        call    #Get_Data
                        mov     t0, par                         
                        add     t0, #36                          'Get right address for word
                        wrlong  t2, t0                           'Pass data to hub
        
                        jmp     #Main

                        
'--------------------------------------------------------------------------------------------------
'-- Subroutines
'--------------------------------------------------------------------------------------------------                      

SetPinDirs              mov     t0, inMask                      'Makes input instead of output
                        rol     t0, din_pin                     'Put 0 on pin position                              
                        mov     din_mask, t0                    'Make mask for pin                                            
                        xor     t0, clrMask                     'Set up mask for reading pin                              
                        mov     rd_din, t0                      'Make mask for reading pin   
                        and     dira, din_mask                  'Set pin direction

                        mov     t0, outMask                     'Put 1 into t0                
                        shl     t0, dout_pin                    'Shift 1 on pin position       
                        mov     dout_mask, t0                   'Make mask for pin            
                        xor     t0, clrMask                     'Set up mask for clearing pin  
                        mov     clr_dout, t0                    'Make mask for clearing pin    
                        or      dira, dout_mask                 'Set pin direction             

                        mov     t0, outMask                     'Similar           
                        shl     t0, mclk_pin             
                        mov     mclk_mask, t0                 
                        or      dira, mclk_mask                          

                        mov     t0, outMask                     'Same            
                        shl     t0, sclk_pin             
                        mov     sclk_mask, t0
                        xor     t0, clrMask                     'Set up mask for clearing pin  
                        mov     clr_sclk, t0                    'Make mask for clearing pin               
                        or      dira, sclk_mask          

SetPinDirs_ret          ret

'--------------------------------------------------------------------------------------------------

Reset_Sensor            mov     t0, resetSeq                    'Copy reset sequence to t0
                        mov     bitCnt, #0                      '0 bit counter counter
                        mov     t1, cnt
                        add     t1, halfSCLK

Reset_loop              test    t0, #1                  wz      'Test for 1 in sequence 
        if_ne           or      outa, dout_mask
        if_e            and     outa, clr_dout
                        shr     t0, #1                          'Align next bit in sequence

                        waitcnt t1, halfSCLK                    'Exercise clock
                        or      outa, sclk_mask                 
                        waitcnt t1, halfSCLK
                        and     outa, clr_sclk

                        add     bitCnt, #1                      'Increment bit counter
                        cmp     bitCnt, #18              wz     'Check for end of sequence
        if_ne           jmp     #Reset_loop
                        
Reset_Sensor_ret        ret

'--------------------------------------------------------------------------------------------------

Get_CalWord             mov     bitCnt, #0                      '0 bit counter counter
                        mov     t2, #0
                        mov     t1, cnt
                        add     t1, halfSCLK
       
Word_Seq_loop           test    t0, #1                  wz      'Test for 1 in sequence 
        if_ne           or      outa, dout_mask
        if_e            and     outa, clr_dout
                        shr     t0, #1                          'Align next bit in sequence

                        waitcnt t1, halfSCLK                    'Exercise clock
                        or      outa, sclk_mask
                        waitcnt t1, halfSCLK
                        and     outa, clr_sclk

                        add     bitCnt, #1                      'Increment bit counter
                        cmp     bitCnt, #11              wc     'Check for end of sequence
        if_b            jmp     #Word_Seq_loop

Read_Word_loop          waitcnt t1, halfSCLK                    'Exercise clock
                        or      outa, sclk_mask
                        waitcnt t1, halfSCLK
                        and     outa, clr_sclk

                        cmp     bitCnt, #13              wc     'See if time to start reading word
        if_b            jmp     #IncBits
                         
                        test    rd_din, ina              wc     'Get bit
                        rcl     t2, #1

IncBits                 add     bitCnt, #1                      'Increment bit counter 
                        cmp     bitCnt, #29              wz     'Check for end of word
        if_ne           jmp     #Read_Word_loop      
      
Get_CalWord_ret         ret

'--------------------------------------------------------------------------------------------------

Get_Data                mov     bitCnt, #0                      '0 bit counter counter
                        mov     t2, #0
                        mov     t1, cnt
                        add     t1, halfSCLK
       
Data_Seq_loop           test    t0, #1                  wz      'Test for 1 in sequence 
        if_ne           or      outa, dout_mask
        if_e            and     outa, clr_dout
                        shr     t0, #1                          'Align next bit in sequence

                        waitcnt t1, halfSCLK                    'Exercise clock
                        or      outa, sclk_mask
                        waitcnt t1, halfSCLK
                        and     outa, clr_sclk

                        add     bitCnt, #1                      'Increment bit counter  
                        cmp     bitCnt, #13             wc      'Check for end of sequence
        if_b            jmp     #Data_Seq_loop

Conversion              test    rd_din, ina             wz      'Wait for end of conversion
        if_ne           jmp     #Conversion

                        mov     t1, cnt                         'Set up delay after waiting on
                        add     t1, halfSCLK                    'conversion.  This is a gotcha

Read_Data_loop          waitcnt t1, halfSCLK                    'Exercise clock
                        or      outa, sclk_mask
                        waitcnt t1, halfSCLK
                        and     outa, clr_sclk
                         
                        test    rd_din, ina              wc     'Get bit
                        rcl     t2, #1

                        add     bitCnt, #1                      'Increment bit counter
                        cmp     bitCnt, #29              wz     'Check for end of data 
        if_ne           jmp     #Read_Data_loop      
      
Get_Data_ret            ret


'--------------------------------------------------------------------------------------------------
'-- Initialized Data
'--------------------------------------------------------------------------------------------------



sysTicks      long      20_000_000
frq_A         long      1_759_219
halfSCLK      long      4_000
inMask        long      $FFFFFFFE
outMask       long      $00000001
clrMask       long      $FFFFFFFF
pressureSeq   long      $0000002F
tempSeq       long      $0000004F
word1_Seq     long      $00000157
word2_Seq     long      $000000D7
word3_Seq     long      $00000137
word4_Seq     long      $000000B7
resetSeq      long      $00005555                     

'--------------------------------------------------------------------------------------------------    
'-- Uninitialized Data
'--------------------------------------------------------------------------------------------------
                      
t0                      res     1
t1                      res     1
t2                      res     1
pause                   res     1
bitCnt                  res     1
mclk_pin                res     1
mclk_mask               res     1
sclk_pin                res     1
sclk_mask               res     1
clr_sclk                res     1
din_pin                 res     1
din_mask                res     1
rd_din                  res     1
dout_pin                res     1
dout_mask               res     1
clr_dout                res     1

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