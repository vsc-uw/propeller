{{  LED_Blink_VGA_02.spin

    Copyright 2011 by Greg Denson
    See bottom of this document for MIT License and terms of use.
    
    Created 2011-07-16, by Greg Denson
    Created using Propeller Tool v.1.2.7

    This is a very simple demonstration of the use of a VGA monitor with the
    Propeller chip.  I used the Propeller Professional Development Board for
    testing the program, but other boards including thh Propeller Demo Board
    have worked just as well with the program.  The Professional Development
    Board, however, gives us a chance to talk more about how to make the VGA
    connections to the Propeller chip's pins - another learning opportunity!

    As with most of my recent postings to the Object Exchange, this program
    is intended for newer users who are just learning how to work with the
    Propeller chip.  Since I'm also fairly new to it, I am just sharing the
    end result of my own research and trial and error testing in order to help
    other new users try out some of the more interesting and difficult uses of
    the Propeller with other hardware - in this case a VGA monitor.

    There are way more comments here than there is code. So, to most
    experienced users, this sort of demo probably won't be too interesting.
    Once you get to a place where you want to build your own project around
    the template in this demo, you can delete most of the comment lines.
    However, if you plan to build something bigger and want to share it with
    other users, please remember to generously comment your new version of
    this program for the benefit of future users.
    
    The original inspiration for this program came from Harprit Singh Sandhu's
    excellent book "Programming the Propeller with Spin - A Beginner's Guide to
    Parallel Processing"  I modified one of his program's for blinking an LED so
    that I would have a program with some sort of visible output to use along
    with the demonstration of the use of the VGA monitor.

    So, what we will discuss below is how to connect your Propeller chip to the
    VGA monitor, and how to use the demo program to send a few simple pieces
    of information to the monitor.  Hopefully, that will be enough to spark
    your own creativity in using the Propeller and VGA in your own projects.

    This demo program uses the vga_Drive.spin object, so you'll want to be
    sure to download a copy of that from the Parallax Object Exchange web site
    and store it in your Propeller Tool's working directory.  This is an easy
    to use VGA text driver by Michael Green.  It contains a few nice text-based
    methods for sending data to the VGA monitor.  The demo program below will
    call those methods to accomplish the tasks it needs to do.  Later, once
    you are familiar with this driver object, you may want to branch out
    into other more complex VGA driver objects that are available on the
    Object Exchange, however, this is a good place to start for your first
    VGA efforts.
}}

CON                            
  _CLKMODE=XTAL1 + PLL16X       ' Here we specify the system clock setup
  _XINFREQ = 5_000_000          ' And here's the frequency of the crystal we will be using (on my PPD Board)
                                '
  high        = 1               ' The 'high' constant lets me refer to sending out a '1' by using the word 'high'
  low         = 0               ' Same approach for sending out a '0' from the Propeller's output pin.
  waitPeriod  = 100_000_000     ' At the clock frequency we are using, this amounts to about a 1 second wait
                                ' each time the LED is turned on or turned off in the program below.

  Cr          = 13              ' This is another constant that I set up to represent a carriage return so that
                                ' we can demonstrate an additional method from the vga_Drive object.  More on this
                                ' below.  For now, just remember that 13 is the ASCII code for a carriage return.


  output_pin  = 0               ' This constant says that the output pin we are using each time will be Pin 0.


  dspPins     = 16              ' This tells the vga_Drive object that my pin setup for VGA starts at Pin 16.
                                ' When we get to the connections diagram below, you will see that my VGA pin
                                ' connections to the Propeller chip run from Pin 16 to Pin 23 (8 pins are used.)
                                ' When setting up my Prof Dev Board, I looked at the Demo Board's VGA connections
                                ' and just copied them. the VGA connector on the Demo Board is hardwired fo Pins
                                ' 16 through 23, so you don't have to wire any connections to set up VGA on that
                                ' board.  However, the PPD Board has a VGA connector, a pin header for VGA
                                ' connections, and has the necessary resistors in place, but does not have any
                                ' permanent connections on the board from the header to the Propeller chip's pins.
                                ' So we have to make those connections ourselves from the VGA header to the
                                ' Propeller Pins 16-23.
              'IMPORTANT NOTE:  ' However, as you can see from this constant, all we have
                                ' to tell the vga_Drive object is the lowest numbered pin - AS LONG AS WE
                                ' CONSISTENTLY WIRE THE OTHER 7 PINS CORRECTLY AS SHOWN BELOW.  This is important.
                                ' because if we don't follow that consistent pattern to make our other connections
                                ' from Pins 17-23 in a particular order, then the program and the vga_Drive object
                                ' won't know where to get our other VGA signals, and it won't work correctly.
                                ' Moral of this story:  Follow the patter below consistenly until you learn
                                ' enough to revise the whole pattern in a way that will work.


