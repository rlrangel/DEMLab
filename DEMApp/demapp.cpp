/*
** --------------------------------------------------------------------------
**
** DEMApp - Discrete Element Method Application
**
** Author:
** Rafael Lopez Rangel (rrangel@cimne.upc.edu)
**
** International Center for Numerical Methods in Engineering (CIMNE)
** Polytechnique University of Catalonia (UPC BarcelonaTech)
**
** --------------------------------------------------------------------------
*/

// Includes and definitions
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

using namespace std;

// Local functions
static char inputFile[80];
void getInputFile(void);

// ================================== getInputFile ==================================
void getInputFile(void)
{
  char arqaux[80];

  printf("\n\n");
  printf("\t --------------------------------------------   \n");
  printf("\t DEMApp - Discrete Element Method Application   \n");
  printf("\t -------------------------------------------- \n\n");
  printf("Enter input file name: ");

  //gets(arqaux);

  //strcpy(inputFile, arqaux);
}

// ================================== main ==================================

int main(int argc, char* argv[])
{
  int status;

  // Get input file
  if (argc == 1)
  {
    getInputFile();
  }
  else
  {
    strcpy(inputFile, argv[1]);
  }

  return 0;
}
