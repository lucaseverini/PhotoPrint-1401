// fred.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#include <stdio.h>
#include <time.h>
#include <conio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <process.h>
#include <io.h>
#include <sys\types.h>
#include <sys\stat.h>
unsigned int	density[21]={255,217,199,191,181,171,161,153,148,140,120,112,102,92,84,54,38,28,18,8,0};
           
// 21 occurnaces of a 9 character string
char darkTbl[21][9]={"        ","-       ","=       ","+       ",")       ","I       ",
                     "Z       ","X       ","A       ","M       ","O-      ","O=      ",
					 "O+      ","O+*     ","O+*.    ","O+*.-   ","O+*.=   ","OX*.HC  ",
					 "OX*.HB  ","OX*.HBV ","OX*.HBVA"};
int  i;
int  returnStatus;
int  kline;
int  jcol;
int  denIndex;
int  row;
int  histrogram[256]; 
char blankLine;
unsigned int  low=999;
unsigned int  high=0;
unsigned int  inTable[133];
char	outTable[133]; 
char    findFile[]="c:\\LocalLib\\OpenDiag.exe";
char	passedFileName[100]="C:\\don.tmp";
char	inFileName[200];
char	outFileName[200];

FILE 	*in, *out;
  
char heading[]="pic to print 11/10/2012\n\n";
void main()
{
  printf("\n%s\n\n",heading);
	  
	  // get the file name and path to process and place it in c:\don.tmp 
  
  i=system(findFile);	
  if(i != 0)
  {
    fprintf(stderr,"Unable to run %s\nProgram terminated\n",findFile);
    fprintf(stderr,"Press any key to exit......");
    getch();
    returnStatus+=4;
    return;
  }
   
    
  // read in the path and file name
  if ((in = fopen(passedFileName, "r")) == NULL)
  {
    fprintf(stderr, "Cannot open input file %s.\n",
    passedFileName);
    fprintf(stderr,"Press any key to exit......");
    getch();
    returnStatus+=8;
    return;
  }
  i=fread(inFileName,1,199,in); //read in the drive,path and file name left for you
  if(i < 3)
  {
    fprintf(stderr,"Error reading file %s\n",passedFileName);
    fprintf(stderr,"Press any key to exit......");
    getch();
    returnStatus+=16;
    return;
  }
  fclose(in); // close c:\don.tmp

  sprintf(outFileName,"%s",inFileName);	
  for(i=0;i<100;i++)
  {
	if(outFileName[i] == '.')
	{
		outFileName[i]=0; //null it out
	}
  }
    sprintf(outFileName,"%s.lst",outFileName);

	/* open the input file */
     
  in=fopen(inFileName,"rb");
     
  if(in==NULL)
  {
    printf("\n\n\tError opening input file %s\n",inFileName);
    exit(1);
  }
   
  
  /* open the output list file*/
  
  out=fopen(outFileName,"w");
     
  if(out==NULL)
  {
    printf("\n\n\tError opening output file %s\n",outFileName);
    exit(1);
  }   
  
  // both input and output files are open

	for(kline=0;kline<85;kline++) // 85lines for the whole picture
	{
		for(jcol=0;jcol<132;jcol++)
		{
			inTable[jcol]=fgetc(in);  //pick up a light value  255 = bright

	       
			if(inTable[jcol] == EOF) inTable[jcol]=0;  //error catcher if file short

    		if(inTable[jcol] < low ) low  = inTable[jcol];
			if(inTable[jcol] > high) high = inTable[jcol];

			for(denIndex=0;denIndex<21;denIndex++)// find the right density key from density table
			{
				if(density[denIndex]<=inTable[jcol]) // m is the index into the dark table
				{
					inTable[jcol]=denIndex;
					break;
				}
			}
		}

	  	for(row=0;row<8;row++)
	  	{
				
				for(jcol=0;jcol<131;jcol++)
				{	
					outTable[jcol]=darkTbl[inTable[jcol]][row];
				}
				
				//load characters into row [1-5] column[1-132] and 
				//from darktable row [1-21] column [1-8]
         			
                		outTable[0]='S'; // overprint
				if(row == 7)
				{
					outTable[0]=' '; // no over print on this line
				}
								
				outTable[132]=0; // line termination
				fprintf(out,"%s\n",outTable);
				
		}
	}
    char tmpbufT[128];
    char tmpbufD[128];
    _tzset();
    _strtime( tmpbufT );
    
    _strdate( tmpbufD );
    for(i=0;i<132;outTable[i++]=' ');

	sprintf(outTable,"Processing date = %s, Time = %s File = %s\n",tmpbufD,tmpbufT,inFileName);
    for(i=0;i<132;i++)
	{
		if(outTable[i]<32)
		{
			outTable[i]=' ';
		}
	}
	
	outTable[132]=0; // line termination
    fprintf(out,"%s\n",outTable);

  fclose(in);
  fclose(out);
    
  printf("\n\n\tThe output analysis of %s \n\tis in %s\n",inFileName,outFileName);
    
  printf("\nlowest value = %d\nhigest value = %d\n",low,high);
  fprintf(stderr,"\nPress any key to exit......");
    getch();
}

