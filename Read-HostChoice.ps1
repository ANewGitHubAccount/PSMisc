<#
.SYNOPSIS
  Lets the host decide what objects to use.
.DESCRIPTION
  The Read-HostChoice cmdlet lets the host decide from a list which object to output on the pipeline. This is done by entering a number.
.EXAMPLE
  "Action A", "Action B" | Read-HostChoice -Message "How do you wish to continue?"
.EXAMPLE
  Get-Process | Read-HostChoice -DisplayAttribute ProcessName -MultiAnswer | Stop-Process

  Use the DisplayAttribute to specify the text that is shown for each object in the list. The MultiAnswer-switch allows multiple answers that are separated by a comma.
.EXAMPLE
  Read-HostChoice $UserAccounts | Enable-ADUser
.PARAMETER InputObject
  The objects to decide from.
.PARAMETER DisplayName
  The attribute that is shown as representing text for each object.
.PARAMETER Message
  The text that is shown to the host when expecting an answer.
.PARAMETER AllowMultipleAnswers
  Allows multiple comma separated answers.
#>
function Read-HostChoice {
    param(
        [Parameter(Position=0,
                   Mandatory=$true,
                   ValueFromPipeline=$true)]
        [AllowEmptyString()]
        $InputObject,

        [Parameter(Position=1,
                   Mandatory=$false)]
        [String]
        $DisplayAttribute,

        [Parameter(Position=2,
                   Mandatory=$false)]
        [String]
        $Message = "Choose an element by entering a number:",

        [Parameter(Position=3,
                   Mandatory=$false)]
        [Alias("MultiAnswer")]
        [Switch]
        $AllowMultipleAnswers
    )

    begin {
        $Objects = @()
    }

    process {
        if ($_ -ne $null) {
            $Objects += $_
        }
    }

    end {
        if (-not $Objects) {
            $Objects = $InputObject
        }

        $ItemCounter = 0
        $ItemList = @()

        # Creating a simple itemlist
        foreach ($Object in $Objects) {
            $ItemCounter++

            if($DisplayAttribute) {
                $ItemList += New-Object -TypeName PSObject -Property @{
                    Index = $ItemCounter
                    Name = $Object | Select-Object -ExpandProperty $DisplayAttribute
                    Object = $Object
                }
            } else {
                $ItemList += New-Object -TypeName PSObject -Property @{
                    Index = $ItemCounter
                    Object = $Object
                }
            }
        }

        # Outputting itemlist to host
        while ($Output -eq $null) {
            foreach ($Item in $ItemList) {
                Write-Host -NoNewline "["
                Write-Host -NoNewline -ForegroundColor Yellow $Item.Index
                Write-Host -NoNewline "] "

                if($DisplayAttribute) {
                    Write-Host $Item.Name
                } else {
                    Write-Host "$($Item.Object)"
                }
            }

            Write-Host ""

            # Waiting for response
            Write-Host -NoNewline "$Message "

            $Response = Read-Host

            $Output = `
            if($AllowMultipleAnswers) {
                $ResponseParts = $Response.split(',').Trim() | Sort-Object | Get-Unique

                ForEach-Object {
                    $ItemList | Where-Object Index -eq $_ | Select-Object -ExpandProperty Object
                }
            } else {
                $ItemList | Where-Object Index -eq $Response.Trim() | Select-Object -ExpandProperty Object
            }
        }

        return $Output
    }
}