'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
'
' Firmware for Unsaturated Hydraulic Conductivity Sensor
' Written by Yasin Osroosh, Ph.D.
' Email: yosroosh@gmail.com
' 
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

$regfile = "M32def.dat"
' Define used crystal
$crystal = 4915200                                          '3932160Hz                                          ' Internal Oscillator=1000000                                        '7862400 Hz                                          ' 3932160 Hz
$baud = 4800

Config Serialin = Buffered , Size = 25
Config Serialout = Buffered , Size = 1
' Configure Watchdog
Config Watchdog = 2048                                      '2048
'Config Clock = Soft , Gosub = Sectic

'Config Timer0 = Timer , Prescale = 1024                     ' each cycle=2.604*10^-4 sec ==> 1 sec= (15 * one cycle )
'Enable Timer0
'Stop Timer0
'Enable Ovf0
'On Ovf0 Ovf0routin

Enable Interrupts

Declare Sub Send_rs232
Declare Sub Rs232
Declare Sub Other_variales

Dim N_cycle As Byte
N_cycle = 0

'-------------------------------------------------------------------------------
'
' Wieghing Sensor
'
'-------------------------------------------------------------------------------
' Configure the SPI hardware SPCR register
Config Spi = Hard , Interrupt = Off , Data Order = Msb , Master = Yes , Polarity = High , Phase = 1 , Noss = 1 , Clockrate = 4       ' Previous Clockrate = 4
' Init the SPI pins directly after the CONFIG SPI statement
Spiinit
' Configure RDY as Input
Config Pinb.0 = Input                                       ' RDY line

' Alias
Rdy Alias Pinb.0                                            ' Ready Pin
Din Alias Pinb.5

' Declare Subroutins
Declare Sub Channel_a
Declare Sub Init_ad7730
Declare Sub Reset_adc
Declare Sub End_conversion
Declare Sub Send_rs232_weight
Declare Sub Check_for_latchup
Declare Sub Averaging_weight
Declare Sub Weighing_sensor
Declare Sub Ini_adc
' calibration
Declare Sub Internal_full_scale_1
Declare Sub Internal_zero_scale_1
Declare Sub Write_gain
Declare Sub Write_offset
Declare Sub Read_gain
Declare Sub Read_offset
Declare Sub Init_ad7730_first
Declare Sub Calibration
Declare Sub Read_of_eeprom

' Declaration
Dim Fixvalue_a(100) As Long                                 ' Single
Dim Xfix_a As Byte
Xfix_a = 0
Dim Weight_loop As Word
Weight_loop = 0
Dim X_ave As Byte
Dim X_pinb0 As Word
X_pinb0 = 0

Dim Hsb As Byte
Dim Msb As Byte
Dim Lsb As Byte

Dim Weight0 As Long                                         'Single
Dim Weight1 As Long                                         'Single
Dim Weight2 As Long                                         'Single
Dim Weight3 As Long                                         'Single
Dim Weight_a As Long                                        'Single
Dim Weight_str As String * 30
Dim W_max As Byte
W_max = 2

Dim X As Byte
Dim Numbertoreset_a As Byte
Numbertoreset_a = 0

Dim Gain_1 As Byte
Dim Gain_2 As Byte
Dim Gain_3 As Byte
Dim Gain_4 As Byte

Dim Offset_1 As Byte
Dim Offset_2 As Byte
Dim Offset_3 As Byte
Dim Offset_4 As Byte

Dim Calibrated As String * 1

Dim Calib_bit As Bit
Calib_bit = 1                                               ' Calibration Bit

Dim Hsb_a(5) As Byte
Dim Msb_a(5) As Byte
Dim Lsb_a(5) As Byte
'-------------------------------------------------------------------------------
'
' Temperature Sensor
'
'-------------------------------------------------------------------------------
Declare Sub Read1820
Declare Sub Crcit
Declare Sub Temperature

Dim Bd(9) As Byte
Dim I As Byte , Tmp As Byte
Dim Crc As Byte
Dim T As Integer , T1 As Integer , T_single As Single
Dim V As Byte
Dim T_str As String * 7

Config 1wire = Pinb.2                                       ' DS1820 on pin Pinb.2

'-------------------------------------------------------------------------------
'
' Complex Impedance Sensor
'
'-------------------------------------------------------------------------------
Config Pinb.1 = Input                                       ' Start Pin
Config Pinb.3 = Output                                      ' Interrupt Output
Reset Portb.3

