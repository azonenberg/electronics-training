/***********************************************************************************************************************
*                                                                                                                      *
* electronics-training                                                                                                 *
*                                                                                                                      *
* Copyright (c) 2023-2026 Andrew D. Zonenberg and contributors                                                         *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

#ifndef hwinit_h
#define hwinit_h

#include <cli/UARTOutputStream.h>

#include <peripheral/CRC.h>
#include <peripheral/Flash.h>
#include <peripheral/GPIO.h>
#include <peripheral/RTC.h>
#include <peripheral/SPI.h>
#include <peripheral/UART.h>

#include <APB_DeviceInfo_7series.h>
#include <APB_GPIO.h>
#include <APB_SerialLED.h>
#include <APB_SPIHostInterface.h>
#include <APB_XADC.h>

#include <embedded-utils/LogSink.h>
#include <embedded-utils/APB_SpiFlashInterface.h>

#include <bootloader/BootloaderAPI.h>

#include <boilerplate/h750/StandardBSP.h>
#include <fpga/FMCUtils.h>

void App_Init();
void InitFMC();
void InitFPGAFlash();
void InitI2C();
void InitITM();

//Common hardware interface stuff (mostly Ethernet related)
extern GPIOPin g_leds[4];
extern APB_GPIOPin g_fpgaLEDs[4];
extern APB_SpiFlashInterface* g_fpgaFlash;
extern APB_GPIOPin g_fpgaIRQ;

void USART1_Handler();

extern volatile APB_DeviceInfo_7series FDEVINFO;
extern volatile APB_XADC FXADC;
extern volatile APB_SerialLED FRGBLED;
extern volatile APB_GPIO FPGA_GPIOA;
extern volatile APB_SPIHostInterface FQSPI;

#endif
