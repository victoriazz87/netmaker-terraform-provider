FROM golang:1.22.3 AS builder
WORKDIR /app
COPY . .
RUN go mod tidy
RUN go build -o terraform-provider-netmaker

FROM hashicorp/terraform:1.8
ENV HOME=/root
RUN mkdir -p /root/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64/
COPY --from=builder /app/terraform-provider-netmaker /root/.terraform.d/plugins/registry.terraform.io/local/netmaker/1.0.0/linux_amd64/
WORKDIR /workspace
ENTRYPOINT ["terraform"]
