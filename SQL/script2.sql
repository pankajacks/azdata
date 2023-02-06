IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'nyc_tlc_yellow_trip_ext')
DROP EXTERNAL TABLE nyc_tlc_yellow_trip_ext
GO

CREATE EXTERNAL TABLE nyc_tlc_yellow_trip_ext (
	[vendorID] varchar(8000),
	[tpepPickupDateTime] datetime2(7),
	[tpepDropoffDateTime] datetime2(7),
	[passengerCount] int,
	[tripDistance] float,
	[puLocationId] varchar(8000),
	[doLocationId] varchar(8000),
	[startLon] float,
	[startLat] float,
	[endLon] float,
	[endLat] float,
	[rateCodeId] int,
	[storeAndFwdFlag] varchar(8000),
	[paymentType] varchar(8000),
	[fareAmount] float,
	[extra] float,
	[mtaTax] float,
	[improvementSurcharge] varchar(8000),
	[tipAmount] float,
	[tollsAmount] float,
	[totalAmount] float
	)
	WITH (
    LOCATION = 'yellow/puYear=2015/puMonth=3/*.parquet',
	-- LOCATION = 'yellow/puYear=*/puMonth=*/*.parquet'
	DATA_SOURCE = [nyctlc_azureopendatastorage_blob_core_windows_net],
	FILE_FORMAT = [SynapseParquetFormat]
	)
GO
