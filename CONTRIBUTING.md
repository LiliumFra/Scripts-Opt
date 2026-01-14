# Contributing to Windows Neural Optimizer

We welcome contributions to the Neural AI Tweak Library! To keep the "Brain" healthy and safe, please follow these guidelines.

## How to Add a New Tweak to `NeuralAI.psm1`

1. **Safety First:**
    * All tweaks must be **reversible**.
    * Must verify `ValueOff` restores the original state.
    * **Risk Level** must be accurate (`Low`, `Medium`, `High`).

2. **Format:**
    Add your entry to the `$Script:TweakLibrary` array in `NeuralModules\NeuralAI.psm1`.

    ```powershell
    @{ 
        Id = "UniqueId"; 
        Name = "Human Readable Name"; 
        Risk = "Low|Medium|High"; 
        Category = "Network|System|Gaming|Privacy"; 
        
        # Option A: Registry
        Path = "HKLM:\..."; 
        Key = "KeyName"; 
        ValueOn = 1; 
        ValueOff = 0; 
        
        # Option B: Command
        CommandOn = "powercfg /..."; 
        CommandOff = "powercfg /...";
        
        Description = "Short explanation of what this does" 
    }
    ```

3. **Submission Checklist:**
    * [ ] Tested on a Virtual Machine first.
    * [ ] Verified `ConditionScript` if hardware-specific (e.g., Lenovo).
    * [ ] Added to the correct category section.

## Reporting Bugs

If the AI makes a bad decision (Performance Regression), please open an issue with:

1. The `TweakId` that caused the regression.
2. Your `NeuralBrain.json` (redacted if necessary).
3. System Specs.
