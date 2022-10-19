import json

def lambda_handler(event, context):
    # TODO implement
    #raise Exception
    print (event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }
