# ChefConf Talk

This repository contains all the materials and a rough outline for my
[2017 ChefConf talk][talk] which discusses using Habitat, Terraform, and Nomad
for a better application experience.

This outline was written in advance of the presentation, so questions or
digressions may not be captured here in the fullest.

These configurations use Terraform 0.9.5, Nomad 0.5.6, and Habitat 0.24, but the
concepts are largely applicable to future releases (although commands and output
may differ).

Finally these are not "best practice" or even "recommended" configurations.
These configurations are optimized for learning and demonstration.

This talk focuses on the journey of an application from local development into
production, using Habitat, Terraform, and Nomad to ease the workflow. The
original version of this talk also used Chef. After testing and surveying, Chef
added an additional layer of abstraction that distracted from the overall goal,
so it was removed.

## Background

This talk uses a simple http server that is going to be the new hotness on the
Internet. This server is a single static go binary with no dependencies. It
binds to a port and echos some text given to it at runtime.

Here is an example of running the binary (no Habitat, no Docker, etc.):

```
$ cd hashicorp/http-echo
$ go build
$ ./http-echo -text="Hello ChefConf!"
$ (show in browser)
```

As I said before, this application is going to go viral. It's the next MySpace,
and I'm Tom.

## 01 Build Binary

I am going to use Habitat to distribute this thing. It's not a very complex
application, but it has dynamic configuration that can be updated at runtime.

```
$ cd 01-binary
```

```
$ hab studio enter
```

I am including curl in my `.studiorc` because I'm on a mac and need to run
supervisor locally, and that is how I'll prove to it's working.

```
$ build
```

```
$ hab svc start sethvargo/http-echo
hab-sup(MN): The supervisor is starting the sethvargo/http-echo service. See the supervisor output for more details.
```

```
$ hab sup status
sethvargo/http-echo/0.2.2/20170522062005, state:up, time:PT7.662687587S, pid:326, group:http-echo.default, style:transient
```

```
$ sup-log
<CTRL+C>
```

GRAB IP

```
$ curl 172.17.0.2:5678
```

```
Hello ChefConf!
```

Stop the service

```
$ hab svc stop sethvargo/http-echo
```

Let's look at the logs to make sure the service stopped:

```
$ sup-log
# ...
http-echo.default(SV): Stopping...
http-echo.default(O): 2017/05/22 06:45:02 [ERR] Unknown signal terminated
hab-sup(SV): http-echo.default - Shutdown method: Killed
<CTRL+C>
```

Hmm - it looks like Habitat is sending SIGTERM to terminate the process. My
server is listening for SIGINT though. I want to change that behavior, so I'll
need to compile the binary myself.

```
$ exit
```

## 02 Compile Source

```
$ cd 02-compile
```

```
$ ll
```

I have my go files, and my habitat folder.

```
$ ll source
```

Edit the go file `source/server.go` to add `syscall.SIGTERM` to the listening
signals.

But now I need to compile the binary, so we need to update our plan.

1. Bump version (we are making changes - add .dev)

    ```
    0.2.2.dev
    ```

1. Change pkg_soruce to `nope`:

    ```
    pkg_source=nope.tar.gz
    ```

1. Delete `pkg_filename` and `pkg_shasum`

1. Add `pkg_deps`:

    ```
    pkg_deps=(core/go)
    ```

1. Add return 0s:

    ```
    do_download() {
      return 0
    }

    do_verify() {
      return 0
    }

    do_unpack() {
      return 0
    }
    ```

Let's enter our studio to build.

```
$ hab studio enter
```

Just like before, we have to build our Habitat package.

```
$ build
```

And run it under the supervisor.

```
$ hab svc start sethvargo/http-echo
```

Show the logs to verify the service is running

```
$ sup-log
```

Stop the service, hopefully gracefully this time:

```
$ hab svc stop sethvargo/http-echo
```

Show logs again to check if the service stopped gracefully

```
$ sup-log
<CTRL+C>
```

Exit studio

```
$ exit
```

## 03 Load Balance

```
$ cd 03-dynamic
```

Edit the `run` hook so that the "text" includes the hostname

```sh
TEXT="$(cat <<-EOH
{{cfg.text}}
I am {{sys.hostname}}
EOH
)"

exec http-echo \
  -listen="{{sys.ip}}:{{cfg.port}}" \
  -text="$TEXT" \
  2>&1
```

Enter the studio and build

```
$ hab studio enter
```

Build the habitat package

```
$ build
```

Since the habitat supervisor can only run one instance of an application at a
time, we'll need to export these as Docker containers.

```
$ hab pkg export docker sethvargo/http-echo
```

In a new tab, start this container:

```
$ docker run -it sethvargo/http-echo
```

Grab the IP and start another one, passing in the `--peer` flag

```
$ docker run -it sethvargo/http-echo --peer 172.17.0.5
```

