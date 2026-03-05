terraform {
  backend "cos" {
    region = "ap-guangzhou"
    bucket = "xinglan-multimodal-1258241193"        
    prefix = "tfstate/multimodal"
  }
}
