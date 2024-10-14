
resource "aws_s3_bucket" "bucket-athena" {
  bucket = var.athena_bucket_name
  force_destroy = true
}

resource "aws_athena_workgroup" "example" {
  name               = "data-analysts-workgroup"
  state              = "ENABLED"

  configuration {
    bytes_scanned_cutoff_per_query = 1000000000
    result_configuration {
        output_location = "s3://${var.athena_bucket_name}/"
    }
  }
  force_destroy = true

}

