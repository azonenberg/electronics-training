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

#include "demo.h"
#include <ctype.h>
#include "../bsp/FPGATask.h"
#include "LocalConsoleTask.h"
#include "DisplayTask.h"
#include "ButtonTask.h"

/**
	@brief Initialize global GPIO LEDs
 */
void InitLEDs()
{
	//Turn on the MCU GPIO LEDs
	g_leds[0] = 1;
	g_leds[1] = 1;
	g_leds[2] = 1;
	g_leds[3] = 1;

	//Turn on the FPGA GPIO LEDs
	g_fpgaLEDs[0] = 1;
	g_fpgaLEDs[1] = 1;
	g_fpgaLEDs[2] = 1;
	g_fpgaLEDs[3] = 1;

	//Turn off all of the RGB LEDs
	/*for(int i=0; i<4; i++)
		FRGBLED.framebuffer[i] = 0x000000;*/

	//Configure the RGB LEDs
	FRGBLED.framebuffer[0] = 0x200000;	//red
	FRGBLED.framebuffer[1] = 0x002000;	//green
	FRGBLED.framebuffer[2] = 0x000020;	//blue
	FRGBLED.framebuffer[3] = 0x202020;	//white
}

/**
	@brief Initialize sensors and log starting values for each
 */
void InitSensors()
{
	g_log("Initializing sensors\n");
	LogIndenter li(g_log);

	//No fans on this board

	//Read FPGA temperature
	auto temp = FXADC.die_temp;
	g_log("FPGA die temperature:              %uhk C\n", temp);

	//Read FPGA voltage sensors
	int volt = FXADC.volt_core;
	g_log("FPGA VCCINT:                        %uhk V\n", volt);
	volt = FXADC.volt_ram;
	g_log("FPGA VCCBRAM:                       %uhk V\n", volt);
	volt = FXADC.volt_aux;
	g_log("FPGA VCCAUX:                        %uhk V\n", volt);

	//TODO: read STM32 temperature

	//TODO: I2C query the supervisor
}

/**
	@brief Initialize the display
 */
void InitDisplay()
{
	g_log("Initializing display\n");
	LogIndenter li(g_log);

	//Set up GPIOs for display bus
	static GPIOPin display_sck(&GPIOF, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 5);
	static GPIOPin display_mosi(&GPIOF, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 5);
	display_sck.SetPullMode(GPIOPin::PULL_DOWN);

	//Set up GPIOs
	static GPIOPin display_busy_n(&GPIOI, 0, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
	static GPIOPin display_bs(&GPIOH, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
	static GPIOPin display_cs_n(&GPIOF, 6, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
	static GPIOPin display_dc(&GPIOI, 1, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_MEDIUM);
	static GPIOPin display_rst_n(&GPIOI, 2, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);

	//BS pin seems to be a strap that just needs to be held low
	display_bs = 0;

	//Set up the display itself
	static DisplayTask display(&g_displaySPI, &display_busy_n, &display_cs_n, &display_dc, &display_rst_n);
	g_display = &display;

	//Change the SPI baud rate once the display has read the ROM
	//div 8 = 14.842 MHz
	g_displaySPI.SetBaudDiv(8);

	//Clear the display
	g_display->Clear();

	//Fill with a checkerboard
	uint32_t size = 8;
	uint h = g_display->GetHeight();
	uint w = g_display->GetWidth();
	for(uint32_t y=0; y < h; y += size)
	{
		for(uint32_t x=0; x < w; x += size)
		{
			uint32_t bx = (x / size) & 1;
			uint32_t by = (y / size) & 1;
			g_display->FilledRect(x, y, x + size, y + size, (bx == by));
		}
	}

	//Actually refresh it
	g_display->StartRefresh(true);

	//Add the task
	g_tasks.push_back(g_display);
}

void App_Init()
{
	//Enable interrupts early on since we use them for e.g. debug logging during boot
	EnableInterrupts();

	//Basic hardware setup
	InitLEDs();
	InitSensors();
	InitDisplay();

	static LocalConsoleTask localConsoleTask;
	static ButtonTask buttonTask;

	g_tasks.push_back(&localConsoleTask);
	g_tasks.push_back(&buttonTask);

	//g_timerTasks.push_back(&phyTask);
}
