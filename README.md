# PhotoPrint-1401
By Luca Severini & Stan Paddock, Computer History Museum, Mountain View 2014-2018.

A simple iPhone app to take, crop, preview, convert to IBM1401 EBCDIC (with overprint*) and send images to a PC server over the wifi network.

Not included in the package is the software to send the converted image to the IBM1401 through a custom parallel interface.

The algorithm to convert the grayscale image data to EBCDIC with overprint is in the files PicToPrint.h and PicToPrint.cpp.

(*) Overprint is a tecnique to print multiple rows without to advance the paper to the next one.
    That way is possible to get a better shading than printing one single char per row position.

Luca Severini
