EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title "Crystal Oscillator Test Board"
Date "2022-01-02"
Rev "0.1"
Comp "Antikernel Labs"
Comment1 "Andrew D. Zonenberg"
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L power-azonenberg:BARREL_JACK J1
U 1 1 61CE4CB4
P 1900 3450
F 0 "J1" H 1783 3925 50  0000 C CNN
F 1 "BARREL_JACK" H 1783 3834 50  0000 C CNN
F 2 "azonenberg_pcb:CONN_CUI_PJ-058BH_HIPWR_BARREL_NOSLOT" H 1900 3450 50  0001 C CNN
F 3 "" H 1900 3450 50  0001 C CNN
	1    1900 3450
	1    0    0    -1  
$EndComp
Text Label 2000 3200 0    50   ~ 0
3V3
Text Label 2000 3300 0    50   ~ 0
GND
NoConn ~ 2000 3400
$Comp
L special-azonenberg:SN74LVC1GX04 U1
U 1 1 61CE58F9
P 2950 3650
F 0 "U1" H 3175 4325 50  0000 C CNN
F 1 "SN74LVC1GX04" H 3175 4234 50  0000 C CNN
F 2 "azonenberg_pcb:SOT23_6" H 2950 3650 50  0001 C CNN
F 3 "" H 2950 3650 50  0001 C CNN
	1    2950 3650
	1    0    0    -1  
$EndComp
Wire Wire Line
	2000 3200 2850 3200
Wire Wire Line
	2850 3300 2000 3300
$Comp
L device:R R3
U 1 1 61CE5FB8
P 4000 3500
F 0 "R3" V 3793 3500 50  0000 C CNN
F 1 "33" V 3884 3500 50  0000 C CNN
F 2 "azonenberg_pcb:EIA_0402_RES_NOSILK" V 3930 3500 50  0001 C CNN
F 3 "" H 4000 3500 50  0001 C CNN
	1    4000 3500
	0    1    1    0   
$EndComp
$Comp
L device:C C1
U 1 1 61CE741D
P 4150 4700
F 0 "C1" H 4265 4746 50  0000 L CNN
F 1 "4.7 uF" H 4265 4655 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0603_CAP_NOSILK" H 4188 4550 50  0001 C CNN
F 3 "" H 4150 4700 50  0001 C CNN
	1    4150 4700
	1    0    0    -1  
$EndComp
Text Label 4150 4550 2    50   ~ 0
3V3
Text Label 4150 4850 2    50   ~ 0
GND
$Comp
L device:C C2
U 1 1 61CE8367
P 4650 4700
F 0 "C2" H 4765 4746 50  0000 L CNN
F 1 "0.47 uF" H 4765 4655 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 4688 4550 50  0001 C CNN
F 3 "" H 4650 4700 50  0001 C CNN
	1    4650 4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	4650 4550 4150 4550
Wire Wire Line
	4150 4850 4650 4850
$Comp
L Connector:Conn_Coaxial J2
U 1 1 61CE911D
P 4900 3500
F 0 "J2" H 5000 3475 50  0000 L CNN
F 1 "SMA-J-P-H-ST-EM1" H 5000 3384 50  0000 L CNN
F 2 "azonenberg_pcb:CONN_SMA_EDGE_SAMTEC_SMA_J_P_H_ST_EM1" H 4900 3500 50  0001 C CNN
F 3 "" H 4900 3500 50  0001 C CNN
	1    4900 3500
	1    0    0    -1  
$EndComp
Text Label 4750 3700 2    50   ~ 0
GND
Wire Wire Line
	4750 3700 4900 3700
$Comp
L device:Crystal Y1
U 1 1 61CEA10A
P 2500 4400
F 0 "Y1" H 2900 4500 50  0000 L CNN
F 1 "ABS07-32.768KHZ-4-T" H 2900 4400 50  0000 L CNN
F 2 "azonenberg_pcb:CRYSTAL_3.2x1.5MM" H 2500 4400 50  0001 C CNN
F 3 "" H 2500 4400 50  0001 C CNN
	1    2500 4400
	1    0    0    -1  
$EndComp
$Comp
L device:R R1
U 1 1 61CEC10B
P 2500 3800
F 0 "R1" V 2293 3800 50  0000 C CNN
F 1 "1M" V 2384 3800 50  0000 C CNN
F 2 "azonenberg_pcb:EIA_0402_RES_NOSILK" V 2430 3800 50  0001 C CNN
F 3 "" H 2500 3800 50  0001 C CNN
	1    2500 3800
	0    1    1    0   