'The internal clock can be divided by 1,8,64,256 or 1024
Config Timer1 = Timer , Prescale = 256                      ' each cycle=5.2083*10^-5 sec
Enable Interrupts
Enable Timer1
Enable Ovf1
On Ovf1 Ovf1routin

Config Adc = Single , Prescaler = Auto , Reference = Avcc
Enable Adc
Start Adc
'On Adc Adc_isr

Declare Sub Send_to_pc_a
Declare Sub Command_2_micro2
Declare Sub Init_sampling
Declare Sub Impedance_sensor

' Dimensions
Dim X_frequency_a(345) As Word
Dim Frequency As Word
Dim X_a As Word
X_a = 0
Dim Y_a As Word
Dim Pin As Bit
Pin = 0
Dim F As Byte
Dim M_cycle As Word
M_cycle = 0

'-------------------------------------------------------------------------------
'
' Suction Sensors
'
'-------------------------------------------------------------------------------
Declare Sub Suction_sensor
Declare Sub Suction_sensor_a
Declare Sub Suction_sensor_b
Declare Sub Ave_suctions

Dim T_1 As Byte
Dim S As Byte
S = 0
Dim Suction_a(10) As Word
Dim Suction_b(10) As Word
Dim Suction_ave_a As Word
Dim Suction_ave_b As Word

'-------------------------------------------------------------------------------
'-------------------------------------------------------------------------------
'-------------------------------------------------------------------------------
'-------------------------------------------------------------------------------
'-------------------------------------------------------------------------------
'
' Program's Body
'
'-------------------------------------------------------------------------------
Program:
   Start Watchdog                                           ' Start Watchdog


'//////////////////////////////////////////////////////////////////////////////
' Initial Routins
'//////////////////////////////////////////////////////////////////////////////
' Weighing Sensor
   If Calib_bit = 1 Then
      Call Calibration
   End If

   Call Ini_adc


'//////////////////////////////////////////////////////////////////////////////
' Measuring Routins
Do

  ' Weighing Sensor
   Call Weighing_sensor                                     ' Wieghing Sensor
   Call Send_rs232_weight                                   ' Send weight data to PC

   Incr N_cycle
   If N_cycle = 20 Then
      N_cycle = 0

      ' Temperature Sensor
      Call Temperature

      ' Weighing Sensor
      Call Weighing_sensor                                  ' Wieghing Sensor

      ' Suction Sensors A and B
      Call Suction_sensor

      Call Rs232                                            ' Send All data to PC

   End If

   Incr M_cycle
   If M_cycle = 3000 Then                                   ' 20000 = 14 min
      M_cycle = 0

      ' Impedance Sensor
      Call Impedance_sensor
   End If

Loop

End


'-------------------------------------------------------------------------------
'
' General Routins
'
'-------------------------------------------------------------------------------
'Adc_isr:
   'Nothing
'Return


'-------------------------------------------------------------------------------
'
' Send Data to PC
'
'-------------------------------------------------------------------------------
Sub Send_rs232:
      Suction_ave_a = Suction_ave_a + 100
      Suction_ave_b = Suction_ave_b + 100

      Print "A" ; "*";                                      '
      Print "B" ; T_str ;                                   ' Send Temperature to the port
      Print "C" ; Suction_ave_a ;                           ' Send Suction A
      Print "M" ; Suction_ave_b ;                           ' Send Suction B                               '
      Print "N" ; "*";
      Print "E" ;                                           '" ";                                      ' Send EOF to the port
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Send_rs232_weight:
      Print "A" ; Weight_a ;                                ' Send weight the port
      Print "B" ; "*";
      Print "C" ; "*";
      Print "M" ; "*";
      Print "N" ; "*";
      Print "E" ;                                           ' Send EOF to the port
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Rs232:
      Suction_ave_a = Suction_ave_a + 100
      Suction_ave_b = Suction_ave_b + 100

      Print "A" ; Weight_a;                                 '
      Print "B" ; T_str ;                                   ' Send Temperature to the port
      Print "C" ; Suction_ave_a ;                           ' Send Suction A
      Print "M" ; Suction_ave_b ;                           ' Send Suction B                               '
      Print "N" ; "*";
      Print "E" ;                                           '" ";                                      ' Send EOF to the port
End Sub

'-------------------------------------------------------------------------------
'
' Suction Sensors
'
'-------------------------------------------------------------------------------
'Sub Suction_sensor_a:
      Suction_ave_a = Getadc(1)                             ' Suction Sensor A
      'Idle
