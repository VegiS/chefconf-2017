# ChefConf Talk

## 01 Build Binary

I am including curl because I'm on a mac and need to run supervisor locally, and
that's how i'll prove to you it's working.

```
$ cd 01-binary
```

```
$ hab studio enter
```

```
$ build
```

```
$ hab svc start sethvargo/http-echo
```

```
$ hab sup status
```

```
$ hab pkg install core/curl --binlink
$ export PATH=$PATH:/bin
```

```
$ sup-log
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
$ hab service stop sethvargo/http-echo
```

```
$ sup-log
```

Hmm - it looks like Habitat is sending SIGTERM to terminate the process. My
server is listening for SIGINT though. I want to change that behavior, so I'll
need to compile the binary myself.

Exit `hab studio`.

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

Edit the go file server.go to add `syscall.SIGTERM` to the listening signals.

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

Enter studio

```
$ hab studio enter
```

Build

```
$ build
```

Run

```
$ hab svc start sethvargo/http-echo
```

Show logs

```
$ sup-log
```

Stop

```
$ hab svc stop sethvargo/http-echo
```

Show logs again

```
$ sup-log
```

Show graceful stop

Exit studio

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

```
$ hab studio enter
```

```
$ build
```

```
$ hab pkg export docker sethvargo/http-echo
```

In new tab, on local laptop, start containers on different ports:

```
$ docker run -it --rm -p 5678:5678 -p 9638:9638 -p 9631:9631 sethvargo/http-echo --listen-gossip 0.0.0.0:9638 --listen-http 0.0.0.0:9631 --peer 172.17.0.2
$ docker run -it --rm -p 5679:5678 -p 9639:9639 -p 9632:9632 sethvargo/http-echo --listen-gossip 0.0.0.0:9639 --listen-http 0.0.0.0:9632 --peer 172.17.0.2
$ docker run -it --rm -p 5680:5678 -p 9640:9640 -p 9633:9633 sethvargo/http-echo --listen-gossip 0.0.0.0:9640 --listen-http 0.0.0.0:9633 --peer 172.17.0.2
```

Now start up the load balancer. This is a tiny Habitat plan I wrote that binds a
list of services to an upstream in nginx.

```
$ docker run -it --rm -p 80:80 sethvargo/nginx-lb --peer 172.17.0.2 --bind backend:http-echo.default
```

Open localhost:80 in browser and show load balancing.

But what if we want to change the configuration, like the text?

Inside the studio

```
$ hab config apply http-echo.default 2 <<< 'text = "Hello <something else>!"'
```

Great, but this is not much of a production scenario... how do I get this into
prod?

## 04 Production

So how do we get this in actual production. Well the easiest way is to use
Terraform to provision the infrastructure resources and Chef to configure those
resources.
