group "default" {
    targets = ["web", "api"]
}
target "docker-metadata-action-api" {}
target "docker-metadata-action-web" {}
target "web" {
    inherits = ["docker-metadata-action-web"]
    context = "./web"
    cache-from = ["type=registry,ref=ghcr.io/stefanschoof/espressoweb:latest"]
    platforms = ["linux/arm/v7"]
}
target "api" {
    inherits = ["docker-metadata-action-api"]
    context = "./node"
    cache-from = ["type=registry,ref=ghcr.io/stefanschoof/espressoapi:latest"]
    platforms = ["linux/arm/v6"]
}