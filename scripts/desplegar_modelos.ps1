#Requires -Version 5.1
<#
.SYNOPSIS
    Coloca los modelos exportados por el notebook 06 donde los esperan la app y el backend.

.DESCRIPTION
    El segmentador y M1 se despliegan en int8, porque la cuantizacion les cuesta 0.005 de F1
    o menos. M2 se despliega en float32, porque perdia 0.040 de F1 al cuantizarse. La decision
    se sostiene en el notebook 13 (docs/reproducibilidad.md).

    models/ no se versiona. app/assets/models/ si, mediante Git LFS.

.PARAMETER Origen
    Carpeta con los artefactos de exportacion. Por defecto training/outputs.

.EXAMPLE
    pwsh scripts/desplegar_modelos.ps1
#>
[CmdletBinding()]
param(
    [string]$Origen = "training/outputs"
)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$src = Join-Path $raiz $Origen
if (-not (Test-Path $src)) {
    throw "No existe la carpeta de origen: $src. Ejecuta antes el notebook 06."
}

$destinos = @(
    @{ Desde = "model1_int8.tflite";    Hasta = "app/assets/models/hs/model.tflite" }
    @{ Desde = "labels_m1.txt";         Hasta = "app/assets/models/hs/labels.txt" }
    @{ Desde = "model2.tflite";         Hasta = "app/assets/models/pd/model_unquant.tflite" }
    @{ Desde = "labels_m2.txt";         Hasta = "app/assets/models/pd/labels.txt" }
    @{ Desde = "model_seg_int8.tflite"; Hasta = "app/assets/models/seg/model_seg.tflite" }

    @{ Desde = "model1.tflite";         Hasta = "models/health/model.tflite" }
    @{ Desde = "model1_int8.tflite";    Hasta = "models/health/model_int8.tflite" }
    @{ Desde = "labels_m1.txt";         Hasta = "models/health/labels.txt" }
    @{ Desde = "model2.tflite";         Hasta = "models/disease/model.tflite" }
    @{ Desde = "model2_int8.tflite";    Hasta = "models/disease/model_int8.tflite" }
    @{ Desde = "labels_m2.txt";         Hasta = "models/disease/labels.txt" }
    @{ Desde = "model_seg.tflite";      Hasta = "models/segmentation/model.tflite" }
    @{ Desde = "model_seg_int8.tflite"; Hasta = "models/segmentation/model_int8.tflite" }
)

$faltantes = $destinos.Desde | Sort-Object -Unique | Where-Object { -not (Test-Path (Join-Path $src $_)) }
if ($faltantes) {
    throw "Faltan artefactos en ${src}:`n  " + ($faltantes -join "`n  ")
}

foreach ($d in $destinos) {
    $desde = Join-Path $src $d.Desde
    $hasta = Join-Path $raiz $d.Hasta
    $carpeta = Split-Path -Parent $hasta
    if (-not (Test-Path $carpeta)) {
        New-Item -ItemType Directory -Force -Path $carpeta | Out-Null
    }
    Copy-Item $desde $hasta -Force
    $mb = [math]::Round((Get-Item $hasta).Length / 1MB, 2)
    "{0,-44} {1,8} MB" -f $d.Hasta, $mb
}

$umbral = Join-Path $raiz "app/assets/models/hs/threshold.json"
if (-not (Test-Path $umbral)) {
    '{"diseased_gate": 0.5}' | Set-Content -Path $umbral -Encoding utf8 -NoNewline
    "{0,-44} {1,>8}" -f "app/assets/models/hs/threshold.json", "creado"
}

Write-Host "`nDespliegue completo." -ForegroundColor Green
