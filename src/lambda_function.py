import json
import boto3
import os
import logging
from typing import Dict, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(os.getenv('LOG_LEVEL', 'INFO'))

# Initialize AWS clients
secrets_client = boto3.client('secretsmanager')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Main Lambda handler for serverless application.
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        API Gateway response
    """
    try:
        # Log the incoming event
        logger.info(f"Received event: {json.dumps(event, default=str)}")
        
        # Extract request details
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        
        # Route based on path and method
        if path == '/health':
            return health_check()
        elif path == '/' and http_method == 'GET':
            return get_root()
        elif path == '/' and http_method == 'POST':
            return post_root(event)
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Not found',
                    'path': path,
                    'method': http_method
                })
            }
            
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }

def health_check() -> Dict[str, Any]:
    """Health check endpoint."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'status': 'healthy',
            'version': '1.0.0',
            'environment': os.getenv('ENVIRONMENT', 'unknown')
        })
    }

def get_root() -> Dict[str, Any]:
    """Handle GET requests to root."""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Welcome to the serverless application!',
            'app_name': os.getenv('APP_NAME', 'serverless-app'),
            'environment': os.getenv('ENVIRONMENT', 'development')
        })
    }

def post_root(event: Dict[str, Any]) -> Dict[str, Any]:
    """Handle POST requests to root."""
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        
        # Example: Echo the received data
        response_data = {
            'message': 'Data received successfully',
            'received_data': body,
            'timestamp': context.aws_request_id if 'context' in locals() else 'unknown'
        }
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(response_data)
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Invalid JSON in request body'
            })
        }

def get_database_credentials() -> Dict[str, str]:
    """
    Retrieve database credentials from AWS Secrets Manager.
    
    Returns:
        Database credentials dictionary
    """
    try:
        secret_arn = os.getenv('DB_SECRET_ARN')
        if not secret_arn:
            raise ValueError("DB_SECRET_ARN environment variable not set")
        
        response = secrets_client.get_secret_value(SecretId=secret_arn)
        credentials = json.loads(response['SecretString'])
        
        return {
            'host': credentials.get('host', os.getenv('DB_HOST')),
            'port': credentials.get('port', os.getenv('DB_PORT')),
            'username': credentials.get('username'),
            'password': credentials.get('password'),
            'database': credentials.get('dbname', os.getenv('DB_NAME'))
        }
        
    except Exception as e:
        logger.error(f"Error retrieving database credentials: {str(e)}")
        raise

# Example database connection function (commented out - requires pymysql)
# def get_database_connection():
#     """Get database connection using retrieved credentials."""
#     try:
#         credentials = get_database_credentials()
#         
#         connection = pymysql.connect(
#             host=credentials['host'],
#             port=int(credentials['port']),
#             user=credentials['username'],
#             password=credentials['password'],
#             database=credentials['database'],
#             cursorclass=pymysql.cursors.DictCursor
#         )
#         
#         return connection
#         
#     except Exception as e:
#         logger.error(f"Error connecting to database: {str(e)}")
#         raise