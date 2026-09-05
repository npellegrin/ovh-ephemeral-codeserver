# Generates the Ansible inventory Makefile targets read from.

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/generated.ini"
  content  = <<-EOT
    [dev_servers]
    ${openstack_compute_instance_v2.dev_instance.access_ip_v4} ansible_user=debian ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'

    [dev_servers:vars]
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