'End Sub

'Sub Suction_sensor_b:
      Suction_ave_b = Getadc(2)                             ' Suction Sensor B
      'Idle
'End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Suction_sensor:
    Do
      Incr S
                                                           '
      Suction_a(s) = Getadc(1)                              ' Suction Sensor A
      'Idle
      Waitms 2
      Suction_b(s) = Getadc(2)                              ' Suction Sensor B
      'Idle
      Waitms 2

    Loop Until S = 5                                        ' S = 5
    Call Ave_suctions
    S = 0
End Sub

Sub Ave_suctions:
    Suction_ave_a = 0
    For T_1 = 1 To S
      Suction_ave_a = Suction_ave_a + Suction_a(t_1)        ' Average at Sensor A
    Next

    Suction_ave_b = 0
    For T_1 = 1 To S
      Suction_ave_b = Suction_ave_b + Suction_b(t_1)        ' Average at Sensor B
    Next

    Suction_ave_a = Suction_ave_a / S
    Suction_ave_b = Suction_ave_b / S
End Sub

'-------------------------------------------------------------------------------
'
' Wieghing Sensor
'
'-------------------------------------------------------------------------------
Sub Ini_adc:
   Call Init_ad7730
' Write to Communications Register Setting Next Operation as write to Mode Register
   X = &H02
   Spiout X , 1
      X = &B00110001                                        ' Unipolar, 24 bit data word and 5V reference, Channel 1 (A)
      Spiout X , 1
      X = &B00000000                                        '  0mV to +10mV input range, 2.5V Reference ==> Real_input_range = 0mV to +XmV/2
      Spiout X , 1

      'Waitms 600                                            ' Make a delay time as 600ms
' Write to Communications Register Setting Next Operation as continuous Read From Data Register
   X = &H21
   Spiout X , 1

      Reset Portb.5                                         ' Reset DIN Line of AD7730 (Ensures Part is not Reset While in Continuous Read Mode)
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Weighing_sensor:
'Do

Read_data_a:
      'If Pinb.0 = 1 Then Goto Read_data_a                   ' Wait for RDY Low (Wait for RDY pin to go low to Indicate Output Update)
      Bitwait Pinb.0 , Reset
      Reset Watchdog

' Read 24-Bit Data From Serial Port (Read Conversion Result from AD7730's Data Register)
      Spiin Hsb , 1
      Spiin Msb , 1
      Spiin Lsb , 1
      'Print "W=" ; Hsb ; "+" ; Msb ; "+" ; Lsb

' Check For Latching-up (If Hsb = Msb = Lsb)
      If Hsb = Msb And Msb = Lsb Then
         Goto Again_channel_a
      End If
' Check For Latching-up (if Bipolar:Weight_a > 100*65535 Or Weight_a < 30*65535)
      If Hsb > 100 Or Hsb < 30 Then
         Goto Again_channel_a
      End If

      Incr Xfix_a
      Hsb_a(xfix_a) = Hsb
      Msb_a(xfix_a) = Msb
      Lsb_a(xfix_a) = Lsb

      If Xfix_a = 2 Then
         Xfix_a = 0
      End If

' Check For Latching-up (If Two Successive Data Are the Same)
      If Hsb_a(1) = Hsb_a(2) And Msb_a(1) = Msb_a(2) And Lsb_a(1) = Lsb_a(2) Then
         Goto Again_channel_a                               '
      Else
        ' Calculate 24-Bit Word
         Weight1 = Hsb * 65536
         Weight2 = Msb * 256
         Weight3 = Weight1 + Weight2
         Weight_a = Weight3 + Lsb
         'Print "W=" ; Hsb ; "+" ; Msb ; "+" ; Lsb
      End If

      Reset Watchdog
      Exit Sub


Again_channel_a:
      Reset Watchdog
      Call Ini_adc
      Goto Read_data_a
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Init_ad7730:
   Call Reset_adc

' Write to Communication Register Setting Next Operation as write to Filter Register
   X = &H03
   Spiout X , 1                                             '
      X = &B01100000                                        ' Writes to Filter Register Setting a 66.7Hz, SF=1536 (57Hz:SF = 1796.49) Output Rate (Output Rate=f_CLK/(16*3*SF))
      Spiout X , 1
      X = &B00000001                                        ' SKIP Mode Disabled (If the Skip Mode is Ebabled, then the CHOP Mode must be Disabled), FASTStep Mode Enabled
      Spiout X , 1
      X = &B00010000                                        ' CHOP Mode Enabled (If enabled: X = &B00010000),AC Excitation Disabled
      Spiout X , 1

