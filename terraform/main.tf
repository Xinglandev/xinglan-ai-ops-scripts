provider "tencentcloud" {
  region = "ap-guangzhou"
}

resource "tencentcloud_vpc" "unused_vpc" {
  name       = "unused-training-vpc-${random_id.env_suffix.hex}"
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Environment = "test"
    Owner       = "legacy-team"
  }
}

resource "tencentcloud_instance" "legacy_cvm" {
  instance_name     = "deprecated-web-server"
  availability_zone = "ap-guangzhou-3"
  instance_type     = "S5.SMALL2"
  system_disk_type  = "CLOUD_PREMIUM"
  system_disk_size  = 50
  
  vpc_id    = tencentcloud_vpc.unused_vpc.id
  subnet_id = tencentcloud_subnet.unused_subnet.id
  
  # 无用的安全组规则
  security_groups = [tencentcloud_security_group.legacy_sg.id]
  
  data_disks {
    data_disk_type = "CLOUD_PREMIUM"
    data_disk_size = 100
  }
}

resource "random_id" "env_suffix" {
  byte_length = 2
}
