$regfile = "M32def.dat"
' Define used crystal
$crystal = 4915200                                          '3932160                                          ' 4.915200 MHz
$baud = 4800

Config Serialin = Buffered , Size = 254
Config Serialout = Buffered , Size = 1


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

' Dimensions
Dim X_frequency_a(345) As Word
Dim Frequency As Word
Dim X_a As Word
X_a = 0
Dim Y_a As Word
Dim Pin As Bit
Pin = 0
Dim F As Byte
                                                     '

'//////////////////////////////////////////////////////////////////////////////

   'For F = 1 To 2
      'Call Command_2_micro2                                 ' Force Micro 2 to Start Generation of Sinewave A
      'Call Init_sampling                                    ' Store Sampled Frequency into Arrays
      'Call Send_to_pc_a                                     ' Send Sampled Frequency to Computer
   'Next
'//////////////////////////////////////////////////////////////////////////////
    Do
      Call Command_2_micro2                                 ' Force Micro 2 to Start Generation of Sinewave A
      Call Init_sampling                                    ' Store Sampled Frequency into Arrays
      Call Send_to_pc_a                                     ' Send Sampled Frequency to Computer
      Wait 1
      ' Nothing
    Loop

End



'//////////////////////////////////////////////////////////////////////////////
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

    Timer1 = 63570                                          '64550                                          '63423                                                                  ' 50 ms, =65535-(1920) for 100 ms, and =65535-(960) for 50 ms
    Start Timer1
    Do
      ' Wait for 100 ms
    Loop Until Pin = 1
    Pin = 0
End Sub
'//////////////////////////////////////////////////////////////////////////////
Sub Init_sampling:
    Timer1 = 63590                                          ' 110 ms, =65535-(1920) for 100 ms, and =65535-(2112) for 110 ms
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
      Print " " ; X_frequency_a(y_a)                        '; " ";                           'Y ; ":" ; X_frequency(y) ; "   ";               'X_frequency(y) ; "   ";
      If Y_a = X_a Then
         Print "End=" ; X_a
      End If
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
Adc_isr:
   'Nothing
Return
'//////////////////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////////////////