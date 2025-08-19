
terraform {
	backend "s3" {
		bucket = "devopstesthari"
		key    = "terraform.tfstate"
		region = "eu-west-2"
	}
}
