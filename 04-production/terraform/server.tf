data "template_file" "server-base" {
  count    = "${var.servers}"
  template = "${file("${path.module}/templates/shared/base.sh")}"

  vars {
    hostname = "${var.namespace}-nomad-server-${count.index}"
  }
}

data "template_file" "server-consul" {
  count    = "${var.servers}"
  template = "${file("${path.module}/templates/server/consul.sh")}"

  vars {
    servers        = "${var.servers}"
    hostname       = "${var.namespace}-nomad-server-${count.index}"
    consul_version = "${var.consul_version}"
  }
}

data "template_file" "server-nomad" {
  count    = "${var.servers}"
  template = "${file("${path.module}/templates/server/nomad.sh")}"

  vars {
    servers       = "${var.servers}"
    hostname      = "${var.namespace}-nomad-server-${count.index}"
    nomad_version = "${var.nomad_version}"
  }
}

resource "aws_instance" "server" {
  count = "${var.servers}"

  ami           = "${data.aws_ami.ubuntu-1604.id}"
  instance_type = "r3.xlarge"
  key_name      = "${aws_key_pair.demo.id}"

  subnet_id              = "${element(aws_subnet.demo.*.id, count.index)}"
  iam_instance_profile   = "${aws_iam_instance_profile.consul-join.name}"
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags {
    "Name"   = "${var.namespace}-nomad-server-${count.index}"
    "consul" = "consul"
  }

  user_data = "${join("\n",
    list(
      element(data.template_file.server-base.*.rendered, count.index),
      element(data.template_file.server-consul.*.rendered, count.index),
      element(data.template_file.server-nomad.*.rendered, count.index),
      file("templates/shared/cleanup.sh"),
    )
  )}"
}

output "servers" {
  value = ["${aws_instance.server.*.public_ip}"]
}