' Write to Communications Register Setting Next Operation as write to DAC Register
   X = &H04
   Spiout X , 1
      X = &B00000001                                        ' Write to Mode Register for adding 2.5mV to the analog input
      Spiout X , 1

      'Waitms 500

      If Calib_bit = 1 Then                                 ' If Calibration Bit is Set
         Call Write_gain
         Call Write_offset
      End If
      Reset Watchdog
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Reset_adc:
' Set-Up AD7730 for Continuous Conversion and Continuous Read Operation
' Write 32 ones with DIN High will reset the AD7730 to the default state
      Set Din                                               ' Set DIN Line of AD7730
      Waitms 5

' Write 32 serial clock cycles with DIN high to return the AD7730 to the default state by resetting the part
      X = &HFF
      Spiout X , 1                                          '
      Spiout X , 1                                          '
      Spiout X , 1                                          '
      Spiout X , 1
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Init_ad7730_first:
   Call Reset_adc

' Write to Communication Register Setting Next Operation as write to Filter Register
   X = &H03
   Spiout X , 1                                             '
      X = &B01100000                                        ' Writes to Filter Register Setting a 66.7Hz, SF=1536 (57Hz:SF = 1796.49) Output Rate (Output Rate=f_CLK/(16*3*SF))
      Spiout X , 1
      X = &B00000001                                        ' SKIP Mode Disabled, FASTStep Mode Enabled (If the Skip Mode is Ebabled, then the CHOP Mode must be Disabled)
      Spiout X , 1
      X = &B00010000                                        ' CHOP Mode Enabled (If enabled: X = &B00010000),AC Excitation Disabled
      Spiout X , 1

' Write to Communications Register Setting Next Operation as write to DAC Register
   X = &H04
   Spiout X , 1
      X = &B00000000                                        ' Write to Mode Register for adding 0mV to the analog input
      Spiout X , 1

      'Waitms 500                                            ' Make a delay time as 500ms
      Reset Watchdog
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Internal_full_scale_1:
' Write to Communications Register Setting Next Operation as write to mode register
   X = &H02
   Spiout X , 1
      X = &B10110001                                        ' Writes to Mode Register Initiating Internal Full-Scale Calibration
      Spiout X , 1                                          '
      X = &B00110000                                        '  0mV to +80mV input range, 2.5V Reference
      Spiout X , 1

Zselfcalibration_1:
      If Pinb.0 = 1 Then Goto Zselfcalibration_1            ' Wait for RDY pin to go low to indicate end of calibration cycle

      Call Read_gain

      Reset Watchdog
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Read_gain:
   ' Write to Communications Register Setting Next Operation as single read of Gain Register
   X = &H16
   Spiout X , 1

Read_1:
      If Pinb.0 = 1 Then Goto Read_1                        ' Wait for RDY Low (Wait for RDY pin to go low to Indicate Output Update)

      ' Read 24-Bit Data From Serial Port
      Spiin Gain_1 , 1
      Spiin Gain_2 , 1
      Spiin Gain_3 , 1

End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Write_gain:
' Write to Communications Register Setting Next Operation as single write to Gain Register
   X = &H06
   Spiout X , 1

      ' Read 24-Bit Data From Serial Port
      Spiout Gain_1 , 1
      Spiout Gain_2 , 1
      Spiout Gain_3 , 1

End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Internal_zero_scale_1:
' Write to Communications Register Setting Next Operation as write to mode register
   X = &H02
   Spiout X , 1
      X = &B10010001                                        ' Writes to Mode Register Initiating Internal Zero-Scale Calibration
      Spiout X , 1
      X = &B00000000                                        '  0mV to +10mV input range, 2.5V Reference
      Spiout X , 1                                          '

Fselfcalibration_1:
      If Pinb.0 = 1 Then Goto Fselfcalibration_1            ' Wait for RDY pin to go low to indicate end of calibration cycle

      Call Read_offset

      Reset Watchdog
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Read_offset:
   ' Write to Communications Register Setting Next Operation as single read of Offset Register
   X = &H15
   Spiout X , 1

