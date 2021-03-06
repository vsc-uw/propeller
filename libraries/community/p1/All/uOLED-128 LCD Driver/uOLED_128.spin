{{
┌──────────────────────┐
│ µOLED-128 LCD Object │
├──────────────────────┴───────────────────────┐
│  Width      : 128 Pixels                     │
│  Height     : 128 Pixels                     │
├──────────────────────────────────────────────┤
│  By      : Simon Ampleman                    │
│            sa@infodev.ca                     │
│  Date    : 2006-11-25                        │
│  Version : 1.0                               │
└──────────────────────────────────────────────┘

Hardware used : µOLED-128-1Mb                    

Schematics
                         P8X32A
                       ┌────┬────┐ 
                       ┤0      31├            ┌────────────────┐
                       ┤1      30├            │                │
                       ┤2      29├            │                │           
                       ┤3      28├            │     PICTURE    │
                       ┤4      27├            │      SIDE      │   1 - See circuit
                       ┤5      26├            │                │   2 - RX (to P15)    
                       ┤6      25├            │                │   3 - TX (to P14)   
                       ┤7      24├            │     1 2 3 4    │   4 - +5V    
                       ┤VSS   VDD├            └─────┬─┬─┬─┬────┘
                       ┤BOEn   XO├                __│ │ │ │                  
                       ┤RESn   XI├      13 ─┬───       
                       ┤VDD   VSS├            2N3904  
                       ┤8      23├       10K│   (NPN)       
                       ┤9      22├          │
                       ┤10     21├          
                       ┤11     20├
                       ┤12     19├ 
                    EN ┤13     18├ 
                    RX ┤14     17├ 
                    TX ┤15     16├ 
                       └─────────┘ 


Information :

I connected the ground of the LCD to a 2N3904 used as a switch controlled by the Propeller Chip on pin 13.
This allows the opening and closing of the LCD power by software and removal of the logo when you
open the LCD by erasing the screen very quickly after initialization. Else, the propeller takes too much
time to boot, and the logo would appear for a 1 or 2 seconds.

The real RGB value is encoded with two bytes :

RRRRRGGG GGGBBBBB

However, In the methods I coded, I used a standard 0 to 255 maximum value for each color and then each channel is
approximated to that value. I thought it would be easier for everyone that way.

Methods :

INIT              - Initialize the LCD at 128000 bauds, must be called before using any other methods
WAITACK           - Wait for acknowledge byte from the RX pin, used after all methods
SHUTDOWN          - Shutdown the LCD properly, MUST be called to protect the LCD electronic at the end
ERASE             - Erase the screen
BACKGROUND        - Set and Paint the background color to RGB value
PUT_PIXEL         - Put a pixel to location X,Y (0 to 128) with RGB value
READ_PIXEL        - Read a pixel color value from location X,Y
CIRCLE            - Draw a circle at X,Y (0 to 128) with radius in pixel, RGB value and filled or not
LINE              - Draw a line from X1,Y1 to X2,Y2 (0 to 128) with RGB value
RECTANGLE         - Draw a rectangle from X1,Y1 to X2,Y2 (0 to 128) with RGB value and filled or not
PAINT             - Paint a zone from X1,Y1 to X2,Y2 with RGB value
BUTTON            - Draw a button from X1,Y1 to X2,Y2 with RGB value and pushed or not
BLOCK_COPY        - Copy a block of pixels from X1,Y1 to X2,Y2 at origin position X3,Y3
FONT_SIZE         - Set the font size between 5x7, 8x8 and 8x12
TEXT_MODE         - Set the text opaque or transparent
FCHAR             - Put a "formatted" character at X,Y with RGB value
UCHAR             - Put an "unformatted" character at X,Y with RGB value and horizontal, vertical scales values
TEXT              - Display a string of character at column X, row Y, with font size and RGB value
DISPLAY           - Set the display of the LCD to ON or OFF - * NOT THE SAME AS POWER *
CONTRAST          - Set the contrast of the LCD from 0 to 15 (15 default)
FADE_OUT          - Fade out the display by reducing the contrast in a loop
POWER             - Set the power of the LCD to ON or OFF   - * NOT THE SAME AS DISPLAY *
IMAGE             - Display an image at X,Y (0 to 128) of width and height in 1 byte per color or 2 byte per color

}}

CON
  
  ACK     = $06                                         ' Acknowledge byte
  NAK     = $15                                         ' Invalid command byte

  EN      = 13                                          ' Enable pin
  RX      = 14                                          ' Receive pin
  TX      = 15                                          ' Transmit pin

OBJ
  SERIAL  : "FullDuplexSerial"
  DELAY   : "Clock"

PUB INIT
  DIRA[EN] := 1
  OUTA[EN] := 0
  SERIAL.start (RX,TX,%0000,128000)

  DELAY.PauseMSec(20)
  ' Initialize LCD
  OUTA[EN] := 1
  SERIAL.rxflush
  DELAY.PauseMSec(20)
  SERIAL.tx ("U")
  WAITACK
  DELAY.PauseMSec(40)
  ERASE

PRI WAITACK | temp
  DELAY.PauseMSec(10)
  REPEAT
    temp := SERIAL.rxtime(20)
    if (temp == ACK)
      quit
    else
      SERIAL.rxflush
      SERIAL.tx ("U")

PUB SHUTDOWN
  POWER(0)

PUB ERASE
  SERIAL.tx ("E")
  WAITACK

PUB BACKGROUND (R,G,B)
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("B")
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK

