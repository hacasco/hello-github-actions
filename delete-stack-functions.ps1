function DeleteStack {
    param (
        [Parameter(Mandatory)] [string] $StackName,
        [int] $SleepInterval = 30

    )
    $deletedStatus = "DELETE_COMPLETE"
    $deletingStatus = "DELETE_IN_PROGRESS"
    
    Write-Host "Attempting to delete stack $StackName"
    
    # check stack status
    $stackStatus = Get-StackStatus -StackName $StackName
    if ($stackStatus -eq $deletedStatus) {
        Write-Host "Stack $StackName does not exist." -ForegroundColor Yellow
        return
    }

    # try to delete during ... minutes
    $tryDuringMinutes = New-TimeSpan -Minutes 5
    $startTime = Get-Date
    $elapsedTime = New-TimeSpan -Minutes 0

    while ($stackStatus -ne $deletedStatus -or ($elapsedTime -le $tryDuringMinutes)) {
        if ($stackStatus -ne $deletingStatus) {
            aws cloudformation delete-stack --stack-name $StackName

            #check stack status after deletion attempt
            Start-Sleep -s 5
            $stackStatus = Get-StackStatus -StackName $StackName
            Write-Host "Stack status: $stackStatus ..." -ForegroundColor Yellow
        }

        # sleep for 30 seconds until next check
        Start-Sleep -s $SleepInterval
        $stackStatus = Get-StackStatus -StackName $StackName
        $elapsedTime = New-TimeSpan -Start $startTime -End $(Get-Date)
    }

    if ($stackStatus -eq $deletedStatus) {
        Write-Host "Successfully deleted $StackName after $elapsedTime." -ForegroundColor Green
    }
    else {
        Write-Host "Could not delete $StackName after $tryDuringMinutes minutes." -ForegroundColor Red
    }
}
function Get-StackStatus {
    param (
        [Parameter(Mandatory)] [string] $StackName
    )
    
    try {
        $stackInfo = aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[].{stackStatus:StackStatus}' | ConvertFrom-Json
        return $stackInfo[0].stackStatus
    }
    catch {
        return "DELETE_COMPLETE"
    }
}

function EmptyS3Bucket {
    param (
        [Parameter(Mandatory)] [string] $S3BucketName
    )
    
    Write-Host "Emptying S3 bucket $S3BucketName"
    aws s3 rm "s3://$($S3BucketName)" --recursive
}

function DispatchToCleaner {
    param (
        [Parameter(Mandatory)] [string] $StackName,
        [Parameter(Mandatory)] [string] $S3BucketName,
        [Parameter(Mandatory)] [string] $CleaningToken
    )

    [string] $appJson = Get-Content -Path ./stack-cleanup.json -Encoding utf8
    $appJson = $appJson.Replace("STACK_NAME", $StackName)
    $appJson = $appJson.Replace("S3_BUCKET_NAME", $S3BucketName)

    Write-Host $appJson

    curl `
    -X POST `
    -H "Accept: application/vnd.github.v3+json" `
    -H "authorization: Bearer $CleaningToken" `
    https://api.github.com/repos/trilogy-group/devfactory-cloudcrm-bootstrap/dispatches `
    -d "$appJson"
}

$asynco = function Asynctest {
    param (
        [Parameter(Mandatory)] [string] $StackName,
        [int] $WaitFor
    )
    
    Write-Host "Corriendo $StackName"
    Write-Host "Durmiendo $WaitFor"
    Start-Sleep -s $WaitFor
    Write-Host "Despertar $StackName"

    return "Terminar $StackName despues de $WaitFor"
}

