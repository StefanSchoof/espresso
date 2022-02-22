group "default" {
    targets = ["web", "api"]
}
target "docker-metadata-action-api" {}
target "docker-metadata-action-web" {}
target "web" {
    inherits = ["docker-metadata-action-web"]
    context = "./web"
    platforms = ["linux/arm/v7"]
    tags = ["espressoweb"]
}
target "api" {
    inherits = ["docker-metadata-action-api"]
    context = "./node"
    platforms = ["linux/arm/v6"]
    tags = ["espressoapi"]
}