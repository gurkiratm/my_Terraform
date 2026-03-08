resource "vsphere_virtual_machine" "vm1" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_host.host1.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore1.id
  num_cpus         = var.cpu
  # num_cpus = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.num_cpus
  memory           = var.memory
  # memory    = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.memory
  guest_id  = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.guest_id
  scsi_type = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.scsi_type
  # firmware  = "efi"
  firmware  = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.firmware

  network_interface {
    network_id = data.vsphere_network.portgroup1.id
    # network_id = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.network_interfaces.0.network_id
  }
  disk {
    label = "disk0"
    # size  = 20
    size  = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.disks.0.size
    thin_provisioned = true
  }
  clone {
    template_uuid = data.vsphere_virtual_machine.syslog-ng_Mum_1_template.id
    customize {
      linux_options {
        host_name = var.hostname
        domain    = "lab"
      }
      network_interface {
        ipv4_address = var.ip_address
        ipv4_netmask = var.ip_subnet
      }
      ipv4_gateway = var.ip_gw
    }
  }
}