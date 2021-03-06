{{
┌───────────────────────────────┬───────────────────┬────────────────────┐   
│     GPS_Str_NMEA.spin v1.0    │ Author: I.Kövesdi │ Rel.: 24. jan 2009 │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2009 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │ 
│  The 'GPS_Str_NMEA' driver interfaces the Propeller to a GPS receiver. │
│ This NMEA-0183 parser captures and decodes RMC, GGA, GLL, GSV and GSA  │
│ type sentences of the GPS Talker device even at 115.2K baud rate. The  │
│ driver extracts and preprocesses all navigation and satellite data in a│
│ robust way. It counts events for timeout control, checks string buffer │
│ overrun, calculates checksum and guards general data integrity. It     │
│ stores time stamps of valid navigation data and it does not overwrite  │
│ valid data during GPS dropouts. It hands out information to higher     │
│ level objects as pointers to the appropriate strings or as long valued │   
│ counters. These strings are grouped in a data depository section of the│ 
│ DAT area. The user can access the last received NMEA data strings, as  │
│ well. Upon arrival of a not recognized NMEA sentence, the driver       │
│ provides the user the type and data strings of that sentence, too. In  │
│ this way she/he can easily enhance the parser to decode those          │
│ sentences, be any of the proprietary formats.                          │   
│                                                                        │  
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│  The NMEA-0813 standard for interfacing marine electronics devices     │
│ specifies the NMEA data sentence structure also general definitions    │
│ of approved sentences. However, the specification does not cover       │
│ implementation and design.                                             │
│  NMEA data is sent from one Talker to Listeners in 8-bit ASCII where   │
│ the MSB is set to zero. The specification also has a set of reserved   │
│ characters. These characters assist in the formatting of the NMEA data │
│ string. The specification also states valid characters and gives a     │
│ table of these characters ranging from HEX 20 to HEX 7E.               │
│  Most GPS unit acts as an NMEA 'Talker'device and sends navigation and │
│ satellite information via an RS232 or TTL serial interface using NMEA  │
│ sentence format starting with '$GP' where '$' is the start of message  │
│ character and 'GP' is the Talker identifier (for GPS). The next 3 ASCII│
│ characters, like 'RMC' in the '$GPRMC' sentence header, define the     │
│ sentence identifier.                                                   │
│  All units that support NMEA should support 4_800 baud (bit per second)│
│ rate. Most NMEA Talker devices can transmit NMEA data at higher baud   │
│ rates, as well. This driver that makes the Prop as a Listener, was     │
│ tested and was found to work well at 4_800 baud and at several higher  │
│ baud rates up to 115_200.                                              │
│  This driver recognizes the NMEA sentences of a GPS Talker device and  │
│ extracts the navigation information from the RMC, GGA, GLL ones and    │
│ the satellite information from the GSV and GSA sentences. Each of these│
│ sentences ends with a <CR> <LF> sequence (HEX 0D, 0A) and can be no    │
│ longer than 79 characters of visible text (plus start of message '$'   │
│ and line terminators <CR><LF>).                                        │
│  The data is contained within a single line with data items separated  │
│ by commas. The minimum number of data fields is 1. The data itself is  │
│ just ASCII text and may extend over multiple sentences in certain      │
│ specialized instance (e.g. GSV sentence packet) but is normally fully  │
│ contained in one variable length sentence. The data may vary for       │
│ precision contained in the message. For example time might be indicated│
│ to decimal parts of a second or location may be show with 3 or even 4  │
│ digits after the decimal point. The driver uses the commas to find     │
│ field boundaries and this way it can accept all precision variants.    │
│  There is a  checksum at the end of each listened sentence that is     │
│ verified by the driver. The checksum field consists of a '*' and two   │
│ hex digits representing an 8 bit exclusive OR of all characters        │
│ between, but not including, the '$' and '*'.                           │
│                                                                        │
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│  This driver has the "GPS_Str_NMEA_Lite.spin v1.0" Driver as its       │
│ smaller and faster sibling but with less features. The Lite version    │
│ keeps the robustness of the full version, though.                      │
│                                                                        │ 
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE        = XTAL1 + PLL16X
_XINFREQ        = 5_000_000

'NMEA sentences ends with <CR>, <LF> (13, 10) bytes. I used only <CR> 
'here to detect sentence termination
_CR             = 13        'Carriage Return ASCII character

_MAX_NMEA_SIZE  = 82        'Including '$', <CR>, <LF> (NMEA-183 protocol)                            

_MAX_FIELDS     = 20        '(NMEA-183 protocol) 

'-----------------Recommended Minimum Specific GNSS Data------------------     
_RMC            = 1         'Time, date, position, course and speed data
                            
'------------------Global Positioning System Fixed Data------------------- 
_GGA            = 2         'Time, position, altitude, MSL and fix data
                            
'------------------------Latitude, Longitude data-------------------------
_GLL            = 3         'Latitude, Longitude,Time

'---------------------GNSS DOP and Active Satellites----------------------
_GSA            = 4         'GPS receiver operating mode, satellites used
                            'in the position solution, and DOP values.
                            
'-------------------------GNSS Satellites in View-------------------------   
_GSV            = 5         'The number of GPS satellites in view,
                            'satellite ID numbers, elevation, azimuth and
                            'SNR values.
'A GSV sentence contains data for up to 4 satellites. There might be up to
'three sentences in a GSV sentence packet at 4_800 baud


VAR

LONG nmea_Rx_Stack[50]
LONG nmea_D_Stack[50]


'COG identifiers
BYTE cog1, cog2, cog3 

BYTE semID_Refresh        'Semaphore ID for allow/deny external data acces
                          'Lock with this ID is set (RED) : data not ready
                          '            If cleared (GREEN) : data ready
BYTE semID_BlockMove      'Semaphore ID for allow / deny strBuffer block
                          'moves                                      

'Arrays used in NMEA sentence receiving / processing
LONG cptr, cptr1, cptr2
BYTE strBufferRx[_MAX_NMEA_SIZE]
BYTE strBuffer1[_MAX_NMEA_SIZE]
BYTE strBuffer2[_MAX_NMEA_SIZE]      
WORD fieldPtrs[_MAX_FIELDS]         

LONG lastReceived        'Type of last received NMEA sentence
LONG ptrNMEASentType     'Pointer to last recognised NMEA sentence type
LONG ptrNMEANotRecog     'Pointer to last not recognised NMEA sent. type

LONG nmeaCntr0           'NMEA started sentence counter
LONG nmeaCntr1           'NMEA verified sentence counter
LONG nmeaCntr2           'NMEA failed sentence counter
LONG rmcCntr
LONG ggaCntr
LONG gllCntr
LONG gsvCntr
LONG gsaCntr

LONG ccCks
LONG rXCks


OBJ

'GPS_UART :  "FullDuplexSerial"               'With 16 byte buffer
                                             'Can be used here up to
                                             '57_600 baud. At higher baud
                                             'rates use the 'Extended'
                                             'variant with 256 byte buffer 
                                              
GPS_UART :  "FullDuplexSerialExtended"       'With 256 byte buffer

   
  
PUB StartCOGs(rX_FR_GPS,tX_TO_GPS,nmea_Mode,nmea_Baud) : oKay
'-------------------------------------------------------------------------
'--------------------------------┌───────────┐----------------------------
'--------------------------------│ StartCOGs │----------------------------
'--------------------------------└───────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: -Starts FullDuplexSerial (that will launch a COG)
''             -Starts 2 COGs for two  SPIN inerpreters for the
''             Concurent_NMEA_Receiver and Concurent_NMEA_Decoder
''             procedures
''             -Resets global pointers                                 
'' Parameters: Rx, Tx pins on Prop and mode, baud parameters for the
''             serial communication with the GPS                                 
''    Results: TRUE if successful, FALSE otherwise                                                                
''+Reads/Uses: cog1, cog2, cog3                                               
''    +Writes: None                                    
''      Calls: None                                                                  
'-------------------------------------------------------------------------
  
'Start FullDuplexSerial for GPS NMEA communication. This will be used
'exclusively by the "Concurent_NMEA_Receiver" procedure
cog1 := GPS_UART.Start(rX_FR_GPS,tX_TO_GPS,nmea_Mode,nmea_Baud)

'Start a SPIN interpreter in separate COG to execute the tokens of the
'"Concurent_NMEA_Receiver" SPIN procedure parallely with the other COGs
cog2 := COGNEW(Concurent_NMEA_Receiver, @nmea_Rx_Stack) + 1

'Start a SPIN interpreter in separate COG to execute the tokens of the
'"Concurent_NMEA_Decoder" SPIN procedure parallely with the other COGs
cog3 := COGNEW(Concurent_NMEA_Decoder, @nmea_D_Stack) + 1 

oKay := cog1 AND cog2 AND cog3
'If oKay then the necessary 3 COGS were available

IF oKay
  'Allow some time for the Concurent_NMEA_Receiver process to fill up the
  'data string table
  WAITCNT(2 * CLKFREQ + CNT)
ELSE    'Some COG was not available
  IF cog1
    GPS_UART.Stop
  IF cog2
    COGSTOP(cog2 - 1)
  IF cog3
    COGSTOP(cog3 - 1)
     
'Reset global pointers
cptr~
cptr1~
cptr2~    
      
RETURN oKay


PUB StopCOGs
'-------------------------------------------------------------------------
'--------------------------------┌──────────┐-----------------------------
'--------------------------------│ StopCOGs │-----------------------------
'--------------------------------└──────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Stops recruited COGs                                 
'' Parameters: None                                 
''    Results: None                                                                
''+Reads/Uses: cog1, cog2                                               
''    +Writes: None                                    
''      Calls: None                                                                  
'-------------------------------------------------------------------------  

GPS_UART.Stop                  'This stops cog1
COGSTOP(cog2 - 1)
COGSTOP(cog3 - 1)
'-------------------------------------------------------------------------

PUB Reset
'-------------------------------------------------------------------------
'----------------------------------┌───────┐------------------------------
'----------------------------------│ Reset │------------------------------
'----------------------------------└───────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Sets back status and mode data to invalid or no Fix                                 
'' Parameters: None                                 
''    Results: None                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: None
''       Note: Valid status may freeze during GPS dropout, when some types
''             of GPS Talkers do not send RMC sentences until the new Fix.
''             The user, however, can recognise this by checking the
''             counters. This process helps to restore correct GPS status                                                                 
'-------------------------------------------------------------------------  

BYTE[@strGPSStatus] := "V"
BYTE[@strGPSMode] := "N"
BYTE[@strPosMode] := "1"
BYTE[@strFixQual] := "0" 
'-------------------------------------------------------------------------


PUB Long_NMEA_Counters(index)
'-------------------------------------------------------------------------
'---------------------------┌────────────────────┐------------------------
'---------------------------│ Long_NMEA_Counters │------------------------
'---------------------------└────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Yields various counters of the driver                                 
'' Parameters: Index: 0 - query No. of started NMEA sentences
''                    1 - query No. of checksum verified sentences
''                    2 - query No. of checksum failed sentences
''                    3 - query No. of decoded RMC sentences
''                    4 - query No. of decoded GGA sentences
''                    5 - query No. of decoded GLL sentences 
''                    6 - query No. of decoded GSV sentences 
''                    7 - query No. of decoded GSA sentences 
''                    8 - query last calculated checksum
''                    9 - query last received checksum
''    Results: Corresponding long value                                            
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                   
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded
CASE index
  0:RETURN nmeaCntr0
  1:RETURN nmeaCntr1
  2:RETURN nmeaCntr2
  3:RETURN rmcCntr
  4:RETURN ggaCntr
  5:RETURN gllCntr
  6:RETURN gsvCntr
  7:RETURN gsaCntr
  8:RETURN cCCks
  9:RETURN rXCks
'-------------------------------------------------------------------------


PUB Str_Last_Decoded_Type(index)
'-------------------------------------------------------------------------
'-------------------------┌───────────────────────┐-----------------------
'-------------------------│ Str_Last_Decoded_Type │-----------------------
'-------------------------└───────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: Returns the type of the last NMEA sentence                                 
'' Parameters: Index                                 
''    Results: Decoded type        for 0
''             Not recognized type for 1                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  0:RETURN ptrNMEASentType
  1:RETURN ptrNMEANotRecog
'-------------------------------------------------------------------------

  
PUB Str_Data_Strings
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Str_Data_Strings │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the data strings of the last sentence as a
''             continuous byte array including terminating zeroes                                 
'' Parameters: None                                 
''    Results: Pointer to string(s)                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded
RETURN @strBuffer1
'-------------------------------------------------------------------------


PUB Str_UTC_Time
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Str_UTC_Time │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the UTC data string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strTime
'-------------------------------------------------------------------------


PUB Str_UTC_Date
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐--------------------------
'------------------------------│ Str_UTC_Date │--------------------------
'------------------------------└──────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the UTC date string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                    
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strDate       
'-------------------------------------------------------------------------

   
PUB Str_GPS_Status
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Str_GPS_Status │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns a one character 'string' for GPS status                                
'' Parameters: None                                 
''    Results: Pointer to string where
''             'V' for GPS data not valid   (Void)
''             'A" for GPS data valid       (Autonomous)                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGpsStatus
'-------------------------------------------------------------------------


PUB Str_GPS_Mode
'-------------------------------------------------------------------------
'------------------------------┌──────────────┐---------------------------
'------------------------------│ Str_GPS_Mode │---------------------------
'------------------------------└──────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns a one character 'string' for GPS working mode                                 
'' Parameters: None                                 
''    Results: Pointer to string where
''             'A' = Autonomous
''             'D' = Differential GPS  (DGPS)
''             'E' = Estimated, (Dead Reckoning mode (DR)) 
''             'M' = Manual Input mode
''             'S' = Simulator mode 
''             'N' = Data not valid                                                              
''+Reads/Uses: None                                               
''    +Writes: None                                                      
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGpsMode        
'-------------------------------------------------------------------------


PUB Str_Latitude
'-------------------------------------------------------------------------
'-------------------------------┌──────────────┐--------------------------
'-------------------------------│ Str_Latitude │--------------------------
'-------------------------------└──────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Latitude data string     
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLatitude      
'-------------------------------------------------------------------------


PUB Str_Lat_N_S
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Str_Lat_N_S │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns hemisphere for the Latitude data (N, S)
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLat_N_S 
'-------------------------------------------------------------------------

    
PUB Str_Longitude
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ Str_Longitude │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Longitude data string    
'' Parameters: None                                 
''    Results: Pointer to string                                                   
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLongitude
'-------------------------------------------------------------------------
        

PUB Str_Lon_E_W
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Str_Lon_E_W │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Hemisphere for Longitude (E, W)
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strLon_E_W
'-------------------------------------------------------------------------
              
         
PUB Str_Speed_Over_Ground
'-------------------------------------------------------------------------
'------------------------┌───────────────────────┐------------------------
'------------------------│ Str_Speed_Over_Ground │------------------------
'------------------------└───────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Speed Over Ground data string                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded
''       Note: In knots [nmi/h]                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded           
RETURN @strSpeedOG
'-------------------------------------------------------------------------


PUB Str_Course_Over_Ground
'-------------------------------------------------------------------------
'------------------------┌────────────────────────┐-----------------------
'------------------------│ Str_Course_Over_Ground │-----------------------
'------------------------└────────────────────────┘-----------------------
'-------------------------------------------------------------------------
''     Action: Returns the Course Over Ground data string('0.00'-'359.99')                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @StrCourseOG
'-------------------------------------------------------------------------


PUB Str_Mag_Variation
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Str_Mag_Variation │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Magnetic Variation data string                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded
''       Note: This important data is not available in some GPS units                                                                 
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strMagVar
'-------------------------------------------------------------------------


PUB Str_MagVar_E_W
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Str_MagVar_E_W │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the 'sign' of Magnetic Variation (See note in DAT)                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded
RETURN @strMV_E_W
'-------------------------------------------------------------------------


PUB Str_Fix_Quality
'-------------------------------------------------------------------------
'----------------------------┌─────────────────┐--------------------------
'----------------------------│ Str_Fix_Quality │--------------------------
'----------------------------└─────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Code of Fix Quality (See note in DAT section)                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strFixQual
'-------------------------------------------------------------------------
   

PUB Str_Altitude_Above_MSL
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Str_Altitude_Above_MSL │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Altitude to Mean See Level (Geoid) data                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strAlt   
'-------------------------------------------------------------------------


PUB Str_Altitude_Unit
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Str_Altitude_Unit │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the MSL Altitude data unit                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strAlt_U


PUB Str_Geoid_Height
'-------------------------------------------------------------------------
'---------------------------┌──────────────────┐--------------------------
'---------------------------│ Str_Geoid_Height │--------------------------
'---------------------------└──────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Geoid Height (MSL) to WGS84 ellipsoid                                  
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGeoidH
'-------------------------------------------------------------------------


PUB Str_Geoid_Height_U
'-------------------------------------------------------------------------
'-------------------------┌────────────────────┐--------------------------
'-------------------------│ Str_Geoid_Height_U │--------------------------
'-------------------------└────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the unit of the Geoid Height                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strGeoidH_U


PUB Str_DGPS_Ref_Station_ID
'-------------------------------------------------------------------------
'----------------------┌─────────────────────────┐------------------------
'----------------------│ Str_DGPS_Ref_Station_ID │------------------------
'----------------------└─────────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the DGPS reference station ID                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded
''       Note: In DGPS mode                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strDGPSRefID
'-------------------------------------------------------------------------


PUB Str_Age_Of_GGPS_Data
'-------------------------------------------------------------------------
'------------------------┌──────────────────────┐-------------------------
'------------------------│ Str_Age_Of_GGPS_Data │-------------------------
'------------------------└──────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Age of DGPS Fix                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strAgeOfDGPS    
'-------------------------------------------------------------------------


PUB Str_Pos_Mode_Selection
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Str_Pos_Mode_Selection │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Positioning Mode selection                                 
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strSelPMode
'-------------------------------------------------------------------------


PUB Str_Actual_Pos_Mode
'-------------------------------------------------------------------------
'------------------------┌─────────────────────┐--------------------------
'------------------------│ Str_Actual_Pos_Mode │--------------------------
'------------------------└─────────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the actual Positioning Mode                                
'' Parameters: None                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
RETURN @strPosMode
'-------------------------------------------------------------------------


PUB Str_Sat_ID_In_Fix(index)
'-------------------------------------------------------------------------
'--------------------------┌───────────────────┐--------------------------
'--------------------------│ Str_Sat_ID_In_Fix │--------------------------
'--------------------------└───────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the ID (PRN) of a satellite in Fix                                 
'' Parameters: Index of satellite in fix, 0 is for the #, 1 is for PRN of
''             1st satellite in Fix, etc...                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  0:RETURN @strNSatsUsed
  1..12:RETURN (@strFSatID01 + 3 * (index - 1))
  OTHER:RETURN -1
'-------------------------------------------------------------------------


PUB Str_Sat_ID_In_View(index)
'-------------------------------------------------------------------------
'--------------------------┌────────────────────┐-------------------------
'--------------------------│ Str_Sat_ID_In_View │-------------------------
'--------------------------└────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns the ID (PRN) of a satellite in View                                 
'' Parameters: Index of satellite in View, 0 is for the #, 1 is for PRN of
''             1st satellite in View, etc...                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                              
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  0:RETURN @strSatsInV
  1..12:RETURN (@strVSatID01 + 13 * (index - 1))
  OTHER:RETURN -1
'-------------------------------------------------------------------------


PUB Str_Sat_Elevation(index)
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Str_Sat_Elevation │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Elevation of a satellite in View                                 
'' Parameters: Index of satellite in View, 1 is for Elevation of 1st
''             satellite in View, etc...                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                           
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  1..12:RETURN (@strElev01 + 13 * (index - 1))    
  OTHER:RETURN -1
'-------------------------------------------------------------------------
    
    
PUB Str_Sat_Azimuth(index)
'-------------------------------------------------------------------------
'---------------------------┌─────────────────┐---------------------------
'---------------------------│ Str_Sat_Azimuth │---------------------------
'---------------------------└─────────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Azimuth of a satellite in View                                 
'' Parameters: Index of satellite in View, 1 is for Azimuth of 1st
''             satellite in View, etc...                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                 
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  1..12:RETURN (@strAzim01 + 13 * (index - 1))    
  OTHER:RETURN -1
'-------------------------------------------------------------------------
 

PUB Str_Sat_SNR(index)
'-------------------------------------------------------------------------
'-------------------------------┌─────────────┐---------------------------
'-------------------------------│ Str_Sat_SNR │---------------------------
'-------------------------------└─────────────┘---------------------------
'-------------------------------------------------------------------------
''     Action: Returns the Signal S/N of a satellite in View                                 
'' Parameters: Index of satellite in View, 1 is for S/N of 1st
''             satellite in View, etc...                                 
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                         
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded 
CASE index
  1..12:RETURN (@strSNR01 + 13 * (index - 1))    
  OTHER:RETURN -1
'-------------------------------------------------------------------------


PUB Str_DOP(index)
'-------------------------------------------------------------------------
'---------------------------------┌─────────┐-----------------------------
'---------------------------------│ Str_DOP │-----------------------------
'---------------------------------└─────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Returns the DOP data strings (See note in DAT section)                                
'' Parameters: index: 0 for PDOP, 1 for HDOP and 2 vor VDOP                                  
''    Results: Pointer to string                                                                
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

Wait_For_New_Data_Decoded
CASE index
  0:RETURN @strPDOP
  1:RETURN @strHDOP
  2:RETURN @strVDOP
'-------------------------------------------------------------------------
       

PUB Str_Time_Stamp(index)
'-------------------------------------------------------------------------
'-----------------------------┌────────────────┐--------------------------
'-----------------------------│ Str_Time_Stamp │--------------------------
'-----------------------------└────────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Returns the time of last reception data for important
''             navigation quantities                                 
'' Parameters: Index                                 
''    Results: Pointer to a string where the string is
''              Latitude time stamp for     index 0
''              Longitude time stamp for    index 1
''              Speed time stamp for        index 2
''              Course time stamp for       index 3   
''              Altitude time stamp for     index 4
''              Geoid Height time stamp for index 5                                                               
''+Reads/Uses: None                                               
''    +Writes: None                                    
''      Calls: Wait_For_New_Data_Decoded                                                                  
'-------------------------------------------------------------------------

CASE index
  1..6:RESULT := @strLat_t + (index - 1) * 11
  OTHER:RESULT := @strNullStr
'-------------------------------------------------------------------------


PRI Concurent_NMEA_Receiver|chr,h0,h1,v0,v1,cks,cks_Rx,cks_OK
'-------------------------------------------------------------------------
'-----------------------┌─────────────────────────┐-----------------------
'-----------------------│ Concurent_NMEA_Receiver │-----------------------
'-----------------------└─────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: -Reads NMEA sentences and preprocesses them before parsing
'             -Cheks cheksum
'             -Meanwhile update some counters
'             -Copies valid strings (from a sentence) into strBuffer1                                  
' Parameters: None                                 
'    Results: Last received (preprocessed) NMEA sentece in strBuffer1                                                                
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None
'       Note: The interpreter for this procedure runs in a separate COG                                                                 
'-------------------------------------------------------------------------

nmeaCntr0~                           'Initialize NMEA sentence counters
nmeaCntr1~
nmeaCntr2~
rmcCntr~
ggaCntr~
gllCntr~
gsvCntr~
gsaCntr~

REPEAT                               'Continuous reading of NMEA sentences
                                     'until POWER OFF or RESET. A separate
                                     'SPIN interpreter is devoted to the
                                     'processing of the tokens of this
                                     'procedure
  
  cks_OK := FALSE                    'To drop into next loop
  chr :=  GPS_UART.Rx
  
  REPEAT UNTIL cks_OK                'Repeat until a received complete 
  '                                  'NMEA sentence is correct
                
    REPEAT WHILE chr <> "$"          'Wait for the start ($) of an NMEA 
      chr :=  GPS_UART.Rx            'sentence

    nmeaCntr0++                      'Increment started NMEA sentence cntr
                                        
    cptr~                            'Initialise char pointer to strBuffer                         
    cks~                             'Initialise running checksum
          
    chr := GPS_UART.Rx               'Get 1st data character after "$"
           
    REPEAT WHILE chr <> _CR          'Read data char until sentence ends
                                     '(or strBuffer is full!)
     'Check received character
     
      IF chr == "*"                  '2 checksum bytes will follow!  
        strBufferRx[cptr++] := 0     'Terminate final data string, though
        h0:=GPS_UART.Rx              'Read 1st checksum control hex char
        h1:=GPS_UART.Rx              'Read 2nd checksum control hex char
         
      ELSE                           'Data or separator char received
      
        cks ^= chr                   'XOR the received byte with running
                                     'checksum. Final result of these
                                     'XORs will be checked with two
                                     'received hex characters at the
                                     'end, after "*", of the NMEA sentence
                                     
        'Decode and place chr into strBuffer (Hot spot of code, 4 lines)                                 
        IF chr == ","                'Separator character received
          strBufferRx[cptr++] := 0   'Terminate data string in buffer
        ELSE                         'Data character received     
          strBufferRx[cptr++] := chr 'Append character to data string

      IF cptr < _MAX_NMEA_SIZE       'Check not to overrun strBuffer(!)
                                     'There can be some noise in the       
                                     'channel or at least good to prepare
                                     'for it. Prop can freeze or reboot
                                     'after such overrun, and that is not
                                     'nice during travel, to say the least
                                     
        chr := GPS_UART.Rx           'Read next char from NMEA stream
      ELSE
        chr := _CR                   'Buffer is full. Something went
                                     'wrong. Mimic <CR> reception to get
                                     'out of here       
      
    'Decode checksum byte sent by the GPS as 2 hex characters: first High,
    'then Low Nibble. Result should be the same as our running XOR value
    '
    '       Checksum =  (1st Hex value) * 16 + (2nd Hex value)
    '
    'First calculate values v0, v1 for hex digits h0, h1
    CASE h0
      $30..$39:v0 := h0 - $30        '"0..9" to 0..9
      $41..$46:v0 := h0 - $37        '"A..F" to 10..16
    CASE h1
      $30..$39:v1 := h1 - $30        '"0..9" to 0..9
      $41..$46:v1 := h1 - $37        '"A..F" to 10..16 
    'Then calculate sent checksum
    cks_Rx := (v0 << 4) + v1         '<<4 stands for *16
      
    rXCks := cks_Rx                  'For debug 
    cCCks := cks
      
    cks_OK := (cks_Rx == cks)        'Check sums.

    IF NOT cks_OK                    'If checksum failed
      nmeaCntr2++                    'Incr. counter of failed sentences

  'It is interesting, or better to say, sad to see, that this very simple
  'checksum algorithm is missed or miscalculated in some GPS NMEA parsers
  'published at Obex. The object that does not calculate it has other
  'serious problems. The corrected 'plus' object miscalculates the
  'checksum and that is even worst, since it discards about half the
  'sentences with all the correct and fresh nav/sat info within.          
  
  'Anyway, if we are here than a complete and correct NMEA sentence was
  'received! Its relevant data are collected in strBufferRx as a
  'continuous package of zero ended strings. strBufferRx may contain null
  'strings, as well. These null strings are "between" two adjacent zero
  'bytes. They occur when the GPS unit does not output data for a given
  'field. Even in that case the GPS transmits the delimiter (,) for the
  'empty field and that comma will be turned into zero by this receiver

  'Move verified NMEA data strings into strBuffer1 for data queue for
  'decoding
  nmeaCntr1++                      'Increment verified sentence counter

  REPEAT WHILE cptr1               'If cptr1 not zero then 'Decoder' did
                                   'not copy strBuffer1 into strBuffer2
                                   'yet. Wait for that. That is a very
                                   'short time, usually.
                                   
  'Now strBuffer1 can be accessed                                 
  BYTEFILL(@strBuffer1, 0, _MAX_NMEA_SIZE)   'Clean up container
  BYTEMOVE(@strBuffer1, @strBufferRx, cptr)  'Copy data
  
  cptr1 := cptr      'Signal a not empty strbuffer1 to the Decoder
  
  'The checksum calculation and the data transfer take about much less
  'than 1 ms. However, the 'Decoder' process can last as long as 1-2 ms.
  'Events can sometime coincide in a way that 'Receiver' has to wait with
  'the data copy for that long. At the highest 115_200 baud rate more than
  '16 characters may accumulate in the UART's receiver buffer during this
  'time. FullDuplexSerial's 16 byte receiver buffer is just not enough for
  'this, but it is fine up to 57_600 baud.  
'-------------------------------------------------------------------------


PRI Concurent_NMEA_Decoder | c0,c1,c2,ps,fp,ac,l
'-------------------------------------------------------------------------
'-----------------------┌────────────────────────┐------------------------
'-----------------------│ Concurent_NMEA_Decoder │------------------------
'-----------------------└────────────────────────┘------------------------
'-------------------------------------------------------------------------
'     Action: -Checks for a not empty strBuffer2
'             -If so then 
'               (After setting RED semaphore to deny external access)
'                decodes its content
'                Sets GREEN semaphore to allow external access to
'                refreshed data  
'             -Checks for a not empty strBuffer1 and for a free access to
'                it   
'             -If so (both) then copies the content of strBuffer1 into
'                strBuffer2                                  
' Parameters: None                                 
'    Results: Refreshed data strings in DAT section                                                               
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None
'       Note: -The interpreter for this procedure runs in a separate COG
'                than for main (in COG0) and for 'Concurent_NMEA_Recever'                                                                
'-------------------------------------------------------------------------

REPEAT                           'Until power off or reset

  IF cptr1  'Then copy a not empty strBuffer1 into strBuffer2 for decoding 
    BYTEFILL(@strBuffer2, 0, _MAX_NMEA_SIZE)     'Clean up container
    BYTEMOVE(@strBuffer2, @strBuffer1, cptr1)    'Copy data quickly
    cptr2 := cptr1
    cptr1 := 0                                   'Release strBuffer1

    'Make an array (fieldPtrs) of string pointers to data fields
    'Initialize
    ps := @strBuffer2            'Pointer to strBuffer
    fp := @fieldPtrs             'Pointer to array of field pointers
    ac~                          'Reset argument counter
  
    'Clear fieldPtrs to zero to prevent data mix-up, e.g., in old
    'fashioned RMC sentences where mode field is missing. Or just
    'prepare for some unforeseen errors because they will happen.
    'We are playing here with strings, so we have to be careful.
    c0 := @strNullStr
    REPEAT _MAX_FIELDS
      WORD[fp][ac++] := c0

    ac~                          'Reset again

    'Finally  create the array of pointers (Hot spot of code, 3 lines)
    REPEAT cptr2                 'We do not parse the whole buffer!
      IF BYTE[ps++] == 0         'String delimiter has been reached
        WORD[fp][ac++]:=ps       'Next byte is a pointer to next string
        
      IF ac == _MAX_FIELDS       'Not to overrun fieldPtrs array(!)
        QUIT    
  
    'Pointers ready. Find kind of NMEA sentence
    lastReceived~
    c0 := strBuffer2[2]
    c1 := strBuffer2[3]
    c2 := strBuffer2[4]
    ptrNMEASentType := @strNullStr
    ptrNMEANotRecog := @strNullStr    
    IF(c0=="R")AND(c1=="M")AND(c2=="C")
      lastReceived := _RMC
     
    ELSEIF(c0=="G")AND(c1=="G")AND(c2=="A")
      lastReceived := _GGA
       
    ELSEIF(c0=="G")AND(c1=="L")AND(c2=="L")
      lastReceived := _GLL
      
    ELSEIF(c0=="G")AND(c1=="S")AND(c2=="A")
      lastReceived := _GSA
     
    ELSEIF(c0=="G")AND(c1=="S")AND(c2=="V")
      lastReceived := _GSV
       
    ELSE
      l := STRSIZE(strBuffer2)
      IF (l < 12)
        BYTEMOVE(@strNotRecog, @strBuffer2, 11)   
      ptrNMEANotRecog := @strNotRecog    'For Debug and development 

    'We are going to access HUB/DAT area that is regularly read by outer
    'code of the application independently of these Receiver/Decoder
    'processes. Between the Receiver and Decoder we can ensure flawless
    'data transfer, only with the cptr, cptr1, cptr2 global pointers,
    'because we know what, when and why. However, an independently running
    ' 'outer' code that uses this object is out of our timing control.
    'So, let us use a semaphore to keep things organized.
    
    'Suspend the memory access of COG0 to the sensitive area until we are
    'ready with data refresh there.
    
    'Claim a free semaphore: Wait for a free semaphore ID
    REPEAT WHILE (semID_Refresh := LOCKNEW) == -1
    
    LOCKSET(semID_Refresh)   'Set it RED. Processes interpreted by COG0 
                             '(or with any other different COG than for
                             'the Receiver and the Decoder) should wait
                             'for a GREEN signal before accessing GPS
                             'info stored in DAT section by calling the
                             '"Wait_For_New_Data_Decoded" procedure or
                             'by direct check of the semaphore
  
    'Now copy strings from NMEA fields into nav/GPS data in DAT section 
    CASE lastReceived
      _RMC:
        ptrNMEASentType := @rmc
        rmcCntr++       
        c0 := fieldPtrs[0]              'UTC time
        c1 := 11
        BYTEMOVE(@strTime, c0, c1)
        BYTEMOVE(@strDate,fieldPtrs[8],7)  
        'Write data Status
        BYTEMOVE(@strGpsStatus,fieldPtrs[1],2)
        'Check for a Valid status
        c2 := BYTE[@strGpsStatus]
        IF c2 == "A"
          'Write new Valid Nav data   
          BYTEMOVE(@strLatitude,fieldPtrs[2],10)
          BYTEMOVE(@strLat_N_S,fieldPtrs[3],2)
          BYTEMOVE(@strLongitude,fieldPtrs[4],11)
          BYTEMOVE(@strLon_E_W,fieldPtrs[5],2)
          BYTEMOVE(@strSpeedOG,fieldPtrs[6],7)
          BYTEMOVE(@strCourseOG,fieldPtrs[7],7)          
          BYTEMOVE(@strMagVar,fieldPtrs[9],5)
          BYTEMOVE(@strMV_E_W,fieldPtrs[10],2)
          'Stamp time of reception to new Valid Nav data
          BYTEMOVE(@strLat_t, c0, c1)
          BYTEMOVE(@strLon_t, c0, c1)
          BYTEMOVE(@strSpeed_t, c0, c1)
          BYTEMOVE(@strCourse_t, c0, c1)
        'Write RMC mode  
        BYTEMOVE(@strGpsMode,fieldPtrs[11],2) 'This field might be missing
                                              'at older GPS units. It does
                                              'not matter here since
                                              'defaults in the fieldPtrs
                                              'array point to a Null str
      _GGA:
        ptrNMEASentType := @gga
        ggaCntr++
        c0 := fieldPtrs[0]              'UTC time
        c1 := 11
        BYTEMOVE(@strTime, c0, c1)       
        'Write new Nav and GPS Fix data if received
        IF STRSIZE(fieldPtrs[1])
          'Write new valid Nav data from GGA sentence
          BYTEMOVE(@strLatitude,fieldPtrs[1],10)
          BYTEMOVE(@strLat_N_S,fieldPtrs[2],2)
          BYTEMOVE(@strLongitude,fieldPtrs[3],11)
          BYTEMOVE(@strLon_E_W,fieldPtrs[4],2)
          'Stamp time of reception to new Nav data
          BYTEMOVE(@strLat_t, c0, c1)
          BYTEMOVE(@strLon_t, c0, c1)
          BYTEMOVE(@strAlt_t, c0, c1)
          BYTEMOVE(@strGeoH_t, c0, c1)
          BYTEMOVE(@strFixQual,fieldPtrs[5],2)
          BYTEMOVE(@strNSatsUsed,fieldPtrs[6],3)
          BYTEMOVE(@strHDOP,fieldPtrs[7],5) 
          BYTEMOVE(@strAlt,fieldPtrs[8],8)
          BYTEMOVE(@strAlt_U,fieldPtrs[9],2)
          BYTEMOVE(@strGeoidH,fieldPtrs[10],6)
          BYTEMOVE(@strGeoidH_U,fieldPtrs[11],2)
          'The next 2 fields might be missing in older GPS units
          'Null string will be returned then
          BYTEMOVE(@strAgeOfDGPS,fieldPtrs[12],3)
          BYTEMOVE(@strDGPSRefID,fieldPtrs[13],5)

      _GLL:
        ptrNMEASentType := @gll
        gllCntr++   
        c0 := fieldPtrs[4]              'UTC time
        c1 := 11
        BYTEMOVE(@strTime, c0, c1)
        BYTEMOVE(@strGpsStatus,fieldPtrs[5],2)
        c2 := BYTE[@strGpsStatus]
        IF c2 == "A"
          'Write new valid Nav data from GGA sentence
          BYTEMOVE(@strLatitude,fieldPtrs[0],10)
          BYTEMOVE(@strLat_N_S,fieldPtrs[1],2)
          BYTEMOVE(@strLongitude,fieldPtrs[2],11)
          BYTEMOVE(@strLon_E_W,fieldPtrs[3],2)
           'Stamp time of reception to new Nav data
          BYTEMOVE(@strLat_t, c0, c1)
          BYTEMOVE(@strLon_t, c0, c1)
          
      'Now comes the cases for satellite data sentences
      _GSA:
        ptrNMEASentType := @gsa
        gsaCntr++  
        BYTEMOVE(@strSelPMode,fieldPtrs[0],2)
        BYTEMOVE(@strPosMode,fieldPtrs[1],2)
        BYTEMOVE(@strFSatID01,fieldPtrs[2],3)
        BYTEMOVE(@strFSatID02,fieldPtrs[3],3)
        BYTEMOVE(@strFSatID03,fieldPtrs[4],3)
        BYTEMOVE(@strFSatID04,fieldPtrs[5],3)
        BYTEMOVE(@strFSatID05,fieldPtrs[6],3)
        BYTEMOVE(@strFSatID06,fieldPtrs[7],3)
        BYTEMOVE(@strFSatID07,fieldPtrs[8],3)
        BYTEMOVE(@strFSatID08,fieldPtrs[9],3)
        BYTEMOVE(@strFSatID09,fieldPtrs[10],3)
        BYTEMOVE(@strFSatID10,fieldPtrs[11],3)
        BYTEMOVE(@strFSatID11,fieldPtrs[12],3)
        BYTEMOVE(@strFSatID12,fieldPtrs[13],3)
        BYTEMOVE(@strPDOP,fieldPtrs[14],5)
        BYTEMOVE(@strHDOP,fieldPtrs[15],5)
        BYTEMOVE(@strVDOP,fieldPtrs[16],5)
      
      _GSV:
        ptrNMEASentType := @gsv
        gsvCntr++ 
        BYTEMOVE(@strSatsInV,fieldPtrs[2],3)

        'c0:=BYTE[fieldPtrs[0]]-$30 'Total # of sentences(we don't care)
       
        'Find out the actual number of this sentence in packet. It arrived
        'as a hexadecimal character
        c1 := BYTE[fieldPtrs[1]] - $30  'This is enough for us to figure
                                        'out satellite data
      
        CASE c1
          1:        '1st GSV sentence in packet for Sats 1-4
            BYTEMOVE(@strVSatID01,fieldPtrs[3],3)
            BYTEMOVE(@strElev01,fieldPtrs[4],3)
            BYTEMOVE(@strAzim01,fieldPtrs[5],4)
            BYTEMOVE(@strSNR01,fieldPtrs[6],3)
            BYTEMOVE(@strVSatID02,fieldPtrs[7],3)
            BYTEMOVE(@strElev02,fieldPtrs[8],3)
            BYTEMOVE(@strAzim02,fieldPtrs[9],4)
            BYTEMOVE(@strSNR02,fieldPtrs[10],3)
            BYTEMOVE(@strVSatID03,fieldPtrs[11],3)
            BYTEMOVE(@strElev03,fieldPtrs[12],3)
            BYTEMOVE(@strAzim03,fieldPtrs[13],4)
            BYTEMOVE(@strSNR03,fieldPtrs[14],3)
            BYTEMOVE(@strVSatID04,fieldPtrs[15],3)
            BYTEMOVE(@strElev04,fieldPtrs[16],3)
            BYTEMOVE(@strAzim04,fieldPtrs[17],4)
            BYTEMOVE(@strSNR04,fieldPtrs[18],3)
          2:         '2nd GSV sentence in packet for Sats 5-8
            BYTEMOVE(@strVSatID05,fieldPtrs[3],3)
            BYTEMOVE(@strElev05,fieldPtrs[4],3)
            BYTEMOVE(@strAzim05,fieldPtrs[5],4)
            BYTEMOVE(@strSNR05,fieldPtrs[6],3)
            BYTEMOVE(@strVSatID06,fieldPtrs[7],3)
            BYTEMOVE(@strElev06,fieldPtrs[8],3)
            BYTEMOVE(@strAzim06,fieldPtrs[9],4)
            BYTEMOVE(@strSNR06,fieldPtrs[10],3)
            BYTEMOVE(@strVSatID07,fieldPtrs[11],3)
            BYTEMOVE(@strElev07,fieldPtrs[12],3)
            BYTEMOVE(@strAzim07,fieldPtrs[13],4)
            BYTEMOVE(@strSNR07,fieldPtrs[14],3)
            BYTEMOVE(@strVSatID08,fieldPtrs[15],3)
            BYTEMOVE(@strElev08,fieldPtrs[16],3)
            BYTEMOVE(@strAzim08,fieldPtrs[17],4)
            BYTEMOVE(@strSNR08,fieldPtrs[18],3)
          3:        '3rd GSV sentence in packet for Sats 9-12 
            BYTEMOVE(@strVSatID09,fieldPtrs[3],3)
            BYTEMOVE(@strElev09,fieldPtrs[4],3)
            BYTEMOVE(@strAzim09,fieldPtrs[5],4)
            BYTEMOVE(@strSNR09,fieldPtrs[6],3)
            BYTEMOVE(@strVSatID10,fieldPtrs[7],3)
            BYTEMOVE(@strElev10,fieldPtrs[8],3)
            BYTEMOVE(@strAzim10,fieldPtrs[9],4)
            BYTEMOVE(@strSNR10,fieldPtrs[10],3)
            BYTEMOVE(@strVSatID11,fieldPtrs[11],3)
            BYTEMOVE(@strElev11,fieldPtrs[12],3)
            BYTEMOVE(@strAzim11,fieldPtrs[13],4)
            BYTEMOVE(@strSNR11,fieldPtrs[14],3)
            BYTEMOVE(@strVSatID12,fieldPtrs[15],3)
            BYTEMOVE(@strElev12,fieldPtrs[16],3)
            BYTEMOVE(@strAzim12,fieldPtrs[17],4)
            BYTEMOVE(@strSNR12,fieldPtrs[18],4)
      OTHER:
      
    cptr2 := 0           'Meaning that strBuffer2 has been processed and
                         'can be overwritten
                         
    'Data refresh is ready Set Green semaphore (unlock it) to allow data
    'access for other COG(s), especially COG0, to the refreshed nav/sat
    'information stored in the DAT section 
    LOCKCLR(semID_Refresh)
'-------------------------------------------------------------------------


PRI Wait_For_New_Data_Decoded
'-------------------------------------------------------------------------
'---------------------┌───────────────────────────┐-----------------------
'---------------------│ Wait_For_New_Data_Decoded │-----------------------
'---------------------└───────────────────────────┘-----------------------
'-------------------------------------------------------------------------
'     Action: -Waits for a GREEN (not set) semID_Refresh
'             -Releases the semaphore                                
' Parameters: None                                 
'    Results: When procedure returns then semID_Refresh is GREEN and GPS
'             data can be freely accessed                                                               
'+Reads/Uses: None                                               
'    +Writes: None                                    
'      Calls: None                                                                  
'-------------------------------------------------------------------------

'Force calling code (probaply by COG0) to wait for GREEN semaphore  
REPEAT UNTIL (NOT LOCKSET(semID_Refresh))

'If here, then we dropped out from the previous REPEAT, so the semaphore
'was switched to GREEN somewhere in the code, but LOCKSET, during the
'test, set it again RED. Let it remain GREEN if it was switched to GREEN!
'If we did not do this, only a single access for the data would be
'allowed. The second attempt would be blocked again, probably
'unnecessarily, until the 'Decoder' will switch the semaphore GREEN again.     
LOCKCLR(semID_Refresh)             'Requiescat in status  GREEN, then
                                        
LOCKRET(semID_Refresh)             'This doesn't prevent cog0 from
                                   'accessing it afterwards, during the
                                   'following data readouts, it only
                                   'allows the HUB to reassign it again
                                   'when requested.
'-------------------------------------------------------------------------


DAT

strNullStr   BYTE 0                'Null string

'NMEA sentence types that are processed in this version of Driver
rmc          BYTE "RMC", 0         'Recommended Minimum Nav Information(C)                                   
gga          BYTE "GGA", 0         'GPS Fix Data. Time, pos and fix relat.
gll          BYTE "GLL", 0         'Lat, Lon, Time

gsa          BYTE "GSA", 0         'Active Satellites and DOP Data
gsv          BYTE "GSV", 0         'Satellites in view

strNotRecog  BYTE 0, "XXXXXXXXXXX", 0   'Not recognised sentence header


'-------------------------------------------------------------------------
'-----------------Receved Data from GPS in string format------------------
'-------------------------------------------------------------------------

'General indicators-------------------------------------------------------
'Note that depending on GPS unit type and brand some (most) of these
'indicators are not used by a given GPS device

strGpsStatus BYTE "X", 0     'GPS Status field

                             'A = Autonomous (Data valid)
                             'V = Void (Data invalid, navigation
                             '    receiver warning)
                             
'The next mode field at the end of RMC sentences is only present in NMEA
'version 3.00 or later. Check your receiver!                                    
strGpsMode   BYTE "X", 0     'GPS Mode

                             'A = Autonomous
                             'D = DGPS
                             'E = Estimated, known as Dead Reckoning (DR)
                             'M = Manual Input mode
                             'S = Simulator mode
                             'N = Data not valid
                             
'DGPS: Most of the errors in two receivers close enough to one another
'are identical. Therefore setting a reference receiver on a known point
'allows one to measure the errors in real time on each satellite visible.
'These can then be broadcast over some communications channel to other
'users near the reference station who use this information to correct
'their measurements in real time. This is Differential GPS or D-DPS
'(DGPS). DGPS uses the code phase of GPS signals. There is a carrier
'phase, too, that allows even more precise positioning. See RTK note                             

'Note that setting the Mode Indicator also influences the value of the
'Status field. The Status field will be set to "A" (Data valid) for Mode
'Indicators A and D, and to "V" (Data invalid) for all other values of
'the Mode Indicator.

                                   
strFixQual   BYTE "X", 0     'Position fix indicator
                             '0 = Fix not available or invalid
                             '1 = GPS SPS Mode, fix valid
                             '2 = DGPS, SPS Mode, fix valid
                             '3 = GPS PPS Mode, fix valid
                             '4 = Real Time Kinematic (RTK), Fixed integer
                             '    arithmetic, fix valid
                             '5 = Float arihtmetic RTK, fix valid
                             '6 = DR Mode, fix valid. 
                             '    This value (6) applies only to NMEA
                             '    version 2.3 (and later)
                             '7 = Manual Input Mode
                             '8 = Simulator mode
                             
'SPS,PPS: The two levels of service provided are known as the Standard
'Positioning Service (SPS) and the Precise Positioning Service (PPS). SPS
'is available to all users and provides horizontal positioning accuracy
'of 36 meters or less, with a probability of 95 percent. PPS is more
'accurate than SPS, but available only to the US military and a limited
'number of other authorized users.

'RTK: Real Time Kinematic is a process where GPS signal corrections are
'transmitted in real time from a reference receiver at a known location to
'one or more remote rover receivers. Using the code phase of GPS signals,
'also the carrier phase, which delivers the most accurate GPS information,
'RTK provides differential corrections to produce the most precise GPS
'positioning service. The use of an RTK capable GPS system can compensate
'for atmospheric delay, orbital errors and other variables in GPS
'geometry, increasing positioning accuracy up to within a centimeter!
'Used by engineers, topographers, surveyors and other professionals, RTK
'is a technique employed in applications where precision is paramount.
'You should know, however, that the mobile units compare their own phase
'measurements with the ones received from the base station. This allows
'the units to calculate only their relative position within centimeters,
'although their absolute position is accurate only to the same accuracy as
'the position of the base station. 


strSelPMode  BYTE "X", 0     'Selection of positioning mode
                             'M = Manual, forced to operate in 2D or 3D
                             'A = Automatic switch between 2D/3D

strPosMode   BYTE "X", 0     'Actual positioning mode
                             '1 = Fix not available
                             '2 = 2D (<4 Sats used)
                             '3 = 3D (>3 Sats used)
                                                                                                                                 

'WGS84 Navigation Data
strDate      BYTE "DDMMYY", 0      'Last received UTC Date
strTime      BYTE "HHMMSS.SSS", 0  'Last received UTC Time
strLatitude  BYTE "DDMM.MMMM", 0   'Last received Latitude  [degrees]
strLat_N_S   BYTE "X", 0           'N for North, S for South hemisphere
strLongitude BYTE "DDDMM.MMMM", 0  'Last received Longitude [degrees]
strLon_E_W   BYTE "X", 0           'E for East, W for West hemisphere

strSpeedOG   BYTE "VVV.VV", 0      'Last received Speed Over Ground in
                                   '[knots]
                                   
strCourseOG  BYTE "CCC.CC", 0      '-Last received Course Over Ground
                                   'in [degrees]. In no wind condition
                                   'it is the same as True Heading. A  
                                   '"True" direction is measured starting
                                   'at true (geographic) North and moving
                                   'clockwise. In a car Course and Heading
                                   'are usually the same except while
                                   'rallying with high beta angle.
                                   '-Sometime called as Track made good
                                   
strAlt       BYTE "AAAAA.A", 0     'Last received Altitude at Mean Sea
                                   'Level (Geoid)
                                      
strAlt_U     BYTE "M", 0           'Altitude unit (M) for [m]

strGeoidH    BYTE "HHH.H", 0       'Last received Geoid Height referred to
                                   'the WGS84 ellipsoid. It is not a
                                   'measured value but is calculated from
                                   'the position (usually interpolated
                                   'from tabulated data).
                                   'In other words : Mean Sea Level
                                   'relative to WGS84 surface
                                   'Sometimes called Geoid Separation
                                   
strGeoidH_U  BYTE "M", 0           'Geoid Height unit (M) for [m]

strMagVar    BYTE "MM.M", 0        'Last received Magn Variation [degrees]

'Magnetic Variation from a GPS is not a measured value. It is calculated 
'from the position using the WMM2005 or IGRF2005 spherical harmonics 
'models of the core magnetic field of Earth. In some (cheaper) GPS units
'this data is simply interpolated from tables or not calculated at all.
'The field is left empty in that last pitiful case.
'USAGE: Your magnetic compass senses magnetic north that can differ from
'true north more than 20° in many  places on the Earth. From a given true
'course you can obtain magnetic course remembering the memory aid 'IF EAST       
'MAGNETIC IS LEAST, IF WEST MAGNETIC IS BEST' and correct for local
'magnetic variation, as said. If the variation is east of true north, it
'is subtracted from the true course, and west variation is added to the
'true course to obtain magnetic course. True course is a geometric kind of
'thing that you can figure out on a mercator map easily for a rhumb line
'navigation. Magnetic heading is something that you really measure with
'your simple and reliable (but not cheap) magnetic compass. The one that
'does not need batteries, or upgrades from the Internet. In no wind
'condition magnetic heading will be the same as magnetic course. Using
'MAGNETIC NORTH is absolutely not old fashioned in today's navigation even
'if we have smarter and smarter GPS units. E.g. Runway directions
'correspond to the MAGNETIC NORTH reference, VOR station radials are
'numbered clockwise from MAGNETIC NORTH, just to mention a few...
                                    
strMV_E_W    BYTE "X", 0           'E for East, W for West Magnetic Var


'Satellite Data-----------------------------------------------------------
'Satellites in Fix Data
strNSatsUsed BYTE "NN", 0          'Number of satelites used in
                                   'positioning calculations (00 - 12)
                                   '00 = No Fix

strFSatID01  BYTE "ID", 0          '1st Satelite ID for Fix
strFSatID02  BYTE "ID", 0          '2nd Satelite ID for Fix
strFSatID03  BYTE "ID", 0          '3rd Satelite ID for Fix
strFSatID04  BYTE "ID", 0          '4st Satelite ID for Fix
strFSatID05  BYTE "ID", 0          '5st Satelite ID for Fix
strFSatID06  BYTE "ID", 0          '6st Satelite ID for Fix
strFSatID07  BYTE "ID", 0          '7st Satelite ID for Fix
strFSatID08  BYTE "ID", 0          '8st Satelite ID for Fix
strFSatID09  BYTE "ID", 0          '9st Satelite ID for Fix
strFSatID10  BYTE "ID", 0          '10st Satelite ID for Fix
strFSatID11  BYTE "ID", 0          '11st Satelite ID for Fix
strFSatID12  BYTE "ID", 0          '12st Satelite ID for Fix

'Satellites in view Data
strSatsInV   BYTE "NN", 0          'Number of satellites in view
strVSatID01  BYTE "ID", 0          '1st Satelite ID in view

strElev01    BYTE "DD", 0          'Elevation angle of satellite [deg] as
                                   'seen from receiver (00-90)
                                
strAzim01    BYTE "DDD", 0         'Satellite Azimuth [deg] as seen from
                                   'receiver (000-359)

strSNR01     BYTE "XX", 0          'Received signal level, (00-99) 00 (or
                                   'empty) when not tracking. Value is not
                                   'calibrated. Between the most weak and
                                   'strong signals of the satellites used
                                   'for fix the difference is about 20-30.
                                   '50 usually means a very strong signal

strVSatID02  BYTE "ID", 0          'String data for the Sats 2 - 12
strElev02    BYTE "DD", 0
strAzim02    BYTE "DDD", 0
strSNR02     BYTE "XX", 0
strVSatID03  BYTE "ID", 0
strElev03    BYTE "DD", 0
strAzim03    BYTE "DDD", 0
strSNR03     BYTE "XX", 0
strVSatID04  BYTE "ID", 0
strElev04    BYTE "DD", 0
strAzim04    BYTE "DDD", 0
strSNR04     BYTE "XX", 0
strVSatID05  BYTE "ID", 0
strElev05    BYTE "DD", 0
strAzim05    BYTE "DDD", 0
strSNR05     BYTE "XX", 0
strVSatID06  BYTE "ID", 0
strElev06    BYTE "DD", 0
strAzim06    BYTE "DDD", 0
strSNR06     BYTE "XX", 0
strVSatID07  BYTE "ID", 0
strElev07    BYTE "DD", 0
strAzim07    BYTE "DDD", 0
strSNR07     BYTE "XX", 0
strVSatID08  BYTE "ID", 0
strElev08    BYTE "DD", 0
strAzim08    BYTE "DDD", 0
strSNR08     BYTE "XX", 0
strVSatID09  BYTE "ID", 0
strElev09    BYTE "DD", 0
strAzim09    BYTE "DDD", 0
strSNR09     BYTE "XX", 0
strVSatID10  BYTE "ID", 0
strElev10    BYTE "DD", 0
strAzim10    BYTE "DDD", 0
strSNR10     BYTE "XX", 0
strVSatID11  BYTE "ID", 0
strElev11    BYTE "DD", 0
strAzim11    BYTE "DDD", 0
strSNR11     BYTE "XX", 0
strVSatID12  BYTE "ID", 0
strElev12    BYTE "DD", 0
strAzim12    BYTE "DDD", 0
strSNR12     BYTE "XX", 0
'At 4800 baud rate the maximum total no. of GSV sentences in a packet is
'usually limited to 3. As each sentence can contain data for 4 satellites,
'I declared only 12 datasets here


'Differential GPS Data----------------------------------------------------
strDGPSRefID BYTE "IIDD", 0        'DGPS reference station ID
strAgeOfDGPS BYTE "SS", 0          'Age of DGPS data in sec (00 - 99)
                                   'Null field when DGPS is not used                                  

'Dilution Of Precision Data-----------------------------------------------
'Dilution Of Precision (DOP) is an indication of the effect of satellite
'geometry on the accuracy of the fix. It is a unitless multiplier 
'where smaller is better. The value given is the factor by which the
'system range errors are multiplied to give a total system error. For 3D
'fixes using >3 sats a 1.0 would be considered a perfect number, however
'for over determined solutions it is possible to see numbers below 1.0
'with some advanced GPS units. So, to get the total accuracy you have to
'multiply the given basic positioning accuracy of your system with the DOD
'value to obtain a reliable (95%) estimate. Intuitively, the best possible
'DOP would be given by one satellite directly overhead and three
'satellites spaced evenly on the horizon. High DOPs result when the
'satellites are clustered together or form a line. As the satellite
'positions are predictable, DOP values can be calculated during the
'planning stages of a short mission to ensure good values.
'Example: if you have SPS service and HDOP is 2.6, which is an acceptably
'good figure, your system's horizontal accuracy is about 2.6*36 m = 94 m.
'This accuracy can be more than enough with your car to find a building or
'with your plane to locate an airfield, but for your robot moving indoor,
'this accuracy will pose quite a challenge for it's navigation algorithm. 

strPDOP      BYTE "--.-", 0        'Position        
strHDOP      BYTE "--.-", 0        'Horizontal
strVDOP      BYTE "--.-", 0        'Vertical


'Time Stamps of last reception  nav/GPS data
strLat_t     BYTE "HHMMSS.SSS", 0
strLon_t     BYTE "HHMMSS.SSS", 0
strSpeed_t   BYTE "HHMMSS.SSS", 0
strCourse_t  BYTE "HHMMSS.SSS", 0
strAlt_t     BYTE "HHMMSS.SSS", 0
strGeoH_t    BYTE "HHMMSS.SSS", 0


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}                  