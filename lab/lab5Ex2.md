## Exercise 3: Optimizing data warehouse query performance in Azure Synapse Analytics

### Task 1: Identify performance issues related to tables

1. Select the **Develop** hub.

    ![The develop hub is highlighted.](media/develop-hub.png "Develop hub")

2. From the **Develop** menu, select the **+** button **(1)** and choose **SQL Script (2)** from the context menu.

    ![The SQL script context menu item is highlighted.](media/synapse-studio-new-sql-script.png "New SQL script")

3. In the toolbar menu, connect to the **SQLPool01** database to execute the query.

    ![The connect to option is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-connect.png "Query toolbar")

4. In the query window, replace the script with the following to count the number of records in a heap table:

    ```sql
    SELECT  
        COUNT_BIG(*)
    FROM
        [wwi_poc].[Sale]
    ```

5. Select **Run** from the toolbar menu to execute the SQL command.

    ![The run button is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-run.png "Run")

    The script takes up to **15 seconds** to execute and returns a count of ~982 million rows in the table.

    > If the script is still running after 45 seconds, click on Cancel.

    > **Note**: _Do not_ execute this query ahead of time. If you do, the query may run faster during subsequent executions.

    ![The COUNT_BIG result is displayed.](media/count-big1.png "SQL script")

6. In the query window, replace the script with the following (more complex) statement:

    ```sql
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_poc].[Sale] S
        GROUP BY
            S.CustomerId
    ) T
    OPTION (LABEL = 'Lab: Heap')
    ```

7. Select **Run** from the toolbar menu to execute the SQL command.

    ![The run button is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-run.png "Run")
  
    The script takes up to **60 seconds** to execute and returns the result. There is clearly something wrong with the `Sale_Heap` table that induces the performance hit.

    > If the script is still running after 90 seconds, click on Cancel.

    ![The query execution time of 51 seconds is highlighted in the query results.](media/sale-heap-result.png "Sale Heap result")

    > Note the OPTION clause used in the statement. This comes in handy when you're looking to identify your query in the [sys.dm_pdw_exec_requests](https://docs.microsoft.com/sql/relational-databases/system-dynamic-management-views/sys-dm-pdw-exec-requests-transact-sql) DMV.
    >
    >```sql
    >SELECT  *
    >FROM    sys.dm_pdw_exec_requests
    >WHERE   [label] = 'Lab: Heap';
    >```

8. Select the **Data** hub.

    ![The data hub is highlighted.](media/data-hub.png "Data hub")

9. Expand the **SQLPool01** database and its list of tables. Right-click **`wwi_poc.Sale` (1)**, select **New SQL script (2)**, then select **CREATE (3)**.

    ![The CREATE script is highlighted for the Sale table.](media/sale-heap-create.png "Create script")

10. Take a look at the script used to create the table:

    ```sql
    CREATE TABLE [wwi_poc].[Sale]
    ( 
        [TransactionId] [uniqueidentifier]  NOT NULL,
        [CustomerId] [int]  NOT NULL,
        [ProductId] [smallint]  NOT NULL,
        [Quantity] [tinyint]  NOT NULL,
        [Price] [decimal](9,2)  NOT NULL,
        [TotalAmount] [decimal](9,2)  NOT NULL,
        [TransactionDateId] [int]  NOT NULL,
        [ProfitAmount] [decimal](9,2)  NOT NULL,
        [Hour] [tinyint]  NOT NULL,
        [Minute] [tinyint]  NOT NULL,
        [StoreId] [smallint]  NOT NULL
    )
    WITH
    (
        DISTRIBUTION = ROUND_ROBIN,
        HEAP
    )
    ```

    > **Note**: *Do not* run this script! It is just for demonstration purposes to review the schema.

    You can immediately spot at least two reasons for the performance hit:

    - The `ROUND_ROBIN` distribution
    - The `HEAP` structure of the table

    > **NOTE**
    >
    > In this case, when we are looking for fast query response times, the heap structure is not a good choice as we will see in a moment. Still, there are cases where using a heap table can help performance rather than hurting it. One such example is when we're looking to ingest large amounts of data into the SQL database associated with the dedicated SQL pool.

    If we were to review the query plan in detail, we would clearly see the root cause of the performance problem: inter-distribution data movements.