Read_2:
      If Pinb.0 = 1 Then Goto Read_2                        ' Wait for RDY Low (Wait for RDY pin to go low to Indicate Output Update)

      ' Read 24-Bit Data From Serial Port
      Spiin Offset_1 , 1
      Spiin Offset_2 , 1
      Spiin Offset_3 , 1
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Write_offset:
' Write to Communications Register Setting Next Operation as single write to Gain Register
   X = &H05
   Spiout X , 1

      ' Read 24-Bit Data From Serial Port
      Spiout Offset_1 , 1
      Spiout Offset_2 , 1
      Spiout Offset_3 , 1

End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Calibration:
      Readeeprom Calibrated , 0
      If Calibrated = "Y" Then
         Call Read_of_eeprom
         Exit Sub
      Else
         Call Init_ad7730_first
         Call Internal_full_scale_1
         Call Internal_zero_scale_1

         ' Write_to_eeprom
         Calibrated = "Y"
         Writeeeprom Calibrated , 0

         Writeeeprom Gain_1 , 1
         Writeeeprom Gain_2 , 2
         Writeeeprom Gain_3 , 3

         Writeeeprom Offset_1 , 4
         Writeeeprom Offset_2 , 5
         Writeeeprom Offset_3 , 6
      End If
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Read_of_eeprom:
      Readeeprom Gain_1 , 1
      Readeeprom Gain_2 , 2
      Readeeprom Gain_3 , 3

      Readeeprom Offset_1 , 4
      Readeeprom Offset_2 , 5
      Readeeprom Offset_3 , 6
End Sub

'-------------------------------------------------------------------------------
'
' Temperature Sensor
'
'-------------------------------------------------------------------------------
Sub Temperature                                             ' actual measuring

   1wwrite &HCC : 1wwrite &H44                              ' start measure
   'Waitms 300                                               ' wait for end of conversion
   Read1820                                                 ' read 9 bytes

   If Err = 1 Then                                          ' if there is no sensor
      T_str = "--"                                          ' we put "-- "
   Else
      If Crc = 0 Then                                       ' sensor present, check CRC
         T_single = T / 100
         T_single = T_single + 273                          ' Centigread --> Kelvin
         T_str = Fusing(t_single , "###.##")                ' CRC OK, print T*10
      Else
         T_str = "**"                                       ' CRC NOT OK, "** "
      End If
   End If
End Sub

'//////////////////////////////////////////////////////////////////////////////
Sub Read1820                                                ' reads sensor ans calculate
   ' T for 0.1 C
   1wreset                                                  ' reset the bus
   1wwrite &HCC                                             ' read internal RAM
   1wwrite &HBE                                             ' read 9 data bytest
   Bd(1) = 1wread(9)                                        ' read bytes in array
   1wreset                                                  ' reset the bus

   Crcit                                                    ' ckeck CRC
   If Crc = 0 Then                                          ' if is OK, calculate for
      Tmp = Bd(1) And 1                                     ' 0.1C precision
      If Tmp = 1 Then Decr Bd(1)
      T = Makeint(bd(1) , Bd(2))
      T = T * 50 : T = T - 25 : T1 = Bd(8) - Bd(7) : T1 = T1 * 100
      T1 = T1 / Bd(8) : T = T + T1 : T = T / 10
   End If
End Sub

'//////////////////////////////////////////////////////////////////////////////
Sub Crcit                                                   ' calculate 8 bit CRC
                                                   ' bigger but faster
   Crc = 0                                                  ' needs a 256 elements table
   For I = 1 To 9
      Tmp = Crc Xor Bd(i)
      Crc = Lookup(tmp , Crc8)
   Next
End Sub

'//////////////////////////////////////////////////////////////////////////////
'-------------------------------------------------------------------------------
'
'  Complex Impedance Sensor
'
'-------------------------------------------------------------------------------
Sub Impedance_sensor:
      Call Command_2_micro2                                 ' Force Micro 2 to Start Generation of Sinewave A
      Call Init_sampling                                    ' Store Sampled Frequency into Arrays
      Call Send_to_pc_a                                     ' Send Sampled Frequency to Computer
End Sub

