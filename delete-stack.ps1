param(
    [Parameter(Mandatory)] [string] $StackName
)

. ./.cicd/cleaning/delete-stack-functions.ps1

# DeleteStack -StackName $StackName

$job1 = Start-Job -InitializationScript $asynco -ScriptBlock { Asynctest -StackName 'Pila 1' -WaitFor 5 } | Wait-Job| Receive-Job

#$job2 = Start-Job -ScriptBlock { Asynctest -StackName 'Pila 2' -WaitFor 7 }

#Receive-Job -Job $job1 -Wait
#Receive-Job -Job $job2