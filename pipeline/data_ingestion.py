import json
import os
import boto3
import requests
from datetime import datetime 
from botocore.exceptions import ClientError

DST_BUCKET = "etl-pipeline-iac-bucket-01072024"
REGION = os.environ.get("AWS_DEFAULT_REGION")
API_KEY = os.environ.get("API_KEY")
URL = f"https://data.opensanctions.org/contrib/everypolitician/countries.json"

s3 = boto3.client("s3", region_name=REGION)

city_name_list = ["France", "Algeria", 'Spain']

def lambda_handler(event, context):
    print("Lambda function started.")
    
    # Attempt to create S3 directories
    try:
        create_s3_directories_based_on_city(s3, city_name_list, database_name_s3="politicians", bucket_name=DST_BUCKET)
        print("Created S3 directories.")
    except Exception as e:
        print(f"Error creating directories: {e}")

    # Attempt to get the current date
    try:
        date = get_time()[1]
        print(f"Current date: {date}")
    except Exception as e:
        print(f"Error getting time: {e}")

    # Attempt to populate S3 bucket
    try:
        populate_database_table_s3_bucket(s3, date, bucket_name=DST_BUCKET, city_name_list=city_name_list, database_name='politicians')
        print("Populated S3 bucket.")
    except Exception as e:
        print(f"Error populating bucket: {e}")
    
    return {"statusCode": 200, "body": "Function executed successfully."}

# create directories based on city name
def create_s3_directories_based_on_city(
    s3, city_name_list, database_name_s3="politicians", bucket_name=DST_BUCKET
):

    for city_name in city_name_list:
        table_name_s3_prefix = str(database_name_s3) + "/" + str(city_name)

        #  check if s3 object already exists
        try:
            s3.head_object(Bucket=bucket_name, Key=table_name_s3_prefix)
        except s3.exceptions.ClientError as e:
            if e.response["Error"]["Code"] == "404":
                # key doesn't exists
                s3.put_object(Bucket=bucket_name, Key=(table_name_s3_prefix + "/"))

                pass
        else:
            # Key exists, do nothing
            pass


#create_s3_directories_based_on_city(s3, city_name_list, database_name_s3="politicians", bucket_name=DST_BUCKET)

def fetch_api_data(url):

    response = requests.get(url)#, headers=headers, params=query)

    if response.status_code == 200:
        data = json.loads(response.text)
        return data
    else:
        raise Exception(f"Error fetching data: {response.text}")

#print(fetch_api_data(URL))
def get_time():
    dt = datetime.now()
    timestamp = str(datetime.timestamp(dt)).replace(".", "_")
    return timestamp, dt.strftime("%Y-%m-%d")


def populate_database_table_s3_bucket(
    s3, date, bucket_name=DST_BUCKET, city_name_list=city_name_list, database_name='politicians'
):

    try:
        all_data = fetch_api_data(URL)
        for table_name in city_name_list:
            file_name = f"{table_name}_{date}.json"
            data = [country_data for country_data in all_data if country_data.get("country") == table_name]
            s3_object_key = f"{database_name}/{table_name}/{date}/{file_name}"
            try:
                # Use head_object to check if the object already exists
                s3.head_object(Bucket=bucket_name, Key=s3_object_key)
                print(f"Object {s3_object_key} already exists in bucket {bucket_name}")
                continue
            except ClientError as e:
                if e.response['Error']['Code'] == '404':
                    try:
                        s3.put_object(
                            Bucket=bucket_name, Key=s3_object_key, Body=json.dumps(data)
                        )
                        print(f"Uploaded {s3_object_key} to bucket {bucket_name}.")

                    except:
                        print("error")  # Re-raise with more context

    except Exception as e:
        print(f"Error populating table '{table_name}': {e}")


populate_database_table_s3_bucket(s3, date=get_time()[1])