$EndComp
$Comp
L device:R R2
U 1 1 61CECF76
P 2750 4050
F 0 "R2" H 2820 4096 50  0000 L CNN
F 1 "324K" H 2820 4005 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_RES_NOSILK" V 2680 4050 50  0001 C CNN
F 3 "" H 2750 4050 50  0001 C CNN
	1    2750 4050
	1    0    0    -1  
$EndComp
Text Notes 3050 4150 0    50   ~ 0
Tune R2 to minimize margin (crystal wants 70K nominal)\nWe want oscillator stable without any added capacitance\nbut significant drift or complete stoppage with loading from R-C divider probe on J3
$Comp
L device:C C3
U 1 1 61CEE341
P 2200 4700
F 0 "C3" H 2315 4746 50  0000 L CNN
F 1 "8 pF" H 2315 4655 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 2238 4550 50  0001 C CNN
F 3 "" H 2200 4700 50  0001 C CNN
	1    2200 4700
	1    0    0    -1  
$EndComp
Text Notes 2200 5150 0    50   ~ 0
Crystal wants 4 pF loading\n4 pF = (C3 * C4) / (C3 + C4)\nC3 = C4 = 8 pF
$Comp
L device:C C4
U 1 1 61CF0D09
P 2750 4700
F 0 "C4" H 2865 4746 50  0000 L CNN
F 1 "8 pF" H 2865 4655 50  0000 L CNN
F 2 "azonenberg_pcb:EIA_0402_CAP_NOSILK" H 2788 4550 50  0001 C CNN
F 3 "" H 2750 4700 50  0001 C CNN
	1    2750 4700
	1    0    0    -1  
$EndComp
Wire Wire Line
	2200 4550 2200 4400
Wire Wire Line
	2200 4400 2350 4400
Wire Wire Line
	2650 4400 2750 4400
Wire Wire Line
	2750 4400 2750 4550
Wire Wire Line
	2750 4850 2200 4850
Text Label 2200 4850 2    50   ~ 0
GND
Wire Wire Line
	2750 4200 2750 4400
Connection ~ 2750 4400
Wire Wire Line
	2750 3900 2750 3800
Wire Wire Line
	2750 3800 2650 3800
Wire Wire Line
	2350 3800 2200 3800
Wire Wire Line
	2200 3800 2200 4400
Connection ~ 2200 4400
Wire Wire Line
	2850 3500 2200 3500
Wire Wire Line
	2200 3500 2200 3800
Connection ~ 2200 3800
Wire Wire Line
	2750 3800 2750 3600
Wire Wire Line
	2750 3600 2850 3600
Connection ~ 2750 3800
$Comp
L Connector:Conn_01x01 J3
U 1 1 61CF4BA7
P 1150 4400
F 0 "J3" H 1068 4175 50  0000 C CNN
F 1 "TESTPOINT" H 1068 4266 50  0000 C CNN
F 2 "azonenberg_pcb:TESTPOINT_SMT_0.5MM" H 1150 4400 50  0001 C CNN
F 3 "~" H 1150 4400 50  0001 C CNN
	1    1150 4400
	-1   0    0    1   
$EndComp
Wire Wire Line
	1350 4400 2200 4400
$Comp
L Connector:Conn_01x01 J4
U 1 1 61CF5C78
P 1150 4850
F 0 "J4" H 1068 4625 50  0000 C CNN
F 1 "TESTCLIP" H 1068 4716 50  0000 C CNN
F 2 "azonenberg_pcb:TESTPOINT_SMT_KEYSTONE_5016" H 1150 4850 50  0001 C CNN
F 3 "~" H 1150 4850 50  0001 C CNN
	1    1150 4850
	-1   0    0    1   
$EndComp
Wire Wire Line
	1350 4850 2200 4850
Connection ~ 2200 4850
Text Label 2200 3500 0    50   ~ 0
X1
Text Label 2750 3800 0    50   ~ 0
X2
Text Label 2750 4400 0    50   ~ 0
X2X
Wire Wire Line
	4150 3500 4750 3500
Wire Wire Line
	3850 3500 3500 3500
Text Label 3550 3500 0    50   ~ 0
VOUT
Text Label 4250 3500 0    50   ~ 0
VOUT_TERM
$EndSCHEMATC
