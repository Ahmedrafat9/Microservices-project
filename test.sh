# Enable APIs manually
gcloud services enable compute.googleapis.com --project=task-464917
gcloud services enable container.googleapis.com --project=task-464917
gcloud services enable redis.googleapis.com --project=task-464917
gcloud services enable secretmanager.googleapis.com --project=task-464917

# Wait for propagation
sleep 60

# Then run terraform
terraform apply