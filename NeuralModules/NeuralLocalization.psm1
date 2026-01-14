<#
.SYNOPSIS
    NeuralLocalization Module v1.0
    Handles multi-language support (ES/EN) for Windows Neural Optimizer.

.DESCRIPTION
    Provides functions to:
    - Detect system language.
    - Store translation dictionaries.
    - Retrieve localized strings via keys.
#>

# Global Language State
$Script:CurrentLanguage = "ES" # Default fallback
$Script:Dictionary = @{}

function Get-SystemLanguage {
    <#
    .SYNOPSIS
    Detects the operating system's display language.
    #>
    try {
        $lang = (Get-Culture).TwoLetterISOLanguageName
        if ($lang -eq "es") { return "ES" }
        return "EN" # Default to English for all non-Spanish systems
    }
    catch {
        return "EN"
    }
}

function Set-Language {
    param(
        [ValidateSet("ES", "EN")]
        [string]$Lang
    )
    if ($Lang -match "^(ES|EN)$") {
        $Script:CurrentLanguage = $Lang
        Write-Host " [INFO] Language set to: $Lang" -ForegroundColor Gray
        
        # Save preference if Utils is loadedr modules
    }
    $global:NeuralLang = $Lang # Export to global scope for other modules
    Write-Host " [i] Language set to: $Lang" -ForegroundColor Gray
}

function Msg {
    <#
    .SYNOPSIS
    Retrieves a localized string by key.
    
    .EXAMPLE
    Msg "MainMenu.Title"
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Key,
        
        [string[]]$FormatArgs
    )

    if (-not $Script:Dictionary.ContainsKey($Key)) {
        return "[$Key]" # Return key if missing
    }

    $entry = $Script:Dictionary[$Key]
    $text = if ($entry.ContainsKey($Script:CurrentLanguage)) { 
        $entry[$Script:CurrentLanguage] 
    }
    else { 
        $entry["EN"] # Fallback to English
    }
    
    # Simple format replacement if args provided (like .NET String.Format)
    # Uses {0}, {1} etc.
    if ($FormatArgs) {
        return ($text -f $FormatArgs)
    }
    
    return $text
}

