#######################################################################################################################
## ----------------------##----------------------------------------------------------------------------------------- ##
## Terraform Root Module ## 
## ----------------------##
## - 
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#BOF
## ---------------------------------------------------
variable "gcpAuthFile" {
  type = string
  description = "Google Cloud Platform Service Account(SA) authenticaion file name"
  default = "auth.json"
}
## ---------------------------------------------------
variable "gcpProject" {
  type = string
  description = "Google Cloud Platform Project Name"
}
## ---------------------------------------------------
variable "gcpRegion" {
  type = string
  description = "Google Cloud Platform Region Name"
  default = "northamerica-northeast2" # aka Toronto, Canada
}
## ---------------------------------------------------
variable "gcpZone" {
  type = string
  description = "Google Cloud Platform Zone Name"
  default = "northamerica-northeast2-a"
}
## ---------------------------------------------------
variable "dnsDomain" {
  type = string
  description = "DNS domian to utilize. NOTE: this object should already exist"
}
## ---------------------------------------------------
variable "dnsZone" {
  type = string
  description = "DNS zone to utilize. NOTE: this object should already exist"
  default = "sandbox"
}
## ---------------------------------------------------
variable "subnetRange" {
  type = string
  description = "Compute subnetwork to provision"
  default = "10.128.0.0/20"
}
## ---------------------------------------------------
variable "computeInstanceKey" {
  type = string
  description = "Unique idenitifer to utilize"
  default = "k8s"
}
## ---------------------------------------------------
variable "computeEnvironment" {
  type = string
  description = "Environment to provision"
  default = "DEV"
}
## ---------------------------------------------------
variable "computeInstances" {
  type        = number
  description = "number of computer instances to create"
  default     = 2
  validation {
    condition     = var.computeInstances > 1 && var.computeInstances < 12
    error_message = "The computeInstances value must greater than one(1) and less than twelve(12)."
  }
}
## ---------------------------------------------------
variable "computeTags" { 
  type = list(string)
  description = "Compute machine tags to apply"
  default = ["training", "kubernetes", "lfs258"]
}
## ---------------------------------------------------
variable "computeMachineType" { 
  type = string
  description = "Compute machine type to use"
  # f1-micro    # Free tier 
  # e2-standard-2 # required by k8s setup
  default = "e2-standard-2"
}
## ---------------------------------------------------
variable "computeSshKeys" {
  type = list(object({
    user = string
    publicKey = string
    privateKeyFile = string # should be the file location
  }))
  description = "List of ssh keys that have access to the compute instances. NOTE: the first listed key will be passed to and used by ansible"
}
#
#######################################################################################################################
## ----------------------------------------------------------------------------------------------------------------- ##
#######################################################################################################################
#EOF