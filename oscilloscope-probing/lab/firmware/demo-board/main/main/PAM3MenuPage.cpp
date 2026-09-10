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
#include "PAM3MenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void PAM3MenuPage::Render()
{
	const char* names[] =
	{
		"100BASE-TX",
		"100BASE-T1"
	};

	bool active = IsRowActive(0);
	Printf("Pattern:  %c %10s %c\n",
		active ? '<' : ' ',
		names[m_mode],
		active ? '>' : ' ');

	if(m_mode == MODE_100BASET1)
	{
		Printf("Mod    :    PAM-3\n");
		Printf("Rate   :     66.6 Mbaud\n");
	}

	if(m_mode == MODE_100BASETX)
	{
		Printf("Mod    :    MLT-3\n");
		Printf("Rate   :    125.0 Mbaud\n");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void PAM3MenuPage::OnLeft()
{
	if(m_mode == MODE_100BASET1)
		m_mode = MODE_100BASETX;
	else
		m_mode = MODE_100BASET1;
}

void PAM3MenuPage::OnRight()
{
	if(m_mode == MODE_100BASET1)
		m_mode = MODE_100BASETX;
	else
		m_mode = MODE_100BASET1;
}