You should see the hooks recompile. Let's start a third one:

```
$ docker run -it sethvargo/http-echo --peer 172.17.0.5
```

All the hooks are compiled, but we didn't bind any ports back to my local
laptop, so there's no easy way for me to make sure these are running.

Let's start a load balancer container that I wrote. This uses habitat binds to
pull the list of peers.

```
$ docker run -it -p 80:80 sethvargo/nginx-lb --peer 172.17.0.5 --bind backend:http-echo.default
```

Notice here I _am_ binding port 80 in the container to port 80 on my local
laptop. This means I can query `localhost` to reach the load balancer, which
will route requests to one of the upstreams.

In a new tab:

```
$ curl localhost
```

And we can see that it's changing with `watch`:

```
$ watch -n 1 -ptd curl -s localhost
```

But what if we want to change the configuration, like the text? Let's go back
into our studio and apply some configuration changes:

```
$ hab config apply --peer 172.17.0.5 http-echo.default 2 <<< 'text = "Hello <something else>!"'
```

You can see all our containers restarted gracefully and are now rendering the
new text.

Great, but I don't know about you, but I don't run production on my laptop...
how do I get this into a production-like scenario?

(Stop all containers)

## 04 Production

So how do we get this in actual production. Well the easiest way is to use
Terraform to provision the infrastructure resources and ~Chef~ bash to configure
those resources.

```
$ cd 04-production
```

Let's spin up a production Nomad and Consul cluster using Terraform:

```
$ cd terraform/
$ terraform apply
```

I did this in advance, but it only takes about 3 minutes to spin up.

```
$ ssh ubuntu@<client_ip>
```

If you recall from the previous section, we had to spin up one peer, grap its IP
address, and then pass that as the peer to the other supervisors. Consul
provides a service discovery layer that makes this less manual.

In our production scenario, we are going to create a dedicated pool of
supervisors. These will not actually manage any applications, but simply provide
a single integration point for our other apps.

Instead of copy-pasting IP addresses, we will register the service with Consul,
and use Consul's DNS interface for peering.

Use Nomad to spin up "dedicated" habitat supervisor. Instead of copy-pasting IP
addresses, we'll use Consul to peer.

- Explain static ports
- Explain service registration -> Consul

```
$ nomad run jobs/hab-sup.nomad
```

This will start a permanent habitat supervisor. It is also registered with
Consul, meaning we can grab its IPs easily via the DNS interface - we don't
need to pass the IP each time.

Check the status of the job

```
$ nomad status hab
```

```
$ nomad alloc-status <alloc-id>
```

Could copy-paste IP, but Consul colves this for us!

```
$ dig +short hab-sup.service.consul
```

Great! Now we have an easy way for our instances of http-echo to peer without
knowing a supervisor IP address in advance. They can just use
`hab-sup.service.consul`!

Next, let's spin up a few http-echo services under Nomad.

- Explain configuring port allocation (dynamic)
- Explain gossip port allocation dynamic
- Note peer is just "hab-sup.service.consul"

```
$ nomad run jobs/http-echo.nomad
```

Run `nomad status` to see the job is running

```
$ nomad status http-echo
```

And then check the status of a single allocation

```
$ nomad alloc-status <alloc-id>
```

There will be a section like this

```
CPU       Memory          Disk    IOPS  Addresses
3/20 MHz  64 MiB/128 MiB  10 MiB  0     http: 10.1.1.140:45484
                                        hab_http: 10.1.1.140:54221
                                        hab_gossip: 10.1.1.140:23546
```

Notice that it's running on a very high port. This allows us to run multiple
services on the same instance. We can query this instance directly:

```
$ curl 10.1.1.140:45484
```

But this output cannot be easily automated (nor should it). Thankfully the nginx
server we wrote earlier can easily run under Nomad too.

- Explain system job
- Explain binding to 80

```
$ nomad run jobs/nginx-lb.nomad
```

We can check the status

```
$ nomad status nginx-lb
```

And now when we query localhost, we are round-robined to all healthy services

```
$ curl localhost
$ watch -tn 0.2 curl -s localhost
```

We bound to port 80 on the host because these are actually public-facing
instances bound to DNS. You can all hit this url in your browser.

```
https://nomad.hashicorp.rocks
```

As I said before, one of the advantages of dynamic ports is that we can really
scale up our service.

Update our `http-echo.nomad` job to run 50 instances and run.

And let's time it:

```
$ time nomad run http-echo.nomad
```

And after those containers start, they will start receiving traffic.

Do you think we can bump to 250? Let's try it out

```
$ time nomad run http-echo.nomad
```

## Bonus Round

Because we used Terraform and the entire process is automated, we can easily
scale up or down.

Edit the `terraform.tfvars` file to add more servers. Run `terraform apply`.
