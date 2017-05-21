data "template_file" "cleanup" {
  template = "${file("${path.module}/templates/shared/cleanup.sh")}"

  vars {
    server_ips = "${join(", ", formatlist("\"%s\"", aws_instance.server.*.private_ip))}"
  }
}

resource "null_resource" "cleanup" {
  count = "${var.servers + var.clients}"

  connection {
    host = "${element(concat(aws_instance.server.*.public_ip, aws_instance.client.*.public_ip), count.index)}"
    user = "ubuntu"
  }

  depends_on = [
    "aws_instance.server",
    "aws_instance.client",
  ]

  provisioner "remote-exec" {
    inline = [
      "${data.template_file.cleanup.rendered}",
    ]
  }
}
