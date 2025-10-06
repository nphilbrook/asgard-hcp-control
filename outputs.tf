data "aws_caller_identity" "default" {
}

# This is nice for debugging IAM stuff, but is noisy
# (changes on every run)
# output "caller_identity_default_full" {
#   value = data.aws_caller_identity.default
# }
