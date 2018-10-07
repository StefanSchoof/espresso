branch=$(basename ${BUILD_SOURCEBRANCH:-$(git rev-parse --abbrev-ref HEAD)})
echo "##vso[task.setvariable variable=branchname]$branch"
targets=( node cppbuilder builder )
image="stefanschoof/espresso"
if [[ ! $(uname -m) == arm* ]]
then
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi
for target in "${targets[@]}"
do
  tag=$image:build-cache-$target
  docker pull $tag
  cachefrom+="--cache-from $tag "
  docker build --target $target \
    $cachefrom\
    -t $tag .
done
if [[ ! -z "$BUILD_BUILDID" ]]
then
  buildtag="-t $image:build$BUILD_BUILDID "
fi

docker build $cachefrom \
  --cache-from $image:$branch \
  $buildtag \
  -t $image:$branch .
