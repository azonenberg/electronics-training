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

#include "prbs.h"

//Global peripherals and state
UART* 						g_uart;
I2C*						g_i2c;
Logger 						g_log;
Timer*						g_timer10KHz;

//I2C addresses
#define U3_I2C_ADDR 0x40
#define U4_I2C_ADDR 0x42
#define U6_I2C_ADDR 0x30

//Operating modes
enum DATA_RATE
{
	RATE_1G25,
	RATE_2G5,
	RATE_5G0,
	RATE_10G3125
} g_rate = RATE_1G25;

enum OUTPUT_SWING
{
	SWING_600M,
	SWING_800M,
	SWING_1000M,
	SWING_1200M
} g_swing = SWING_600M;

enum PATTERN
{
	PATTERN_PRBS9,
	PATTERN_PRBS31
} g_pattern = PATTERN_PRBS9;

enum EMPHASIS
{
	EMPHASIS_0,
	EMPHASIS_0P9,
	EMPHASIS_2P0,
	EMPHASIS_3P3,
	EMPHASIS_6P0,
	EMPHASIS_12P0
} g_emphasis = EMPHASIS_0;

void RetimerWrite(uint8_t regid, uint8_t value, uint8_t mask = 0xff);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Entry point

//When possible, long-lived stuff here should be declared static.
//This puts them in .bss instead of stack, and enables better accounting of memory usage
int main()
{
	//Copy .data from flash to SRAM (for some reason the default newlib startup won't do this??)
	memcpy(&__data_start, &__data_romstart, &__data_end - &__data_start + 1);

	//Initialize the PLL
	//CPU clock = AHB clock = APB clock = 48 MHz
	RCCHelper::InitializePLLFromInternalOscillator(2, 12, 1, 1);

	//Initialize LED GPIOs
	static GPIOPin button_nextRate(		&GPIOA, 0, GPIOPin::MODE_INPUT);
	static GPIOPin button_nextSwing(	&GPIOA, 1, GPIOPin::MODE_INPUT);
	static GPIOPin button_nextPattern(	&GPIOA, 2, GPIOPin::MODE_INPUT);
	static GPIOPin button_nextEmphasis(	&GPIOA, 3, GPIOPin::MODE_INPUT);

	//Configure pulldowns
	button_nextRate.SetPullMode(GPIOPin::PULL_DOWN);
	button_nextSwing.SetPullMode(GPIOPin::PULL_DOWN);
	button_nextPattern.SetPullMode(GPIOPin::PULL_DOWN);
	button_nextEmphasis.SetPullMode(GPIOPin::PULL_DOWN);

	//Initialize the UART
	static GPIOPin uart_tx(&GPIOA, 9,	GPIOPin::MODE_PERIPHERAL, 1);
	static GPIOPin uart_rx(&GPIOA, 10, GPIOPin::MODE_PERIPHERAL, 1);
	static UART uart(&USART1, &USART1, 417);
	g_uart = &uart;

	//Enable RXNE interrupt vector (IRQ27)
	//TODO: better contants here
	volatile uint32_t* NVIC_ISER0 = (volatile uint32_t*)(0xe000e100);
	*NVIC_ISER0 = 0x8000000;

	//Set up timer with 100us (10 kHz) ticks, required by logger
	static Timer timer(&TIM1, Timer::FEATURE_ADVANCED, 4800);
	g_timer10KHz = &timer;

	//Set up logging
	g_log.Initialize(g_uart, &timer);
	g_log("UART logging ready\n");

	//Set up I2C.
	//Prescale divide by 8 (6 MHz, 166.6 ns/tick)
	//Divide I2C clock by 16 after that to get 375 kHz
	static GPIOPin i2c_sda( &GPIOB, 7, GPIOPin::MODE_PERIPHERAL, 1);
	static GPIOPin i2c_scl( &GPIOB, 6, GPIOPin::MODE_PERIPHERAL, 1);
	static I2C i2c(&I2C1, 8, 8);
	g_i2c = &i2c;

	//Set up both I/O expanders to have all pins as outputs
	g_i2c->BlockingWrite16(U3_I2C_ADDR, 0x0100);
	g_i2c->BlockingWrite16(U4_I2C_ADDR, 0x0100);

	//Enable interrupts only after all setup work is done
	EnableInterrupts();

	//Push initial LED config
	UpdateLEDs();

	//Initialize the signal generator
	UpdateSignalGenerator();

	//Main loop
	while(true)
	{
		//Watch for button presses
		bool changed = false;
		if(button_nextRate)
		{
			NextRate();
			changed = true;
		}
		if(button_nextSwing)
		{
			NextSwing();
			changed = true;
		}
		if(button_nextPattern)
		{
			NextPattern();
			changed = true;
		}
		if(button_nextEmphasis)
		{
			NextEmphasis();
			changed = true;
		}

		//If any buttons were pushed, send updates
		if(changed)
		{
			UpdateLEDs();
			UpdateSignalGenerator();

			//Wait until the buttons are released (plus debounce delay)
			SleepMs(50);
			while(button_nextRate || button_nextSwing || button_nextPattern || button_nextEmphasis)
				SleepMs(5);
			SleepMs(50);
		}
	}

	return 0;
}

