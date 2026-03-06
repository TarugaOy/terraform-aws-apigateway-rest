locals {

  route_map = {
    for r in var.routes :
    "${r.path}-${r.method}" => r
  }

}