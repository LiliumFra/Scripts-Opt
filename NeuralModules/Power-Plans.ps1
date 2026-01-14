function Invoke-PowerPlanCreation {
    Write-Step "GESTION DE PLANES DE ENERGIA"

    # GUIDs
    $highPerfGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
    $balancedGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
    $subProc = "54533251-82be-4824-96c1-47b60b740d00"
    
    # Hidden Settings GUIDs
    $guidCoreParkingMin = "0cc5b647-c1df-4637-891a-dec35c318583" # Min Cores
    $guidCoreParkingMax = "ea062031-0e34-4ff1-9b6d-eb1059334029" # Max Cores
    $guidIdleDisable = "5d76a2ca-e8c0-402f-a133-2158492d58ad" # Idle Disable
    $guidPerfBoost = "be337238-0d82-4146-a960-4f3749d470c7" # Perf Boost Mode
    $guidThrottling = "bc5038f7-23e0-4960-96da-33abaf5935ec" # Max Processor State
    
    # Check existing plans
    $plans = powercfg /list
    
    # --- 1. NEURAL LOW LATENCY (Gaming) ---
    $planName = "Neural Low Latency"
    if ($plans -notmatch $planName) {
        Write-Host "   [+] Creando plan: $planName..." -ForegroundColor Cyan
        # Duplicate High Perf
        $output = powercfg -duplicatescheme $highPerfGuid 2>&1
        $newGuid = $output | Select-String -Pattern "([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})" | ForEach-Object { $matches[0] }
        
        if ($newGuid) {
            powercfg -changename $newGuid $planName
            
            # Tweaks (AC Value)
            # Disable Core Parking (100% Min/Max)
            powercfg -setacvalueindex $newGuid $subProc $guidCoreParkingMin 100
            powercfg -setacvalueindex $newGuid $subProc $guidCoreParkingMax 100
            
            # Turbo Boost: Aggressive (2)
            powercfg -setacvalueindex $newGuid $subProc $guidPerfBoost 2
            
            # Disable Idle States (1 = Disable Idle) - CAUTION: High Temps
            # We treat "Low Latency" as eSports mode.
            powercfg -setacvalueindex $newGuid $subProc $guidIdleDisable 1
            
            # USB/PCI OFF
            $guidUsbSub = "2a737441-1930-4402-8d77-b94982726d37"
            $guidUsbSel = "48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
            powercfg -setacvalueindex $newGuid $guidUsbSub $guidUsbSel 0 # Disabled
            
            Write-Host "   [OK] Plan '$planName' configurado (Aggressive Turbo, No Parking)" -ForegroundColor Green
        }
    }
    else {
        Write-Host "   [OK] Plan '$planName' ya existe." -ForegroundColor  DarkGray
    }

    # --- 2. NEURAL BALANCED (Daily/Laptop) ---
    $planName = "Neural Balanced"
    if ($plans -notmatch $planName) {
        Write-Host "   [+] Creando plan: $planName..." -ForegroundColor Cyan
        $output = powercfg -duplicatescheme $balancedGuid 2>&1
        $newGuid = $output | Select-String -Pattern "([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})" | ForEach-Object { $matches[0] }
         
        if ($newGuid) {
            powercfg -changename $newGuid $planName
            
            # Tweaks
            # Core Parking: Allow default (efficiency)
            # Turbo Boost: Efficient Aggressive (4)
            powercfg -setacvalueindex $newGuid $subProc $guidPerfBoost 4
            
            Write-Host "   [OK] Plan '$planName' configurado (Efficient Turbo)" -ForegroundColor Green
        }
    }

    # --- 3. NEURAL STREAMING (Stable) ---
    $planName = "Neural Streaming"
    if ($plans -notmatch $planName) {
        Write-Host "   [+] Creando plan: $planName..." -ForegroundColor Cyan
        $output = powercfg -duplicatescheme $highPerfGuid 2>&1
        $newGuid = $output | Select-String -Pattern "([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})" | ForEach-Object { $matches[0] }
         
        if ($newGuid) {
            powercfg -changename $newGuid $planName
            
            # Tweaks
            # Unpark Cores (Stable performance)
            powercfg -setacvalueindex $newGuid $subProc $guidCoreParkingMin 100
             
            # Turbo Boost: Efficient Aggressive (4) or Disabled (0) for stability? 
            # Streaming needs stability. Let's start with Efficient Enabled (3)
            powercfg -setacvalueindex $newGuid $subProc $guidPerfBoost 3
            
            Write-Host "   [OK] Plan '$planName' configurado (Stable Turbo, Unparked)" -ForegroundColor Green
        }
    }
}

function Set-NeuralPowerPlan {
    param([string]$ProfileName) # Gaming, Balanced, Streaming
    
    $plans = powercfg /list
    $targetName = "Neural Balanced"
    
    switch ($ProfileName) {
        "High" { $targetName = "Neural Low Latency" }
        "Ultra" { $targetName = "Neural Low Latency" }
        "Streaming" { $targetName = "Neural Streaming" }
        Default { $targetName = "Neural Balanced" }
    }
    
    # Find GUID
    # Regex to find GUID associated with the name
    # Output format: Power Scheme GUID: xxxx-xxxx...  (Name)
    $lines = $plans -split "`r`n"
    $match = $lines | Where-Object { $_ -like "*$targetName*" }
    
    if ($match) {
        $guid = $match | Select-String -Pattern "([a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12})" | ForEach-Object { $matches[0] }
        if ($guid) {
            Write-Host "   [i] Activando plan de energia: $targetName..." -ForegroundColor Cyan
            powercfg -setactive $guid
            Write-Host "   [OK] Plan Activo: $targetName" -ForegroundColor Green
        }
    }
    else {
        Write-Host "   [!] Plan '$targetName' no encontrado. Usando default." -ForegroundColor Yellow
    }
}
