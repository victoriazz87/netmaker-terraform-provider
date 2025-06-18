package main
import (
  "github.com/hashicorp/terraform-plugin-sdk/v2/plugin"
  "terraform-provider-netmaker/provider"
)
func main() {
  plugin.Serve(&plugin.ServeOpts{
    ProviderFunc: provider.Provider,
  })
}
