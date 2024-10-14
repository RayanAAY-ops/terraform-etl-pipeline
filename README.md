# terraform-etl-pipeline


# Glue 
Glue will recognize the delimiter, the format using the classifier, statistics about the table
the inference of column name and data type
A worker in AWS Glue is like a virtual machine or an entire computer with its own allocated resources, including CPU, memory, and disk storage. Each worker has its own processing power (vCPUs), memory, and disk, enabling it to perform tasks independently of other workers.

So when you're running an AWS Glue job with multiple workers, you're essentially running multiple virtual "computers" or machines in parallel to process your data. This allows you to scale your job by adding more workers to handle larger datasets or more complex transformations.

To recap:

Worker = Virtual machine/computer with a set amount of CPU, memory, and disk.
Multiple workers = Multiple parallel machines working on your Glue job.

How Spark Parallelization Works:
Worker: In AWS Glue, a worker is essentially a node (a machine) that has a specific amount of resources like CPU, memory, and disk space. For example, G.1X has 4 vCPUs and 16 GB of memory.

Executor: Each worker runs executors, which are responsible for running tasks (part of a Spark job). In AWS Glue, each worker typically runs one executor per worker. So, for example, if you have two G.1X workers, you’ll have two executors (one per worker).

Cores: Executors use cores to execute tasks in parallel. Each core can handle one task at a time. If your worker type has 4 vCPUs, it means that the executor on that worker will have 4 cores to run tasks in parallel.

Example: D.1X with 2 Workers
Worker type: D.1X workers have 4 vCPUs (cores) each.
Number of workers: 2 workers.
Total vCPUs (cores): 4 vCPUs (cores) per worker × 2 workers = 8 vCPUs (cores) in total.
With 8 vCPUs, your Spark job will have 8 cores available for parallelization. Spark will break the job into smaller tasks, and each task will be processed by one core, meaning you can run 8 tasks in parallel.

Important Considerations:
Executor per worker: By default in Glue, one executor per worker. So, if you have 2 D.1X workers, you’ll have 2 executors.

Task parallelism: Each executor will use all the available cores on its worker. For example, if each worker has 4 cores, the executor will be able to run 4 tasks in parallel on that worker.

Thus, with 2 workers, each having 4 cores, you can parallelize up to 8 tasks at once.

Key Points:
Spark uses cores for parallel execution: 1 core = 1 parallel task.
The number of cores per worker depends on the worker type. For example, D.1X has 4 vCPUs (cores).
If you have multiple workers, your total number of parallel tasks is the sum of cores across all workers.


# Athena requires a bucket to store the results
Before you run your first query, you need to set up a query result location in Amazon S3.

Exactly! By using Athena workgroups, you can allocate resources based on the specific needs of different teams or use cases. Here’s how you can manage resource allocation effectively:

Resource Allocation:

You can configure different workgroups to have varying limits on the amount of data scanned per query. For instance:
Data Team Workgroup: This workgroup could have higher limits for data scanning since the data team might run larger and more complex queries on extensive datasets.
Business Team Workgroup: For teams that typically query smaller datasets, you can set stricter limits to prevent excessive resource usage and control costs.
Cost Management:

By limiting the data scanned for smaller queries, you reduce the cost incurred by those teams. This ensures that only the necessary resources are used, which can lead to significant cost savings.
Performance Optimization:

You can tune the performance for each workgroup based on the type of queries that are run. Teams that require faster results can be given priority by allowing them to scan larger datasets efficiently.
Isolation of Queries:

Queries from different teams can be isolated by assigning them to different workgroups. This allows for better management of query execution and resource usage without interference from other teams.
Monitoring and Reporting:

With separate workgroups, you can monitor the performance and cost associated with each group more effectively. This allows for data-driven decisions on resource allocation and optimization strategies.