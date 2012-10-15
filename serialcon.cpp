// serialcon.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <Windows.h>


int _tmain(int argc, _TCHAR* argv[])
{
	HANDLE hSerial;
	DWORD err;
	hSerial=CreateFile(L"COM6", GENERIC_READ | GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	
	if(hSerial==INVALID_HANDLE_VALUE)
	{
		err=GetLastError();
		if(err==ERROR_FILE_NOT_FOUND)
			fprintf(stderr, "No such serial port!\n");
		else
			fprintf(stderr, "Cannot open serial port! Error code %d\n", err); 
		return -1;
	}

	LPDCB dcbSerialParams=new(DCB);

	if(!GetCommState(hSerial, dcbSerialParams))
	{
		fprintf(stderr, "Cannot get serial port state!\n");
		return -1;
	}
	
	dcbSerialParams->BaudRate=CBR_9600;
	dcbSerialParams->ByteSize=8;
	dcbSerialParams->Parity=NOPARITY;
	dcbSerialParams->StopBits=TWOSTOPBITS;

	if(!SetCommState(hSerial, dcbSerialParams))
	{
		fprintf(stderr, "Cannot set port state!\n");
		return -1;
	}

	LPCOMMTIMEOUTS timeouts=new(COMMTIMEOUTS);
	timeouts->ReadIntervalTimeout=50;
	timeouts->ReadTotalTimeoutConstant=50;
	timeouts->ReadTotalTimeoutMultiplier=10;
	timeouts->WriteTotalTimeoutConstant=50;
	timeouts->WriteTotalTimeoutMultiplier=10;

	if(!SetCommTimeouts(hSerial, timeouts))
	{
		fprintf(stderr, "Cannot set timeouts!\n");
		return -1;
	}

	DWORD bytesRead;
	char buffer[128]={0};

//	do
	while(1)
	{

		// Read in the input
		scanf("%s", buffer);
		if(!WriteFile(hSerial, buffer, strlen(buffer), &bytesRead, NULL))
		{
			fprintf(stderr, "Unable to write serial port\n");
		}

		if(!ReadFile(hSerial, buffer, 128, &bytesRead, NULL))
		{
			fprintf(stderr, "Unable to read serial port\n");
			bytesRead=0;
		}
		else
			if(bytesRead>0)
				printf("%s\n", buffer);
	} //while(bytesRead>0);

	CloseHandle(hSerial);

	return 0;
}

