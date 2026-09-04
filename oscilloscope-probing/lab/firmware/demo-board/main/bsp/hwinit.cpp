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

/**
	@file
	@author	Andrew D. Zonenberg
	@brief	Boot-time hardware initialization
 */
#include <core/platform.h>
#include "hwinit.h"
#include "FPGATask.h"
#include <peripheral/QuadSPI.h>
/*
#include <peripheral/DWT.h>
#include <peripheral/ITM.h>
#include <ctype.h>
#include <embedded-utils/CoreSightRom.h>
#include <fpga/FPGAFirmwareUpdater.h>
*/

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Memory mapped SFRs on the FPGA
/*
volatile APB_GPIO FPGA_GPIOA __attribute__((section(".fgpioa")));
volatile APB_DeviceInfo_Generic FDEVINFO __attribute__((section(".fdevinfo")));
volatile APB_SPIHostInterface FSPI1 __attribute__((section(".fspi1")));

volatile APB_MDIO FMDIO __attribute__((section(".fmdio")));

//volatile APB_Curve25519 FCURVE25519 __attribute__((section(".fcurve25519")));

volatile APB_EthernetTxBuffer_10G FETHTX __attribute__((section(".fethtx")));
volatile APB_EthernetRxBuffer FETHRX __attribute__((section(".fethrx")));
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Common peripherals used by application and bootloader

/**
	@brief UART console

	Default after reset is for UART1 to be clocked by PCLK2 (APB2 clock) which is 118.75 MHz
	So we need a divisor of 1030.81
 */
UART<32, 256> g_cliUART(&USART1, 1031);

/**
	@brief MCU GPIO LEDs
 */
 /*
GPIOPin g_leds[4] =
{
	GPIOPin(&GPIOI, 4, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW),
	GPIOPin(&GPIOI, 6, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW),
	GPIOPin(&GPIOI, 7, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW),
	GPIOPin(&GPIOI, 5, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW)
};
*/

/**
	@brief FPGA GPIO LEDs
 */
/*
APB_GPIOPin g_fpgaLEDs[8] =
{
	APB_GPIOPin(&FPGA_GPIOA, 8, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 9, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 10, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 11, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 12, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 13, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 14, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED),
	APB_GPIOPin(&FPGA_GPIOA, 15, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED)
};

///@brief FPGA IRQ pin
APB_GPIOPin g_fpgaIRQ(&FPGA_GPIOA, 0, APB_GPIOPin::MODE_OUTPUT, APB_GPIOPin::INIT_DEFERRED);
*/
/**
	@brief MAC address I2C EEPROM
	Default kernel clock for I2C1 is pclk1 (118.75 MHz for our current config)
	Prescale by 16 to get 29.68 MHz
	Divide by 128 after that to get 231 kHz
*/
//I2C g_macI2C(&I2C1, 16, 128);

/**
	@brief Microkvs and firmware storage for the MCU

	Initialize the QSPI block assuming 128 Mbits to start
	QSPI kernel clock defaults to HCLK3 which is 237.5 MHz
	Divide by 4 gives 59.375 MHz which should be fairly safe to start
 */
//QuadSPI_SpiFlashInterface g_flashQspi(&_QUADSPI, 128 * 1024 * 1024, 4);

///@brief Boot flash on the FPGA
//APB_SpiFlashInterface* g_fpgaFlash = nullptr;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Task tables

etl::vector<Task*, MAX_TASKS>  g_tasks;
etl::vector<TimerTask*, MAX_TIMER_TASKS>  g_timerTasks;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Do other initialization

void InitITM();
//void InitQSPI();

void BSP_InitTasks();

void BSP_Init()
{
	/*
	//Set up PLL2 to run the external memory bus
	//We have some freedom with how fast we clock this!
	//Doesn't have to be a multiple of CPU clock since separate VCO from the main system
	RCCHelper::InitializePLL(
		2,		//PLL2
		25,		//input is 25 MHz from the HSE
		2,		//25/2 = 12.5 MHz at the PFD
		20,		//12.5 * 20 = 250 MHz at the VCO
		32,		//div P (not used for now)
		32,		//div Q (not used for now)
		2,		//div R (125 MHz FMC kernel clock = 62.5 MHz FMC clock)
		RCCHelper::CLOCK_SOURCE_HSE
	);

	g_leds[0] = 1;

	InitRTCFromHSE();
	InitQSPI();
	DoInitKVS();
	InitFMC();
	InitFPGA();
	InitFPGAFlash();

	//Initialize the LEDs and FPGA IRQ (for now turn them all on)
	for(auto& led : g_fpgaLEDs)
	{
		led.DeferredInit();
		led = 1;
	}
	g_fpgaIRQ.DeferredInit();

	InitI2C();
	InitMacEEPROM();
	InitManagementPHY();

	//TODO: tune this to see what gives the best results and how wide our data window is
	g_log("Poking clock skew register\n");
	g_phyMdio->WriteExtendedRegister(2, REG_KSZ9031_MMD2_CLKSKEW, 0x3ff0);

	InitIP();
	//InitITM();

	//Standard tasks used by both bootloader and application
	BSP_InitTasks();

	App_Init();
	*/
}
/*
void BSP_InitTasks()
{
	//Create tasks
	static FPGATask fpgaTask;
	static IPAgingTask1Hz agingTask1;
	static IPAgingTask10Hz agingTask10;
	static PhyPollTask phyTask;

	g_tasks.push_back(&fpgaTask);
	g_tasks.push_back(&agingTask1);
	g_tasks.push_back(&agingTask10);
	g_tasks.push_back(&phyTask);

	g_timerTasks.push_back(&agingTask1);
	g_timerTasks.push_back(&agingTask10);
	g_timerTasks.push_back(&phyTask);
}
*/
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Enable trace

