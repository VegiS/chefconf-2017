provider "cloudflare" {
  email = "${var.cloudflare_email}"
  token = "${var.cloudflare_token}"
}

resource "cloudflare_record" "demo" {
  domain  = "hashicorp.rocks"
  type    = "CNAME"
  name    = "nomad"
  value   = "${aws_alb.demo.dns_name}"
  ttl     = "1"
  proxied = "1"
}
