FROM golang as tf2pulumi

RUN go get -d github.com/pulumi/tf2pulumi/...
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
RUN cd $(go env GOPATH)/src/github.com/pulumi/tf2pulumi \
 && dep ensure \
 && go install github.com/pulumi/tf2pulumi

FROM node

COPY --from=tf2pulumi /go/bin/tf2pulumi /usr/local/bin
WORKDIR espresso/deploy
RUN curl -fsSL https://get.pulumi.com | sh
ENV PATH="/root/.pulumi/bin:${PATH}" 
RUN pulumi login --local
COPY *.tf ./
RUN pulumi new typescript --dir my-stack -y
RUN pulumi plugin install resource azure 0.16.9
RUN pulumi plugin install resource terraform-template 0.15.0
CMD tf2pulumi 
