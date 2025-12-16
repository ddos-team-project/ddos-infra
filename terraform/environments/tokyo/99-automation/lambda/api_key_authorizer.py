"""
API Key Authorizer Lambda

X-Api-Key 헤더를 검증하여 API 접근을 제어합니다.
"""

import os
import boto3


def lambda_handler(event, context):
    """
    API Gateway Lambda Authorizer (Simple Response Format 2.0)
    """
    ssm_client = boto3.client('ssm')

    # 요청에서 API Key 추출
    request_api_key = event.get('headers', {}).get('x-api-key', '')

    if not request_api_key:
        return {
            'isAuthorized': False
        }

    try:
        # SSM Parameter에서 유효한 API Key 조회
        parameter_name = os.environ.get('API_KEY_PARAMETER_NAME', '/ddos/disaster-failover/api-key')
        response = ssm_client.get_parameter(
            Name=parameter_name,
            WithDecryption=True
        )
        valid_api_key = response['Parameter']['Value']

        # API Key 비교
        if request_api_key == valid_api_key:
            return {
                'isAuthorized': True
            }
        else:
            return {
                'isAuthorized': False
            }

    except Exception as e:
        print(f"Authorization error: {str(e)}")
        return {
            'isAuthorized': False
        }
