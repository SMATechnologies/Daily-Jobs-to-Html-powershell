    
    
param(
	[string] $OpScheduleDate = "",
    [string] $OpJobStatus = "",
    [string] $OpConUser = "ocadm",
	[string] $OpConPassword,
    [string] $ServerUrl = "https://192.168.2.30:443"
    )


    
function Ignore-SelfSignedCerts {
    add-type -TypeDefinition  @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}


function Invoke-OpConRestMethod {
    param(
        [ValidateNotNullorEmpty()]
        [String]$Uri,
        [ValidateNotNullorEmpty()]
        [String]$Method,
        [object]$Body = $null
    )


    if (!$Global:OpconRESTApiUrl -or !$Global:OpconRESTApiAuthHeader)
    {
        Write-Warning "No values for Opcon REST Api.  Please use Logon-OpConApi before using cmdlet."
        throw [System.Exception] "Invalid OpCon REST API Values"
    }


    $uri = $Global:OpconRESTApiUrl + $Uri
    
    Write-Verbose("Sending Web Request...")
    try
    {
        if ($Body -eq $null)
        {
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $Global:OpconRESTApiAuthHeader -ErrorVariable $RestException 
        }
        else
        {
            $Body = ConvertTo-Json $Body -Depth 99
            $response = Invoke-RestMethod -Method $Method -Uri $uri -Headers $Global:OpconRESTApiAuthHeader -Body $Body -ContentType 'application/json; charset=utf-8' -ErrorVariable $RestException 
        }
        Write-Verbose ("`n")
        Write-Verbose("RESPONSE:")
        Write-Verbose(ConvertTo-Json $response -Depth 9)
        return $response
    }
    catch
    {
        Write-Warning ("Error")
        Write-Warning ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
        Write-Warning ("StatusDescription: " + $_.Exception.Response.StatusDescription)
        $opconApiError = ConvertFrom-Json $_.ErrorDetails.Message
        Write-Warning ("ErrorCode: " + $opconApiError.code)
        Write-Warning ("ErrorMessage: " + $opconApiError.message)
        throw
        ##exit $_.Exception.Response.StatusCode.value__
    }
}


function Get-OpConApiToken {
[cmdletbinding()]
param(
    [string] $Url,
    [string] $User,
    [string] $Password
    )
$tokensUri = -join($Url, "/api/tokens")
Write-Host ("Retrieving authorization token...")
Write-Host ("Uri: " + $tokensUri)
Write-Host ("User: " + $User)
$tokenObject = @{
    user = @{
        loginName = $User
        password = $Password
    }
    tokenType = @{
        type = "User"
    }
}
try
{
    Ignore-SelfSignedCerts
    #$token = Invoke-RestMethod -Method Post -Uri $tokensUri -Body (ConvertTo-Json $tokenObject) -ContentType 'application/json; charset=utf-8' -ErrorVariable $RestException -SkipCertificateCheck
    $token = Invoke-RestMethod -Method Post -Uri $tokensUri -Body (ConvertTo-Json $tokenObject) -ContentType 'application/json; charset=utf-8' -ErrorVariable $RestException 
}
catch
{
   ## $error = ConvertFrom-Json $RestException.ErrorDetails.Message
    ##Write-Host ("Unable to fetch token for user '" + $user + "'")
    ##Write-Host ("Error Code: " + $error.code)
    ##Write-Host ("Message: " + $error.message)
    Write-Host ("StatusCode: " + $_.Exception.Response.StatusCode.value__)
    Write-Host ("StatusDescription: " + $_.Exception.Response.StatusDescription)
    Write-Host ("Message: " + $_[0].message)
    ##$Global:OpConRESTAPIException = $_
    throw
    ##exit $_.Exception.Response.StatusCode.value__
}
Write-Host ("Token retrieved successfully, Id: " + $token.id + ", Valid Until: " + $token.validUntil)
return $token
}


function Get-OpConApiAuthHeader {
param(
    [string] $Token
    )
    $authHeader = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $authHeader.Add("Authorization", ("Token " + $Token))
    return $authHeader
}



