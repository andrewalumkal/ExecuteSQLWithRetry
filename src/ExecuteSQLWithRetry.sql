
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.ExecuteSQLWithRetry 
	@sql NVARCHAR(max) = NULL,  --SQL statement or Stored proc to be executed. Required parameter.
	@retryCount INT = 1,	    --Max number of times to retry when @sql exceeds lock timeout. 1 by default.
	@lockTimeoutms INT = 1000,	--Lock timeout in milliseconds. 1000 by default.
	@delaySeconds INT = 1		--Delay in seconds between each retry. 1 by default.
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SessionCommand nvarchar(max);
	
		--Check parameters
		IF (@sql is NULL)
		BEGIN
			PRINT 'Please input the @sql to be executed'
			RETURN
		END

		IF (@retryCount is NULL)
		BEGIN
			SET @retryCount=1
		END

		IF (@lockTimeoutms is NULL)
		BEGIN
			SET @lockTimeoutms=1000
		END

		IF (@delaySeconds is NULL)
		BEGIN
			SET @delaySeconds=1
		END

		DECLARE @delay VARCHAR(10);
		SET @delay = (SELECT CONVERT(VARCHAR, DATEADD(second, @delaySeconds, 0), 114))

		--Set session command
		SET @SessionCommand = N'SET DEADLOCK_PRIORITY LOW; ';
		SET @SessionCommand += N'SET XACT_ABORT ON; ';
		SET @SessionCommand += N'SET LOCK_TIMEOUT '+ cast(@lockTimeoutms as varchar(10)) + N'; ';

		--PRINT @SessionCommand;


	DECLARE @currentTimeoutretry int = 1
	DECLARE @sqlToExecute NVARCHAR(max)
	SET @sqlToExecute = @SessionCommand + @sql


	WHILE @currentTimeoutretry <= @retryCount
		BEGIN
			BEGIN TRY

				EXEC sp_executesql @sqlToExecute
				RETURN

			END TRY

			BEGIN CATCH

				IF @@error IN ( 1222, 1205 ) --lock time out or deadlock
					BEGIN
						set @currentTimeoutretry += 1;
						WAITFOR DELAY @delay;
					END;

				ELSE
					BEGIN
						THROW;
					END
			END CATCH

		END

	DECLARE @currentProc NVARCHAR(200);
	DECLARE @errormsg NVARCHAR(max);

	SET @currentProc=(SELECT OBJECT_NAME(@@PROCID))
	SET @errormsg= @currentProc + ': ' + 'Command failed to execute within the specified @retryCount(' + CAST(@retryCount AS NVARCHAR(2)) + ') and @lockTimeoutms(' + CAST(@lockTimeoutms AS NVARCHAR(10)) + ')'

	RAISERROR(@errormsg,17,1)

END
GO
