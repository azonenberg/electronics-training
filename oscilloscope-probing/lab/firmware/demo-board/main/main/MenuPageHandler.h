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

#ifndef MenuPageHandler_h
#define MenuPageHandler_h

class MenuSystem;

/**
	@brief Base class for menu event handlers
 */
class MenuPageHandler
{
public:
	MenuPageHandler(MenuSystem* parent)
		: m_parent(parent)
		, m_activeRow(0)
	{}

	virtual void DeferredInit()
	{}

	virtual void Render()
	{}

	virtual void OnLeft()
	{}

	virtual void OnRight()
	{}

	virtual void OnUp()
	{}

	virtual void OnDown()
	{}

	virtual void OnEnter()
	{}

protected:

	void RenderSpinner(
		const char* name,
		uint16_t row,
		uint32_t sel,
		int numwidth)
	{
		bool active = IsRowActive(row);
		Printf("%s: %c ", name, active ? '<' : ' ');

		char format[16];
		StringBuffer s(format, sizeof(format));
		s.Printf("%%%dd %c\n", numwidth, active ? '>' : ' ');

		Printf(format, sel);
	}

	template<class T>
	void RenderSelector(
		const char* name,
		uint16_t row,
		T sel,
		const char* names[],
		int namewidth)
	{
		bool active = IsRowActive(row);
		Printf("%s: %c ", name, active ? '<' : ' ');

		char format[16];
		StringBuffer s(format, sizeof(format));
		s.Printf("%%%ds %c\n", namewidth, active ? '>' : ' ');

		Printf(format, names[static_cast<uint32_t>(sel)]);
	}

	template<class T>
	void EnumLeft(T& sel, T maxval)
	{
		if(static_cast<uint32_t>(sel) > 0)
			sel = static_cast<T>(static_cast<uint32_t>(sel) - 1);
		else
			sel = static_cast<T>(static_cast<uint32_t>(maxval) - 1);
	}

	template<class T>
	void EnumRight(T& sel, T maxval)
	{
		if(static_cast<uint32_t>(sel) < (static_cast<uint32_t>(maxval) - 1))
			sel = static_cast<T>(static_cast<uint32_t>(sel) + 1);
		else
			sel = static_cast<T>(0);
	}

	bool IsRowActive(uint32_t row);

	void Printf(const char* format, ...);

	MenuSystem* m_parent;

	uint32_t m_activeRow;
};

#endif