void SleepMs(uint32_t ms)
{
	for(uint32_t i=0; i<ms; i++)
		g_timer10KHz->Sleep(10, true);
}

void SetExpandedGPIO(uint8_t addr, uint8_t value)
{
	//high 8 bits is 0x00 = RegData
	g_i2c->BlockingWrite16(addr, value);
}

void UpdateLEDs()
{
	uint8_t u3_leds = 0;

	//Line rate
	switch(g_rate)
	{
		case RATE_1G25:
			u3_leds |= 0x10;
			break;

		case RATE_2G5:
			u3_leds |= 0x20;
			break;

		case RATE_5G0:
			u3_leds |= 0x40;
			break;

		case RATE_10G3125:
			u3_leds |= 0x80;
			break;
	}

	//Drive strength
	switch(g_swing)
	{
		case SWING_600M:
			u3_leds |= 0x01;
			break;

		case SWING_800M:
			u3_leds |= 0x02;
			break;

		case SWING_1000M:
			u3_leds |= 0x04;
			break;

		case SWING_1200M:
			u3_leds |= 0x08;
			break;
	}

	//Pattern
	uint8_t u4_leds = 0;
	switch(g_pattern)
	{
		case PATTERN_PRBS9:
			u4_leds |= 0x01;
			break;

		case PATTERN_PRBS31:
			u4_leds |= 0x02;
			break;
	}

	//Emphasis
	switch(g_emphasis)
	{
		case EMPHASIS_0:
			u4_leds |= 0x04;
			break;

		case EMPHASIS_0P9:
			u4_leds |= 0x08;
			break;

		case EMPHASIS_2P0:
			u4_leds |= 0x10;
			break;

		case EMPHASIS_3P3:
			u4_leds |= 0x20;
			break;

		case EMPHASIS_6P0:
			u4_leds |= 0x40;
			break;

		case EMPHASIS_12P0:
			u4_leds |= 0x80;
			break;
	}

	//Send to the GPIO expander (invert because LEDs are driven in sink mode)
	SetExpandedGPIO(U3_I2C_ADDR, ~u3_leds);
	SetExpandedGPIO(U4_I2C_ADDR, ~u4_leds);
}

