import boto3
import json
import time

# ── Clients ───────────────────────────────────────────────────
bedrock = boto3.client(
    service_name='bedrock-runtime',
    region_name='us-east-1'
)
bedrock_agent = boto3.client(
    service_name='bedrock-agent',
    region_name='us-east-1'
)
bedrock_agent_runtime = boto3.client(
    service_name='bedrock-agent-runtime',
    region_name='us-east-1'
)
s3 = boto3.client('s3', region_name='us-east-1')

# ── Config ────────────────────────────────────────────────────
S3_BUCKET_NAME    = 'My-s3-bucket-name'        # 
S3_FILE_KEY       = 'My-folder/your-file.pdf'  # 
KNOWLEDGE_BASE_ID = 'My-knowledge-base-id'     # 
DATA_SOURCE_ID    = 'My-data-source-id'         # 
RAG_MODEL_ID      = 'anthropic.claude-3-sonnet-20240229-v1:0'


# ══════════════════════════════════════════════════════════════
# STEP 1 — Verify S3 File Exists
# ══════════════════════════════════════════════════════════════
def verify_s3_file(bucket, key):
    print(f"\n🪣 Verifying S3 file: s3://{bucket}/{key}")
    try:
        obj = s3.head_object(Bucket=bucket, Key=key)
        size_kb = obj['ContentLength'] / 1024
        print(f"✅ File found! Size: {size_kb:.2f} KB | Last Modified: {obj['LastModified']}")
        return True
    except Exception as e:
        print(f"❌ File not found in S3: {e}")
        return False


# ══════════════════════════════════════════════════════════════
# STEP 2 — Sync S3 File → Knowledge Base (Daily Refresh)
# ══════════════════════════════════════════════════════════════
def sync_knowledge_base(knowledge_base_id, data_source_id):
    print(f"\n🔄 Starting ingestion job for Knowledge Base: {knowledge_base_id}")
    try:
        response = bedrock_agent.start_ingestion_job(
            knowledgeBaseId=knowledge_base_id,
            dataSourceId=data_source_id,
            description='Daily scheduled sync from S3'
        )
        job_id = response['ingestionJob']['ingestionJobId']
        print(f"📋 Ingestion Job ID: {job_id}")

        # Poll until ingestion completes
        print("⏳ Waiting for ingestion to complete", end='', flush=True)
        while True:
            status_response = bedrock_agent.get_ingestion_job(
                knowledgeBaseId=knowledge_base_id,
                dataSourceId=data_source_id,
                ingestionJobId=job_id
            )
            status = status_response['ingestionJob']['status']

            if status == 'COMPLETE':
                stats = status_response['ingestionJob'].get('statistics', {})
                print(f"\n✅ Ingestion Complete!")
                print(f"   📄 Documents Scanned  : {stats.get('numberOfDocumentsScanned', 'N/A')}")
                print(f"   ✅ Documents Indexed  : {stats.get('numberOfNewDocumentsIndexed', 'N/A')}")
                print(f"   🔁 Docs Updated       : {stats.get('numberOfModifiedDocumentsIndexed', 'N/A')}")
                print(f"   ❌ Docs Failed        : {stats.get('numberOfDocumentsFailed', 'N/A')}")
                return True

            elif status == 'FAILED':
                print(f"\n❌ Ingestion Failed: {status_response['ingestionJob'].get('failureReasons', '')}")
                return False

            else:
                print('.', end='', flush=True)
                time.sleep(10)

    except Exception as e:
        print(f"\n❌ Error starting ingestion job: {e}")
        return False


# ══════════════════════════════════════════════════════════════
# STEP 3 — Query RAG with Your Business Question
# ══════════════════════════════════════════════════════════════
def query_rag(knowledge_base_id, user_question, model_id=RAG_MODEL_ID):
    print("\n" + "=" * 60)
    print("         BEDROCK RAG — QUERY RESPONSE")
    print("=" * 60)
    print(f"\n❓ Question : {user_question}")
    print(f"🤖 Model    : {model_id}")

    try:
        response = bedrock_agent_runtime.retrieve_and_generate(
            input={'text': user_question},
            retrieveAndGenerateConfiguration={
                'type': 'KNOWLEDGE_BASE',
                'knowledgeBaseConfiguration': {
                    'knowledgeBaseId': knowledge_base_id,
                    'modelArn': f'arn:aws:bedrock:us-east-1::foundation-model/{model_id}',
                    'retrievalConfiguration': {
                        'vectorSearchConfiguration': {
                            'numberOfResults': 5
                        }
                    }
                }
            }
        )

        # ── Generated Answer ───────────────────────────────────
        answer = response['output']['text']
        print(f"\n💬 Answer:\n{'-' * 60}\n{answer}")

        # ── Source Citations ───────────────────────────────────
        citations = response.get('citations', [])
        if citations:
            print(f"\n📚 Sources Retrieved ({len(citations)} citation(s)):")
            print("-" * 60)
            for i, citation in enumerate(citations, 1):
                refs = citation.get('retrievedReferences', [])
                for ref in refs:
                    location = ref.get('location', {})
                    s3_loc   = location.get('s3Location', {})
                    content  = ref.get('content', {}).get('text', '')[:200]
                    print(f"\n  [{i}] 📄 S3 URI : {s3_loc.get('uri', 'N/A')}")
                    print(f"       📝 Excerpt : {content}...")

        print("\n" + "=" * 60)
        return answer

    except Exception as e:
        print(f"\n❌ RAG Query Failed: {e}")
        return None


# ══════════════════════════════════════════════════════════════
# DAILY JOB RUNNER
# ══════════════════════════════════════════════════════════════
def run_daily_rag_job(user_question):
    print("\n" + "🚀 " * 20)
    print("   DAILY RAG JOB STARTED")
    print("🚀 " * 20)

    # Step 1: Verify file exists in S3
    if not verify_s3_file(S3_BUCKET_NAME, S3_FILE_KEY):
        print("⛔ Aborting — File not found in S3.")
        return

    # Step 2: Sync latest S3 file into Knowledge Base
    synced = sync_knowledge_base(KNOWLEDGE_BASE_ID, DATA_SOURCE_ID)
    if not synced:
        print("⛔ Aborting — Knowledge Base sync failed.")
        return

    # Step 3: Query RAG with your business question
    query_rag(KNOWLEDGE_BASE_ID, user_question)

    print("\n✅ Daily RAG Job Completed Successfully!")


# ══════════════════════════════════════════════════════════════
# MAIN — My Business Query about sales
# ══════════════════════════════════════════════════════════════
if __name__ == "__main__":
    run_daily_rag_job(
        user_question="What is the total sales in last week for South region?"
    )