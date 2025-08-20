
terraform {
	backend "s3" {
		bucket = "haridevopstestbucket"
		key    = "terraform.tfstate"
		region = "eu-west-2"
	}
}

