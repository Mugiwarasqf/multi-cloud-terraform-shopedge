variable "location" {
  description = "Azure region"
  type        = string
}

variable "node_vm_size" {
  description = "VM size for the AKS node pool"
  type        = string
}
