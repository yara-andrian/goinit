# GoInit
An opionated Makefile based Golang project initializer.

```
$$$$$$\            $$$$$$\           $$\   $$\      
$$  __$$\           \_$$  _|          \__|  $$ |    
$$ /  \__| $$$$$$\    $$ |  $$$$$$$\  $$\ $$$$$$\   
$$ |$$$$\ $$  __$$\   $$ |  $$  __$$\ $$ |\_$$  _|  
$$ |\_$$ |$$ /  $$ |  $$ |  $$ |  $$ |$$ |  $$ |    
$$ |  $$ |$$ |  $$ |  $$ |  $$ |  $$ |$$ |  $$ |$$\ 
\$$$$$$  |\$$$$$$  |$$$$$$\ $$ |  $$ |$$ |  \$$$$  |
 \______/  \______/ \______|\__|  \__|\__|   \____/ 
```

# Get Started

## Option 1: You have Go
Run the following:

```
go get -v github.com/zephinzer/goinit
```

Then in any directory you can run `goinit` and a Makefile will appear. Run `make init` and you're good to go.

To uninstall, run:

```sh
rm -rf $(go env | grep GOPATH | cut -f 2 -d '=' | sed -e 's|"||g')/src/github.com/zephinzer/goinit;
rm -rf $(go env | grep GOPATH | cut -f 2 -d '=' | sed -e 's|"||g')/bin/goinit;
```

## Option 2: You don't have Go and want a binary
Go to [the Releases tab], download a zip of the latest release and:

1. Unzip it.
1. In the `./bin` directory, copy the relevant binary out and move it to `/opt`.
1. Create a symlink of the binary (`ln -s /opt/goinit-linux-amd64 /usr/local/bin/goinit`)
1. Make the symlink executable (`chmod 550 /usr/local/bin/goinit`)

> Change `/usr/local/bin/goinit` to anywhere you deem fit.


## Option 3: You don't have Go and don't want a binary
Yes, I know binaries can be scary. You can make your own script out of the following to get the `Makefile` which `goinit` provisions:

```sh
curl -s -o "$(pwd)/Makefile" 'https://raw.githubusercontent.com/zephinzer/goinit/master/Makefile';
```

From the same directory you are in, run `make init`.

# Scope and Principles and Usage

## Monocommand Setup
It's tough enough to code, here's a single command to set up this initializer.

Run: `goinit` in an empty directory. The latest self-contained `Makefile` should appear.

## Develop Anywhere
I don't know about you but I dislike having all (even unrelated) Go projects at `$GOPATH`. Using containers allows us to write our code anywhere and this initializer works as such.

Run: `make init` in the directory you ran `goinit` in.

## Container-Ready
The environment generated using `goinit` accounts for both development and production within containers so that we don't touch your native system's Go. This reduces occurrences of *"it works on my machine"* and keeps your `$GOPATH` pristine. Heck, you don't even need Go installed on your system!

To build your application: `make build`

To build the production container: `make build.docker.production`

## Local Dependencies
Related to writing your Go application anywhere you deem fit (instead of where `$GOPATH` deems fit), this initializer uses `dep` to manage a local set of dependencies in a `vendor` directory. A `src` directory is symlinked to it so that code editors such as VSCode can use their spidey Intellisenses.

To initialise dependencies: `make dep.init`

To update dependencies: `make dep.ensure`

To run an arbitrary `dep` command: `make dep ARGS="whatever"`

## Quick Feedback
Fast feedback cycles allow us to iterate quicker. In development, code is live-reloaded as it is saved, same goes for tests.

- Realize by @oxequa is used for live-reloading of your application.
- A handy `auto-run.py` script by GoConvey is used for watching test files.

To start development, create a `main.go` and run `make start`

For libraries, create a `something.go` and a `something_test.go` and run `make test.watch`

## Pipeline Ready
Continuous integration/delivery is all part of the Agile hype - albeit a well-justified hype.

To run tests with coverage, run: `make test`

## Semver Versioning
This initializers enables easy bumping of patch, minor, and major versions. Good enough for smaller projects that just need to get up and going quickly.

To get the latest version, run: `make version.get`

To bump the PATCH version, run: `make version.bump`

To bump the MINOR version, run: `make version.bump.minor`

To bump the MAJOR version, run: `make version.bump.major`

# Motiviation
I'm by day a DevOps engineer and by night a Go newbie. In my efforts to learn Go, I decided to make setting up of a project as system-independent as possible so that I can do work on both my Mac and my Ubuntu. This should work on Windows too but it's not within my interest to support that. Contribute if it's broken/you wish!

# Contribution
- The `./src` directory contains all files which will be used in the Makefile.
- These files are copied into the Makefile on build and pushed to this repository.
- After modifying the scripts or Dockerfile, use the `./.make.sh` script to update the main `Makefile`.
- Then run `make build` to create the binaries.
- Push it to your fork and create a pull request.

# License
Code for this initializer is licensed under the MIT license. See [./LICENSE] for the full text.
