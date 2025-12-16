"""
Aurora Disaster Failover TEST Trigger Lambda

실제 DB 작업 없이 API 플로우만 테스트합니다.
테스트용 더미 런북을 실행하여 전체 파이프라인을 검증합니다.
"""

import json
import os
import boto3
from datetime import datetime


def lambda_handler(event, context):
    """
    API Gateway에서 호출되어 테스트용 SSM Automation Document를 실행합니다.
    """
    ssm_client = boto3.client('ssm')

    # 환경변수에서 설정 로드
    document_name = os.environ.get('SSM_DOCUMENT_NAME', 'Aurora-Disaster-Failover-Test-Runbook-Tokyo')
    automation_role_arn = os.environ.get('AUTOMATION_ROLE_ARN', '')

    # 테스트용 파라미터
    parameters = {
        'GlobalClusterIdentifier': ['dh-prod-global-rds-v2'],
        'LocalClusterRegion': ['ap-northeast-1'],
        'LocalClusterIdentifier': ['dh-prod-db-tokyo-aurora-secondary-v2'],
        'FailedRegion': ['ap-northeast-2'],
        'FailedRegionName': ['Seoul'],
        'IncidentNumber': [f'TEST-{datetime.now().strftime("%Y%m%d%H%M%S")}'],
        'SkipSnapshot': ['false']
    }

    # AutomationAssumeRole 설정
    if automation_role_arn:
        parameters['AutomationAssumeRole'] = [automation_role_arn]

    try:
        # SSM Automation 실행 (테스트 런북)
        response = ssm_client.start_automation_execution(
            DocumentName=document_name,
            Parameters=parameters
        )

        execution_id = response['AutomationExecutionId']

        # 실행 URL 생성
        region = os.environ.get('AWS_REGION', 'ap-northeast-1')
        console_url = f"https://{region}.console.aws.amazon.com/systems-manager/automation/execution/{execution_id}"

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': '[TEST] Disaster failover test automation started successfully',
                'test_mode': True,
                'execution_id': execution_id,
                'document_name': document_name,
                'console_url': console_url,
                'note': 'This is a TEST run. No actual DB operations will be performed.',
                'parameters': {k: v[0] for k, v in parameters.items() if k != 'AutomationAssumeRole'}
            }, ensure_ascii=False)
        }

    except ssm_client.exceptions.AutomationDefinitionNotFoundException:
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'Test SSM Document not found',
                'document_name': document_name
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to start test automation execution'
            })
        }
