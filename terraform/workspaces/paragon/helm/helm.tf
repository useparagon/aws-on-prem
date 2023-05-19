locals {
  supported_microservices_values = <<EOF
subchart:
  cerberus:
    enabled: ${contains(keys(var.microservices), "cerberus")}
  chronos:
    enabled: ${contains(keys(var.microservices), "chronos")}
  connect:
    enabled: ${contains(keys(var.microservices), "connect")}
  dashboard:
    enabled: ${contains(keys(var.microservices), "dashboard")}
  hades:
    enabled: ${contains(keys(var.microservices), "hades")}
  hercules:
    enabled: ${contains(keys(var.microservices), "hercules")}
  hermes:
    enabled: ${contains(keys(var.microservices), "hermes")}
  minio:
    enabled: ${contains(keys(var.microservices), "minio")}
  passport:
    enabled: ${contains(keys(var.microservices), "passport")}
  plato:
    enabled: ${contains(keys(var.microservices), "plato")}
  pheme:
    enabled: ${contains(keys(var.microservices), "pheme")}
  zeus:
    enabled: ${contains(keys(var.microservices), "zeus")}
  worker-actions:
    enabled: ${contains(keys(var.microservices), "worker-actions")}
  worker-credentials:
    enabled: ${contains(keys(var.microservices), "worker-credentials")}
  worker-crons:
    enabled: ${contains(keys(var.microservices), "worker-crons")}
  worker-proxy:
    enabled: ${contains(keys(var.microservices), "worker-proxy")}
  worker-triggers:
    enabled: ${contains(keys(var.microservices), "worker-triggers")}
  worker-workflows:
    enabled: ${contains(keys(var.microservices), "worker-workflows")}
EOF
}

# creates the `paragon` namespace
resource "kubernetes_namespace" "paragon" {
  metadata {
    name = "paragon"

    annotations = {
      name = "paragon"
    }
  }
}

# kubernetes secret to pull docker image from docker hub
resource "kubernetes_secret" "docker_login" {
  metadata {
    name      = "docker-cfg"
    namespace = "paragon"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.docker_registry_server}" = {
          "username" = var.docker_username
          "password" = var.docker_password
          "email"    = var.docker_email
          "auth"     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }

  depends_on = [
    kubernetes_namespace.paragon
  ]
}

# ingress controller; provisions load balancer
resource "helm_release" "ingress" {
  name        = "ingress"
  description = "AWS Ingress Controller"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  namespace        = "paragon"
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  verify           = false

  set {
    name  = "autoDiscoverAwsRegion"
    value = "true"
  }

  set {
    name  = "autoDiscoverAwsVpcID"
    value = "true"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  depends_on = [
    kubernetes_namespace.paragon
  ]
}

# metrics server for hpa
resource "helm_release" "metricsserver" {
  name        = "metricsserver"
  description = "AWS Metrics Server"

  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  namespace        = "paragon"
  create_namespace = true
  cleanup_on_fail  = true
  atomic           = true
  verify           = false

  depends_on = [
    helm_release.ingress
  ]
}

# microservices deployment
resource "helm_release" "paragon_on_prem" {
  name             = "paragon-on-prem"
  description      = "Paragon microservices"
  chart            = "./charts/paragon-onprem"
  namespace        = "paragon"
  cleanup_on_fail  = true
  create_namespace = false
  atomic           = true
  verify           = false
  timeout          = 900 # 15 minutes

  values = [
    local.supported_microservices_values,

    // map `var.helm_values` but remove `global.env`, as we'll map it below
    yamlencode(merge(nonsensitive(var.helm_values), {
      global = merge(nonsensitive(var.helm_values).global, {
        env = {}
      })
    }))
  ]

  # force redeploy when Chart.yaml changes
  set {
    name  = "chartHash"
    value = filesha256("./charts/paragon-onprem/Chart.yaml")
  }

  # used to determine which version of paragon microservices to pull
  set {
    name  = "global.paragon_version"
    value = var.helm_values.global.env["VERSION"]
  }

  # used to load environment variables into microservices
  dynamic "set_sensitive" {
    for_each = nonsensitive(merge(var.helm_values.global.env))
    content {
      name  = "global.env.${set_sensitive.key}"
      value = set_sensitive.value
    }
  }

  # used to set map the ingress to the public url of each microservice
  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.ingress.host"
      value = replace(replace(set.value.public_url, "https://", ""), "http://", "")
    }
  }

  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.env.SERVICE"
      value = set.key
    }
  }

  # configures the ssl cert to the load balancer
  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.ingress.acm_certificate_arn"
      value = var.acm_certificate_arn
    }
  }

  # configures the load balancer name
  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.ingress.load_balancer_name"
      value = var.aws_workspace
    }
  }

  # configures whether the load balancer is 'internet-facing' (public) or 'internal' (private)
  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.ingress.schema"
      value = var.ingress_scheme
    }
  }

  # configures load balancer bucket for logging
  dynamic "set" {
    for_each = var.microservices

    content {
      name  = "${set.key}.ingress.logs_bucket"
      value = var.logs_bucket 
    }
  }

  set {
    name  = "global.env.K8_VERSION"
    value = "1.22"
  }

  depends_on = [
    helm_release.ingress,
    kubernetes_secret.docker_login
  ]
}