11. Run the same script as the one you've run at step 2, but this time with the `EXPLAIN WITH_RECOMMENDATIONS` line before it:

    ```sql
    EXPLAIN WITH_RECOMMENDATIONS
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_poc].[Sale] S
        GROUP BY
            S.CustomerId
    ) T
    ```

    The `EXPLAIN WITH_RECOMMENDATIONS` clause returns the query plan for an Azure Synapse Analytics SQL statement without running the statement. Use EXPLAIN to preview which operations will require data movement and to view the estimated costs of the query operations. By default, you will get the execution plan in XML format, which you can export to other formats like CSV or JSON. **Do not** select `Query Plan` from the toolbar as it will try do download the query plan and open it in SQL Server Management Studio.

    Your query should return something similar to:

    ```xml
    <data><row><explain><?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="4" number_distributions="60" number_distributions_per_node="15">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_poc].[Sale] S
        GROUP BY
            S.CustomerId
    ) T</sql>
    <materialized_view_candidates>
        <materialized_view_candidates with_constants="False">CREATE MATERIALIZED VIEW View1 WITH (DISTRIBUTION = HASH([Expr0])) AS
    SELECT [S].[CustomerId] AS [Expr0],
        SUM([S].[TotalAmount]) AS [Expr1]
    FROM [wwi_poc].[Sale] [S]
    GROUP BY [S].[CustomerId]</materialized_view_candidates>
    </materialized_view_candidates>
    <dsql_operations total_cost="4.0656044" total_number_operations="5">
        <dsql_operation operation_type="RND_ID">
        <identifier>TEMP_ID_56</identifier>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">CREATE TABLE [qtabledb].[dbo].[TEMP_ID_56] ([CustomerId] INT NOT NULL, [col] DECIMAL(38, 2) NOT NULL ) WITH(DISTRIBUTED_MOVE_FILE='');</sql_operation>
        </sql_operations>
        </dsql_operation>
        <dsql_operation operation_type="SHUFFLE_MOVE">
        <operation_cost cost="4.0656044" accumulative_cost="4.0656044" average_rowsize="13" output_rows="78184.7" GroupNumber="11" />
        <source_statement>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT SUM([T2_1].[TotalAmount]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [SQLPool01].[wwi_poc].[Sale] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 4, MIN_GRANT_PERCENT = [MIN_GRANT], DISTRIBUTED_MOVE(N''))</source_statement>
        <destination_table>[TEMP_ID_56]</destination_table>
        <shuffle_columns>CustomerId;</shuffle_columns>
        </dsql_operation>
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) SUM([T2_1].[col]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [qtabledb].[dbo].[TEMP_ID_56] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 4, MIN_GRANT_PERCENT = [MIN_GRANT])</select>
        </dsql_operation>
        <dsql_operation operation_type="ON">
        <location permanent="false" distribution="AllDistributions" />
        <sql_operations>
            <sql_operation type="statement">DROP TABLE [qtabledb].[dbo].[TEMP_ID_56]</sql_operation>
        </sql_operations>
        </dsql_operation>
    </dsql_operations>
    </dsql_query></explain></row></data>
    ```

    Notice the details of the internal layout of the MPP system:

    `<dsql_query number_nodes="4" number_distributions="60" number_distributions_per_node="15">`

    This layout is given by the current Date Warehouse Units (DWU) setting. In the setup used for the example above, we were running at `DW2000c` which means that there are 4 physical nodes to service the 60 distributions, giving a number of 15 distributions per physical node. Depending on your own DWU settings, these numbers will vary.

    The query plan indicates data movement is required. This is indicated by the `SHUFFLE_MOVE` distributed SQL operation.

    Data movement is an operation where parts of the distributed tables are moved to different nodes during query execution. This operation is required where the data is not available on the target node, most commonly when the tables do not share the distribution key. The most common data movement operation is shuffle. During shuffle, for each input row, Synapse computes a hash value using the join columns and then sends that row to the node that owns that hash value. Either one or both sides of join can participate in the shuffle. The diagram below displays shuffle to implement join between tables T1 and T2 where neither of the tables is distributed on the join column col2.

    ![Shuffle move conceptual representation.](media/shuffle-move.png "Shuffle move")

    Let's dive now into the details provided by the query plan to understand some of the problems our current approach has. The following table contains the description of every operation mentioned in the query plan:

    Operation | Operation Type | Description
    ---|---|---
    1 | RND_ID | Identifies an object that will be created. In our case, it's the `TEMP_ID_76` internal table.
    2 | ON | Specifies the location (nodes or distributions) where the operation will occur. `AllDistributions` means here the operation will be performed on each of the 60 distributions of the SQL pool. The operation will be a SQL operation (specified via `<sql_operations>`) that will create the  `TEMP_ID_76` table.
    3 | SHUFFLE_MOVE | The list of shuffle columns contains only one column which is `CustomerId` (specified via `<shuffle_columns>`). The values will be distributed to the hash owning distributions and saved locally in the `TEMP_ID_76` tables. The operation will output an estimated number of 41265.25 rows (specified via `<operation_cost>`). According to the same section, the average resulting row size is 13 bytes.
    4 | RETURN | Data resulting from the shuffle operation will be collected from all distributions (see `<location>`) by querying the internal temporary table `TEMP_ID_76`.
    5 | ON | The `TEMP_ID_76` will be deleted from all distributions.

    It becomes clear now what is the root cause of the performance problem: the inter-distribution data movements. This is actually one of the simplest examples given the small size of the data that needs to be shuffled. You can imagine how much worse things become when the shuffled row size becomes larger.

    You can learn more about the structure of the query plan generated by the EXPLAIN statement [here](https://docs.microsoft.com/en-us/sql/t-sql/queries/explain-transact-sql?view=azure-sqldw-latest).

12. Besides the `EXPLAIN` statement, you can also understand the plan details using the `sys.dm_pdw_request_steps` DMV.

    Query the `sys.dm_pdw_exec_requests` DMW to find your query id (this is for the query you executed previously at step 6):

    ```sql
    SELECT  
        *
    FROM    
        sys.dm_pdw_exec_requests
    WHERE   
        [label] = 'Lab: Heap'
    ```

    The result contains, among other things, the query id (`Request_id`), the label, and the original SQL statement:

    ![Retrieving the query id](./media/lab3_query_id.png)

13. With the query id (`QID5418` in this case, **substitute with your id**) you can now investigate the individual steps of the query:

    ```sql
    SELECT
       *
    FROM
        sys.dm_pdw_request_steps
    WHERE
        request_id = 'QID5418'
    ORDER BY
       step_index
    ```

    The steps (indexed 0 to 4) are matching operations 2 to 6 from the query plan. Again, the culprit stands out: the step with index 2 describes the inter-partition data movement operation. By looking at the `TOTAL_ELAPSED_TIME` column one can clearly tell the largest part of the query time is generated by this step. **Take note of the step index** for the next query.

    ![Query execution steps](./media/lab3_shuffle_move_2.png)

14. Get more details on the problematic step using the following SQL statement (substitute the `request_id` and `step_index` with your values):

    ```sql
    SELECT
    *
    FROM
        sys.dm_pdw_sql_requests
    WHERE
        request_id = 'QID5418'
        AND step_index = 2
    ```

    The results of the statement provide details about what happens on each distribution within the SQL pool.

    ![Query execution step details](./media/lab3_shuffle_move_3.png)

15. Finally, you can use the following SQL statement to investigate data movement on the distributed databases (substitute the `request_id` and `step_index` with your values):

    ```sql
    SELECT
        *
    FROM
        sys.dm_pdw_dms_workers
    WHERE
        request_id = 'QID5418'
        AND step_index = 2
    ORDER BY
        distribution_id
    ```

    The results of the statement provide details about data being moved at each distribution. The `ROWS_PROCESSED` column is especially useful here to get an estimate of the magnitude of the data movement happening when the query is executed.

    ![Query execution step data movement](./media/lab3_shuffle_move_4.png)

### Task 2: Improve table structure with hash distribution and columnstore index

1. Select the **Develop** hub.

    ![The develop hub is highlighted.](media/develop-hub.png "Develop hub")

2. From the **Develop** menu, select the **+** button **(1)** and choose **SQL Script (2)** from the context menu.

    ![The SQL script context menu item is highlighted.](media/synapse-studio-new-sql-script.png "New SQL script")

3. In the toolbar menu, connect to the **SQLPool01** database to execute the query.

    ![The connect to option is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-connect.png "Query toolbar")

4. In the query window, replace the script with the following to create an improved version of the table using CTAS (Create Table As Select):

     ```sql
    CREATE TABLE [wwi_perf].[Sale_Hash]
    WITH
    (
        DISTRIBUTION = HASH ( [CustomerId] ),
        CLUSTERED COLUMNSTORE INDEX
    )
    AS
    SELECT
        *
    FROM
        [wwi_poc].[Sale]
    ```

5. Select **Run** from the toolbar menu to execute the SQL command.

    ![The run button is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-run.png "Run")

    The query will take around **10 minutes** to complete. While this is running, read the rest of the lab instructions to familiarize yourself with the content.

    > **NOTE**
    >
    > CTAS is a more customizable version of the SELECT...INTO statement.
    > SELECT...INTO doesn't allow you to change either the distribution method or the index type as part of the operation. You create the new table by using the default distribution type of ROUND_ROBIN, and the default table structure of CLUSTERED COLUMNSTORE INDEX.
    >
    > With CTAS, on the other hand, you can specify both the distribution of the table data as well as the table structure type.

6. In the query window, replace the script with the following to see performance improvements:

    ```sql
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
        GROUP BY
            S.CustomerId
    ) T
    ```

7. Select **Run** from the toolbar menu to execute the SQL command.

    ![The run button is highlighted in the query toolbar.](media/synapse-studio-query-toolbar-run.png "Run")

    You should see a performance improvement executing against the new Hash table compared to the first time we ran the script against the Heap table. In our case, the query executed in about 8 seconds.

    ![The script run time of 6 seconds is highlighted in the query results.](media/sale-hash-result.png "Hash table results")

8. Run the following EXPLAIN statement again to get the query plan (do not select `Query Plan` from the toolbar as it will try do download the query plan and open it in SQL Server Management Studio):

    ```sql
    EXPLAIN
    SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
        GROUP BY
            S.CustomerId
    ) T
    ```

    The resulting query plan is clearly much better than the previous one, as there is no more inter-distribution data movement involved.

    ```xml
    <data><row><explain><?xml version="1.0" encoding="utf-8"?>
    <dsql_query number_nodes="5" number_distributions="60" number_distributions_per_node="12">
    <sql>SELECT TOP 1000 * FROM
    (
        SELECT
            S.CustomerId
            ,SUM(S.TotalAmount) as TotalAmount
        FROM
            [wwi_perf].[Sale_Hash] S
        GROUP BY
            S.CustomerId
    ) T</sql>
    <dsql_operations total_cost="0" total_number_operations="1">
        <dsql_operation operation_type="RETURN">
        <location distribution="AllDistributions" />
        <select>SELECT [T1_1].[CustomerId] AS [CustomerId], [T1_1].[col] AS [col] FROM (SELECT TOP (CAST ((1000) AS BIGINT)) SUM([T2_1].[TotalAmount]) AS [col], [T2_1].[CustomerId] AS [CustomerId] FROM [SQLPool01].[wwi_perf].[Sale_Hash] AS T2_1 GROUP BY [T2_1].[CustomerId]) AS T1_1
    OPTION (MAXDOP 4)</select>
        </dsql_operation>
    </dsql_operations>
    </dsql_query></explain></row></data>
    ```

9. Try running a more complex query and investigate the execution plan and execution steps. Here is an example of a more complex query you can use:

    ```sql
    SELECT
        AVG(TotalProfit) as AvgMonthlyCustomerProfit
    FROM
    (
        SELECT
            S.CustomerId
            ,D.Year
            ,D.Month
            ,SUM(S.TotalAmount) as TotalAmount
            ,AVG(S.TotalAmount) as AvgAmount
            ,SUM(S.ProfitAmount) as TotalProfit
            ,AVG(S.ProfitAmount) as AvgProfit
        FROM
            [wwi_perf].[Sale_Partition01] S
            join [wwi].[Date] D on
                D.DateId = S.TransactionDateId
        GROUP BY
            S.CustomerId
            ,D.Year
            ,D.Month
    ) T
    ```

### Task 4: Improve further the table structure with partitioning

Table partitions enable you to divide your data into smaller groups of data. Partitioning can benefit data maintenance and query performance. Whether it benefits both or just one is dependent on how data is loaded and whether the same column can be used for both purposes, since partitioning can only be done on one column.

Date columns are usually good candidates for partitioning tables at the distributions level. In the case of Tailwind Trader's sales data, partitioning based on the `TransactionDateId` column seems to be a good choice.

The dedicated SQL pool already contains two versions of the `Sale` table that have been partitioned using `TransactionDateId`. These tables are `[wwi_perf].[Sale_Partition01]` and `[wwi_perf].[Sale_Partition02]`. Below are the CTAS queries that have been used to create these tables.

1. In the query window, replace the script with the following CTAS queries that create the partition tables (**do not** execute):

    ```sql
    CREATE TABLE [wwi_perf].[Sale_Partition01]
    WITH
    (
      DISTRIBUTION = HASH ( [CustomerId] ),
      CLUSTERED COLUMNSTORE INDEX,
      PARTITION
      (
        [TransactionDateId] RANGE RIGHT FOR VALUES (
                20190101, 20190201, 20190301, 20190401, 20190501, 20190601, 20190701, 20190801, 20190901, 20191001, 20191101, 20191201)
      )
    )
    AS
    SELECT
      *
    FROM	
      [wwi_perf].[Sale_Heap]
    OPTION  (LABEL  = 'CTAS : Sale_Partition01')

    CREATE TABLE [wwi_perf].[Sale_Partition02]
    WITH
    (
      DISTRIBUTION = HASH ( [CustomerId] ),
      CLUSTERED COLUMNSTORE INDEX,
      PARTITION
      (
        [TransactionDateId] RANGE RIGHT FOR VALUES (
                20190101, 20190401, 20190701, 20191001)
      )
    )
    AS
    SELECT *
    FROM
        [wwi_perf].[Sale_Heap]
    OPTION  (LABEL  = 'CTAS : Sale_Partition02')
    ```

    > **Note**
    >
    > These queries have already been run on the dedicated SQL pool. **Do not** execute the script.

Notice the two partitioning strategies we've used here. The first partitioning scheme is month-based and the second is quarter-based **(3)**.

![The queries are highlighted as described.](media/partition-ctas.png "Partition CTAS queries")

#### Task 4.1: Table distributions

As you can see, the two partitioned tables are hash-distributed **(1)**. A distributed table appears as a single table, but the rows are actually stored across 60 distributions. The rows are distributed with a hash or round-robin algorithm.

The types of distributions are:

- **Round-robin distributed**: Distributes table rows evenly across all distributions at random.
- **Hash distributed**: Distributes table rows across the Compute nodes by using a deterministic hash function to assign each row to one distribution.
- **Replicated**: Full copy of table accessible on each Compute node.

A hash-distributed table distributes table rows across the Compute nodes by using a deterministic hash function to assign each row to one distribution.

Since identical values always hash to the same distribution, the data warehouse has built-in knowledge of the row locations.

Dedicated SQL pool uses this knowledge to minimize data movement during queries, which improves query performance. Hash-distributed tables work well for large fact tables in a star schema. They can have very large numbers of rows and still achieve high performance. There are, of course, some design considerations that help you to get the performance the distributed system is designed to provide.

*Consider using a hash-distributed table when:*

- The table size on disk is more than 2 GB.
- The table has frequent insert, update, and delete operations.

#### Task 4.2: Indexes

Looking at the query, also notice that both partitioned tables are configured with a **clustered columnstore index (2)**. There are different types of indexes you can use in dedicated SQL pool:

- **Clustered Columnstore index (Default Primary)**: Offers the highest level of data compression and best overall query performance.
- **Clustered index (Primary)**: Is performant for looking up a single to few rows.
- **Heap (Primary)**: Benefits from faster loading and landing temporary data. It is best for small lookup tables.
- **Nonclustered indexes (Secondary)**: Enable ordering of multiple columns in a table and allows multiple nonclustered on a single table. These can be created on any of the above primary indexes and offer more performant lookup queries.

By default, dedicated SQL pool creates a clustered columnstore index when no index options are specified on a table. Clustered columnstore tables offer both the highest level of data compression as well as the best overall query performance. They will generally outperform clustered index or heap tables and are usually the best choice for large tables. For these reasons, clustered columnstore is the best place to start when you are unsure of how to index your table.

There are a few scenarios where clustered columnstore may not be a good option:

- Columnstore tables do not support `varchar(max)`, `nvarchar(max)`, and `varbinary(max)`. Consider heap or clustered index instead.
- Columnstore tables may be less efficient for transient data. Consider heap and perhaps even temporary tables.
- Small tables with less than 100 million rows. Consider heap tables.

#### Task 4.3: Partitioning

Again, with this query, we partition the two tables differently **(3)** so we can evaluate the performance difference and decide which partitioning strategy is best long-term. The one we ultimately go with depends on various factors with Tailwind Trader's data. You may decide to keep both to optimize query performance, but then you double the data storage and maintenance requirements for managing the data.

Partitioning is supported on all table types.

The **RANGE RIGHT** option that we use in the query **(3)** is used for time partitions. RANGE LEFT is used for number partitions.

The primary benefits to partitioning is that it:

- Improves efficiency and performance of loading and querying by limiting the scope to a subset of data.
- Offers significant query performance enhancements where filtering on the partition key can eliminate unnecessary scans and eliminate I/O (input/output operations).

The reason we have created two tables with different partition strategies **(3)** is to experiment with proper sizing.

While partitioning can be used to improve performance, creating a table with too many partitions can hurt performance under some circumstances. These concerns are especially true for clustered columnstore tables, like we created here. For partitioning to be helpful, it is important to understand when to use partitioning and the number of partitions to create. There is no hard and fast rule as to how many partitions are too many, it depends on your data and how many partitions you are loading simultaneously. A successful partitioning scheme usually has tens to hundreds of partitions, not thousands.

*Supplemental information*:

When creating partitions on clustered columnstore tables, it is important to consider how many rows belong to each partition. For optimal compression and performance of clustered columnstore tables, a minimum of 1 million rows per distribution and partition is needed. Before partitions are created, dedicated SQL pools already divides each table into 60 distributed databases. Any partitioning added to a table is in addition to the distributions created behind the scenes. Using this example, if the sales fact table contained 36 monthly partitions, and given that dedicated SQL pool has 60 distributions, then the sales fact table should contain 60 million rows per month, or 2.1 billion rows when all months are populated. If a table contains fewer than the recommended minimum number of rows per partition, consider using fewer partitions in order to increase the number of rows per partition.
