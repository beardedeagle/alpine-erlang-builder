# Docker + Alpine + Erlang = Love

This Dockerfile provides a good base build image to use in multistage builds for Erlang apps. It comes with the latest version of Alpine, Erlang and Rebar. It is intended for use in creating release images with or for your application and allows you to avoid cross-compiling releases. The exception of course is if your app has NIFs which require a native compilation toolchain, but that is left as an exercise let to the user.

No effort has been made to make this image suitable to run in unprivileged environments. The repository owner is not responsible for any loses that result from improper usage or security practices, as it is expected that the user of this image will implement proper security practices themselves.

## Software/Language Versions

```shell
Alpine 3.8
OTP/Erlang 21.1.3
Rebar 3.7.2
```

## Usage

To boot straight to a erl prompt in the image:

```shell
$ docker run --rm -i -t beardedeagle/alpine-erlang-builder erl
Erlang/OTP 21 [erts-10.1.3] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

Eshell V10.1.3  (abort with ^G)
1>
```
