//
//  PreviewController.h
//  PhotoSender
//
//  Created by Luca Severini on 4/24/15.
//  Copyright (c) 2015 Luca Severini. All rights reserved.
//

#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>

int picToPrint(const char *outFile, const unsigned char *data)
{
	static unsigned int density[] = {255, 217, 199, 191, 181, 171, 161, 153, 148, 140, 120, 112, 102, 92, 84, 54, 38, 28, 18, 8, 0};
	
	// 21 occurnaces of a 9 character string
	char darkTbl[21][9] = { "        ","-       ","=       ","+       ",")       ","I       ",
							"Z       ","X       ","A       ","M       ","O-      ","O=      ",
							"O+      ","O+*     ","O+*.    ","O+*.-   ","O+*.=   ","OX*.HC  ",
							"OX*.HB  ","OX*.HBV ","OX*.HBVA" };
	int			 dataIdx = 0;
	int			 kline = 0;
	int			 jcol = 0;
	int			 denIndex = 0;
	int			 row = 0;
	unsigned int inTable[133] = {0};
	char		 outTable[256] = {0};
	FILE		 *out = NULL;
	unsigned int low = 999;
	unsigned int high = 0;

	out = fopen(outFile, "w");
	if(out == NULL)
	{
		printf("Error opening output file %s\n", outFile);
		return errno;
	}
	
	for(kline = 0; kline < 83; kline++)			// 83 lines for the whole picture (was 87)
	{
		for(jcol = 0; jcol < 131; jcol++)
		{
			inTable[jcol] = data[dataIdx++];	// pick up a light value 255 = bright
			
			if(inTable[jcol] < low )
			{
				low  = inTable[jcol];
			}
			
			if(inTable[jcol] > high)
			{
				high = inTable[jcol];
			}
			
			for(denIndex = 0; denIndex < 21; denIndex++)	// find the right density key from density table
			{
				if(density[denIndex] <= inTable[jcol])
				{
					inTable[jcol] = denIndex;
					break;
				}
			}
		}
		
		for(row = 0; row < 8; row++)
		{
			for(jcol = 0; jcol < 131; jcol++)
			{
				outTable[jcol] = darkTbl[inTable[jcol]][row];
			}
			
			// load characters into row [1-5] column[1-132] and
			// from darktable row [1-21] column [1-8]
			
			outTable[0] = 'S';					// overprint
#pragma message "Verify if '&& kline < 86' in line below is correct to avoid printing the last row of image together with the last row with file info"
			if(row == 7 && kline < 82)
			{
				outTable[0] = ' ';				// no over print on this line
			}
			outTable[132] = '\0';
			
			fprintf(out, "%s\r\n", outTable);	// write the output file
			// printf("%s\n", outTable);
		}
	}
	
	time_t rawtime;
	time(&rawtime);
	struct tm *timeinfo;
	timeinfo = localtime(&rawtime);
	
	char tmpbufT[128];
	strftime(tmpbufT, sizeof(tmpbufT), "%I:%M%p",  timeinfo);
	
	char tmpbufD[128];
	strftime(tmpbufD, sizeof(tmpbufD), "%A, %b %d %Y",  timeinfo);
	
	const char *fileName = strrchr(outFile, '/');
	if(fileName != NULL)
	{
		fileName++;
	}
	else
	{
		fileName = outFile;
	}
	
	// Next line must have some spaces in front to avoid the floowing newline to be cleared away
	sprintf(outTable, "          \r\n Processing date: %s %s  File: %s", tmpbufD, tmpbufT, fileName);
	for(int idx = (int)strlen(outTable); idx < 132; idx++)
	{
		outTable[idx] = ' ';
	}
	outTable[132] = '\0';
	
	fprintf(out, "%s", outTable);		// write the output file
	// printf("%s\n", outTable);
	
	fclose(out);
	
	// printf("Lowest value = %d\nHigest value = %d\n", low, high);
	
	return 0;
}

