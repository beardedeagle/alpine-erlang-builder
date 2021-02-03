# Docker + Alpine + Erlang = Love

This Dockerfile provides a good base build image to use in multistage builds for Erlang apps. It comes with the latest version of Alpine, Erlang and Rebar. It is intended for use in creating release images with or for your application and allows you to avoid cross-compiling releases. The exception of course is if your app has NIFs which require a native compilation toolchain, but that is an exercise left to the user.

No effort has been made to make this image suitable to run in unprivileged environments. The repository owner is not responsible for any loses that result from improper usage or security practices, as it is expected that the user of this image will implement proper security practices themselves.

## Software/Language Versions

```shell
Alpine 3.13.1
OTP/Erlang 23.2.3
Rebar 3.14.3
Git 2.30.0
```

## Usage

To boot straight to a erl prompt in the image:

```shell
$ docker run --rm -i -t beardedeagle/alpine-erlang-builder erl
Erlang/OTP 23 [erts-11.1.7] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1]

Eshell V11.1.7  (abort with ^G)
1>
```
