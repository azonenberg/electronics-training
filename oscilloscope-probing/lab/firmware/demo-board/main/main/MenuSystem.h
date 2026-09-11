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

#ifndef MenuSystem_h
#define MenuSystem_h

#include "MenuPageHandler.h"

/**
	@brief Data for a single menu page
 */
struct MenuPageData
{
	const char* m_name;
	MenuPageHandler* m_handler;
};

//TODO: Refactor this to something we can use on other projects
class MenuSystem
{
public:
	MenuSystem();

	void DeferredInit();
	void Render();

	void OnLeft();
	void OnRight();
	void OnUp();
	void OnDown();
	void OnEnter();

	void Printf(const char* format, ...)
	{
		__builtin_va_list list;
		__builtin_va_start(list, format);
		Printf(format, list);
		__builtin_va_end(list);
	}

	void Printf(const char* format, __builtin_va_list list);

	void MoveTo(uint16_t x, uint16_t y)
	{
		m_textStartX = x;
		m_textStartY = y;

		m_textPosX = x;
		m_textPosY = y;
	}

	bool IsInSettingsMode()
	{ return m_selMode == MODE_SETTING; }

protected:
	uint8_t m_menuRowIdx;
	MenuPageData* m_currentMenuPage;

	bool m_nextRefreshIsFull;

	enum SelectionMode
	{
		MODE_MENU_PAGE,
		MODE_SETTING
	} m_selMode;

protected:

	uint16_t m_textWidth;
	uint16_t m_textHeight;
	uint16_t m_textRowPitch;

	//GUI state
	uint16_t m_textStartX;
	uint16_t m_textStartY;

	uint16_t m_textPosX;
	uint16_t m_textPosY;

	//GUI working buffer (big enough to hold a full line of text)
	char m_textBufferStorage[38];
	StringBuffer m_textBuffer;
};

#endif
