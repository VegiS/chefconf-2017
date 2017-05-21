data "template_file" "server-base" {
  count    = "${var.servers}"
  template = "${file("${path.module}/templates/shared/base.sh")}"

  vars {
    hostname = "${var.namespace}-nomad-server-${count.index}"
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
  instance_type = "r3.large"
  key_name      = "${aws_key_pair.demo.id}"

  subnet_id              = "${element(aws_subnet.demo.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags {
    "Name" = "${var.namespace}-nomad-server-${count.index}"
  }

  user_data = "${join("\n",
    list(
      element(data.template_file.server-base.*.rendered, count.index),
      element(data.template_file.server-nomad.*.rendered, count.index),
    )
  )}"
}

output "servers" {
  value = ["${aws_instance.server.*.public_ip}"]
}
