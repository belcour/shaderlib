# Javascript library for WebGL + Reveal.JS

## Requirements

This library requires additional modules to be loaded. For testing purposes,
we provide them in `./tests/ext/`.

   + `JQuery` at tag 3.2.1

## Run the tests

To look at the tests and example, we advise to use the python simple web server using the following command:
```
$ python3 -m http.server
```

Once the web server is up, go to `127.0.0.1:4000/tests/` and browse the different tests.

## Usage

In you own repository, we advise to set the dependencies using submodules such as:

```
git submodule add https://github.com/jquery/jquery.git
cd jquery
git checkout f71eeda0fac4ec1442e631e90ff0703a0fb4ac96

```