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
#include "AboutMenuPage.h"
#include "RGBMenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Menu pages

//Forward declarations so they can go in the initialized vector
extern MenuPageData g_aboutPage;
extern MenuPageData g_clipPage;
extern MenuPageData g_dacPage;
extern MenuPageData g_rgbPage;
extern MenuPageData g_pmodPage;
extern MenuPageData g_smaPage;
extern MenuPageData g_transceiverPage;

etl::vector g_topLevelSidebar =
{
	&g_aboutPage,
	&g_clipPage,
	&g_dacPage,
	&g_pmodPage,
	&g_rgbPage,
	&g_smaPage,
	&g_transceiverPage
};

AboutMenuPage g_aboutHandler(&g_menu);
RGBMenuPage g_rgbHandler(&g_menu);

MenuPageData g_aboutPage		= { "About",	&g_topLevelSidebar, &g_aboutPage,	&g_clipPage,		&g_aboutHandler};
MenuPageData g_clipPage			= { "Clip",		&g_topLevelSidebar, &g_aboutPage,	&g_dacPage,			nullptr};
MenuPageData g_dacPage			= { "DAC",		&g_topLevelSidebar, &g_clipPage,	&g_pmodPage,		nullptr};
MenuPageData g_pmodPage			= { "PMOD",		&g_topLevelSidebar, &g_dacPage,		&g_rgbPage,			nullptr};
MenuPageData g_rgbPage			= { "RGB LED",	&g_topLevelSidebar, &g_pmodPage,	&g_smaPage,			&g_rgbHandler};
MenuPageData g_smaPage			= { "SMA out",	&g_topLevelSidebar, &g_rgbPage,		&g_transceiverPage,	nullptr};
MenuPageData g_transceiverPage	= { "Xcvrs",	&g_topLevelSidebar, &g_smaPage,		&g_transceiverPage,	nullptr};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

MenuSystem::MenuSystem()
	: m_currentMenuPage(&g_aboutPage)
	, m_nextRefreshIsFull(true)
	, m_selMode(MODE_MENU_PAGE)
	, m_textWidth(6)
	, m_textHeight(8)
	, m_textRowPitch(10)
	, m_textStartX(0)
	, m_textStartY(0)
	, m_textBuffer(m_textBufferStorage, sizeof(m_textBufferStorage))
{

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void MenuSystem::Render()
{
	//Clear the display
	g_display->Clear();

	//Constants for text layout
	const int16_t menuLeftPos			= 0;
	const int16_t menuLeftMargin		= 1;
	const int16_t menuRightMargin		= 1;
	const int16_t menuTopMargin			= 0;
	const int16_t pageTextWidth			= 6;
	const int16_t pageTextHeight		= 8;
	const int16_t pageHighlightMargin	= 1;
	const int16_t pageRowPitch			= pageTextHeight + 2*pageHighlightMargin;
	const int16_t pageListWidthChars	= 7;
	const int16_t pageListWidth			= pageListWidthChars * pageTextWidth + menuLeftMargin + menuRightMargin;

	//Draw background for the left side menu page list
	g_display->FilledRect(0, 0, pageListWidth - 1, g_display->GetHeight() - 1, true);

	//Draw the list of pages
	//Origin is bottom left and we want to be top-down so start at top of the display
	int16_t y = g_display->GetHeight() - (1 + pageRowPitch + menuTopMargin);
	for(auto ppage : *m_currentMenuPage->m_sidebar)
	{
		//Draw the name, highlight if active
		if(ppage == m_currentMenuPage)
		{
			//white background
			g_display->FilledRect(
				menuLeftPos,
				y - pageHighlightMargin,
				menuLeftPos + pageListWidth,
				y + pageTextHeight + pageHighlightMargin,
				false);

			g_display->Text6x8(menuLeftPos + menuLeftMargin, y - pageHighlightMargin, ppage->m_name, true);
		}

		//Inactive, white text on black
		else
			g_display->Text6x8(menuLeftPos + menuLeftMargin, y - pageHighlightMargin, ppage->m_name, false);

		y -= pageRowPitch;
	}

	//Draw the actual page
	MoveTo(
		pageListWidth + menuRightMargin,
		g_display->GetHeight() - (1 + m_textRowPitch));

	if(m_currentMenuPage->m_handler)
		m_currentMenuPage->m_handler->Render();

	//Kick off the refresh
	g_display->StartRefresh(m_nextRefreshIsFull);
	m_nextRefreshIsFull = false;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Text rendering helpers

void MenuSystem::Printf(const char* format, __builtin_va_list list)
{
	m_textBuffer.Clear();
	m_textBuffer.Printf(format, list);

	//Draw it
	g_display->Text6x8(m_textPosX, m_textPosY, m_textBufferStorage, true);

	//Calculate cursor movement
	for(size_t i=0; i<sizeof(m_textBufferStorage); i++)
	{
		if(m_textBufferStorage[i] == '\n')
		{
			m_textPosY -= m_textRowPitch;
			m_textPosX = m_textStartX;
		}
		else if(m_textBufferStorage[i] == '\0')
			break;
		else
			m_textPosX += m_textWidth;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void MenuSystem::OnLeft()
{
	//menu mode
	if(m_selMode == MODE_MENU_PAGE)
	{}

	//settings mode
	else if(m_currentMenuPage->m_handler)
		m_currentMenuPage->m_handler->OnLeft();
}

void MenuSystem::OnRight()
{
	//menu mode
	if(m_selMode == MODE_MENU_PAGE)
	{}

	//settings mode
	else if(m_currentMenuPage->m_handler)
		m_currentMenuPage->m_handler->OnRight();
}

void MenuSystem::OnUp()
{
	//menu mode
	if(m_selMode == MODE_MENU_PAGE)
		m_currentMenuPage = m_currentMenuPage->m_upPage;

	//settings mode
	else if(m_currentMenuPage->m_handler)
		m_currentMenuPage->m_handler->OnUp();
}

void MenuSystem::OnDown()
{
	if(m_selMode == MODE_MENU_PAGE)
		m_currentMenuPage = m_currentMenuPage->m_downPage;

	//settings mode
	else if(m_currentMenuPage->m_handler)
		m_currentMenuPage->m_handler->OnDown();
}

void MenuSystem::OnEnter()
{
	if(m_selMode == MODE_MENU_PAGE)
		m_selMode = MODE_SETTING;
	else
		m_selMode = MODE_MENU_PAGE;
}
