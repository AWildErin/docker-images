param (
	[string]$WindowsTag = "ltsc2022",

    # Path relative to mcr.microsoft.com
    [string]$WindowsImage = "windows/servercore"
)

$CI = $env:CI

# Tag used when pushing to docker hub
$ConstructedTag = ""

# If we're a sub image of windows, strip the start
if ($WindowsImage.StartsWith("windows/"))
{
    $ConstructedTag = $WindowsImage.Substring("windows/".Length)
}
else 
{
    $ConstructedTag = $WindowsImage    
}

$ConstructedTag += "-$WindowsTag"
$DockerHubRepo = "awilderin/windows-docker:$ConstructedTag"

Write-Host "Generating docker image for $DockerHubRepo"

if ($CI)
{
    $env:TOKEN | docker login -u $env:USER --password-stdin
}

docker build  -t "$DockerHubRepo" -f "windows-docker.dockerfile" --build-arg "BASE_IMAGE=$WindowsImage" --build-arg "BASE_TAG=$WindowsTag" .
$RET_CODE = $LastExitCode

if ($RET_CODE -ne 0)
{
    Write-Output "Exited with $RET_CODE"
    exit $RET_CODE
}

if ($CI)
{
    docker push $DockerHubRepo
    docker logout
}

