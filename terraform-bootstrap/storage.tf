# Object Storage bucket that backup.yml/restore.yml (Ansible) read and write.

resource "openstack_objectstorage_container_v1" "backup_bucket" {
  region = var.region
  name   = "${local.resource_prefix}-backups"

  metadata = {
    purpose = "dev-environment-backups"
  }
}