{{ CONNECTING THE HARDWARE:

(1)  Connections from the VGA header on the PPD Board to the Propeller chip's pins:                                                       

 VGA Header     
(Left Side)      PROPELLER (Professional Development Board)
       ───┐      ┌───
  0 - V   │─────│ Pin 16    At the far left, the number is my own numbering scheme for pins on the PPDB VGA header
  1 - H   │─────│ Pin 17    The letter/number combinations are the signal IDs for the various pins of the VGA header:
  2 - B1  │─────│ Pin 18    V = Vertical, H = Horizontal, B = Blue, G = Green, R = Red, etc.
  3 - B0  │─────│ Pin 19    Each of the RGB signals are split into two values using different size resistors on the PPDB & Demo Boards
  4 - G1  │─────│ Pin 20    
  5 - G0  │─────│ Pin 21    The Pin IDs on the right side of this diagram are the Propeller chip pins to which
  6 - R1  │─────│ Pin 22    VGA connections are made.
  7 - R0  │─────│ Pin 23
       ───┘      └───
VGA Header
(Right Side)


NOTE:  For more information on VGA connections, see the Propeller Demo Board schematic available for download from Parallax.com.
-------------------------------------------------------------------------------------------------------------
Here's another diagram that attempts to show the pin header sockets on the VGA header and the Propeller pins
to which they are connected.  I've also added the IDs for the various signals on each pin as they are
printed on the PPDB's circuit board.  Below that is the pin designation for the VGA cable's pins as well.
You shouldn't need the information in the lower half of the diagram unless you're building your own VGA
cable connection as part of a project.

The connections below are from the Professional Development Board's VGA header 
to the PPDB's Propeller pins.  The left and right directions are correct when you
are facing the end of the PPD Board where the VGA connector is located.


       VGA Pin Header Sockets:
Left    0  1  2  3  4  5  6  7   Right    (These are my own numbers for the sockets on the VGA header from left to right. They aren't on the board.)  
       [ ][ ][ ][ ][ ][ ][ ][ ]           (These brackets represent the holes in the VGA pin header near the VGA Cable connector on the PPDB)

       PPD Board's Prop Pins:
        16 17 18 19 20 21 22 23           Propeller Pin Numbers to which the above header sockets are connected
       [ ][ ][ ][ ][ ][ ][ ][ ]           (These brackets represent the holes on the pin header for connecting to the Propeller chip on the PPDB)

        Just for future reference:
        V   H  B1  B0  G1  G0  R1  R0      (IDs of the signals on each of the 8 pins of the VGA header - Vertical, Horizontal, RGB)
        14  13  3   3   2   2   1   1      Pin numbers for the associated VGA cable connector.
                                           The multiple connections to some pins (1, 2, 3) are passed through
                                           two different sizes of resistors to obtain the necessary final resistance values.
                                           If you ever create your own connections to a VGA cable, you would need to include
                                           these resistors in your design. As you can see, only 5 pins (1,2,3,13,14) of the VGA
                                           cable are used for signals.  With the splitting of the RGB signals on pins 1-3 into two
                                           each, you wind up needing the 8 pins of the PPDB's VGA header to accommodate all the
                                           signals for this VGA setup. There are also several ground and +5V connections that you
                                           would need to deal with for your own design. These power connections are already handled
                                           for you on the PPD Board and the Demo Board.   
                                                      
                                                        
(2) And, her's the connection for the LED.  It's pretty simple, but just to be sure everyone knows how to connect it,
    here's the setup I used while preparing this demo program.  All the connections are made to the Propeller chip's pins
    (or to breadboard pins tied to the Propeller chip's pins if you use a breadboard.)

    As you can see, I connected my LED and a resistor between Pin 0 of the Propeller chip and one of the ground pins on the PPDB.
    In various designs, I see people use resistors of 220, 270, 330, or 470 Ohms for this sort of application. You can calculate the
    proper size for this sort of thing, but I had a 220 Ohm resistor handy, and it worked, and by the way 220 Ohms is about the right
    size for use with most LEDs with 3.3 Volts.  If you power the LED with 5 Volts, you may want to go to a higher resistance.

    Now, when I say 'most' LEDs above, that means the typical ones that draw about 20mA of current. Rather than
    writing a book on this subject, I will suggest that if you want to get into the finer points of calculating current limiting
    resistors for your projects, you visit a web site such as:  http://tinkerlog.com/2009/04/05/driving-an-led-with-or-without-a-resistor/
    and read some more about it. As you can tell from the URL, you have a choice to not use an LED.  However, it's purpose is to limit
    current that may damage your electronic devices, and you should know that a small change in voltage could result in a very large
    change in current.  So... USE THE RESISTOR!!!  It's cheap and effective.

         PROPELLER (Propeller Professional Development Board - PPDB)

             ───┐    LED     220 Ohm      
          P0    │───────────────┐     Be sure the cathode of the LED is connected toward the ground (GND) side of the circuit.  
                │                   │     The cathode is the shorter lead of the LED, and often has a flat spot on the rim of the LED, too.
          GND   │───────────────────┘
             ───┘         

    Again, notice that the LED is connected to Pin 0 of the Propeller chip.  That is important because the program below will expect it
     to be on that pin.  If you want to use another pin for some reason, be sure to change the "output_pin" constant above to have the
     new pin number instead of '0' which is its current value.                           
 }}

OBJ
   dsp : "vga_Drive"            ' We give the vga_Drive.spin object the name of 'dsp' which we will use in the code below.
                                ' vga_Drive.spin contains the methods for starting and stopping the VGA functionality, and for
                                ' sending out the data to the VGA monitor.  Open up the vga_Drive.spin program and have a look
                                ' at all the PUB methods that are included in it.  You can use these to send various types of data
                                ' to the monitor.  We will be using the 'str' and 'out' methods in our demo, below.  You may find
                                ' other methods you'd like to try as well.  The declaration of each of those PUB methods also acts
                                ' as a template to show you how to send your data to the vga_Drive method. For example, look at this
                                ' declaration of the 'start' method in vga_Drive.spin:
                                '      PUB start(basePin)                 
                                ' it tells us that when we call the 'start' method, we should send in our base pin number - the lowest
                                ' numbered pin of the ones we're using for our VGA connection.  Look up above in the CON section of
                                ' this demo program and find:   "dspPins     = 16"
                                ' This is where we set up pin 16 to be our base pin.  And here is where we actually called the 'start'
                                ' object for this demo - look down below just a few lines in the PUB Go method and find:
                                '      dsp.start(dspPins)
                                ' In that line, below, we sent dspPins, which is set to 16, to the 'start' method of vga_Drive.spin so
                                ' that vga_Drive.spin will know that our base pin is Pin 16.   
   
PUB Go
  dsp.start(dspPins)            ' This call to the vga_Drive 'start' method, uses Pin 16 (dspPins constant) as the base pin.
  waitcnt(clkfreq + cnt)        ' A short wait while everything gets started up.  I like to do this to be sure my monitor comes awake
                                ' in time to see the first data come in.  You can remove this line if you don't need or want it.
                                '
                                ' NOTE:  As this program runs, all you're going to see on the VGA Monitor. after a short delay, is this:
                                ' LED Off
                                ' LED On
                                ' LED Off
                                ' LED On
                                ' ...
                                ' repeated over and over again, but that's what will let you know you have the connections right,
                                ' and that the program is working correctly.  I hope that will be enough to spark your imagination
                                ' and desire to experiment with this basic setup, and do something more adventurous with it.
                                ' Good luck!!!    
                                '
  dira [output_pin]~~           ' output_pin is set to '0' fpr this demo, Pin 0 is set up to be an output pin by this command '~~'.
  outa [output_pin]~~           ' This command now sets output pin 0 to high (turns on the LED for starters.)

  repeat                        ' Now we go into a loop that will continuously turn the LED on and off based on the commands, below.
                                ' I've actually included two ways of doing this in the lines below.  One of them directly turns the LED
                                ' on or off from within the repeat loop.  The other one calls a PRI method, listed below to turn the LED
                                ' off and another PRI method to turn it on.  If you are going to use this demo as a template to do
                                ' greater things, you should learn to use techniques like these PRI methods since you may have other parts
                                ' of your program that need to call a routine to turn the LED on and off.  It makes the code reusable, and
                                ' simpler to read.  The PRI methods below were used in Harprit Sandhu's book where I found the original
                                ' LED code for this demo.  Again, it's a good idea to learn this technique. I just included the lines below
                                ' that are commented out to show you that if you only need the simple straightforward method without calling
                                ' the PRI methods, you can use that as well.  You must comment out one of the techniques or the other, so
                                ' if you leave "outa[0] := 0" commented out, the PRI methods will be called and used.  However, if you
                                ' uncomment those lines, and comment out the lines like this "turnOff_LED", then the PRI methods won't
                                ' be called, and the repeat loop will take care of the turn on / turn off by itself.
                                ' Again, comment out one or the other, but not both or neither, for best results.  Otherwise, you're
                                ' on your own.  :)
                                   
    turnOff_LED                 ' Call the private (PRI) method below to turn the LED off. You can use this method as is, or comment out
                                ' this line, and uncomment the line below to skip the call to the PRI method below
    'outa[0] := 0               ' An optional method of turning off the LED without the turnOff_LED method (comment out one or the other)

    dsp.str(string("LED Off"))  ' Here we tell the vga_Drive 'str' method to output a string message to the VGA monitor.  In this case, we
                                ' letting ourselves know, via the monitor, that our LED is OFF.  So, 'str' is the
                                ' name of the method in vga_Drive that we are calling, and we have to send it some sort of representation
                                ' of the string we want to print.  In this case, we just sent it the literal string.  If we had stored our
                                ' string in a variable, we would have had to send the location of that variable to the method instead. We
                                ' can also use lines like this:  dsp.str(string("LED Off", 13))
                                ' to send our message plus a carriage return (ASCII code 13) to the monitor.  A few lines farther down,
                                ' and we will see some other ways to send that ASCII code 13 for a Carriage Return.
                                
    dsp.out(13)                 ' Here's another way to send that carriage return.  Just output 13 to the monitor.
    wait                        ' We have this wait in order to allow the LED to remain off for about a second.  If we don't do this, the
                                ' LED will blink so fast that it appears to be ON all the time!
                                
    turnOn_LED                  ' Next, we call the turnOn_LED method to light up the LED.
    'outa[0] := 1               ' Again an optional method for turning on the LED from inside this loop.
    dsp.str(string("LED On"))   ' This tells us, via the monitor, that the LED is now ON.
    
    dsp.out(Cr)                 ' Yet another way to send a carriage return.  This time we stored the value 13 in a variable, and use the
                                ' variable's name to call up that value via the 'out' method in vga_Drive.spin.
    wait                        ' Another wait period to allow the LED to stay on for about a second.  Notice that 'wait' is also the name
                                ' of another PRI method, shown below.  So this line simply makes a call to the 'wait' method and it has
                                ' the necessary code to cause the one second delay (approximately).

PRI turnOn_LED                  ' This method sets the LED output pin to HIGH to turn the LED to ON
  outa[output_pin] := high      ' And this line is the one that actually sets the LED output pin to HIGH

PRI turnOff_LED                 ' These lines do the same thing in order to turn the LED to OFF.
  outa[output_pin] := low       ' This line sets the LED output pin to LOW or OFF

PRI wait                        ' The method to give us approximately one second of dellay.
  waitCnt(waitPeriod + cnt)     ' This works by adding our waitPeriod constant from the CON section above to the current 'cnt' counter value
                                ' and then waiting until 'cnt' reaches that new time (or count). 

{{
                            TERMS OF USE: MIT License

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
}}       
    