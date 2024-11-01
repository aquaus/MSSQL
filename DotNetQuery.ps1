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
    Param ( 
        $StoredProcName,
        $parameters=@{},
        [string]$conn = $DefaultConnectionString,
        $timeout=60
    )
 
    $cmd= New-Object System.Data.SqlClient.SqlCommand

    $cmd.CommandType=[System.Data.CommandType]'StoredProcedure'
    $cmd.Connection=$conn
    $cmd.CommandText=$storedProcName
    $cmd.CommandTimeout=$timeout
    ForEach($p in $parameters.Keys){
        [Void] $cmd.Parameters.AddWithValue("@$p",$parameters[$p])
    }
     
    #$id=$cmd.ExecuteScalar()
    $adapter=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    $dataset=New-Object system.Data.DataSet
   
    $adapter.fill($dataset) | Out-Null
   
       #$reader = $cmd.ExecuteReader()
   
       #$results = @()
       #while ($reader.Read())
       #{
       #    write-host "reached" -ForegroundColor Green
       #}
   
    return $dataSet.Tables[0]
   }