function Initialize-Localization {
    $detected = Get-SystemLanguage
    Set-Language $detected
    
    # ========================================================================
    # DICTIONARY DEFINITIONS
    # ========================================================================
    
    # COMMON
    $Script:Dictionary["Common.Yes"] = @{ ES = "Sí"; EN = "Yes" }
    $Script:Dictionary["Common.No"] = @{ ES = "No"; EN = "No" }
    $Script:Dictionary["Common.Continue"] = @{ ES = "Presione cualquier tecla..."; EN = "Press any key to continue..." }
    $Script:Dictionary["Common.Error"] = @{ ES = "ERROR"; EN = "ERROR" }
    $Script:Dictionary["Common.AdminRequired"] = @{ 
        ES = "Se requieren permisos de Administrador"; 
        EN = "Administrator privileges required" 
    }

    # MAIN MENU
    $Script:Dictionary["Menu.Title"] = @{ 
        ES = "WINDOWS NEURAL OPTIMIZER v6.0 ULTRA"; 
        EN = "WINDOWS NEURAL OPTIMIZER v6.0 ULTRA" 
    }
    $Script:Dictionary["Menu.Option.1"] = @{ ES = "Optimización Neuronal (IA Recomienda)"; EN = "Neural Optimization (AI Recommended)" }
    $Script:Dictionary["Menu.Option.2"] = @{ ES = "Optimización Gaming (Latency/FPS)"; EN = "Gaming Optimization (Latency/FPS)" }
    $Script:Dictionary["Menu.Option.3"] = @{ ES = "Optimización Avanzada (Vanguard/HPET)"; EN = "Advanced Optimization (Vanguard/HPET)" }
    $Script:Dictionary["Menu.Option.4"] = @{ ES = "Per-Game Profiles (Prioridad/Afinidad)"; EN = "Per-Game Profiles (Priority/Affinity)" }
    $Script:Dictionary["Menu.Option.5"] = @{ ES = "Optimización de Red (TCP/DNS)"; EN = "Network Optimization (TCP/DNS)" }
    $Script:Dictionary["Menu.Option.6"] = @{ ES = "Gestor de Servicios (Safe/Aggressive)"; EN = "Service Manager (Safe/Aggressive)" }
    $Script:Dictionary["Menu.Option.7"] = @{ ES = "Optimización de Arranque (Boot)"; EN = "Boot Optimization" }
    $Script:Dictionary["Menu.Option.8"] = @{ ES = "Limpieza Profunda (Temporales)"; EN = "Deep Cleanup (Temp Files)" }
    $Script:Dictionary["Menu.Option.9"] = @{ ES = "Herramientas (Repair/Restore)"; EN = "Tools (Repair/Restore)" }
    $Script:Dictionary["Menu.Option.X"] = @{ ES = "Salir"; EN = "Exit" }
    
    # ALERTS
    $Script:Dictionary["Alert.UnsupportedOS"] = @{
        ES = "Versión de Windows no soportada. Se requiere Windows 10/11.";
        EN = "Unsupported Windows version. Windows 10/11 required."
    }

    # NEURAL UTILS
    $Script:Dictionary["Utils.Admin.Title"] = @{ ES = "SE REQUIEREN PERMISOS DE ADMINISTRADOR"; EN = "ADMINISTRATOR PRIVILEGES REQUIRED" }
    $Script:Dictionary["Utils.Admin.Request"] = @{ ES = "Solicitando permisos de administrador..."; EN = "Requesting administrator privileges..." }
    $Script:Dictionary["Utils.Admin.Error"] = @{ ES = "ERROR: Reinicie como Administrador."; EN = "ERROR: Restart as Administrator." }
    
    $Script:Dictionary["Utils.Restore.Check"] = @{ ES = "Verificando Sistema de Restauracion..."; EN = "Checking Restore System..." }
    $Script:Dictionary["Utils.Restore.Creating"] = @{ ES = "Creando Punto de Restauracion: '{0}'..."; EN = "Creating Restore Point: '{0}'..." }
    $Script:Dictionary["Utils.Restore.Success"] = @{ ES = "Punto de Restauracion Creado Exitosamente."; EN = "Restore Point Created Successfully." }
    $Script:Dictionary["Utils.Restore.Fail"] = @{ ES = "No se pudo crear el Punto de Restauracion."; EN = "Could not create Restore Point." }
    
    $Script:Dictionary["Utils.Rollback.Title"] = @{ ES = "SYSTEM RESTORE ROLLBACK"; EN = "SYSTEM RESTORE ROLLBACK" }
    $Script:Dictionary["Utils.Rollback.NoPoints"] = @{ ES = "No hay puntos de restauración disponibles."; EN = "No restore points available." }
    $Script:Dictionary["Utils.Rollback.Recent"] = @{ ES = "Puntos de restauración recientes:"; EN = "Recent restore points:" }
    $Script:Dictionary["Utils.Rollback.Select"] = @{ ES = "Seleccione número para restaurar (0 para cancelar)"; EN = "Select number to restore (0 to cancel)" }
    $Script:Dictionary["Utils.Rollback.Warning"] = @{ ES = "ADVERTENCIA: El sistema se reiniciará para restaurar: {0}"; EN = "WARNING: System will restart to restore: {0}" }
    $Script:Dictionary["Utils.Rollback.Confirm"] = @{ ES = "¿Continuar? (S/N)"; EN = "Continue? (Y/N)" }
    
    # HARDWARE & FILES
    $Script:Dictionary["Utils.FS.Freed"] = @{ ES = "Liberado: {0} MB"; EN = "Freed: {0} MB" }
    $Script:Dictionary["Utils.Hw.Storage"] = @{ ES = "Almacenamiento: {0}"; EN = "Storage: {0}" }
    $Script:Dictionary["Utils.Hw.Network"] = @{ ES = "Red: {0}"; EN = "Network: {0}" }
    $Script:Dictionary["Utils.Hw.Speed"] = @{ ES = "Velocidad: {0}"; EN = "Speed: {0}" }
    $Script:Dictionary["Utils.Hw.NoHistory"] = @{ ES = "No hay historial disponible."; EN = "No history available." }
    $Script:Dictionary["Utils.Hw.Recent"] = @{ ES = "Actividad reciente:"; EN = "Recent activity:" }
    
    # NETWORK OPTIMIZER
    $Script:Dictionary["Net.Title"] = @{ ES = "NEURAL NETWORK OPTIMIZER v6.0 ULTRA"; EN = "NEURAL NETWORK OPTIMIZER v6.0 ULTRA" }
    
    $Script:Dictionary["Net.Profile.General.Name"] = @{ ES = "Propósito General"; EN = "General Purpose" }
    $Script:Dictionary["Net.Profile.General.Desc"] = @{ ES = "Configuración balanceada para uso diario"; EN = "Balanced settings for everyday use" }
    
    $Script:Dictionary["Net.Profile.Gaming.Name"] = @{ ES = "Gaming Competitivo"; EN = "Competitive Gaming" }
    $Script:Dictionary["Net.Profile.Gaming.Desc"] = @{ ES = "Latencia mínima para juegos online (CS2, Valorant)"; EN = "Minimum latency for online gaming (CS2, Valorant)" }
    
    $Script:Dictionary["Net.Profile.Streaming.Name"] = @{ ES = "Streaming/Creación"; EN = "Streaming/Content Creation" }
    $Script:Dictionary["Net.Profile.Streaming.Desc"] = @{ ES = "Optimizado para ancho de banda (OBS, XSplit)"; EN = "Optimized for high throughput (OBS, XSplit)" }
    
    $Script:Dictionary["Net.Step.TCP"] = @{ ES = "[1/4] PILA TCP/IP"; EN = "[1/4] TCP/IP STACK" }
    $Script:Dictionary["Net.Step.Netsh"] = @{ ES = "[2/4] AJUSTES NETSH TCP"; EN = "[2/4] NETSH TCP SETTINGS" }
    
    $Script:Dictionary["Net.Desc.TCPNoDelay"] = @{ ES = "TCP No Delay (Nagle)"; EN = "TCP No Delay (Nagle)" }
    $Script:Dictionary["Net.Desc.AckFreq"] = @{ ES = "Frecuencia ACK TCP"; EN = "TCP ACK Frequency" }
    $Script:Dictionary["Net.Desc.DelAck"] = @{ ES = "Ticks ACK Retardado"; EN = "Delayed ACK Ticks" }
    $Script:Dictionary["Net.Desc.Throttling"] = @{ ES = "Throttling de Red"; EN = "Network Throttling" }
    $Script:Dictionary["Net.Desc.Congestion"] = @{ ES = "Proveedor de Congestión: {0}"; EN = "Congestion Provider: {0}" }
    $Script:Dictionary["Net.Desc.ECN"] = @{ ES = "ECN: {0}"; EN = "ECN: {0}" }
    
    # GAMING & PERFORMANCE
    $Script:Dictionary["Game.Title"] = @{ ES = "GAMING & PERFORMANCE v3.5 (DEEP TUNED)"; EN = "GAMING & PERFORMANCE v3.5 (DEEP TUNED)" }
    $Script:Dictionary["Game.Hw.Detected"] = @{ ES = "Hardware Detectado:"; EN = "Hardware Detected:" }
    $Script:Dictionary["Game.Step.GameMode"] = @{ ES = "[1/10] CONFIGURACION GAME MODE"; EN = "[1/10] GAME MODE CONFIGURATION" }
    $Script:Dictionary["Game.Step.GPU"] = @{ ES = "[2/10] GPU SCHEDULING & DIRECTX"; EN = "[2/10] GPU SCHEDULING & DIRECTX" }
    $Script:Dictionary["Game.Step.Input"] = @{ ES = "[3/10] OPTIMIZACION MOUSE & INPUT"; EN = "[3/10] MOUSE & INPUT OPTIMIZATION" }
    
    $Script:Dictionary["Game.Desc.GameModeAuto"] = @{ ES = "Auto Game Mode ON"; EN = "Auto Game Mode ON" }
    $Script:Dictionary["Game.Desc.GameModeEnabled"] = @{ ES = "Game Mode Habilitado"; EN = "Game Mode Enabled" }
    $Script:Dictionary["Game.Desc.DVR"] = @{ ES = "Game DVR Deshabilitado"; EN = "Game DVR Disabled" }
    $Script:Dictionary["Game.Desc.FSE"] = @{ ES = "FSE Behavior optimizado"; EN = "FSE Behavior optimized" }
    $Script:Dictionary["Game.Desc.HAGS"] = @{ ES = "Hardware GPU Scheduling ON"; EN = "Hardware GPU Scheduling ON" }
    
    # AI RECOMMENDATIONS
    $Script:Dictionary["AI.Analying"] = @{ ES = "Analizando sistema..."; EN = "Analyzing system..." }
    $Script:Dictionary["AI.Progress.Hw"] = @{ ES = "Hardware..."; EN = "Hardware..." }
    $Script:Dictionary["AI.Progress.Perf"] = @{ ES = "Rendimiento..."; EN = "Performance..." }
    $Script:Dictionary["AI.Progress.Usage"] = @{ ES = "Patrones de uso..."; EN = "Usage Patterns..." }
    $Script:Dictionary["AI.Progress.Health"] = @{ ES = "Chequeo de salud..."; EN = "Health Check..." }
    $Script:Dictionary["AI.Workload.Unknown"] = @{ ES = "Desconocido"; EN = "Unknown" }
}

# Auto-initialize on import
Initialize-Localization

Export-ModuleMember -Function Get-SystemLanguage, Set-Language, Msg


