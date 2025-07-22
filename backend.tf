terraform {
  backend "gcs" {
    bucket  = "my-project-tf-state"  # Replace with your bucket name
    prefix  = "prod-infra"                    # Folder path inside the bucket
  }
}
