import json
import os
import boto3
import requests
from datetime import datetime 
from botocore.exceptions import ClientError
import hashlib
DST_BUCKET = "etl-pipeline-iac-bucket-09072024"
REGION = os.environ.get("AWS_DEFAULT_REGION")
API_KEY = os.environ.get("API_KEY")
URL = f"https://data.opensanctions.org/contrib/everypolitician/countries.json"

s3 = boto3.client("s3", region_name=REGION)



def lambda_handler(event, context):
    print(os.environ.get("data_hash"))