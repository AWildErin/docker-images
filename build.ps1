param
(
    [Parameter(Mandatory=$true)]
    [string]$DockerFile,

    [Parameter(Mandatory=$true)]
    [string]$Repository,

    [string]$Tag = "latest"
)

$Root = $PSScriptRoot

$RepoWithTag = "$env:USER/${Repository}:$Tag"

# TODO: use stdin instead of passing it with -p
$env:TOKEN | docker login -u $env:USER --password-stdin
docker build -f "$DockerFile" -m 16G -t "$RepoWithTag" .
$RET_CODE = $LastExitCode
if ($RET_CODE -ne 0)
{
    Write-Output "Exited with $RET_CODE"
    exit $RET_CODE
}

docker push $RepoWithTag
docker logout
