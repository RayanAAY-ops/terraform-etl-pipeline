import os
import boto3
import pytest
import json
import requests
# Sample code for listing S3 buckets and calling an API

DST_BUCKET = "etl-pipeline-iac-bucket-01072024"
REGION = os.environ.get("AWS_DEFAULT_REGION")
API_KEY = os.environ.get("API_KEY")
URL = "https://data.opensanctions.org/contrib/everypolitician/countries.json"

s3 = boto3.client("s3", region_name=REGION)

def test_list_s3_buckets():
    response_s3 = s3.list_buckets(MaxBuckets=10)
    assert response_s3['ResponseMetadata']['HTTPStatusCode'] == 200

def test_fetch_data():
    response = requests.get(URL)
    assert response.status_code == 200



#response = s3.get_object(Bucket=DST_BUCKET, Key="politicians/Algeria/2024-10-07/Algeria_2024-10-07.json")
#object_content = response["Body"].read().decode("utf-8")

#print(response)
#print(len(object_content))

