EESchema Schematic File Version 4
EELAYER 30 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L device:C C1
U 1 1 61A4FBF5
P 2900 2500
F 0 "C1" V 2648 2500 50  0000 C CNN
F 1 "Shunt path" V 2739 2500 50  0000 C CNN
F 2 "" H 2938 2350 50  0001 C CNN
F 3 "" H 2900 2500 50  0001 C CNN
	1    2900 2500
	0    1    1    0   
$EndComp
$Comp
L device:R R1
U 1 1 61A50155
P 2900 2950
F 0 "R1" V 2693 2950 50  0000 C CNN
F 1 "Desired" V 2784 2950 50  0000 C CNN
F 2 "" V 2830 2950 50  0001 C CNN
F 3 "" H 2900 2950 50  0001 C CNN
	1    2900 2950
	0    1    1    0   
$EndComp
$Comp
L device:L L1
U 1 1 61A508A4
P 2400 2750
F 0 "L1" V 2219 2750 50  0000 C CNN
F 1 "Mount" V 2310 2750 50  0000 C CNN
F 2 "" H 2400 2750 50  0001 C CNN
F 3 "" H 2400 2750 50  0001 C CNN
	1    2400 2750
	0    1    1    0   
$EndComp
Wire Wire Line
	2550 2750 2750 2750
Wire Wire Line
	2750 2750 2750 2500
Wire Wire Line
	2750 2750 2750 2950
Connection ~ 2750 2750
Wire Wire Line
	3050 2950 3200 2950
Wire Wire Line
	3200 2950 3200 2500
Wire Wire Line
	3200 2500 3050 2500
$EndSCHEMATC
