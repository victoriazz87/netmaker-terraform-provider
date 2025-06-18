package provider
import (
  "bytes"
  "encoding/json"
  "fmt"
  "net/http"
  "github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)
func resourceNetwork() *schema.Resource {
  return &schema.Resource{
    Create: resourceNetworkCreate,
    Read:   resourceNetworkRead,
    Delete: resourceNetworkDelete,
    Schema: map[string]*schema.Schema{
      "name": {
        Type:     schema.TypeString,
        Required: true,
        ForceNew: true,
      },
      "addressrange": {
        Type:     schema.TypeString,
        Optional: true,
        Default:  "10.0.0.0/24",
        ForceNew: true,
      },
    },
  }
}
func resourceNetworkCreate(d *schema.ResourceData, meta interface{}) error {
  providerConf, ok := meta.(map[string]interface{})
  if !ok || providerConf == nil {
    return fmt.Errorf("provider configuration not set (meta is nil or wrong type)")
  }
  apiURL, ok := providerConf["api_url"].(string)
  if !ok || apiURL == "" {
    return fmt.Errorf("api_url missing in provider configuration")
  }
  token, ok := providerConf["api_token"].(string)
  if !ok || token == "" {
    return fmt.Errorf("api_token missing in provider configuration")
  }
  payload := map[string]interface{}{
    "netid":        d.Get("name").(string),
    "addressrange": d.Get("addressrange").(string),
  }
  body, err := json.Marshal(payload)
  if err != nil {
    return fmt.Errorf("failed to marshal payload: %v", err)
  }
  req, err := http.NewRequest("POST", fmt.Sprintf("%s/api/networks", apiURL), bytes.NewBuffer(body))
  if err != nil {
    return fmt.Errorf("failed to create http request: %v", err)
  }
  req.Header.Set("Authorization", "Bearer "+token)
  req.Header.Set("Content-Type", "application/json")
  client := &http.Client{}
  resp, err := client.Do(req)
  if err != nil {
    return fmt.Errorf("failed to execute http request: %v", err)
  }
  defer resp.Body.Close()
  if resp.StatusCode != 200 && resp.StatusCode != 201 {
    return fmt.Errorf("network creation failed: %s", resp.Status)
  }
  d.SetId(d.Get("name").(string))
  return nil
}
func resourceNetworkRead(d *schema.ResourceData, meta interface{}) error {
  providerConf := meta.(map[string]interface{})
  apiURL := providerConf["api_url"].(string)
  token := providerConf["api_token"].(string)
  netid := d.Id()

  req, err := http.NewRequest("GET", fmt.Sprintf("%s/api/networks/%s", apiURL, netid), nil)
  if err != nil {
    return fmt.Errorf("failed to create GET request: %v", err)
  }
  req.Header.Set("Authorization", "Bearer "+token)

  client := &http.Client{}
  resp, err := client.Do(req)
  if err != nil {
    return fmt.Errorf("failed to perform GET: %v", err)
  }
  defer resp.Body.Close()

  if resp.StatusCode == http.StatusNotFound {
    // Remove resource from Terraform state if it no longer exists
    d.SetId("")
    return nil
  }
  if resp.StatusCode != 200 {
    return fmt.Errorf("unexpected status code %d from Netmaker API", resp.StatusCode)
  }

  var data map[string]interface{}
  if err := json.NewDecoder(resp.Body).Decode(&data); err != nil {
    return fmt.Errorf("failed to decode response: %v", err)
  }

  // Update resource fields in Terraform state
  d.Set("name", data["netid"])
  d.Set("addressrange", data["addressrange"])
  d.Set("defaultinterface", data["defaultinterface"])
  d.Set("islocal", data["islocal"])
  d.Set("networkinterface", data["networkinterface"])

  return nil
}
func resourceNetworkDelete(d *schema.ResourceData, meta interface{}) error {
  providerConf := meta.(map[string]interface{})
  apiURL := providerConf["api_url"].(string)
  token := providerConf["api_token"].(string)
  req, _ := http.NewRequest("DELETE", fmt.Sprintf("%s/api/networks/%s", apiURL, d.Id()), nil)
  req.Header.Set("Authorization", "Bearer "+token)
  client := &http.Client{}
  _, err := client.Do(req)
  if err != nil {
    return err
  }
  d.SetId("")
  return nil
}