PUB PUT_PIXEL (X,Y,R,G,B)
  '     X : 0 to 127
  '     Y : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255

  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("P")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK    

PUB READ_PIXEL (X,Y) : RGB
  '     X : 0 to 127
  '     Y : 0 to 127
  SERIAL.tx ("R")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  WAITACK
  RGB.byte[1] := SERIAL.rx
  RGB.byte[0] := SERIAL.rx

PUB CIRCLE (X,Y, RADIUS, R, G, B, FILL) : RGB
  '     X : 0 to 127
  '     Y : 0 to 127
  ' RADIUS: 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  FILL : 0 or 1 : Coloured fill circle or not

  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  if (FILL)
    SERIAL.tx ("i")
  else
    SERIAL.tx ("C")    
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (RADIUS)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0]) 
  WAITACK     

PUB LINE (X1, Y1, X2, Y2, R, G, B)
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("L")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK

PUB RECTANGLE (X1, Y1, X2, Y2, R, G, B, FILL)
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  FILL : 0 or 1 : Coloured fill rectangle or not
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("r")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  SERIAL.tx (FILL) 
  WAITACK  

PUB PAINT (X1, Y1, X2, Y2, R, G, B)
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("p")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK

PUB BUTTON (X1,Y1, X2, Y2, R, G, B, STATE)
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  ' STATE : 0 : DOWN, 1 : UP
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("b")    
  SERIAL.tx (STATE)
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK

PUB BLOCK_COPY (X1, Y1, X2, Y2, X3, Y3)
  '    X1 : 0 to 127
  '    Y1 : 0 to 127
  '    X2 : 0 to 127
  '    Y2 : 0 to 127
  '    X3 : 0 to 127
  '    Y3 : 0 to 127
  SERIAL.tx ("c")    
  SERIAL.tx (X1)
  SERIAL.tx (Y1)
  SERIAL.tx (X2)
  SERIAL.tx (Y2)
  SERIAL.tx (X3)
  SERIAL.tx (Y3)
  WAITACK

PUB FONT_SIZE (MODE)
  ' MODE = 0 : 5x7  font
  ' MODE = 1 : 8x8  font
  ' MODE = 2 : 8x12 font
  SERIAL.tx ("F")    
  SERIAL.tx (MODE)    
  WAITACK

PUB TEXT_MODE (MODE)
  ' MODE = 0 : Transparent Text
  ' MODE = 1 : Opaque Text
  SERIAL.tx ("O")    
  SERIAL.tx (MODE)    
  WAITACK

PUB FCHAR (X, Y, R, G, B, CHAR)
  '     X : 0-20 in 5x7, 0-15 in 8x8 and 8x12
  '     Y : 0-15 in 5x7 and 8x8, 0-9 in 8x12
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  CHAR : character to output
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("T")
  SERIAL.tx (CHAR)
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  WAITACK 

PUB UCHAR (X, Y, R, G, B, CHAR, WIDTH, HEIGHT)
  '     X : 0-127
  '     Y : 0-127
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  CHAR : character to output
  ' WIDTH : horizontal zoom factor
  'HEIGHT : vertical zoom factor
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("t")
  SERIAL.tx (CHAR)
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  WAITACK 

PUB TEXT (X,Y, R,G,B, FONT, STR)
  '     X : 0-20 in 5x7, 0-15 in 8x8 and 8x12
  '     Y : 0-15 in 5x7 and 8x8, 0-9 in 8x12
  '   Red : 0 to 255
  ' Green : 0 to 255
  '  Blue : 0 to 255
  '  FONT : See FONT_SIZE
  '  TEXT : Null-terminated string
  G := (G >> 2) << 5
  B := G + B >> 3
  R := B + (R >> 3) << 11
  SERIAL.tx ("s")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (FONT)
  SERIAL.tx (R.byte[1])
  SERIAL.tx (R.byte[0])
  REPEAT strsize(STR)
    SERIAL.tx (byte[STR++])
  SERIAL.tx (0)
  WAITACK 
  
PUB DISPLAY (mode)
  ' Mode : 0 - Down
  '        1 - Up
  SERIAL.tx ("Y")
  SERIAL.tx (1)
  SERIAL.tx (mode)      

PUB CONTRAST (value)
  ' value : 0 to 15
  SERIAL.tx ("Y")
  SERIAL.tx (2)
  SERIAL.tx (value)

PUB FADE_OUT (tdelay) | CCNT
  CCNT := 15
  REPEAT UNTIL CCNT < 0
    CONTRAST (CCNT)
    CCNT--
    DELAY.PauseMSec(tdelay)
  DISPLAY(0)

PUB POWER (mode)
  ' Mode : 0 - Down
  '        1 - Up
  SERIAL.tx ("Y")
  SERIAL.tx (3)
  SERIAL.tx (mode)

PUB IMAGE (X, Y, WIDTH, HEIGHT, COLOUR_MODE, PIXEL) | CCNT
  ' COLOUR_MODE : 8 -> 256 colour mode, 1 byte per pixel
  '              16 -> 65K colour mode, 2 bytes per pixel
  SERIAL.tx ("I")
  SERIAL.tx (X)
  SERIAL.tx (Y)
  SERIAL.tx (WIDTH)
  SERIAL.tx (HEIGHT)
  SERIAL.tx (COLOUR_MODE)
  CCNT := 0
  REPEAT WIDTH * HEIGHT * (COLOUR_MODE / 8)
    SERIAL.tx (BYTE[CCNT++ +PIXEL])
  SERIAL.tx (0)
  WAITACK  

   