# paragon logging stack fluent bit , kibana , elasticsearch
resource "helm_release" "paragon_logging" {
  name             = "paragon-logging"
  description      = "Paragon logging services"
  chart            = "./charts/paragon-logging"
  namespace        = "paragon"
  create_namespace = true
  cleanup_on_fail  = true
  atomic           = true
  verify           = false

  values = [
    local.supported_microservices_values,

    // map `var.helm_values` but remove `global.env`, as we'll map it below
    yamlencode(merge(nonsensitive(var.helm_values), {
      global = merge(nonsensitive(var.helm_values).global, {
        env = {}
      })
    }))
  ]

  depends_on = [
    helm_release.ingress,
    kubernetes_secret.docker_login,
  ]
}

# monitors deployment
resource "helm_release" "paragon_monitoring" {
  count = var.monitors_enabled ? 1 : 0

  name             = "paragon-monitoring"
  description      = "Paragon monitors"
  chart            = "./charts/paragon-monitoring"
  namespace        = "paragon"
  cleanup_on_fail  = true
  create_namespace = false
  atomic           = true
  verify           = false

  values = [
    local.supported_microservices_values,

    // map `var.helm_values` but remove `global.env`, as we'll map it below
    yamlencode(merge(nonsensitive(var.helm_values), {
      global = merge(nonsensitive(var.helm_values).global, {
        env = {}
      })
    }))
  ]

  # force redeploy when Chart.yaml changes
  set {
    name  = "chartHash"
    value = filesha256("./charts/paragon-monitoring/Chart.yaml")
  }

  # used to determine which version of paragon microservices to pull
  set {
    name  = "global.paragon_version"
    value = var.helm_values.global.env["VERSION"]
  }

  # used to load environment variables into microservices
  dynamic "set_sensitive" {
    for_each = nonsensitive(merge(var.helm_values.global.env))
    content {
      name  = "global.env.${set_sensitive.key}"
      value = set_sensitive.value
    }
  }

  # used to set map the ingress to the public url of each microservice
  dynamic "set" {
    for_each = var.public_monitors

    content {
      name  = "${set.key}.ingress.host"
      value = replace(replace(set.value.public_url, "https://", ""), "http://", "")
    }
  }

  # configures the ssl cert to the load balancer
  dynamic "set" {
    for_each = var.public_monitors

    content {
      name  = "${set.key}.ingress.acm_certificate_arn"
      value = var.acm_certificate_arn
    }
  }

  # configures the load balancer name
  dynamic "set" {
    for_each = var.public_monitors

    content {
      name  = "${set.key}.ingress.load_balancer_name"
      value = var.aws_workspace
    }
  }

  # configures whether the load balancer is 'internet-facing' (public) or 'internal' (private)
  dynamic "set" {
    for_each = var.public_monitors

    content {
      name  = "${set.key}.ingress.schema"
      value = var.ingress_scheme
    }
  }

  dynamic "set" {
    for_each = var.monitors

    content {
      name  = "${set.key}.image.tag"
      value = var.monitor_version
    }
  }

  set {
    name  = "global.env.K8_VERSION"
    value = "1.22"
  }

  depends_on = [
    helm_release.ingress,
    kubernetes_secret.docker_login
  ]
}
