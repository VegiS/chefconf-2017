data "template_file" "client-base" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/shared/base.sh")}"

  vars {
    hostname = "${var.namespace}-nomad-client-${count.index}"
  }
}

data "template_file" "client-consul" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/client/consul.sh")}"

  vars {
    hostname       = "${var.namespace}-nomad-client-${count.index}"
    consul_version = "${var.consul_version}"
  }
}

data "template_file" "client-nomad" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/client/nomad.sh")}"

  vars {
    hostname      = "${var.namespace}-nomad-client-${count.index}"
    nomad_version = "${var.nomad_version}"
  }
}

resource "aws_instance" "client" {
  count = "${var.clients}"

  ami           = "${data.aws_ami.ubuntu-1604.id}"
  instance_type = "r3.xlarge"
  key_name      = "${aws_key_pair.demo.id}"

  subnet_id              = "${element(aws_subnet.demo.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags {
    "Name"   = "${var.namespace}-nomad-client-${count.index}"
    "consul" = "consul"
  }

  user_data = "${join("\n",
    list(
      element(data.template_file.client-base.*.rendered, count.index),
      file("templates/client/docker.sh"),
      file("templates/client/habitat.sh"),
      element(data.template_file.client-consul.*.rendered, count.index),
      element(data.template_file.client-nomad.*.rendered, count.index),
      file("templates/shared/cleanup.sh"),
    )
  )}"

  connection {
    user = "ubuntu"
  }

  provisioner "file" {
    source      = "${path.module}/../jobs"
    destination = "/home/ubuntu"
  }
}

output "clients" {
  value = ["${aws_instance.client.*.public_ip}"]
}
