import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

# Add 'DATABASE_NAME' and 'TABLE_NAME' to the arguments
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'DATABASE_NAME', 'TABLE_NAME', "DEST_BCKET_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Use the parameters in your Glue job
database_name = args['DATABASE_NAME']
table_name = args['TABLE_NAME']
output_bucket_name = args['DEST_BCKET_NAME']

# Script generated for node AWS Glue Data Catalog
AWSGlueDataCatalog_node1728313861962 = glueContext.create_dynamic_frame.from_catalog(
    database=database_name, 
    table_name=table_name, 
    transformation_ctx="AWSGlueDataCatalog_node1728313861962"
)

# Script generated for node Change Schema
ChangeSchema_node1728314130582 = ApplyMapping.apply(
    frame=AWSGlueDataCatalog_node1728313861962, 
    mappings=[
        ("name", "string", "name", "string"), 
        ("country", "string", "country", "string"), 
        ("code", "string", "code", "string"), 
        ("slug", "string", "slug", "string"), 
        #("legislatures", "array", "legislatures", "array"), 
        ("partition_0", "string", "partition_0", "string"), 
        ("partition_1", "string", "partition_1", "string"), 
        ("partition_2", "string", "partition_2", "string")
    ], 
    transformation_ctx="ChangeSchema_node1728314130582"
)

AmazonS3_node1728316632190 = glueContext.write_dynamic_frame.from_options(
    frame=ChangeSchema_node1728314130582, 
    connection_type="s3", 
    format="glueparquet", 
    connection_options={
        "path": f"s3://{output_bucket_name}", 
        "partitionKeys": ["partition_0", "partition_1"]
    }, 
    format_options={"compression": "snappy"}, 
    transformation_ctx="AmazonS3_node1728316632190"
)

job.commit()
