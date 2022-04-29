group "default" {
    targets = ["web", "api"]
}
target "docker-metadata-action-api" {}
target "docker-metadata-action-web" {}
target "web" {
    inherits = ["docker-metadata-action-web"]
    context = "./web"
    platforms = ["linux/arm/v7"]
}
target "api" {
    inherits = ["docker-metadata-action-api"]
    context = "./api"
    platforms = ["linux/arm/v6"]
}