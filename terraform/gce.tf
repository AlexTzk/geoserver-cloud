resource "google_compute_instance" "geoserver-nfs-gke" {
  boot_disk {
    auto_delete = true
    device_name = "geoserver-nfs-gke-os-disk"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20230727"
      size  = 50
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  # Change the deletion_protection to True in PROD
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf-nfs-gke"
  }

  machine_type = "n1-standard-1"
# NVME section
  scratch_disk {
    interface = "NVME"
  }
  scratch_disk {
    interface = "NVME"
  }
  # Uncomment block below if not using NVMEs + last block
  /*
  attached_disk {
    device_name = "backup-nfs"
    mode        = "READ_WRITE"
    source      = google_compute_disk.backup.self_link
  }*/
  metadata = {
    block-project-ssh-keys = "true"
    enable-oslogin         = "true"
    startup-script =  file("${path.module}/startup_nfs.sh")
  }

  name = "${var.company}-${var.env}-nfs-gke"

  network_interface {
    network_ip = "${var.vm_ip_nfs}"
  }

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  tags = ["allow-ssh", "allow-gke-range"]
  zone = "${var.zone}"
}

## Use this to access the VM remotely using GCP IAP if instance doesn't have EXT IP
resource "google_iap_tunnel_instance_iam_member" "instance" {
  instance = "${var.company}-${var.env}-geoserver-nfs-gke"
  zone     = "${var.zone}"
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:alexandru@mydomain.com"
  depends_on = [google_compute_instance.nfs-gke]
}

## Uncomment this only if you remove the NVME disks and would rather use an SSD/HDD
/*
resource "google_compute_disk" "backup" {
  name  = "backup-nfs"
  type  = "pd-balanced"
  size  = 1000
  zone  = "${var.zone}"
  labels = {
    environment = "${var.env}"
  }
  physical_block_size_bytes = 4096
}
*/