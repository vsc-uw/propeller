{{
┌────────────────────────────────┐
│ Nx2 LCD Driver                 │
├────────────────────────────────┴────────────────────┐
│  Version : 1.3                                      │
│  By      : Tom Dinger                               │   
│            propeller@tomdinger.net                  │
│  Date    : 2010-11-14                               │
│  (c) Copyright 2010 Tom Dinger                      │
│  See end of file for terms of use.                  │
├─────────────────────────────────────────────────────┤
│  Width      : 16 Characters (columns)               │
│  Height     :  2 Lines (rows)                       │
│  Controller :  HD44780-based                        │
│                (KS0066 and similar)                 │
└─────────────────────────────────────────────────────┘
}}
{
  Version History:
  1.2 -- 2010-10-23 -- Initial release of 20x4 driver, in
                       the LCD_Ding_Batty package.

  1.3 -- 2010-11-14 -- changed the pin variable names to allow for
                       use of either the 4-bit or the 8-bit lowest-
                       level driver; added an alternate OBJ
}
{{

This is a driver for a 16 character, 2 line LCD display, but it should
work for any 2 line LCD with number of characters on the line

The display used for testing is part number NC1602B, manufactured
by NewTec Display Co. Ltd.
I found a proper datasheet at:
    http://microcontrollershop.com/download/mc1602b-series.pdf
It seems to use the the Samsung KS0066 display controller, which is
command-compatible with the HD44780 display controller. I expect that
many 16x2 LCD displays are compatible. 

This driver provides direct access to the functions of the display:
- writing text
- positioning the cursor
- setting the cursor mode: invisible, underline, blinking block
- shifting the display left and right
- shifting the cursor left and right.

This driver uses a lower-level driver object that manages initialization
of the display and data and command I/O, so that this object (and other
objects at this level) can focus on management of displayed data for
a particular geometry of display. 

Resources:
---------
NewTec Display Co. Ltd. display NC1602B:
    http://microcontrollershop.com/download/mc1602b-series.pdf
    
Hitachi HC44780U datasheet:
  http://www.sparkfun.com/datasheets/LCD/HD44780.pdf
Samsung KS0066U datasheet:
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXuuzvr.pdf
Samsung S6A0069 datasheet (successor to KS0066U):
  http://www.datasheetcatalog.org/datasheet/SamsungElectronic/mXruzuq.pdf
  

Interface Pins to the Display Module:
------------------------------------
Note that the actual assignments of functions to pins is done by
the code that uses this object -- the pin numbers are passed into
the Init() method.

   R/S  [Output] Indicates if the operation is a command or data:
                   0 - Command (write) or Busy Flag + Address (read)
                   1 - Data
   R/W  [Output] I/O Direction:
                   0 - Write to Module
                   1 - Read From Module
   E    [Output] Enable -- triggers the I/O operation 
   DB0  [In/Out] Data Bus Pin 0 -- bidirectional, tristate 
   DB1  [In/Out] Data Bus Pin 1 -- bidirectional, tristate
   DB2  [In/Out] Data Bus Pin 2 -- bidirectional, tristate
   DB3  [In/Out] Data Bus Pin 3 -- bidirectional, tristate
   DB4  [In/Out] Data Bus Pin 4 -- bidirectional, tristate 
   DB5  [In/Out] Data Bus Pin 5 -- bidirectional, tristate
   DB6  [In/Out] Data Bus Pin 6 -- bidirectional, tristate
   DB7  [In/Out] Data Bus Pin 7 -- bidirectional, tristate


DDRAM Address Map:
------------------   

    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│  <- ROW0 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│  <- ROW1 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘

}}      

CON

  ' Display dimensions
  NumLines =  2
  NumCols  = 16
  
  Line0Col0Addr       = $00
  Line1Col0Addr       = $40

  ' CharsInOneLine is the number of character positions in display RAM
  ' for one line. It does not necessarily correspond to the number
  ' of visible characters in one row of the display. This is used to
  ' determine when the cursor has moved off the end of a "line" in
  ' display memory.
  CharsInOneLine      = $28 ' == 40  

  LF  = 10


OBJ
  ' The LCDBase object provides access to the actual display device,
  ' and manages the details of the data interface (4 or 8 bit) and
  ' the other signals to the controller.
  '
  ' Pick only one of thexe lines, and make sure that the top-level
  ' program passes in the proper values for the data pins:
  ' 4 consecutive pins for the 4-bit interface, or 8 consecutive
  ' pins for the 8-bit interface.
  
  LCDBase : "LCDBase_4bit_direct_HD44780"
  'LCDBase : "LCDBase_8bit_direct_HD44780"

