/***********************************************************************************************************************
*                                                                                                                      *
* prbs-generator v0.1                                                                                                  *
*                                                                                                                      *
* Copyright (c) 2022 Andrew D. Zonenberg                                                                               *
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
#ifndef prbs_h
#define prbs_h

#include <stm32fxxx.h>
#include <peripheral/UART.h>
#include <peripheral/GPIO.h>
#include <peripheral/SPI.h>
#include <peripheral/I2C.h>
#include <peripheral/Timer.h>
#include <util/StringBuffer.h>
#include <util/Logger.h>
#include <string.h>
#include <stdlib.h>
#include <cli/UARTOutputStream.h>
//#include "BringupCLISessionContext.h"

extern UART* 			g_uart;
extern I2C*				g_i2c;
extern Logger	 		g_log;
//extern UARTOutputStream g_uartStream;
//extern BringupCLISessionContext g_cliContext;
extern Timer*			g_timer10KHz;

void SleepMs(uint32_t ms);

void SetExpandedGPIO(uint8_t addr, uint8_t value);
void UpdateLEDs();
void UpdateSignalGenerator();

void NextRate();
void NextSwing();
void NextPattern();
void NextEmphasis();

#endif