/**
	@brief Initialize tracing
 */
void InitITM()
{
	/*
	g_log("Initializing ITM\n");

	//Enable ITM, enable PC sampling, and turn on forwarding to the TPIU
	#ifdef _DEBUG
		ITM::Enable();
		DWT::EnablePCSampling(DWT::PC_SAMPLE_SLOW);
		ITM::EnableDwtForwarding();
	#endif
	*/
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// BSP overrides for low level init
/*
void BSP_InitUART()
{
	//Initialize the UART for local console: 115.2 Kbps using PA9 for UART1 transmit and PA10 for UART1 receive
	//TODO: nice interface for enabling UART interrupts
	static GPIOPin uart_tx(&GPIOA, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);
	static GPIOPin uart_rx(&GPIOA, 10, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 7);

	//Enable the UART interrupt
	NVIC_EnableIRQ(37);

	g_logTimer.Sleep(10);	//wait for UART pins to be high long enough to remove any glitches during powerup
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Higher level initialization we used for a lot of stuff

void InitQSPI()
{
	g_log("Initializing QSPI...\n");

	//Set up QSPI pins
	g_leds[1] = 1;
	static GPIOPin quadspi_sck(&GPIOB, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 9);
	static GPIOPin quadspi_cs_n(&GPIOB, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 10);
	static GPIOPin quadspi_dq0(&GPIOF, 8, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 10);
	static GPIOPin quadspi_dq1(&GPIOF, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 10);
	static GPIOPin quadspi_dq2(&GPIOF, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 9);
	static GPIOPin quadspi_dq3(&GPIOF, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_FAST, 9);

	//Bring the QSPI up in memory mapped mode
	g_leds[2] = 1;
	g_flashQspi.SetDoubleRateMode(false);
	g_flashQspi.SetInstructionMode(QuadSPI::MODE_SINGLE);
	g_flashQspi.SetAddressMode(QuadSPI::MODE_SINGLE, 3);
	g_flashQspi.SetAltBytesMode(QuadSPI::MODE_NONE, 0);
	g_flashQspi.SetDataMode(QuadSPI::MODE_SINGLE);
	g_flashQspi.SetDummyCycleCount(8);
	g_flashQspi.SetDeselectTime(1);
	g_flashQspi.SetFifoThreshold(1);
	g_flashQspi.Enable();
	g_leds[3] = 1;

	//break point in case of issues
	g_logTimer.Sleep(5000);

	g_flashQspi.Discover();

	//fail to detect flash if size is implausibly small
	if(g_flashQspi.GetFlashSize() < 4096 )
	{
		g_log(Logger::ERROR, "Failed to detect SPI flash\n");
		while(1)
		{}
	}

	g_flashQspi.MemoryMap();
}

void InitFMC()
{
	g_log("Initializing FMC...\n");
	LogIndenter li(g_log);

	static GPIOPin fmc_ad0(&GPIOD, 14, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad1(&GPIOD, 15, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad2(&GPIOD, 0, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad3(&GPIOD, 1, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad4(&GPIOE, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad5(&GPIOE, 8, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad6(&GPIOE, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad7(&GPIOE, 10, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad8(&GPIOE, 11, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad9(&GPIOE, 12, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad10(&GPIOE, 13, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad11(&GPIOE, 14, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad12(&GPIOE, 15, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad13(&GPIOD, 8, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad14(&GPIOD, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ad15(&GPIOD, 10, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);

	static GPIOPin fmc_a16(&GPIOD, 11, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a17(&GPIOD, 12, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a18(&GPIOD, 13, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a19(&GPIOE, 3, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a20(&GPIOE, 4, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a21(&GPIOE, 5, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_a22(&GPIOE, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	//no A23...25 pinned out on this board
	//static GPIOPin fmc_a23(&GPIOE, 2, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, FIXME);
	//static GPIOPin fmc_a24(&GPIOG, 13, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, FIXME);
	//static GPIOPin fmc_a25(&GPIOG, 14, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, FIXME);

	static GPIOPin fmc_nl_nadv(&GPIOB, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_nwait(&GPIOD, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_ne1(&GPIOD, 7, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	//static GPIOPin fmc_ne3(&GPIOG, 6, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, FIXME);

	static GPIOPin fmc_clk(&GPIOD, 3, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_noe(&GPIOD, 4, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_nwe(&GPIOD, 5, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_nbl0(&GPIOE, 0, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);
	static GPIOPin fmc_nbl1(&GPIOE, 1, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_VERYFAST, 12);

	//Add a pullup on NWAIT
	fmc_nwait.SetPullMode(GPIOPin::PULL_UP);

	InitFMCForFPGA();

	//Wait a little while for FPGA PLL to lock etc before we start talking to it
	g_logTimer.Sleep(500);
}

void InitI2C()
{
	g_log("Initializing I2C interfaces\n");
	static GPIOPin mac_i2c_scl(&GPIOB, 8, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
	static GPIOPin mac_i2c_sda(&GPIOB, 9, GPIOPin::MODE_PERIPHERAL, GPIOPin::SLEW_SLOW, 4, true);
}

void InitFPGAFlash()
{
	g_log("Initializing FPGA flash\n");
	LogIndenter li(g_log);

	static APB_SpiFlashInterface flash(&FSPI1, 2);	//62.5 MHz PCLK / 2 = 31.25 MHz SCK
													//(even dividers required)
	g_fpgaFlash = &flash;
}
*/
