import json
import os
import boto3
import requests
from datetime import datetime 
from botocore.exceptions import ClientError
import hashlib
REGION = os.environ.get("AWS_DEFAULT_REGION")
API_KEY = os.environ.get("API_KEY")
URL = f"https://data.opensanctions.org/contrib/everypolitician/countries.json"


# Initialize the SSM/Lambda client
ssm = boto3.client('ssm', region_name=REGION)
lambda_client = boto3.client("lambda", region_name=REGION)

def get_initial_hash(parameter_name):
    try:
        # Retrieve the parameter value
        response = ssm.get_parameter(
            Name=parameter_name,
            WithDecryption=True  # Set to True if the parameter is of type SecureString
        )
        return response['Parameter']['Value']  # Extract the value from the response
    except ssm.exceptions.ParameterNotFound:
        print(f"Parameter '{parameter_name}' not found.")
    except Exception as e:
        print(f"Error retrieving parameter: {str(e)}")


def fetch_next_hash(url):

    response = requests.get(url)#, headers=headers, params=query)

    if response.status_code == 200:
        data = json.loads(response.text)
        metadata = {
            'last_update': response.headers.get('Last-Modified'),  # Last modified date
            'content_type': response.headers.get('Content-Type'),  # Content type
            'content_length': response.headers.get('Content-Length'),  # Length of the content
            'etag': response.headers.get('ETag')  # ETag for cache validation
        }

        hash_metadata = json.dumps(metadata, sort_keys=True)
        # Store hash in Parameter Store
        
        my_next_hash=hashlib.sha1(hash_metadata.encode('utf-8')).hexdigest()

        return my_next_hash
    else:
        raise Exception(f"Error fetching data: {response.text}")


def trigger_next_lambda():
    response = lambda_client.invoke(
        FunctionName='python_ingestion_lambda',  # Replace with your next Lambda function's name
        InvocationType='Event'  # Use 'Event' for asynchronous invocation
    )
    print(f'Triggered next Lambda function, response: {response}')


def lambda_handler(event, context):
    print("OUTPUT")
    initial_hash = get_initial_hash("/myapp/data_hash")
    next_hash = fetch_next_hash(URL)

    if next_hash != initial_hash:
        print("initial hash", initial_hash)
        print("next hash", next_hash)
        print("Hashes are different, triggering next Lambda function...")
        trigger_next_lambda()
        # If its different, we need to update to the new hash to kee ptrack
        ssm.put_parameter(
            Name="/myapp/data_ingestion_hash",
            Value=next_hash,
            Type='String',
            Overwrite=True  # Set to True to overwrite existing value
        )

    else:
        print("initial hash", initial_hash)
        print("next hash", next_hash)
        print("Hashes are the same, no action needed.")

    
