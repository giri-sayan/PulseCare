# Export Word Document to PDF with Auto-Updated Table of Contents & Page Numbers
# Student: Sayan Giri (24BCT0281)

$baseDir = Split-Path -Parent $PSScriptRoot
if (-not $baseDir) { $baseDir = (Get-Item $PSScriptRoot).Parent.FullName }

[string]$docxPath = Join-Path $PSScriptRoot "BCSE302P_Project_24BCT0281.docx"
[string]$pdfPath1 = Join-Path $baseDir "BCSE302P_Project_24BCT0281.pdf"
[string]$pdfPath2 = Join-Path $PSScriptRoot "BCSE302P_Project_24BCT0281.pdf"

Write-Host "Starting Microsoft Word COM Automation..."

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsNone

try {
    Write-Host "Opening document: $docxPath"
    $doc = $word.Documents.Open($docxPath)

    Write-Host "Updating all fields and Table of Contents..."
    $doc.Fields.Update()

    # If there are tables of contents, update both entries and page numbers
    foreach ($toc in $doc.TablesOfContents) {
        $toc.Update()
    }

    Write-Host "Saving updated docx with synchronized TOC..."
    $doc.Save()

    Write-Host "Exporting to PDF: $pdfPath1"
    # wdFormatPDF = 17
    $formatPdf = 17
    $doc.SaveAs([ref]$pdfPath1, [ref]$formatPdf)

    Write-Host "Exporting to PDF: $pdfPath2"
    $doc.SaveAs([ref]$pdfPath2, [ref]$formatPdf)

    $doc.Close([ref]0)
    Write-Host "PDF Export Completed Successfully!"
}
catch {
    Write-Host "An error occurred during Word automation: $_"
}
finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}