function Login-RestApi {
[cmdletbinding()]
param(
    [string] $ApiUrl,
    [string] $OpConUser,
    [string] $OpConPassword
    )


    Write-Verbose ("Parameters =")
    Write-Verbose ("ApiUrl: " + $ApiUrl)
    Write-Verbose ("OpConUser: " + $OpConUser)
    Write-Verbose ("OpConPassword: (hidden)")


    $ApiUrl = $ApiUrl.ToLower().TrimEnd("/").TrimEnd("/api")


    Write-Host ("Logging in to OpCon REST API: " + $ApiUrl)


    $Global:OpconRESTApiUrl = $ApiUrl
    $Global:OpconRESTApiUser = $OpConUser
    $Global:OpConRESTApiPassword = $OpConPassword
    $token = Get-OpConApiToken -Url $ApiUrl -User $OpConUser -Password $OpConPassword
    $Global:OpconRESTApiToken = $token.id


    $Global:OpconRESTApiAuthHeader = Get-OpConApiAuthHeader -Token $token.id
    Write-Host ('Token successfully stored for future calls in session.')
} 

 
 function GetJobListToUpdateInTrances
 {
 [cmdletbinding()]
 param(
    [string] $Status,
    [string] $Dates,
    [string] $JobType
    )

        $offset =0; # start from 
	    $size=0; # number of jobs retrieved each call
	    $limit=1000; # max number of record x trance
        $jobListFull = New-Object System.Collections.Generic.List[System.Object]

        
        Write-Host ("===> Start retrieving jobs in trances of $limit ")
        

        do{
            $jobUri = -join($Url, "/api/dailyJobs/?dates=$Dates&scheduleIds=$($daily.id)&status=$Status&jobType=$JobType&limit=$limit&offset=$offset")
            #$jobUri = -join($Url, "/api/dailyJobs/?dates=$Dates&scheduleIds=$($daily.id)&jobType=$JobType&limit=$limit&offset=$offset")
            $jobResponse = Invoke-OpConRestMethod -Uri $jobUri -Method GET -ContentType "application/json"-Headers $Global:OpconRESTApiAuthHeader -ErrorVariable $RestException; 
            #Write-Host ("Job URI : $($jobUri)")
                       
            Foreach($job in $jobResponse)
            {
                #$entry= "$($job.schedule.name) - $($job.id)"
                $jobListFull.Add($job)
                #$jobListFull.Add(@{id = $job.id})
               #Write-Host ("Job name : $($job.id)")
            }
            
            
            $size = $jobResponse.Length;
            $jobListFullsize = $jobListFull.Count
            Write-Host ("Partial/Total retrieved n.: $size/$jobListFullsize")

            $offset+=$limit;
            if ($size -lt $limit)
            {
            	$size = 0;
            }
            # If is necessary a delay between calls uncomment and tune the line below
            # Start-Sleep -s 5
        }While ($size -gt 0)

           
        if ($jobListFull.Count -gt 0)
        {
            Write-host ("Total jobs retrieved : $($jobListFull.Count)")
		}
		
        return,   $jobListFull      
}


function TryParseDate{
    [cmdletbinding()]
    param(
       [object] $inDate,
       [string] $format
       )
       $outDate = ""
       try {
        $outDate =[datetime]::parseexact($($inDate), $($format),$null)
       }
       catch {
        $outDate = "?"
       }
    return $outDate
} 



 function DisplayDailyJobs
 {
 [cmdletbinding()]
 param(
    [string] $Status,
    [string] $Action,
    [string] $Dates,
    [string] $JobType
    )

        #Get job list to update in trances
        $jobList = GetJobListToUpdateInTrances -Status $Status  -Dates $Dates -JobType $JobType

        #$lst = jobList.chunked(3)

        Foreach($job in $jobList)
        {
            #Write-Host ("Schedule: $($job.schedule.name) Job : $($job.name)")

            #$dt = [datetime]::parseexact($($job.schedule.date), 'yyyy-MM-ddTHH:mm:ss.fffffffzzz',$null)
            $dt = TryParseDate -inDate $job.schedule.date -format  'yyyy-MM-ddTHH:mm:ss.fffffffzzz' 
            $StartTimeProgrammed = TryParseDate -inDate $job.computedStartTime.ProgrammedFor -format 'yyyy-MM-ddTHH:mm:ss.fffffffzzz'

			$StartTimeTime =TryParseDate -inDate $job.computedStartTime.time -format 'yyyy-MM-ddTHH:mm:ss.fffffffzzz'
            $StartTimeTimeEstimated = ""
            if ($job.computedStartTime.isEstimated -contains "True") {
                $StartTimeTimeEstimated =  "*"
            }

			$EndTimeProgrammed = TryParseDate -inDate $job.computedEndTime.ProgrammedFor -format 'yyyy-MM-ddTHH:mm:ss.fffffffzzz'
			$EndTimeTime = TryParseDate -inDate $job.computedEndTime.time -format 'yyyy-MM-ddTHH:mm:ss.fffffffzzz'
			$EndTimeTimeEstimated = ""
            if ($job.computedEndTime.isEstimated -contains "True") {
                $EndTimeTimeEstimated =  "*"
            }

            $DurationEstimated = ""
            if ($job.computedDuration.isEstimated -contains "True") {
                $DurationEstimated =  "*"
            }

            $DateStr = $dt.ToString("dd/MM/yyyy")
            
            $htmlCellStyle =  ""
            if ($job.status.description -contains "Failed") {
                $htmlCellStyle =  "style='background:#FF0000'"
            }

            $dataRow = "
            </tr>
            <td>$($DateStr) </td>
            <td>$($job.schedule.name) </td>
            <td>$($job.name)</td>
            <td>$($job.primaryMachine.name)</td>
            <td>$($job.jobType.description)</td>
            <td $($htmlCellStyle)>$($job.status.description)</td>
            <td>$($StartTimeProgrammed)</td>
            <td>$($EndTimeProgrammed)</td>
            <td>$($StartTimeTime) $($StartTimeTimeEstimated)</td>
            <td>$($EndTimeTime) $($EndTimeTimeEstimated)</td>
            <td>$($job.computedDuration.duration/1000/60) $($DurationEstimated)</td>
            </tr>"

            $FinalData += $datarow         
        }

        
        (Get-Content -path HtmlTemplate.html -Raw) -replace 'ROWS_PLACE_HOLDER',$FinalData | Out-File -FilePath outfile.html
}


$SecPass = $null;
$clearPassword = ""
if ($OpConPassword.Length -eq 0 ) {
    $SecPass = Read-Host 'What is your password?' -AsSecureString    
    $clearPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
                     [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecPass))
}
else {
    $clearPassword = $OpConPassword
}

Login-RestApi -ApiUrl $ServerUrl -OpConUser $OpConUser -OpConPassword $clearPassword 

DisplayDailyJobs -Status $OpJobStatus  -Dates $OpScheduleDate -JobType "" 

.\outfile.html
