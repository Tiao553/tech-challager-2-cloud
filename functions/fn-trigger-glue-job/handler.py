import boto3
import json
import time

def lambda_handler(event, context):
    client = boto3.client('glue')
    
    # Nome do Glue Job configurado
    glue_job_name = 'your-glue-job-name'
    
    try:
        # Inicia o job no Glue
        response = client.start_job_run(JobName=glue_job_name)
        job_run_id = response['JobRunId']
        print(f"Glue Job started successfully with JobRunId: {job_run_id}")
        
        # Verifica o status do Glue Job
        while True:
            job_status = client.get_job_run(JobName=glue_job_name, RunId=job_run_id)
            state = job_status['JobRun']['JobRunState']
            print(f"Current Job State: {state}")
            
            if state in ['SUCCEEDED']:
                print("Glue Job completed successfully.")
                break
            elif state in ['FAILED', 'STOPPED', 'TIMEOUT']:
                raise Exception(f"Glue Job failed with state: {state}")
            
            # Espera antes de verificar novamente
            time.sleep(10)
        
        return {
            'statusCode': 200,
            'body': json.dumps(f"Glue Job {job_run_id} completed successfully.")
        }
    
    except Exception as e:
        print(f"Error triggering Glue Job: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error triggering Glue Job: {str(e)}")
        }

