group "default" {
targets = ["testresult", "runner"]
}

target "runner" {
inherits = ["common"]
target = "runner"
tags = ["docker.io/stefanschoof/espresso:bake"]
}

target "testresult" {
 output = ["type=local,dest=."]
target = "testresult"
inherits = ["common"]
}

target "common" {
platforms = ["linux/arm/v6"]
cache-from = ["docker.io/stefanschoof/espresso:cache"]
}
