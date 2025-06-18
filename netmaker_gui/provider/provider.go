package provider
import (
  "context"
  "github.com/hashicorp/terraform-plugin-sdk/v2/diag"
  "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)
func Provider() *schema.Provider {
  return &schema.Provider{
    Schema: map[string]*schema.Schema{
      "api_url": {
        Type:        schema.TypeString,
        Required:    true,
        DefaultFunc: schema.EnvDefaultFunc("NETMAKER_API_URL", nil),
      },
      "api_token": {
        Type:        schema.TypeString,
        Required:    true,
        Sensitive:   true,
        DefaultFunc: schema.EnvDefaultFunc("NETMAKER_API_TOKEN", nil),
      },
    },
    ResourcesMap: map[string]*schema.Resource{
      "netmaker_network": resourceNetwork(),
    },
    ConfigureContextFunc: providerConfigure,
  }
}
func providerConfigure(ctx context.Context, d *schema.ResourceData) (interface{}, diag.Diagnostics) {
  config := map[string]interface{}{
    "api_url":   d.Get("api_url").(string),
    "api_token": d.Get("api_token").(string),
  }
  return config, nil
}
