#undef UNICODE

#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>
#include <direct.h>
#include <iphlpapi.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <Shlwapi.h>
#include <Shellapi.h>
#include <Shlobj.h>

#pragma comment (lib, "Ws2_32.lib")
#pragma comment (lib, "IPHLPAPI.lib")
#pragma comment (lib, "Shlwapi.lib")
#pragma comment (lib, "Shell32.lib")

#define DEFAULT_BUFLEN 1024
#define DEFAULT_PORT "25000"
#define DEFAULT_FOLDER "C:\\PicPrint1401"

#define MALLOC(x) HeapAlloc(GetProcessHeap(), 0, (x))
#define FREE(x) HeapFree(GetProcessHeap(), 0, (x))

typedef unsigned char boolean;
#define true (boolean)1
#define false (boolean)0

char destDir[256];

int manageData (char* data);
boolean fileExists (const char *fname);

int __cdecl main(int argc, char* argv[]) 
{
    WSADATA wsaData;
    int iResult;

    SOCKET udpSocket = INVALID_SOCKET;
    SOCKET listenSocket = INVALID_SOCKET;
    SOCKET clientSocket = INVALID_SOCKET;

    struct addrinfo *result = NULL;
    struct addrinfo hints;
    int iSendResult;
    char recvbuf[DEFAULT_BUFLEN];
    int recvbuflen = DEFAULT_BUFLEN;
    char sendbuf[DEFAULT_BUFLEN];
    int sendbuflen = DEFAULT_BUFLEN;
    int idx, port, addr_len, clientAddr_len;
    struct sockaddr_in *sockaddr_ipv4;
    PIP_ADAPTER_ADDRESSES pAddresses;
    PIP_ADAPTER_UNICAST_ADDRESS pUnicast;
    ULONG outBufLen;
    struct sockaddr_in *sa_in;
    struct sockaddr_in addr, clientAddr;
    char addressStr[256] = "";
    u_long longOpt;
    boolean removeFiles = false;
   
    printf("IBM 1401 Photo receiver - v. 1.0 - Jul 20 2015\n");
 
	// Set the folder to the default one on Desktop
	// SHGetFolderPath(NULL, CSIDL_DESKTOPDIRECTORY | CSIDL_FLAG_CREATE, NULL, 0, destDir);
    PathAppend(destDir, DEFAULT_FOLDER);
    
    for(idx = 1; idx < argc; idx++)
    {
		if(strcmp(argv[idx], "-f") == 0)
		{
			if(++idx < argc)
			{
				strcpy(destDir, argv[idx]);
			}
		}
		else if(strcmp(argv[idx], "-d") == 0)
		{
			removeFiles = true;
		}
		else if(strcmp(argv[idx], "-h") == 0)
		{
			printf("Usage: Receiver.exe [-f folder_path] [-d]\n");
			printf("-f folder_path to set the path to the folder containing the files to be printed.\n");
			printf("   If no folder is set with -f a folder named PrintFiles on is created and used on Desktop.\n");
			printf("-d to delete all the files in the folder before start receiving new files.\n");
			return 0;
		}
    }
 
 	printf("Files to print saved in %s\n", destDir);

	iResult = _mkdir(destDir);
	if(iResult != 0 && GetLastError() != 183)
	{
		printf("Folder %s not available\n", destDir);
		return 1;
	}

 	if(!PathIsDirectoryEmpty(destDir) && removeFiles)
	{
		int len = strlen(destDir) + 2; // required to set 2 nulls at end of argument to SHFileOperation.
		char* tmpDir = (char*)malloc(len);
		memset(tmpDir, 0, len);
		strcpy(tmpDir, destDir);

		SHFILEOPSTRUCT file_op = 
		{
			NULL,
			FO_DELETE,
			tmpDir,
			"",
			FOF_NOCONFIRMATION | FOF_NOERRORUI | FOF_SILENT,
			false,
			0,
			"" 
		};
		iResult = SHFileOperation(&file_op);
		free(tmpDir);
		
		if(iResult != 0)
		{
			printf("Folder %s can't be emptied\n", destDir);
			return 1;
		}
		
		printf("Removed old files to print\n");
	}
		       
	if(destDir[strlen(destDir) - 1] != '\\')
	{
		strcat(destDir, "\\");
	}

    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
    if (iResult != 0) 
    {
        printf("WSAStartup failed with error: %d\n", iResult);
        return 1;
    }
    
    outBufLen = 10240;
    pAddresses = (IP_ADAPTER_ADDRESSES*)MALLOC(outBufLen);
    iResult = GetAdaptersAddresses(AF_INET, GAA_FLAG_INCLUDE_PREFIX, NULL, pAddresses, &outBufLen);
    pUnicast = pAddresses->FirstUnicastAddress;
    if (pUnicast != NULL) 
    {
		for (idx = 0; pUnicast != NULL; idx++)
		{
			if (pUnicast->Address.lpSockaddr->sa_family == AF_INET)
			{
				sa_in = (struct sockaddr_in *)pUnicast->Address.lpSockaddr;
				strcpy(addressStr, inet_ntoa(sa_in->sin_addr));
			}
			else
			{
				printf("IP address non found\n");
			}
			
			pUnicast = pUnicast->Next;
		}
	}
	
	printf("Server address: %s\n", addressStr);

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_DGRAM; // SOCK_STREAM;
    hints.ai_protocol = IPPROTO_UDP; //IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;

    // Resolve the server address and port for udp
    iResult = getaddrinfo(NULL, DEFAULT_PORT, &hints, &result);
    if ( iResult != 0 ) 
    {
        printf("getaddrinfo failed with error: %d\n", iResult);
        WSACleanup();
        return 1;
    }

    // Create a udp SOCKET
    udpSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    if (udpSocket == INVALID_SOCKET) 
    {
        printf("socket failed with error: %ld\n", WSAGetLastError());
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }
       
    char opt = 1;
    if(setsockopt(udpSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) != 0)
    {
		printf("setsockopt failed with error: %ld\n", WSAGetLastError());
		closesocket(udpSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }

    opt = 1;
	if(setsockopt(udpSocket, SOL_SOCKET, SO_BROADCAST, &opt, sizeof(opt)) != 0)
	{
		printf("setsockopt failed with error: %ld\n", WSAGetLastError());
 		closesocket(udpSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
	}
	
	iResult = bind(udpSocket, result->ai_addr, (int)result->ai_addrlen);
    if (iResult == SOCKET_ERROR)
    {
        printf("bind failed with error: %d\n", WSAGetLastError());
        freeaddrinfo(result);
        closesocket(udpSocket);
        WSACleanup();
        return 1;
    }

	longOpt = 1;
	if(ioctlsocket(udpSocket, FIONBIO, &longOpt) != 0)
	{
		printf("ioctlsocket failed with error: %ld\n", WSAGetLastError());
 		closesocket(udpSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
	}

    freeaddrinfo(result);

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;

    // Resolve the server address and port for tcp
    iResult = getaddrinfo(NULL, DEFAULT_PORT, &hints, &result);
    if (iResult != 0) 
    {
        printf("getaddrinfo failed with error: %d\n", iResult);
        closesocket(listenSocket);
        WSACleanup();
        return 1;
    }

    // Create a tcp SOCKET
    listenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    if (listenSocket == INVALID_SOCKET) 
    {
        printf("socket failed with error: %ld\n", WSAGetLastError());
        closesocket(udpSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }
       
    opt = 1;
    if(setsockopt(listenSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) != 0)
    {
		printf("setsockopt failed with error: %ld\n", WSAGetLastError());
        closesocket(udpSocket);
		closesocket(listenSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }
	
	iResult = bind(listenSocket, result->ai_addr, (int)result->ai_addrlen);
    if (iResult == SOCKET_ERROR)
    {
        printf("bind failed with error: %d\n", WSAGetLastError());
        closesocket(udpSocket);
		closesocket(listenSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
    }
    
    sockaddr_ipv4 = (struct sockaddr_in*)result->ai_addr;
	port = ntohs(sockaddr_ipv4->sin_port);

    freeaddrinfo(result);

    iResult = listen(listenSocket, SOMAXCONN);
    if (iResult == SOCKET_ERROR) 
    {
        printf("listen failed with error: %d\n", WSAGetLastError());
        closesocket(udpSocket);
		closesocket(listenSocket);
        WSACleanup();
        return 1;
    }

 	longOpt = 1;
	if(ioctlsocket(listenSocket, FIONBIO, &longOpt) != 0)
	{
		printf("ioctlsocket failed with error: %ld\n", WSAGetLastError());
        closesocket(udpSocket);
		closesocket(listenSocket);
        freeaddrinfo(result);
        WSACleanup();
        return 1;
	}
	
	printf("Server waiting for UDP connection to port %d...\n\n", port);

    do 
    {
		boolean idle = true;
		
		struct sockaddr sockAddr;
		int sockAddrLen = sizeof(sockAddr);
        iResult = recvfrom(udpSocket, recvbuf, recvbuflen, 0, &sockAddr, &sockAddrLen);
        if (iResult > 0) 
        {
			idle = false;
			
            printf("UDP Received %d bytes\n", iResult);
            
            recvbuf[iResult] = '\0';
            
            if(strcmp(recvbuf, "IBM1401-Photoserver") == 0)
            {
				sprintf(sendbuf, "IBM1401-Photoserver:%s", addressStr);
			}
			else
			{
				sprintf(sendbuf, "Server received: %s", recvbuf);
			}
			
			// Echo the buffer back to the sender
			sendbuflen = strlen(sendbuf);
            iSendResult = sendto(udpSocket, sendbuf, sendbuflen, 0, &sockAddr, sockAddrLen);
            if (iSendResult == SOCKET_ERROR) 
            {
                printf("UDP sendto failed with error: %d\n", WSAGetLastError());
                closesocket(udpSocket);
                closesocket(clientSocket);
                break;
            }
            
            printf("UDP Sent %d bytes\n", iSendResult);
            
            sendbuf[iSendResult] = '\0';
        }
        else if (iResult == 0)
        {
            printf("UDP Connection closed\n");
        }
        else
        {
			if(WSAGetLastError() != WSAEWOULDBLOCK)
			{
				printf("UDP recvfrom failed with error: %d\n", WSAGetLastError());
				break;
			}
        }

		if(clientSocket == INVALID_SOCKET)
		{
			// Accept a client socket
 			clientAddr.sin_family = AF_INET;
			clientAddr_len = sizeof(clientAddr);
			clientSocket = accept(listenSocket, (struct sockaddr*)&clientAddr, &clientAddr_len);
			if (clientSocket == INVALID_SOCKET) 
			{
				if(WSAGetLastError() != WSAEWOULDBLOCK)
				{
					printf("TCP Accept failed with error: %d\n", WSAGetLastError());
				}
			}
			else
			{
				addr.sin_family = AF_INET;
				addr_len = sizeof(addr);
				iResult = getsockname (clientSocket, (struct sockaddr*)&addr, &addr_len);
				if(iResult > 0)
				{
					strcpy(addressStr, inet_ntoa(addr.sin_addr));
				}
				
				printf("TCP Client %s connected\n", inet_ntoa(clientAddr.sin_addr));
			}
		}
		
		if(clientSocket != INVALID_SOCKET)
		{
			// printf("Server waiting for data...\n");
			idle = false;

			iResult = recv(clientSocket, recvbuf, recvbuflen, 0);
			if (iResult > 0) 
			{
				printf("TCP Received %d bytes\n", iResult);
				
				recvbuf[iResult] = '\0';				
				manageData(recvbuf);          
			}
			else if (iResult == 0)
			{
				printf("TCP Connection closed\n");

				closesocket(clientSocket);
				clientSocket = INVALID_SOCKET;
						
				printf("\nServer waiting for connection to port %d...\n\n", port);
			}
			else
			{
				if(WSAGetLastError() != WSAEWOULDBLOCK)
				{
					printf("TCP recv failed with error: %d\n", WSAGetLastError());
					
					closesocket(clientSocket);
					clientSocket = INVALID_SOCKET;
				}
			}
		}
		
		if(idle)
		{
			Sleep(100);
		}
    } 
    while (1);

    // shutdown the connection since we're done
    iResult = shutdown(udpSocket, SD_SEND);
    if (iResult == SOCKET_ERROR) 
    {
        printf("shutdown failed with error: %d\n", WSAGetLastError());
    }

    iResult = shutdown(clientSocket, SD_SEND);
    if (iResult == SOCKET_ERROR) 
    {
        printf("shutdown failed with error: %d\n", WSAGetLastError());
    }

    // cleanup
    closesocket(udpSocket);
    closesocket(listenSocket); 
    closesocket(clientSocket); 
    WSACleanup();
    
    printf("Done.\n");
    
	system("pause");
	
    return 0;
}

int manageData (char *data)
{
	static const char *beginStr = "@@@@BEGIN:";
	static const char *dataStr = "@@@@DATA:";
	static const char *endStr = "@@@@END";
	static char tmpFilePath[256];
	static char fileName[256], rest[256], uniqueFileName[256];
	static FILE *tmpFile;
	char *row;
	char *newData = NULL;
	long ticks = 0;
	
	if(strlen(rest) > 0)
	{
		char *newData = (char*)malloc(strlen(rest) + strlen(data) + 1);
		if(newData == NULL)
		{
			printf("Error %d in malloc()\n",  errno);
			return 1;		
		}
		
		strcpy(newData, rest);
		strcat(newData + strlen(rest), data);
		
		data = newData;
	}
	
	if(strstr(data, beginStr) == data)
	{
		data += strlen(beginStr);
		
		fileName[0] = '\0';
		if(sscanf(data, "%[^\n]", fileName) != 1)
		{
			printf("Invalid filename\n");
			return 1;
		}
	
		data += strlen(fileName);
				
		if (GetTempPath(sizeof(tmpFilePath), tmpFilePath) == 0)
		{
			printf("Error %d in GetTempPath()\n",  GetLastError());
			return 1;
		}
		
		strcat(tmpFilePath, "\\1401-photoprint.tmp");	
		tmpFile = fopen(tmpFilePath, "w");
		if(tmpFile == NULL)
		{
			printf("Error %d in fopen()\n",  errno);
		}
	}
	
	while((row = strstr(data, dataStr)) != NULL && strstr(row + strlen(dataStr), "@@@@") != NULL)
	{
		int dataLen;
		char rowData[256] = "";
		
		if(sscanf(row + strlen(dataStr), "%[^@@@@]", rowData) != 1)
		{
			printf("Invalid data\n");
			return 1;
		}
		
		dataLen = strlen(rowData);
		if(fwrite(rowData, sizeof(char), dataLen, tmpFile) != dataLen)
		{
			printf("Error %d in fwrite()\n",  errno);
			return 1;
		}
		
		fflush(tmpFile);
		
		data = row + strlen(dataStr) + dataLen + 4;
	}
	
	if(strcmp(data, endStr) == 0)
	{
		char destFile[512];
		
		data += strlen(endStr);
	
		if(fclose(tmpFile) != 0)
		{
			printf("Error %d in fclose()\n",  errno);
			return 1;
		}
		
		do {
			strcpy(destFile, destDir);
			
			if(ticks != 0)
			{
				sprintf(uniqueFileName, "%s_%d.lst", fileName, ticks);
			}
			else
			{
				sprintf(uniqueFileName, "%s.lst", fileName);
			}

			strcat(destFile, uniqueFileName);
			
			ticks = GetTickCount();
		}
		while(fileExists(destFile));
		
		if(rename(tmpFilePath, destFile) != 0)
		{
			printf("Error %d in rename()\n",  errno);
			return 1;
		}	
		else
		{
			printf("File %s ready to be printed\n",  uniqueFileName);
		}	
	}
	
	strcpy(rest, data);
	
	if(newData != NULL)
	{
		free(newData);
	}
	
	return 0;
}

boolean fileExists (const char *fname)
{
    FILE *file;
    
    if (file = fopen(fname, "r"))
    {
        fclose(file);
        
        return true;
    }
    
    return false;
}
