resource "aws_alb" "demo" {
  name = "${var.namespace}-demo"

  security_groups = ["${aws_security_group.demo.id}"]
  subnets         = ["${aws_subnet.demo.*.id}"]

  tags {
    Name = "${var.namespace}-demo"
  }
}

resource "aws_alb_target_group" "demo" {
  name     = "${var.namespace}-demo"
  port     = "80"
  vpc_id   = "${aws_vpc.demo.id}"
  protocol = "HTTP"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/"
    port              = "80"
    protocol          = "HTTP"
    healthy_threshold = 2
  }
}

resource "aws_alb_listener" "demo" {
  load_balancer_arn = "${aws_alb.demo.arn}"

  port     = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.demo.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "demo" {
  count            = "${var.clients}"
  target_group_arn = "${aws_alb_target_group.demo.arn}"
  target_id        = "${element(aws_instance.client.*.id, count.index)}"
  port             = "80"
}
