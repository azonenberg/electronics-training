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
#include "ButtonTask.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

ButtonTask::ButtonTask()
	: TimerTask(0, 10 * 10)	//100 Hz update rate
	, m_buttonDown{0}
	, m_leftButton(&GPIOJ, 7, GPIOPin::MODE_INPUT, 0, false)
	, m_rightButton(&GPIOJ, 11, GPIOPin::MODE_INPUT, 0, false)
	, m_upButton(&GPIOJ, 6, GPIOPin::MODE_INPUT, 0, false)
	, m_downButton(&GPIOJ, 10, GPIOPin::MODE_INPUT, 0, false)
	, m_enterButton(&GPIOJ, 9, GPIOPin::MODE_INPUT, 0, false)
{
	m_buttons[BUTTON_LEFT] = &m_leftButton;
	m_buttons[BUTTON_RIGHT] = &m_rightButton;
	m_buttons[BUTTON_UP] = &m_upButton;
	m_buttons[BUTTON_DOWN] = &m_downButton;
	m_buttons[BUTTON_ENTER] = &m_enterButton;

	for(auto& b : m_buttons)
		b->SetPullMode(GPIOPin::PULL_DOWN);

	//Give the pulldowns time to do their thing before we read button state for the first time
	g_logTimer.Sleep(25 * 10);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void ButtonTask::OnTimer()
{
	//Get current button state
	bool down[5];
	for(size_t i=0; i<5; i++)
		down[i] = *m_buttons[i];

	//Check for events and pass them up to the menu system
	bool hit = false;
	if(down[BUTTON_LEFT] && !m_buttonDown[BUTTON_LEFT])
	{
		g_menu.OnLeft();
		hit = true;
	}
	if(down[BUTTON_RIGHT] && !m_buttonDown[BUTTON_RIGHT])
	{
		g_menu.OnRight();
		hit = true;
	}
	if(down[BUTTON_UP] && !m_buttonDown[BUTTON_UP])
	{
		g_menu.OnUp();
		hit = true;
	}
	if(down[BUTTON_DOWN] && !m_buttonDown[BUTTON_DOWN])
	{
		g_menu.OnDown();
		hit = true;
	}
	if(down[BUTTON_ENTER] && !m_buttonDown[BUTTON_ENTER])
	{
		g_menu.OnEnter();
		hit = true;
	}

	//Ugly debounce delay but we can afford the time
	if(hit)
		g_logTimer.Sleep(5);

	//If a button was pressed, trigger a re-render of the display
	if(hit)
		g_menu.Render();

	//Save state
	for(size_t i=0; i<5; i++)
		m_buttonDown[i] = down[i];
}
