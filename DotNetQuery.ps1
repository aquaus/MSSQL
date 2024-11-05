try
    {
        Add-Type -Path ".\bin\Microsoft.Identity.Client.dll" -ErrorAction Stop #microsoft.identity.client.4.66.1.nupkg
        Add-Type -Path ".\bin\Microsoft.Data.SqlClient.dll" -ErrorAction Stop #microsoft.data.sqlclient.5.2.0.nupkg   / microsoft.data.sqlclient.sni.runtime.5.2.0.nupkg
        Add-Type -Path ".\bin\Microsoft.SqlServer.Server.dll" -ErrorAction Stop #microsoft.sqlserver.server.1.0.0.nupkg
    }
    catch [System.Reflection.ReflectionTypeLoadException]
    {
        Write-Host "Message: $($_.Exception.Message)"
        Write-Host "StackTrace: $($_.Exception.StackTrace)"
        Write-Host "LoaderExceptions: $($_.Exception.LoaderExceptions)"
    } 

using namespace System.Data
using namespace Microsoft.Data
using namespace Microsoft.Data.SqlClient
using namespace Microsoft.SqlServer.Server
using namespace Microsoft.Data.SqlClient.Server
using namespace Microsoft.Data.SqlTypes
using namespace Microsoft.Data.Sql

Function Invoke-SQLQuery {
    Param (
        [Parameter(Mandatory = $true, ParameterSetName="NoLogin")]
        [Parameter(Mandatory = $false, ParameterSetName="Login")]
        [string]$ConnString = $DefaultConnectionString,
        [Parameter(Mandatory = $true, ParameterSetName="NoLogin")]
        [Parameter(Mandatory = $true, ParameterSetName="Login")]
        [string]$Query,
        [Parameter(Mandatory = $true, ParameterSetName="Login")]
        [string]$SQLLogin
    )

    $sqlConn = New-Object System.Data.SqlClient.SqlConnection
    $sqlConn.ConnectionString = $ConnString

    If ($PsCmdlet.ParameterSetName -eq "Login") {
        $sqlcred = New-Object System.Data.SqlClient.SqlCredential($SQLLogin.Username, $SQLLogin.Password)

        $sqlConn.Credential = $sqlcred
    }

    $sqlConn.Open()

    $command = $sqlconn.CreateCommand()
    $command.CommandText = $Query

    $dataSet = New-Object System.Data.DataSet
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $adapter.Fill($dataSet) | Out-Null
    $sqlConn.Close()
    $dataSet.Tables
}

Function Invoke-SQLStoredProcedure {
    param(
        [string]$connectionString = $DefaultConnectionString,
        [string]$StoredProcedure,
        [int32]$timeout = 60,
        [hashtable]$parameters = @{},
        [switch]$NoResults
    )
    
    try {
        #$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection = New-Object Microsoft.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $connectionString
        
        #$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd = New-Object Microsoft.Data.SqlClient.SqlCommand

        $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure
        $SqlCmd.CommandText = $StoredProcedure
        $SqlCmd.CommandTimeout = $timeout
        $SqlCmd.Connection = $SqlConnection

        If ($parameters.count -gt 0) {
        # Add parameters
                    $paramArray = $SqlCmd.parameters

                    ForEach ($parameterName in $parameters.Keys) {
                        Switch ($parameters[$parameterName].gettype().name) {
                            "String" {$type = [System.Data.SqlDbType]::NVarChar}
                            "Int32" {$type = [System.Data.SqlDbType]::Int}
                            "DateTime" {$type = [System.Data.SqlDbType]::DateTime2}
                            "float"  {$type = [System.Data.SqlDbType]::Decimal}
                            "boolean" {$type = [System.Data.SqlDbType]::Bool}
                            Default {$type = [System.Data.SqlDbType]::NVarChar}
                        }

                        $param = New-Object Microsoft.Data.SqlClient.SqlParameter #System.Data.SqlClient.SqlParameter

                        $param.ParameterName = "@$parameterName"

                        $param.SqlDbType = $type

                        #$param = New-Object System.Data.SqlClient.SqlParameter("@$parameterName", $type)
                        If ($parameters[$parameterName] -eq $null) {
                            $param.Value =  [DBNull]::Value
                        } Else {
                            $param.Value = $parameters[$parameterName]
                        }
                
                        $SqlCmd.Parameters.Add($param) | Out-Null
                    }
               
        }

    }
    catch {
        Write-Error $_
    }

    $SqlConnection.Open()

    $SqlAdapter = New-Object Microsoft.Data.SqlClient.SqlDataAdapter
    $SqlAdapter.SelectCommand = $SqlCmd

    $DataSet = New-Object System.Data.DataSet

    $SqlAdapter.Fill($DataSet) | Out-Null

    $SqlConnection.Close()
    If (!$NoResults) {
        $DataSet.Tables[0]
    }
    
}

