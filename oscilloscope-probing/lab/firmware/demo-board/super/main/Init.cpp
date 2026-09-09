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

#include "supervisor.h"
#include "LEDTask.h"
#include "ButtonTask.h"
#include "SensorTask.h"
#include <math.h>
#include <peripheral/DWT.h>
#include "ITMTask.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail descriptors

GPIOPin g_1v0_en(&GPIOC, 13, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndADC g_1v0("1V0", g_1v0_en, 6, 0.925, 1.05, 1.0, g_logTimer, 50);

GPIOPin g_1v2_en(&GPIOC, 15, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndADC g_1v2("1V2", g_1v2_en, 8, 1.15, 1.25, 1.0, g_logTimer, 50);

GPIOPin g_1v8_en(&GPIOH, 0, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndADC g_1v8("1V8", g_1v8_en, 7, 1.7, 1.85, 1.0, g_logTimer, 50);

GPIOPin g_3v3_en(&GPIOC, 14, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
RailDescriptorWithEnableAndADC g_3v3("3V3", g_3v3_en, 9, 3.15, 3.35, 1.0, g_logTimer, 50);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Power rail sequence

etl::vector g_powerSequence
{
	//VCCINT - VCCAUX - VCCO for the FPGA
	(RailDescriptor*)&g_1v0,
	&g_1v8,
	&g_3v3,

	//1V2 Vtt rail for the GTP comes last
	&g_1v2
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Reset descriptors

//Active low edge triggered reset
GPIOPin g_fpgaResetN(&GPIOB, 5, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);
ActiveLowResetDescriptor g_fpgaResetDescriptor(g_fpgaResetN, "FPGA PROG");

//Active low level triggered delay-boot flag
//Use this as the "FPGA is done booting" indicator
//Note: DONE pin here is active *low* due to inverting level shifter on the board
GPIOPin g_fpgaInitN(&GPIOA, 11, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0, true);
GPIOPin g_fpgaDone(&GPIOB, 9, GPIOPin::MODE_INPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptorWithActiveHighDone g_fpgaInitDescriptor(g_fpgaInitN, g_fpgaDone, "FPGA INIT");

//MCU reset comes at the end
GPIOPin g_mcuResetN(&GPIOA, 8, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW);
ActiveLowResetDescriptor g_mcuResetDescriptor(g_mcuResetN, "MCU");

//TODO mcu has software done line on PB8

etl::vector g_resetSequence
{
	//First boot the FPGA
	(ResetDescriptorBase*)&g_fpgaResetDescriptor,	//need to cast at least one entry to base class
												//for proper template deduction
	&g_fpgaInitDescriptor,

	//then release the MCU
	&g_mcuResetDescriptor,
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Other GPIOS

GPIOPin g_mainBoot0(&GPIOA, 12, GPIOPin::MODE_OUTPUT, GPIOPin::SLEW_SLOW, 0);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Task tables

etl::vector<Task*, MAX_TASKS>  g_tasks;
etl::vector<TimerTask*, MAX_TIMER_TASKS>  g_timerTasks;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The top level supervisor controller

DemoPowerResetSupervisor g_super(g_powerSequence, g_resetSequence);

void DemoPowerResetSupervisor::PrintRailVoltages()
{
	g_log("Last measured rail voltages:\n");

	LogIndenter li(g_log);

	g_log("3V3: %d mV\n", static_cast<int>(g_3v3.PeekVoltage() * 1000));
	g_log("1V8: %d mV\n", static_cast<int>(g_1v8.PeekVoltage() * 1000));
	g_log("1V2: %d mV\n", static_cast<int>(g_1v2.PeekVoltage() * 1000));
	g_log("1V0: %d mV\n", static_cast<int>(g_1v0.PeekVoltage() * 1000));
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Peripheral initialization

void App_Init()
{
	RCCHelper::Enable(&_RTC);

	//Format version string
	StringBuffer buf(g_version, sizeof(g_version));
	static const char* buildtime = __TIME__;
	buf.Printf("%s %c%c%c%c%c%c",
		__DATE__, buildtime[0], buildtime[1], buildtime[3], buildtime[4], buildtime[6], buildtime[7]);
	g_log("Firmware version %s\n", g_version);

	//Start tracing
	#ifdef _DEBUG
		ITM::Enable();
		DWT::EnablePCSampling(DWT::PC_SAMPLE_SLOW);
		ITM::EnableDwtForwarding();
	#endif

	static LEDTask ledTask;
	static ButtonTask buttonTask;
	static SensorTask sensorTask;
	#ifdef _DEBUG
		static ITMTask itmTask;
	#endif

	g_tasks.push_back(&ledTask);
	g_tasks.push_back(&buttonTask);
	g_tasks.push_back(&g_super);
	g_tasks.push_back(&sensorTask);
	#ifdef _DEBUG
		g_tasks.push_back(&itmTask);
	#endif

	g_timerTasks.push_back(&ledTask);
	#ifdef _DEBUG
		g_timerTasks.push_back(&itmTask);
	#endif

	//Pull BOOT0 on main MCU low
	g_mainBoot0 = 0;

	//Log parameters
	{
		g_log("Initial system health check\n");
		LogIndenter li(g_log);

		g_log("Supervisor temperature: %uhk C\n", g_adc->GetTemperature());

		auto vdd = g_adc->GetSupplyVoltage();
		g_log("3V3_SB: %d mV\n", vdd);

		//3V3_SB hasn't come up fully yet, give it time
		//The FT234 doesn't have a very high output current so decoupling caps take a while to charge,
		//and if we don't let the rails stabilize then ADC readings used by the boot process will be wrong
		const int min_vdd = 3280;
		if(vdd < min_vdd)
		{
			g_log("Waiting for 3V3_SB rail to stabilize\n");

			while(vdd < min_vdd)
			{
				LogIndenter li2(g_log);
				vdd = g_adc->GetSupplyVoltage();
				g_log("3V3_SB: %d mV\n", vdd);
				g_logTimer.Sleep(250);
			}
		}

		g_log("Power is stable\n");
	}

	//Turn on immediately, don't wait for a button press
	g_super.PowerOn();
}
