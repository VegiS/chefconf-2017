data "template_file" "client-base" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/shared/base.sh")}"

  vars {
    hostname = "${var.namespace}-nomad-client-${count.index}"
  }
}

data "template_file" "client-docker" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/client/docker.sh")}"
}

data "template_file" "client-habitat" {
  count    = "${var.clients}"
  template = "${file("${path.module}/templates/client/habitat.sh")}"
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
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.demo.id}"

  subnet_id              = "${element(aws_subnet.demo.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.demo.id}"]

  tags {
    "Name" = "${var.namespace}-nomad-client-${count.index}"
  }

  user_data = "${join("\n",
    list(
      element(data.template_file.client-base.*.rendered, count.index),
      element(data.template_file.client-docker.*.rendered, count.index),
      element(data.template_file.client-habitat.*.rendered, count.index),
      element(data.template_file.client-nomad.*.rendered, count.index),
    )
  )}"
}

output "clients" {
  value = ["${aws_instance.client.*.public_ip}"]
}
