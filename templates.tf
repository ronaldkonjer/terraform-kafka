/*
 * Kafka module templates
 */

data "template_file" "mount-volumes" {
  template = file("${path.module}/user_data/mount-volumes.sh")
  vars = {
    device_name = var.ebs_device_name
    mount_point = var.ebs_mount_point
  }
}

data "template_file" "setup-zookeeper" {
  template = file("${path.module}/scripts/setup-zookeeper.sh")
  vars = {
    count = length(aws_instance.zookeeper-server)
    repo = var.zookeeper_repo
    version = var.zookeeper_version
    ip_addrs = join(" ", aws_instance.zookeeper-server.*.private_ip)
  }
}

data "template_file" "zookeeper-ctl" {
  template = file("${path.module}/scripts/zookeeper-ctl")
  vars = {
    version = var.zookeeper_version
  }
}

data template_file "setup-kafka" {
  template = file("${path.module}/scripts/setup-kafka.sh")
  count = length(data.aws_subnet.subnet)
  vars = {
    repo = var.kafka_repo
    version = var.kafka_version
    scala_version = var.scala_version
    mount_point = var.ebs_mount_point
    zookeeper_connect = join(",", formatlist("%s:2181", aws_instance.zookeeper-server.*.private_ip))
    num_partitions = var.num_partitions
    log_retention = var.log_retention
    repl_factor = length(data.aws_subnet.subnet)
  }
}

data template_file "kafka-ctl" {
  template = file("${path.module}/scripts/kafka-ctl")
  vars = {
    scala_version = var.scala_version
    kafka_version = var.kafka_version
  }
}

data "aws_region" "current" {}

data template_file "zookeeper-status" {
  template = file("${path.module}/scripts/process-status.sh")
  vars = {
    region = data.aws_region.current.name
    service = "zookeeper"
    metric = "ZookeeperStatus"
  }
}

data template_file "kafka-status" {
  template = file("${path.module}/scripts/process-status.sh")
  vars = {
    region = data.aws_region.current.name
    service = "kafka"
    metric = "KafkaStatus"
  }
}

data "aws_caller_identity" "current" {}

data template_file "zookeeper-state-change" {
  template = file("${path.module}/event_patterns/ec2-state-change.json")
  vars = {
    instances = join("\",\"", formatlist(format("arn:aws:ec2:%s:%s:instance/%%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id), aws_instance.zookeeper-server.*.id))
  }
}


data template_file "kafka-state-change" {
  template = file("${path.module}/event_patterns/ec2-state-change.json")
  vars = {
    instances = join("\",\"", formatlist(format("arn:aws:ec2:%s:%s:instance/%%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id), aws_instance.kafka-server.*.id))
  }
}