'//////////////////////////////////////////////////////////////////////////////
Sub Command_2_micro2:
    Set Portb.3                                             ' Set Intrrupt Pin of Micro 2
    Waitms 1
    Reset Portb.3                                           ' Reset Intrrupt Pin of Micro 2

    Do
      ' Nothing
      ' Wait Until Micro 2 Starts Generating Sinewave
    Loop Until Pinb.1 = 1
    'Do
      '  Nothing
    'Loop Until Pinb.1 = 0

    Timer1 = 63570                                          ' 50 ms, =65535-(1920) for 100 ms, and =65535-(960) for 50 ms
    Start Timer1
    Do
      ' Wait for 50 ms
    Loop Until Pin = 1
    Pin = 0
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Init_sampling:
    Timer1 = 63590                                          ' 100 ms, =65535-(1920) for 100 ms, and =65535-(2112) for 110 ms
    Start Timer1
    Do                                                      ' Do Loop for 110 ms
      Incr X_a                                              ' Initial Value of X_a is "Zero"
      X_frequency_a(x_a) = Getadc(0)
      'Idle
      Waitms 2
    Loop Until Pin = 1
    Pin = 0
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Send_to_pc_a:
    For Y_a = 1 To X_a
      'Print " " ; X_frequency_a(y_a)                        '; " ";                           'Y ; ":" ; X_frequency(y) ; "   ";               'X_frequency(y) ; "   ";

      Print "A" ; "*";                                      '
      Print "B" ; "*";                                      ' Send Temperature to the port
      Print "C" ; "*";                                      ' Send Suction A
      Print "M" ; "*";                                      ' Send Suction B                               '
      Print "N" ; X_frequency_a(y_a);
      Print "E" ;                                           '" ";                                      ' Send EOF to the port

      'If Y_a = X_a Then
         'Print "End=" ; X_a
      'End If
    Next
    X_a = 0
End Sub
'//////////////////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////////////////
Ovf1routin:
   Stop Timer1
   'Disable Timer1
   'Disable Ovf1
   Pin = 1
Return


'//////////////////////////////////////////////////////////////////////////////
Crc8:
Data 0 , 94 , 188 , 226 , 97 , 63 , 221 , 131 , 194 , 156
Data 126 , 32 , 163 , 253 , 31 , 65 , 157 , 195 , 33 , 127
Data 252 , 162 , 64 , 30 , 95 , 1 , 227 , 189 , 62 , 96
Data 130 , 220 , 35 , 125 , 159 , 193 , 66 , 28 , 254 , 160
Data 225 , 191 , 93 , 3 , 128 , 222 , 60 , 98 , 190 , 224
Data 2 , 92 , 223 , 129 , 99 , 61 , 124 , 34 , 192 , 158
Data 29 , 67 , 161 , 255 , 70 , 24 , 250 , 164 , 39 , 121
Data 155 , 197 , 132 , 218 , 56 , 102 , 229 , 187 , 89 , 7
Data 219 , 133 , 103 , 57 , 186 , 228 , 6 , 88 , 25 , 71
Data 165 , 251 , 120 , 38 , 196 , 154 , 101 , 59 , 217 , 135
Data 4 , 90 , 184 , 230 , 167 , 249 , 27 , 69 , 198 , 152
Data 122 , 36 , 248 , 166 , 68 , 26 , 153 , 199 , 37 , 123
Data 58 , 100 , 134 , 216 , 91 , 5 , 231 , 185 , 140 , 210
Data 48 , 110 , 237 , 179 , 81 , 15 , 78 , 16 , 242 , 172
Data 47 , 113 , 147 , 205 , 17 , 79 , 173 , 243 , 112 , 46
Data 204 , 146 , 211 , 141 , 111 , 49 , 178 , 236 , 14 , 80
Data 175 , 241 , 19 , 77 , 206 , 144 , 114 , 44 , 109 , 51
Data 209 , 143 , 12 , 82 , 176 , 238 , 50 , 108 , 142 , 208
Data 83 , 13 , 239 , 177 , 240 , 174 , 76 , 18 , 145 , 207
Data 45 , 115 , 202 , 148 , 118 , 40 , 171 , 245 , 23 , 73
Data 8 , 86 , 180 , 234 , 105 , 55 , 213 , 139 , 87 , 9
Data 235 , 181 , 54 , 104 , 138 , 212 , 149 , 203 , 41 , 119
Data 244 , 170 , 72 , 22 , 233 , 183 , 85 , 11 , 136 , 214
Data 52 , 106 , 43 , 117 , 151 , 201 , 74 , 20 , 246 , 168
Data 116 , 42 , 200 , 150 , 21 , 75 , 169 , 247 , 182 , 232
Data 10 , 84 , 215 , 137 , 107 , 53