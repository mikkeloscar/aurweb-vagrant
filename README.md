# AURweb vagrant setup

## Setup Virtualbox machine

install `packer-io` from AUR.

```
$ git clone https://github.com/elasticdog/packer-arch.git
$ cd packer-arch/
$ packer-io build -only=virtualbox-iso arch-template.json
$ vagrant box add arch packer_arch_virtualbox.box
```

## Add Vagrant

Copy or symlink `Vagrantfile` and `bootstrap.sh` into the root of you `aurweb`
repo. Change directory to `aurweb` and run `vagrant up`. This will boot a
virtual machine + install and setup everything needed for running aurweb.

When the machine is booted and ready the aur website will be available at
`http://localhost:8080` on your host machine.
