# ExecuteSQLWithRetry
Executes a given SQL statement or stored procedure with option to specify lock_timeout and max number of retries

```
EXEC dbo.ExecuteSQLWithRetry @sql = N'', --SQL statement or Stored proc to be execute. Required parameter.
                             @retryCount, --Max number of times to retry when @sql exceeds lock timeout. 1 by default.
                             @lockTimeoutms, --Lock timeout in milliseconds. 1000 by default.
                             @delaySeconds --Delay in seconds between each retry. 1 by default.
```
# Examples

Get current servername - use default values

```EXEC dbo.ExecuteSQLWithRetry @sql='SELECT @@SERVERNAME'```



Execute MyProc with lock_timeout of 10 seconds, retry up to 10 times, with a delay of 2 seconds between each retry attempt
```
EXEC dbo.ExecuteSQLWithRetry @sql = N'EXEC dbo.MyProc @ParamString=''value1'', @ParamInt=3', --Remember to escape quotes
                             @retryCount=10,
                             @lockTimeoutms=10000,
                             @delaySeconds=2
```