void UpdateSignalGenerator()
{
	//Disable channel B
	RetimerWrite(0xff, 0x05);
	RetimerWrite(0x15, 0x18);

	//Configure channel A
	RetimerWrite(0xff, 0x04);			//Select channel A
	RetimerWrite(0x00, 0x04, 0x04);		//Reset
	RetimerWrite(0x14, 0x80, 0x80);		//Force signal detect on
	RetimerWrite(0x09, 0x04, 0x04);		//Override divider select
	RetimerWrite(0x09, 0x80, 0x80);		//Reserved (VCO cap count override flag per table 20 line 5)
	RetimerWrite(0x08, 0x12, 0x1f);		//CDR cap count

	//VCO frequency programming: select 10.3125 Gbps or 10 Gbps depending on group selection
	if(g_rate == RATE_10G3125)
	{
		RetimerWrite(0x60, 0x90);
		RetimerWrite(0x61, 0xb3);
		RetimerWrite(0x62, 0x90);
		RetimerWrite(0x63, 0xb3);
		RetimerWrite(0x64, 0xdd);
	}

	//VCO frequency: 10.0 Gbps
	else
	{
		//PPM config
		RetimerWrite(0x60, 0x00);
		RetimerWrite(0x61, 0xb2);
		RetimerWrite(0x62, 0x00);
		RetimerWrite(0x63, 0xb2);
		RetimerWrite(0x64, 0xcc);
	}

	//Subrate control
	switch(g_rate)
	{
		case RATE_10G3125:
			RetimerWrite(0x18, 0x00, 0x70);		//VCO divider ratio: /1
			break;

		case RATE_5G0:
			RetimerWrite(0x18, 0x10, 0x70);		//VCO divider ratio: /2
			break;

		case RATE_2G5:
			RetimerWrite(0x18, 0x20, 0x70);		//VCO divider ratio: /4
			break;

		case RATE_1G25:
			RetimerWrite(0x18, 0x30, 0x70);		//VCO divider ratio: /8
			break;
	}


	RetimerWrite(0x09, 0x08, 0x08);		//Reserved (Charge pump power down override per table 20 line 8)
	RetimerWrite(0x1b, 0x00, 0x03);		//Reserved (Disable both charge pumps per table 20 line 9)
	RetimerWrite(0x09, 0x40, 0x40);		//Reserved (override loop filter DAC per table 20 line 10)
	//RetimerWrite(0x1f, 0x12, 0x1f);		//Reserved (Loop filter DAC value per table 20 line 11)

	if(g_rate == RATE_10G3125)
	{
		RetimerWrite(0x1f, 0x17, 0x1f);		//This value vs the table 20 value seems to give more accurate freq
											//on my board
	}
	else
	{
		RetimerWrite(0x1f, 0x0e, 0x1f);		//This value vs the table 20 value seems to give more accurate freq
											//on my board
	}

	RetimerWrite(0x1e, 0x10, 0x10);		//Enable PRBS generator

	//Enable PRBS generator clock and select pattern
	if(g_pattern == PATTERN_PRBS9)
		RetimerWrite(0x30, 0x08, 0x0f);
	else
		RetimerWrite(0x30, 0x0a, 0x0f);

	//Select output drive strength
	switch(g_swing)
	{
		case SWING_600M:
			RetimerWrite(0x2d, 0x00, 0x07);
			break;

		case SWING_800M:
			RetimerWrite(0x2d, 0x02, 0x07);
			break;

		case SWING_1000M:
			RetimerWrite(0x2d, 0x04, 0x07);
			break;

		case SWING_1200M:
			RetimerWrite(0x2d, 0x06, 0x07);
			break;
	}

	//Select output emphasis
	switch(g_emphasis)
	{
		case EMPHASIS_0:
			RetimerWrite(0x15, 0x00, 0x47);
			break;

		case EMPHASIS_0P9:
			RetimerWrite(0x15, 0x41, 0x47);
			break;

		case EMPHASIS_2P0:
			RetimerWrite(0x15, 0x42, 0x47);
			break;

		case EMPHASIS_3P3:
			RetimerWrite(0x15, 0x44, 0x47);
			break;

		case EMPHASIS_6P0:
			RetimerWrite(0x15, 0x04, 0x47);
			break;

		case EMPHASIS_12P0:
			RetimerWrite(0x15, 0x07, 0x47);
			break;
	}

	RetimerWrite(0x09, 0x20, 0x20);		//Override loopthru select
	RetimerWrite(0x1e, 0x80, 0xe0);		//Output mux: select PRBS
	RetimerWrite(0x0d, 0x20, 0x20);		//Load PRBS seed
}

void RetimerWrite(uint8_t regid, uint8_t value, uint8_t mask)
{
	g_i2c->BlockingWrite8(U6_I2C_ADDR, regid);

	uint8_t tmp;
	g_i2c->BlockingRead(U6_I2C_ADDR, &tmp, 1);

	g_i2c->BlockingWrite16(U6_I2C_ADDR, (regid << 8) | (tmp & ~mask) | (value & mask) );
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Handle button pushes

void NextRate()
{
	switch(g_rate)
	{
		case RATE_1G25:
			g_rate = RATE_2G5;
			break;

		case RATE_2G5:
			g_rate = RATE_5G0;
			break;

		case RATE_5G0:
			g_rate = RATE_10G3125;
			break;

		case RATE_10G3125:
			g_rate = RATE_1G25;
			break;
	}
}

void NextSwing()
{
	switch(g_swing)
	{
		case SWING_600M:
			g_swing = SWING_800M;
			break;

		case SWING_800M:
			g_swing = SWING_1000M;
			break;

		case SWING_1000M:
			g_swing = SWING_1200M;
			break;

		case SWING_1200M:
			g_swing = SWING_600M;
			break;
	}
}

void NextPattern()
{
	switch(g_pattern)
	{
		case PATTERN_PRBS9:
			g_pattern = PATTERN_PRBS31;
			break;

		case PATTERN_PRBS31:
			g_pattern = PATTERN_PRBS9;
			break;
	}
}

void NextEmphasis()
{
	switch(g_emphasis)
	{
		case EMPHASIS_0:
			g_emphasis = EMPHASIS_0P9;
			break;

		case EMPHASIS_0P9:
			g_emphasis = EMPHASIS_2P0;
			break;

		case EMPHASIS_2P0:
			g_emphasis = EMPHASIS_3P3;
			break;

		case EMPHASIS_3P3:
			g_emphasis = EMPHASIS_6P0;
			break;

		case EMPHASIS_6P0:
			g_emphasis = EMPHASIS_12P0;
			break;

		case EMPHASIS_12P0:
			g_emphasis = EMPHASIS_0;
			break;
	}
}
