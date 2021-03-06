function ImportTheme {
    <#
        .SYNOPSIS
            Imports themes by name
    #>
    [CmdletBinding()]
    param(
        # A theme to import (can be the name of an installed theme, or the full path to a psd1 file)
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [Alias("PSPath")]
        [string]$Name,

        # One or more modules to export the theme from (ignores all other modules)
        [Parameter(ParameterSetName = "Whitelist")]
        [Alias("Module")]
        [string[]]$IncludeModule,

        # One or more modules to skip in the theme
        [Parameter(Mandatory, ParameterSetName = "Blacklist")]
        [string[]]$ExcludeModule
    )
    process {
        # Trace-Message -Verbose "PROCESS ImportTheme $Name $($PSCmdlet.ParameterSetName)"
        Write-Verbose "Loading theme from disk: $Name"

        # Normalize the Path, the file name must end with ".theme.psd1"
        $FileName = $Name -replace "((\.theme)?\.psd1)?$" -replace '$', ".theme.psd1"

        # The path needs to be a full file-sytem path
        if (Test-Path -LiteralPath $FileName) {
            $Path = Convert-Path -LiteralPath $FileName
        }

        # Trace-Message -Verbose "PATH: $Path"
        # Otherwise, use FindTheme
        if (!$Path) {
            $Themes = @(FindTheme $Name)
            if ($Themes.Count -eq 1) {
                $Path = $Themes[0].Path
            } elseif ($Themes.Count -gt 1) {
                Write-Warning "No exact match for $Name. Using $($Themes[0]), but also found $($Themes[1..$($Themes.Count-1)] -join ', ')"
                $Path = $Themes[0].Path
            }
            if (!$Path) {
                Write-Error "No theme '$Name' found. Try Get-Theme to see available themes."
                return
            }
        }

        Write-Verbose "Importing $Name theme from $Path"
        # Trace-Message -Verbose "Importing by casting [Theme]$Path"
        $Theme = [Theme]$Path

        if ($IncludeModule) {
            # Trace-Message "Filter IncludeModule $IncludeModule"
            Write-Debug "IncludeModule: $IncludeModule"
            $IncludeModule = @(
                foreach ($module in $IncludeModule) {
                    $Theme.Modules.Where{ ($_ -like $Module) -or $_ -eq "Theme.$Module" -or $_ -eq "$Module.Theme" }
                }
            )
            Write-Debug "IncludeModule: $IncludeModule"
            foreach ($unwanted in $Theme.Modules.Where{ $_ -notin $IncludeModule }) {
                Write-Debug "Removing $Unwanted from imported $Name theme"
                $null = $Theme.Remove($unwanted)
            }
        } elseif ($ExcludeModule) {
            # Trace-Messsage "Filter ExcludeModule $ExcludeModule"
            Write-Debug "ExcludeModule: $ExcludeModule"
            foreach ($module in $ExcludeModule) {
                foreach ($unwanted in @($Theme.Modules.Where{ ($_ -like $Module) -or $_ -eq "Theme.$Module" -or $_ -eq "$Module.Theme" })) {
                    Write-Debug "Excluding $Unwanted from imported $Name theme"
                    $null = $Theme.Remove($unwanted)
                }
            }
        }
        # Trace-Message -Verbose "END ImportTheme"

        $Theme
    }
}