"""
Aurora Disaster Failover Trigger Lambda

서울 리전 장애 시 도쿄 리전 Aurora DB를 페일오버하는 SSM Automation Document를 실행합니다.
"""

import json
import os
import boto3
from datetime import datetime


def lambda_handler(event, context):
    """
    API Gateway에서 호출되어 SSM Automation Document를 실행합니다.
    """
    ssm_client = boto3.client('ssm')

    # 환경변수에서 설정 로드
    document_name = os.environ.get('SSM_DOCUMENT_NAME', 'Aurora-Disaster-Failover-Runbook-Tokyo')
    automation_role_arn = os.environ.get('AUTOMATION_ROLE_ARN', '')

    # 기본 파라미터 (런북의 기본값 사용)
    parameters = {
        'GlobalClusterIdentifier': ['dh-prod-global-rds-v2'],
        'LocalClusterRegion': ['ap-northeast-1'],
        'LocalClusterIdentifier': ['dh-prod-db-tokyo-aurora-secondary-v2'],
        'FailedRegion': ['ap-northeast-2'],
        'FailedRegionName': ['Seoul'],
        'IncidentNumber': [f'INC-{datetime.now().strftime("%Y%m%d%H%M%S")}'],
        'SkipSnapshot': ['false']
    }

    # AutomationAssumeRole 설정
    if automation_role_arn:
        parameters['AutomationAssumeRole'] = [automation_role_arn]

    # 요청 본문에서 파라미터 오버라이드 (선택사항)
    if event.get('body'):
        try:
            body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']
            if body.get('incident_number'):
                parameters['IncidentNumber'] = [body['incident_number']]
            if body.get('skip_snapshot'):
                parameters['SkipSnapshot'] = [str(body['skip_snapshot']).lower()]
        except (json.JSONDecodeError, KeyError):
            pass

    try:
        # SSM Automation 실행
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
                'message': 'Disaster failover automation started successfully',
                'execution_id': execution_id,
                'document_name': document_name,
                'console_url': console_url,
                'parameters': {k: v[0] for k, v in parameters.items() if k != 'AutomationAssumeRole'}
            }, ensure_ascii=False)
        }

    except ssm_client.exceptions.AutomationDefinitionNotFoundException:
        return {
            'statusCode': 404,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': 'SSM Document not found',
                'document_name': document_name
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({
                'error': str(e),
                'message': 'Failed to start automation execution'
            })
        }