VAR
  ' CurDisplayCmd contains the most recent settings for the
  ' Display: display on/off, and cursor mode. It is used when changing
  ' only some of the display properties in methods of this obejct.
  byte CurDisplayCmd

  ' CurDisplayShift is the amount the display has been shifted,
  ' relative to the position after a Clear.
  ' Another way to interpret this value is that it is the display RAM
  ' address shown in the leftmost character position on the display.
  ' So, a left-shift of the display will increment this value.
  byte CurDisplayShift
  

PUB Init( Epin, RSpin, RWpin, DBHighPin, DBLowPin )
'' Initialize the display: assign I/O pins to functions, initialize the
'' communication, clear it, turn the display on, turn the
'' cursor off.

  ' We will be using both "lines" of the display controllery.
  LCDBase.Init( true, Epin, RSpin, RWpin, DBHighPin, DBLowPin )

  ' The following is how LCDBase initialized the display.
  ' If we wanted something different, we could issue the command
  ' ourselves at this point.
  CurDisplayCmd   := LCDBase#DispCtlCmd_On_CrsrOff_NoBlink
  CurDisplayShift := 0
  

PUB RawSetPos(addr)
'' Setthe next display RAM address that will be written, without
'' doing any adjustments for the geometry of the display.
'' This method is intended for special uses, and will not be used
'' by typical applications.

  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + addr )


PUB RawWriteChr( chr )
'' Write a character to the display, without adjustments for cursor
'' positioning on the display. Primarily used for "special effects".
'' Generally, PrintChr() will be more useful.

  return LCDBase.WriteByte( chr )
  ' no other adjustments
  

PUB RawWriteStr( str )
'' Write a series of characters (a string) to the display, without
'' adjusting for cursor positioning on the display. Primarily used for
'' "special effects". Generally, PrintStr() will be more useful.

  LCDBase.WriteData( str, strsize(str) )

PUB RawReadData : chr
'' read the data at the current position
'' NOTE: this does not always work as expected -- see the
'' relevant data sheets. It should always work right
'' after a cursor shift or cursor address operation.

  chr := LCDBase.ReadData
  'return chr


PUB Clear
'' Clear the display: write all spaces to the Display RAM, set the
'' display back to unshifted, cursor back to first character (leftmost)
'' on the display.

  LCDBase.WriteCommand( LCDBase#ClearDisplayCmd )
  CurDisplayShift := 0
  
  ' For some reason, for this display, we need to add a short
  ' delay here, or else the next couple of operations (the second
  ' data write done by PrintChr, to be precise) are not reliable.
  ' My best guess as to why: the current cursor address is
  ' not correct until a short while after the clear instruction
  ' reaches the "not busy" state, so the second address written to
  ' by PrintChr() will be calculated wrong.
  usDelay( 40 )


PUB GetPos( adr ) : RowAndCol
'' Gets the cursor position, as a row and column, encoded into the
'' value returned:
''     encoded as (row << 8) | col

  if ( adr => Line1Col0Addr )
    RowAndCol := constant( 1 << 8 )
    adr -= Line1Col0Addr
  else
    RowAndCol := 0
  
  ' Now, adjust for the display shift
  if ( adr < CurDisplayShift )
    adr += CharsInOneLine
  RowAndCol += adr - CurDisplayShift
  ' return rowcol

  
PUB SetPos(pos)
'' Sets the cursor position, to the row and column encoded into the
'' position value:
'' pos -- row and column, encoded as (row << 8) | col

  return SetRowCol( (pos >> 8), pos & $FF )


PUB SetRowCol(line,col) | addr
'' Position the cursor to a specific line and character position (column)
'' within that line.
'' line -- 0-based line number, masked to range 0..1
'' col  -- 0-based column number, or character position, in the line,
''         limited to 0..39.

  line &= $03             ' limit (modulus) to 0.. 1 -- masking is quicker
  col //=  CharsInOneLine ' limit (modulus) to 0..39

  ' We want these positions to correspond to what is showing on the
  ' display, so we adjust the location to write to, based on the
  ' amount the display has been shifted.
  col += CurDisplayShift
  if ( col => CharsInOneLine )
    col -= CharsInOneLine

  addr := col
  if ( line > 0 )
    addr += Line1Col0Addr
  else
    addr += Line0Col0Addr 

  return LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + addr )


