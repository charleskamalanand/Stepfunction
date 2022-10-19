import json
import boto3

client = boto3.client('stepfunctions')

def lambda_handler(event, context):
	input = {"customerId": event["customerId"],"orderId": event["orderId"]}
	print(event)
	response = client.start_execution(
		stateMachineArn='arn:aws:states:us-east-1:951560400874:stateMachine:MyStateMachine',
		input=json.dumps(input))