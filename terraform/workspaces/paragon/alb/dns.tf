data "aws_lb" "load_balancer" {
  name = var.aws_workspace

  depends_on = [
    var.release_ingress,
    var.release_paragon_on_prem,
  ]
}

resource "aws_route53_zone" "paragon" {
  name          = var.domain
  force_destroy = false
}

resource "aws_route53_record" "microservice" {
  for_each = var.microservices

  zone_id = aws_route53_zone.paragon.zone_id
  name = replace(
    replace(
      replace(each.value.public_url, var.domain, ""),
      "https://",
      ""
    ),
    "http://",
    ""
  )
  type    = "CNAME"
  ttl     = 300
  records = [data.aws_lb.load_balancer.dns_name]
}