PUB PrintChr( chr ) : curadr | col, row
'' Displays the character passed in at the current cursor position, and
'' advances the cursor position.
'' Returns the display RAM address of the cursor before writing the char
'' As of now, there is no spcial interpretation for "carriage control"
'' characters such as CR and LF.

  if ( chr == LF )
    return Newline

  curadr := LCDBase.WriteByte( chr )

  ' This is supposed to work "right" even when the display has been
  ' shifted left or right. To do that, we need to force the
  ' cursor to stay on the same line in a few cases.
  ' Hmmmm... It might just be easier to always set the new cursor
  ' position...
   
  col := GetPos( curadr )
  row := col >> 8
  col &= $FF
    
  if ( CurDisplayShift <> 0 )
    ' Here we need to worry about keeping the cursor on the
    ' same display row, when the controller would like to
    ' move it to another display row.
    ' The only boundary condition we deal with here is
    ' if we are crossing from line offset 39 to 40.
    ' In that case, we want to go back to line offset 0
    
    if ( (curadr & $3F) == constant(CharsInOneLine - 1) )
      ' Force the cursor to stay on the same row
      ' SetRowCol( row, col+1 )
      RawSetPos( curadr - constant(CharsInOneLine - 1) )
      return curadr ' this cannot be the end of a line, since
                    ' CurDisplayShift <> 0

  ' Always check for, and adjust, line changes.
  if ( col == constant( CharsInOneLine - 1 ) )
    ' We _always_ adjust which row the cursor moves to
    ' ASSUMING address increment, the cursor should now appear on the
    ' next line of the display
    SetRowCol( (row + 1) & $01, 0 )
     
  ' return curadr


PUB PrintStr( str )
'' Prints out each character of the string by calling PrintChr().

  ' For each character of the string
  '   printchr(c)
  repeat strsize(str)
    PrintChr( byte[str++] )


PUB Newline
'' Advance to the start of the next line of the display.

  ' TODO: do we clear the next line?

  return SetRowCol( MapAdrToLine(LCDBase.WaitUntilReady)+ 1, 0 )

PUB Home
'' Move the cursor (and the next write address) to the first character
'' position on the display.

  ' TODO: Use the LCDBase#CursorHomeCmd -- this will also "unshift"
  ' a shifted display.

  SetRowCol( 0, 0 )

PUB GetDisplayAddr : adr
'' Returns the next RAM address (the current cursor position).
  return LCDBase.WaitUntilReady '  & LCDBase#DisplayRamAddrMask

PUB usDelay(us)
'' Delay the specified number of microseconds, but not less than 382 us.

  LCDBase.usDelay(us)

PUB CursorOff
'' Turns the cursor off

  CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  'CurDisplayCmd |= LCDBase#DispCtl_CursorOff  ' = $00
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorBlink
'' Turn the cursor on -- for the tested display, it appears as a steady
'' underline, and the character cell alternates between the character
'' shown at that position, and all piels on (all black).

  'CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  CurDisplayCmd |= LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking
  LCDBase.WriteCommand( CurDisplayCmd )

PUB CursorSteady
'' Turns the cursor on -- for the tested display, it appears as a
'' steady underline.

  CurDisplayCmd &= !(LCDBase#DispCtl_CursorOn | LCDBase#DispCtl_Blinking)
  CurDisplayCmd |= LCDBase#DispCtl_CursorOn ' | LCDBase#DispCtl_NoBlinking
  LCDBase.WriteCommand( CurDisplayCmd )
 
PUB DisplayOff
'' Turns the dislpay off.

  CurDisplayCmd &= !LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB DisplayOn
'' Turns the display on -- makes no change to the contents of display RAM,
'' it just enabled the display of what is already in RAM.

  CurDisplayCmd |= LCDBase#DispCtl_DisplayOn
  LCDBase.WriteCommand( CurDisplayCmd )

PUB ShiftCursorLeft | curadr, col
'' Shift the cursor position to the left one character.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Left )

  ' TODO: Is that enough?

PUB ShiftCursorRight | curadr, col
'' Shift the cursor position to the right one character.

  curadr := LCDBase.WriteCommand( LCDBase#CursorShiftCmd_Right )

  ' TODO: Is that enough?

PUB ShiftDisplayLeft
'' This shifts the entire display contents to the left one character.
'' The cursor "moves" with the display, so that it appears to stay
'' on the same character being displayed.

  LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Left )
  CurDisplayShift += 1
  if ( CurDisplayShift => CharsInOneLine )
    CurDisplayShift -= CharsInOneLine ' limit to $00..$27

PUB ShiftDisplayRight
'' This shifts the entire display contents to the right one character.
'' The cursor "moves" with the display, so that it appears to stay
'' on the same character being displayed.

  LCDBase.WriteCommand( LCDBase#DisplayShiftCmd_Right )
  if ( CurDisplayShift == 0 )
    CurDisplayShift := constant(CharsInOneLine-1) ' limit to $00..$27
  else
    CurDisplayShift -= 1


PUB WriteCharGen( index, pRows ) | c, curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' pRows -- a pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) )
  
  c := byte[ pRows++ ]   ' get the first character  
  repeat while ( (c & $E0) == 0 )
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( c )
    c := byte[ pRows++ ]

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )


