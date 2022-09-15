#include <Windows.h>
#include <stdio.h>
#include <tlhelp32.h>

/**
 * https://vimalshekar.github.io/codesamples/Checking-If-Admin
 */
BOOL IsProcessElevated()
{
	BOOL fIsElevated = FALSE;
	HANDLE hToken = NULL;
	TOKEN_ELEVATION elevation;
	DWORD dwSize;

	if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) 
    goto Cleanup;
	if (!GetTokenInformation(hToken, TokenElevation, &elevation, sizeof(elevation), &dwSize)) 
    goto Cleanup;

	fIsElevated = elevation.TokenIsElevated;

Cleanup:
	if (hToken) CloseHandle(hToken);
	return fIsElevated; 
}

void getProcessName(DWORD pid, char * buff) {
	HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

	PROCESSENTRY32 pe32;
	pe32.dwSize = sizeof(pe32);

	Process32First(snap, &pe32);

	do {
		if (pe32.th32ProcessID == pid) {
			memcpy(buff, pe32.szExeFile, 260);
		}
	} while (Process32Next(snap, &pe32));

	CloseHandle(snap);
}