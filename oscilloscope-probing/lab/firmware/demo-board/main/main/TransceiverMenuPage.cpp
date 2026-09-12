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
	m_gtp0MuxSel 	= GTPMode::PRBS7;
	m_gtp1MuxSel 	= GTPMode::PRBS7;

	m_lane0Rate		= GTPRate::RATE_5GBPS;
	m_lane1Rate		= GTPRate::RATE_5GBPS;

	m_txPreCursor	= 0;
	m_txPostCursor	= 3;
	m_txSwing		= GTPSwing::SWING_561MV;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void TransceiverMenuPage::Render()
{
	//TODO: actually make these do stuff
	RenderSelector("GTP0  data", 0, m_gtp0MuxSel, g_gtpmodeNames, 6);
	RenderSelector("      rate", 1, m_lane0Rate, g_gtprateNames, 10);

	RenderSelector("GTP1  data", 2, m_gtp1MuxSel, g_gtpmodeNames, 6);
	RenderSelector("      rate", 3, m_lane1Rate, g_gtprateNames, 10);

	RenderSpinner("Precursor ", 4, m_txPreCursor, 2);
	RenderSpinner("Postcursor", 5, m_txPostCursor, 2);

	RenderSelector("Swing (mv)", 6, m_txSwing, g_gtpswingNames, 4);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void TransceiverMenuPage::OnUp()
{
	if(m_activeRow > 0)
		m_activeRow --;
	else
		m_activeRow = 6;
}

void TransceiverMenuPage::OnDown()
{
	if(m_activeRow < 7)
		m_activeRow ++;
	else
		m_activeRow = 0;
}

void TransceiverMenuPage::OnLeft()
{
	switch(m_activeRow)
	{
		case 0:
			EnumLeft(m_gtp0MuxSel, GTPMode::Count);
			break;

		case 1:
			EnumRight(m_lane0Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 2:
			EnumLeft(m_gtp1MuxSel, GTPMode::Count);
			break;

		case 3:
			EnumRight(m_lane1Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 4:
			if(m_txPreCursor > 0)
				m_txPreCursor --;
			break;

		case 5:
			if(m_txPostCursor > 0)
				m_txPostCursor --;
			break;

		case 6:
			EnumLeft(m_txSwing, GTPSwing::Count);
			break;

	}

	UpdateFPGA();
}

void TransceiverMenuPage::OnRight()
{
	switch(m_activeRow)
	{
		case 0:
			EnumRight(m_gtp0MuxSel, GTPMode::Count);
			break;

		case 1:
			EnumLeft(m_lane0Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 2:
			EnumRight(m_gtp1MuxSel, GTPMode::Count);
			break;

		case 3:
			EnumLeft(m_lane1Rate, GTPRate::RATE_Count);	//reverse order
			break;

		case 4:
			if(m_txPreCursor < 31)
				m_txPreCursor ++;
			break;

		case 5:
			if(m_txPostCursor < 31)
				m_txPostCursor ++;
			break;

		case 6:
			EnumRight(m_txSwing, GTPSwing::Count);
			break;

	}

	UpdateFPGA();
}

void TransceiverMenuPage::UpdateFPGA()
{
	uint32_t drivercfg = (static_cast<int>(m_txSwing) << 16) | (m_txPreCursor << 8) | (m_txPostCursor);
	FGTPGEN.LANE0_DRIVER = drivercfg;
	FGTPGEN.LANE1_DRIVER = drivercfg;

	FGTPGEN.LANE0_RATE = static_cast<uint32_t>(m_lane0Rate) + 1;
	FGTPGEN.LANE1_RATE = static_cast<uint32_t>(m_lane1Rate) + 1;

	//TODO: pattern config
}