PUB WriteCharGenCnt( index, line, pRows, len ) | curadr
'' Write the supplied pattern to the character generator RAM.
'' index -- The character index to write, from 0..7
''          The value is masked to that range
'' line -- Scan line to start within the character, from 0..7
''         The value is masked to that range.
'' pRows -- A pointer to the character cell row data; only the low
''          order 5 bits are used for the character.
''          Any byte outside the range $00..$1F will end the range
''          written to the Char Gen RAM
'' len -- Number of character scan lines to write -- one character
''        contains 8 scan lines. NOTE: Not range-limited!

  ' We save the current cursor position so we can restore it later...
  curadr := LCDBase.WriteCommand( LCDBase#SetCgRamAddrCmd + ((index & $07) << 3) + (line & $07) )
  
  repeat len
    ' The high bits are not set
    ' NOTE: This assumes addresses auto-increment 
    LCDBase.WriteByte( byte[ pRows++ ] )

  ' Now that we have written all the CG data, restore the
  ' current cursor position
  LCDBase.WriteCommand( LCDBase#SetDisplayRamAddrCmd + curadr )

    
' ---------------------------------------------------------------
' We define some helper functions: map from a low-area address to
' a high-area, and vice-versa, and cnovert between an address and a
' column position

PRI MapAdrToLine( adr ) : line
  ' Given a display RAM address, determine the display row
  ' containing it, using the current display shift.

  if ( adr => Line1Col0Addr )
    line := 1            ' either line 1 or line 3
  else
    line := 0            ' either line 0 or line 2
  ' return line

PRI MapAdrToCol( adr ) : col
  ' Given a display RAM address, determine the display column
  ' containing it, using the current display shift.
  if ( adr => Line1Col0Addr )
    adr -= Line1Col0Addr ' make adr $00..$27
  
  ' Now, adjust for the display shift
  if ( adr < CurDisplayShift )
    adr += CharsInOneLine
  col := adr - CurDisplayShift
  ' return col



' TODO:
' - Clear to EOL method?
'
' Open questions:
' - Do we need, for the FunctionSet command:
'   - IncrementingAddresses
'   - DecrementingAddresses
'   - Enable/Disable display shift on write

{{
Detailed Display Information:
----------------------------

The display seems to use the Samsung KS0066 LCD display controller,
which accepts the same command set as the HD44780 controller, and has
a parallel interface either 4 bits or 8 bits wide.

The display has 80 characters in 4 rows of 20 columns, which is exactly
the number of Display RAM characters supported by the controller. The
only thing that makes use of the display a little complicated is that
the order in which the controller writes the character positions is
not quite the expected reading order: after the top row, the next row
of characters written is the _third_ row, then the _second_ row, and
finally the fourth row. So the PrintChr() and PrintStr() methods
compensate for this, to change the order in which the rows are written.

Another consequence of this is that when scrolling the entire display,
the first and third lines scroll together, and the second and fourth
lines scroll together, as if they were one long 40-character line. This
makes display scrolling less useful. 


DDRAM Address Map:
------------------   
    00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19   <- CHARACTER POSITION
   ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
   │00│01│02│03│04│05│06│07│08│09│0A│0B│0C│0D│0E│0F│10│11│12│13│  <- ROW0 DDRAM ADDRESS
   │40│41│42│43│44│45│46│47│48│49│4A│4B│4C│4D│4E│4F│50│51│52│53│  <- ROW1 DDRAM ADDRESS
   │14│15│16│17│18│19│1A│1B│1C│1D│1E│1F│20│21│22│23│24│25│26│27│  <- ROW2 DDRAM ADDRESS
   │54│55│56│57│58│59│5A│5B│5C│5D│5E│5F│60│61│62│63│64│65│66│67│  <- ROW3 DDRAM ADDRESS
   └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
}}
{{

  (c) Copyright 2010 Tom Dinger

┌────────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                           │                                                            
├────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a     │
│copy of this software and associated documentation files (the               │
│"Software"), to deal in the Software without restriction, including         │
│without limitation the rights to use, copy, modify, merge, publish,         │
│distribute, sublicense, and/or sell copies of the Software, and to          │
│permit persons to whom the Software is furnished to do so, subject to       │
│the following conditions:                                                   │
│                                                                            │
│The above copyright notice and this permission notice shall be included     │
│in all copies or substantial portions of the Software.                      │
│                                                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS     │
│OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                  │
│MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.      │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, │
│DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       │
│OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE   │
│USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└────────────────────────────────────────────────────────────────────────────┘
}}
  