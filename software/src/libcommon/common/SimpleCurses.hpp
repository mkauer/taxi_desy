/*
 * SimpleCurses.hpp
 *
 *  Created on: Jul 12, 2016
 *      Author: marekp
 */

#ifndef HESS1U_SIMPLECURSES_HPP_
#define HESS1U_SIMPLECURSES_HPP_

#include <stdio.h>
#include <vector>

namespace sc {

void clear()
{
	printf("\e[2J");
}

enum {
	black 	= 0,
	red 	= 1,
	green 	= 2,
	yellow 	= 3,
	blue 	= 4,
	magenta = 5,
	cyan 	= 6,
	white 	= 7,
	normal	= 9
};

void movexy(int x, int y)
{
	printf("\e[%d;%dH", y,x);
}

void setFg(int fg, bool bold=false)
{
	if (bold) printf("\e[1m"); else printf("\e[0m");
	printf("\e[%dm", 30+fg);

}

void done()
{
	printf("\e[100B");
	printf("\e[400D");
	setFg(normal);
}

class Table
{
	int m_x;
	int m_y;
	int m_row;
	int m_col;
	std::vector<int> m_columnWidths;
public:
	Table(int _x, int _y)
	: m_x(_x), m_y(_y)
	{
		m_row=-1;
		m_col=0;
	}
	void addColumn(int _w)
	{
		m_columnWidths.push_back(_w);
	}
	void nextRow()
	{
		m_row++;
		m_col=0;
		movexy(m_x,m_y+m_row);
	}
	void nextColumn()
	{
		m_col++;
		int x=0;
		int colwidth=10;
		for (int i=0;i<m_col;i++) {
			if (i<m_columnWidths.size()) colwidth=m_columnWidths[i]; else colwidth=10;
			x+=colwidth;
		}
		movexy(m_x+x,m_y+m_row);
		std::string s(colwidth,' ');
		printf(s.c_str());
		movexy(m_x+x,m_y+m_row);


	}
};

} // namespace sc


#endif /* SIMPLECURSES_HPP_ */
