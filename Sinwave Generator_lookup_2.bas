'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
'
' Firmware for Unsaturated Hydraulic Conductivity Sensor
' Written by Y. Osroosh, Ph.D.
' Email: yosroosh@gmail.com
' 
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
'@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

$regfile = "M32def.dat"
' Define used crystal
$crystal = 16000000                                         ' 4.915200 MHz
$baud = 9600

Config Serialin = Buffered , Size = 254
Config Serialout = Buffered , Size = 1
' Configure Watchdog
Config Watchdog = 2048


'The internal clock can be divided by 1,8,64,256 or 1024
Config Timer1 = Timer , Prescale = 8                        ' 0.5 microsecond
Enable Interrupts
Enable Timer1
Enable Ovf1
On Ovf1 Ovf1routin
Timer1 = 1                                                  ' Defualt Value for Timer 1

' Configure Pinb.1 as Output
Config Pinb.1 = Output                                      ' Sinwave Output
Config Pinb.2 = Output                                      ' Informing Pin Output
Reset Portb.2                                               ' Reset Portb.2 (Informing Pin)
Config Pind.2 = Input                                       ' Interrupt Pin


' Alias Pins
Pwm Alias Pinb.1                                            ' PWM Output


Declare Sub Cal_freq_points_a
Declare Sub Sinewave_gener_a

' Dimensions
Dim T As Single                                             ' micro second
Dim T_pulse As Single                                       ' micro second
Dim T_pulse_long As Long
Dim T_pulse_half As Long
Dim Pw As Single                                            ' micro second
Dim Pw_long As Long
Dim W As Long                                               ' Calculation place
Dim W_high(256) As Word                                     ' High Width of Pulse (micro second)
Dim W_low(256) As Word                                      ' Low Width of Pulse (micro second)
Dim F_sinwave As Word                                       ' Hertz
Dim F_x As Word                                             '
Dim X_lut As Word
Dim X As Word
Dim X_frequency As Word                                     '
Dim X_sinwave As Word
Dim Pin As Bit
Pin = 0                                                     ' Sinewave output Low/High
'Dim M(256) As Word , N(256) As Word , O(256) As Word
Dim Y As Byte
Dim Num_waves As Byte


'//////////////////////////////////////////////////////////////////////////////
    F_sinwave = 10                                          ' Frequency of Sinwave (Hertz)
    Call Cal_freq_points_a                                  ' Calculate Data Points for Specified Frequency
Do
    ' Frequency 1
    'F_sinwave = 10                                          ' Frequency of Sinwave (Hertz)
    'Call Cal_freq_points_a                                  ' Calculate Data Points for Specified Frequency
    Do
      ' Nothing
      Reset Watchdog
    Loop Until Pind.2 = 1
    'F_sinwave = 10                                          ' Frequency of Sinwave (Hertz)
    'Call Cal_freq_points_a                                  ' Calculate Data Points for Specified Frequency
    Call Sinewave_gener_a                                   ' Generate the Corresponding Sinwave

    ' Frequemcy 2
    'Do
      ' Nothing
    'Loop Until Pind.2 = 1
    'F_sinwave = 20                                          ' Frequency of Sinwave (Hertz)
    'Call Cal_freq_points_a                                  ' Calculate Data Points for Specified Frequency
    'Call Sinewave_gener_a                                   ' Generate the Corresponding Sinwave
Loop

End

'//////////////////////////////////////////////////////////////////////////////
Sub Cal_freq_points_a:
    T = 1000000 / F_sinwave                                 ' micro second
    T_pulse = T / 256

    T_pulse_long = Round(t_pulse)
    T_pulse_half = T_pulse_long / 2
    T_pulse_long = T_pulse_long * 2

    For X = 1 To 256
         Y = X - 1
         F_x = Lookup(y , Sine)                             ' f_x = f(x)/100
         W = T_pulse_half * F_x                             ' W_high = (F_x/254)*T_pulse_half =(F_x*T_pulse_half)/(254)
         W = W / 127                                        ' High Width of Pulse,   micro second*100, 0.5*2=1 microsecond

         W_high(x) = 65535 - W                              ' Timer counts from the W_high point to 65535

         W = T_pulse_long - W                               ' Low Width of Pulse
         W = W - 47                                         ' Corection Constant
         W_low(x) = 65535 - W                               ' Timer counts from the W_low point to 65535
    Next
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Sinewave_gener_a:
   Num_waves = F_sinwave / 10
   Num_waves = Num_waves * 3
   'Do
    Set Portb.2                                             ' Set informing Pin

    For X_sinwave = 1 To Num_waves                          ' Number of sinewaves
      For X_lut = 1 To 256
         Timer1 = W_high(x_lut)
         Start Timer1

         Set Portb.1                                        ' Set Portb.1 (Pulse Pin) High
         Bitwait Pin , Set                                  ' Wait until bit pin is set
         Reset Portb.1                                      ' Set Portb.1 (Pulse Pin) Low
         Pin = 0

         Timer1 = W_low(x_lut)
         Start Timer1
         Bitwait Pin , Set                                  ' Wait until bit pin is set
         Pin = 0

         'M(x_lut) = W_high
         'N(x_lut) = W_low
         'O(x_lut) = F_x
      Next
      'For Y = 0 To 255
         'Print Y ; "=" ; M(y) ; "+" ; N(y) ; "+" ; O(y) ; "- ";
      'Next
      'Wait 4
    Next

    Reset Portb.2                                           ' Reset informing Pin
   'Loop

