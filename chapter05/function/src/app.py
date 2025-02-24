def lambda_handler(event, context):
    print(f'bucket = {event['Records'][0]['s3']['bucket']['name']}')
    print(f'key = {event['Records'][0]['s3']['object']['key']}')
