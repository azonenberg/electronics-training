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
#include "MenuSystem.h"
#include "TransceiverMenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

TransceiverMenuPage::TransceiverMenuPage(MenuSystem* parent)
	: MenuPageHandler(parent)
{
	m_lane0MuxSel 	= GTPMode::PRBS7;
	m_lane1MuxSel 	= GTPMode::PRBS7;

	m_lane0Rate		= GTPRate::RATE_5GBPS;
	m_lane1Rate		= GTPRate::RATE_5GBPS;

	m_lane0PreCursor	= 0;
	m_lane1PreCursor	= 0;

	m_lane0PostCursor	= 3;
	m_lane1PostCursor	= 3;

	m_lane0Swing		= GTPSwing::SWING_561MV;
	m_lane1Swing		= GTPSwing::SWING_561MV;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void TransceiverMenuPage::Render()
{
	RenderSelector("GTP0  data", 0, m_lane0MuxSel, g_gtpmodeNames, 9);
	RenderSelector("      rate", 1, m_lane0Rate, g_gtprateNames, 10);
	RenderSpinner(" Precursor", 2, m_lane0PreCursor, 2);
	RenderSpinner("Postcursor", 3, m_lane0PostCursor, 2);
	RenderSelector("Swing (mv)", 4, m_lane0Swing, g_gtpswingNames, 4);

	//Divider
	int16_t y = g_display->GetHeight() - 1 - (10 * 5);
	g_display->Line(0, y, g_display->GetWidth(), y, true);

	RenderSelector("GTP1  data", 5, m_lane1MuxSel, g_gtpmodeNames, 9);
	RenderSelector("      rate", 6, m_lane1Rate, g_gtprateNames, 10);

	RenderSpinner(" Precursor", 7, m_lane1PreCursor, 2);
	RenderSpinner("Postcursor", 8, m_lane1PostCursor, 2);
	RenderSelector("Swing (mv)", 9, m_lane1Swing, g_gtpswingNames, 4);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void TransceiverMenuPage::OnUp()
{
	if(m_activeRow > 0)
		m_activeRow --;
	else
		m_activeRow = 9;
}

void TransceiverMenuPage::OnDown()
{
	if(m_activeRow < 10)
		m_activeRow ++;
	else
		m_activeRow = 0;
}

void TransceiverMenuPage::OnLeft()
{
	switch(m_activeRow)
	{
		case 0:
			EnumLeft(m_lane0MuxSel, GTPMode::Count);
			break;

		case 1:
			EnumRight(m_lane0Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 2:
			if(m_lane0PreCursor > 0)
				m_lane0PreCursor --;
			break;

		case 3:
			if(m_lane0PostCursor > 0)
				m_lane0PostCursor --;
			break;

		case 4:
			EnumLeft(m_lane0Swing, GTPSwing::Count);
			break;

		case 5:
			EnumLeft(m_lane1MuxSel, GTPMode::Count);
			break;

		case 6:
			EnumRight(m_lane1Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 7:
			if(m_lane1PreCursor > 0)
				m_lane1PreCursor --;
			break;

		case 8:
			if(m_lane1PostCursor > 0)
				m_lane1PostCursor --;
			break;

		case 9:
			EnumLeft(m_lane1Swing, GTPSwing::Count);
			break;

	}

	UpdateFPGA();
}

void TransceiverMenuPage::OnRight()
{
	switch(m_activeRow)
	{
		case 0:
			EnumRight(m_lane0MuxSel, GTPMode::Count);
			break;

		case 1:
			EnumLeft(m_lane0Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 2:
			if(m_lane0PreCursor < 31)
				m_lane0PreCursor ++;
			break;

		case 3:
			if(m_lane0PostCursor < 31)
				m_lane0PostCursor ++;
			break;

		case 4:
			EnumRight(m_lane0Swing, GTPSwing::Count);
			break;

		case 5:
			EnumRight(m_lane1MuxSel, GTPMode::Count);
			break;

		case 6:
			EnumLeft(m_lane1Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 7:
			if(m_lane1PreCursor < 31)
				m_lane1PreCursor ++;
			break;

		case 8:
			if(m_lane1PostCursor < 31)
				m_lane1PostCursor ++;
			break;

		case 9:
			EnumRight(m_lane1Swing, GTPSwing::Count);
			break;

	}

	UpdateFPGA();
}

void TransceiverMenuPage::UpdateFPGA()
{
	FGTPGEN.LANE0_DRIVER = (static_cast<uint32_t>(m_lane0Swing) << 16) | (m_lane0PreCursor << 8) | (m_lane0PostCursor);
	FGTPGEN.LANE1_DRIVER = (static_cast<uint32_t>(m_lane1Swing) << 16) | (m_lane1PreCursor << 8) | (m_lane1PostCursor);

	FGTPGEN.LANE0_RATE = static_cast<uint32_t>(m_lane0Rate) + 1;
	FGTPGEN.LANE1_RATE = static_cast<uint32_t>(m_lane1Rate) + 1;

	FGTPGEN.LANE0_PATTERN = static_cast<uint32_t>(m_lane0MuxSel);
	FGTPGEN.LANE1_PATTERN = static_cast<uint32_t>(m_lane1MuxSel);
}
