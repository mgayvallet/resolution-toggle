# ResToggle.ps1 - bascule la resolution de l'ecran principal avec un raccourci clavier
# Usage :  powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File ResToggle.ps1
#          powershell -File ResToggle.ps1 -ListModes   (liste les resolutions dispo)
#          powershell -File ResToggle.ps1 -Once        (bascule une seule fois, sans raccourci)
param([switch]$ListModes, [switch]$Once)

# ===== CONFIG =====
$ResA = @{ W = 1920; H = 1080 }   # resolution normale
$ResB = @{ W = 1280; H = 960 }   # resolution alternative (ex : stretched)
# Raccourci : Ctrl+Alt+R par defaut. Modifs : Alt=1 Ctrl=2 Shift=4 Win=8 (additionner)
$Modifiers = 1 + 2
$Key       = 0x52                  # 'R'  (Entree = 0x0D, F9 = 0x78, etc.)
# ==================

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public static class Res {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra;
        public int dmFields;
        public int dmPositionX, dmPositionY, dmDisplayOrientation, dmDisplayFixedOutput;
        public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
        public int dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct MSG { public IntPtr hwnd; public uint message; public IntPtr wParam, lParam; public uint time; public int x, y; }

    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int ChangeDisplaySettings(ref DEVMODE dm, int flags);
    [DllImport("user32.dll")] static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern int GetMessage(out MSG m, IntPtr h, uint a, uint b);

    static DEVMODE New() { var d = new DEVMODE(); d.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return d; }

    public static int[] Current() { var d = New(); EnumDisplaySettings(null, -1, ref d); return new[] { d.dmPelsWidth, d.dmPelsHeight, d.dmDisplayFrequency }; }

    public static List<string> Modes() {
        var l = new List<string>(); var d = New();
        for (int i = 0; EnumDisplaySettings(null, i, ref d); i++) {
            string s = d.dmPelsWidth + "x" + d.dmPelsHeight + " @" + d.dmDisplayFrequency + "Hz";
            if (!l.Contains(s)) l.Add(s);
        }
        return l;
    }

    // Change la resolution en gardant la frequence actuelle si possible
    public static int Set(int w, int h) {
        var d = New(); EnumDisplaySettings(null, -1, ref d);
        d.dmPelsWidth = w; d.dmPelsHeight = h;
        d.dmFields = 0x80000 | 0x100000 | 0x400000; // WIDTH | HEIGHT | FREQUENCY
        int r = ChangeDisplaySettings(ref d, 0);
        if (r != 0) { d.dmFields = 0x80000 | 0x100000; r = ChangeDisplaySettings(ref d, 0); }
        return r; // 0 = OK
    }

    public static bool Register(uint mods, uint vk) { return RegisterHotKey(IntPtr.Zero, 1, mods | 0x4000 /*NOREPEAT*/, vk); }
    public static bool Wait() { MSG m; return GetMessage(out m, IntPtr.Zero, 0, 0) > 0 && m.message == 0x0312; }
}
'@

if ($ListModes) { [Res]::Modes(); "Actuelle : " + ([Res]::Current() -join 'x'); return }

function Toggle {
    $c = [Res]::Current()
    $t = if ($c[0] -eq $ResA.W -and $c[1] -eq $ResA.H) { $ResB } else { $ResA }
    $r = [Res]::Set($t.W, $t.H)
    "$(Get-Date -f HH:mm:ss) -> $($t.W)x$($t.H) @$([Res]::Current()[2])Hz (code $r)"
}
if ($Once) { Toggle; return }

if (-not [Res]::Register($Modifiers, $Key)) {
    Write-Error "Impossible d'enregistrer le raccourci (deja utilise par une autre appli ?)"; exit 1
}
"Raccourci actif. Ferme cette fenetre (ou tue le process) pour arreter."
while ($true) {
    if ([Res]::Wait()) { Toggle }
}
