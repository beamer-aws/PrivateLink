data "aws_acm_certificate" "star_nlb_server" {
    domain = var.nlb_certificate
    most_recent = true
}