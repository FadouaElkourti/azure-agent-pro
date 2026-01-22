#Requires -Modules Az.Accounts, Az.Websites, Az.Monitor

<#
.SYNOPSIS
    Auto-scale App Service Plan based on business hours schedule
    
.DESCRIPTION
    Adjusts App Service Plan instance count based on time:
    - Business hours (Mon-Fri 8am-8pm CET): Min 1, Max 3 instances
    - Off-hours (nights + weekends): Min 1, Max 1 instance
    
    Ahorro estimado: $2-3/mes (20-25%)
    Zero downtime approach
    
.NOTES
    Author: Azure Architect Pro
    Date: 2026-01-22
    Environment: Dev
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-kitten-missions-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanName = "plan-kitten-missions-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$TimeZone = "Central Europe Standard Time"
)

# Connect to Azure using Managed Identity (Azure Automation)
try {
    Write-Output "Connecting to Azure using Managed Identity..."
    Connect-AzAccount -Identity -ErrorAction Stop
    Write-Output "✅ Connected to Azure successfully"
}
catch {
    Write-Error "❌ Failed to connect to Azure: $_"
    exit 1
}

# Get current time in specified timezone
$CurrentTime = [System.TimeZoneInfo]::ConvertTimeFromUtc(
    (Get-Date).ToUniversalTime(),
    [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
)

Write-Output "Current time in $TimeZone: $($CurrentTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Output "Day of week: $($CurrentTime.DayOfWeek)"

# Determine if it's business hours
$IsWeekday = $CurrentTime.DayOfWeek -notin @('Saturday', 'Sunday')
$IsBusinessHours = ($CurrentTime.Hour -ge 8) -and ($CurrentTime.Hour -lt 20)
$IsActiveTime = $IsWeekday -and $IsBusinessHours

Write-Output "Is Weekday: $IsWeekday"
Write-Output "Is Business Hours (8am-8pm): $IsBusinessHours"
Write-Output "Should be in ACTIVE mode: $IsActiveTime"

# Get current App Service Plan
try {
    $AppServicePlan = Get-AzAppServicePlan `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppServicePlanName `
        -ErrorAction Stop
    
    Write-Output "✅ Found App Service Plan: $AppServicePlanName"
    Write-Output "   Current SKU: $($AppServicePlan.Sku.Name)"
    Write-Output "   Current Capacity: $($AppServicePlan.Sku.Capacity) instances"
}
catch {
    Write-Error "❌ Failed to get App Service Plan: $_"
    exit 1
}

# Determine target auto-scale settings
if ($IsActiveTime) {
    # Business hours: Allow scaling up to 3 instances
    $TargetMinInstances = 1
    $TargetMaxInstances = 3
    $ScaleMode = "ACTIVE (Business Hours)"
}
else {
    # Off-hours: Keep at 1 instance only
    $TargetMinInstances = 1
    $TargetMaxInstances = 1
    $ScaleMode = "IDLE (Off Hours)"
}

Write-Output "Target configuration: Min $TargetMinInstances, Max $TargetMaxInstances ($ScaleMode)"

# Get current auto-scale settings
$AutoscaleSettingName = "$AppServicePlanName-autoscale"
try {
    $AutoscaleSetting = Get-AzAutoscaleSetting `
        -ResourceGroupName $ResourceGroupName `
        -Name $AutoscaleSettingName `
        -ErrorAction SilentlyContinue
    
    if ($null -eq $AutoscaleSetting) {
        Write-Output "⚠️  No auto-scale settings found. Will create new configuration."
        $NeedsCreation = $true
    }
    else {
        Write-Output "✅ Found existing auto-scale setting: $AutoscaleSettingName"
        $CurrentProfile = $AutoscaleSetting.Profiles[0]
        $CurrentMin = $CurrentProfile.Capacity.Minimum
        $CurrentMax = $CurrentProfile.Capacity.Maximum
        
        Write-Output "   Current: Min $CurrentMin, Max $CurrentMax"
        
        # Check if update is needed
        if ($CurrentMin -eq $TargetMinInstances -and $CurrentMax -eq $TargetMaxInstances) {
            Write-Output "✅ Auto-scale settings already correct. No changes needed."
            exit 0
        }
        
        $NeedsCreation = $false
    }
}
catch {
    Write-Error "❌ Failed to check auto-scale settings: $_"
    exit 1
}

# Create or update auto-scale rule
try {
    Write-Output "🔄 Updating auto-scale configuration..."
    
    # Create scale rule for CPU-based scaling (only during business hours)
    $ScaleOutRule = New-AzAutoscaleRule `
        -MetricName "CpuPercentage" `
        -MetricResourceId $AppServicePlan.Id `
        -Operator GreaterThan `
        -MetricStatistic Average `
        -Threshold 70 `
        -TimeGrain 00:01:00 `
        -TimeWindow 00:10:00 `
        -ScaleActionDirection Increase `
        -ScaleActionScaleType ChangeCount `
        -ScaleActionValue 1 `
        -ScaleActionCooldown 00:05:00
    
    $ScaleInRule = New-AzAutoscaleRule `
        -MetricName "CpuPercentage" `
        -MetricResourceId $AppServicePlan.Id `
        -Operator LessThan `
        -MetricStatistic Average `
        -Threshold 30 `
        -TimeGrain 00:01:00 `
        -TimeWindow 00:15:00 `
        -ScaleActionDirection Decrease `
        -ScaleActionScaleType ChangeCount `
        -ScaleActionValue 1 `
        -ScaleActionCooldown 00:10:00
    
    # Create auto-scale profile
    $AutoscaleProfile = New-AzAutoscaleProfile `
        -DefaultCapacity $TargetMinInstances `
        -MaximumCapacity $TargetMaxInstances `
        -MinimumCapacity $TargetMinInstances `
        -Rule $ScaleOutRule, $ScaleInRule `
        -Name "Default-Profile"
    
    # Apply auto-scale setting
    if ($NeedsCreation) {
        Add-AzAutoscaleSetting `
            -Location $AppServicePlan.Location `
            -Name $AutoscaleSettingName `
            -ResourceGroupName $ResourceGroupName `
            -TargetResourceId $AppServicePlan.Id `
            -AutoscaleProfile $AutoscaleProfile `
            -ErrorAction Stop
        
        Write-Output "✅ Created new auto-scale setting"
    }
    else {
        # Update existing
        Add-AzAutoscaleSetting `
            -Location $AppServicePlan.Location `
            -Name $AutoscaleSettingName `
            -ResourceGroupName $ResourceGroupName `
            -TargetResourceId $AppServicePlan.Id `
            -AutoscaleProfile $AutoscaleProfile `
            -ErrorAction Stop
        
        Write-Output "✅ Updated auto-scale setting"
    }
    
    Write-Output "✅ Auto-scale configuration applied successfully"
    Write-Output "   Mode: $ScaleMode"
    Write-Output "   Min instances: $TargetMinInstances"
    Write-Output "   Max instances: $TargetMaxInstances"
}
catch {
    Write-Error "❌ Failed to update auto-scale settings: $_"
    exit 1
}

# Optional: Manually scale to min instances during off-hours for immediate cost savings
if (-not $IsActiveTime -and $AppServicePlan.Sku.Capacity -gt 1) {
    Write-Output "🔄 Off-hours detected with $($AppServicePlan.Sku.Capacity) instances running"
    Write-Output "   Scaling down to 1 instance for immediate savings..."
    
    try {
        Set-AzAppServicePlan `
            -ResourceGroupName $ResourceGroupName `
            -Name $AppServicePlanName `
            -NumberofWorkers 1 `
            -ErrorAction Stop
        
        Write-Output "✅ Scaled down to 1 instance"
    }
    catch {
        Write-Warning "⚠️  Failed to scale down immediately: $_"
        Write-Output "   Auto-scale will handle this automatically"
    }
}

Write-Output ""
Write-Output "================================================"
Write-Output "Auto-Scale Schedule Update Completed"
Write-Output "================================================"
Write-Output "Resource Group: $ResourceGroupName"
Write-Output "App Service Plan: $AppServicePlanName"
Write-Output "Current Mode: $ScaleMode"
Write-Output "Min Instances: $TargetMinInstances"
Write-Output "Max Instances: $TargetMaxInstances"
Write-Output "Estimated Monthly Savings: $2-3 (20-25%)"
Write-Output "================================================"