End Sub
'//////////////////////////////////////////////////////////////////////////////
Ovf1routin:
   Pin = 1
   Stop Timer1
Return
'//////////////////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////////////////
Sine:                                                       ' 256 step sinewave table
 ' Formula: f(x) = 127 + 127 * sin(2*PI*x/256) , x [0 ... 255]
 Data 127 % , 130 % , 133 % , 136 % , 139 % , 143 % , 146 % , 149 % , 152% , 155% , 158 % , 161% , 164% , 167% , 170% , 173% , 176%
 Data 178 % , 181 % , 184 % , 187 % , 190 % , 192 % , 195 % , 198 % , 200 % , 202 % , 205 % , 208 % , 210 % , 212 % , 215 % , 217 %
 Data 219 % , 221 % , 223 % , 225 % , 227 % , 229 % , 231 % , 233 % , 234 % , 236 % , 238 % , 239 % , 240 % , 242 % , 243 % , 244 %
 Data 246 % , 247 % , 248 % , 249 % , 249 % , 250 % , 251 % , 252 % , 252 % , 253 % , 253 % , 253 % , 254 % , 254 % , 254 % , 254 %
 Data 254 % , 254 % , 254 % , 253 % , 253 % , 253 % , 252 % , 252 % , 251 % , 250 % , 249 % , 249 % , 248 % , 247 % , 246 % , 244 %
 Data 243 % , 242 % , 241 % , 239 % , 238 % , 236 % , 234 % , 233 % , 231 % , 229 % , 227 % , 225 % , 223 % , 221 % , 219 % , 217 %
 Data 215 % , 212 % , 210 % , 208 % , 205 % , 203 % , 200 % , 198 % , 195 % , 192 % , 190 % , 187 % , 184 % , 182 % , 179 % , 176 %
 Data 173 % , 170 % , 167 % , 164 % , 161 % , 158 % , 155 % , 152 % , 149 % , 146 % , 143 % , 140 % , 137 % , 133 % , 130 % , 127 %
 Data 124 % , 121 % , 118 % , 115 % , 112 % , 109 % , 106 % , 102 % , 99 % , 96 % , 93 % , 90 % , 87 % , 84 % , 82 % , 79 %
 Data 76 % , 73 % , 70 % , 67 % , 65 % , 62 % , 59 % , 57 % , 54 % , 52 % , 49 % , 47 % , 44 % , 42 % , 40 % , 37 %
 Data 35 % , 33 % , 31 % , 29 % , 27 % , 25 % , 23 % , 22 % , 20 % , 18 % , 17 % , 15 % , 14 % , 12 % , 11 % , 10 %
 Data 9 % , 8 % , 7 % , 6 % , 5 % , 4 % , 3 % , 3 % , 2 % , 1 % , 1 % , 0 % , 0 % , 0 % , 0 % , 0 %
 Data 0 % , 0 % , 0 % , 1 % , 1 % , 1 % , 3 % , 3 % , 3 % , 4 % , 5 % , 5 % , 6 % , 7 % , 8 % , 10 %
 Data 11 % , 12 % , 13 % , 15 % , 16 % , 18 % , 20 % , 21 % , 23 % , 25 % , 27 % , 29 % , 31 % , 33 % , 35 % , 37 %
 Data 39 % , 41 % , 44 % , 46 % , 49 % , 51 % , 54 % , 56 % , 59 % , 61 % , 64 % , 67 % , 70 % , 72 % , 75 % , 78 %
 Data 81 % , 84 % , 87 % , 90 % , 93 % , 96 % , 99 % , 102 % , 105 % , 108 % , 111 % , 114 % , 117 % , 120 % , 124 % , 127 %
