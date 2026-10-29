terraform {
  backend "s3" {
    bucket       = "aws-assessment-tfstate-808486947900-ap-south-1"
    key          = "aws-assessment/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
