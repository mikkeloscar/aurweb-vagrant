# AURweb vagrant setup

## Setup Virtualbox machine

First you need a base box with archlinux. An easy way to create one yourself is
to use `packer-io` from AUR along with
[packer-arch](https://github.com/elasticdog/packer-arch).

1. Install `packer-io` from AUR.

2. generate base box (can take some time)

  ```
  $ git clone https://github.com/elasticdog/packer-arch.git
  $ cd packer-arch/
  $ packer-io build -only=virtualbox-iso arch-template.json
  ```

3. Add the box to vagrant (note the name `arch` this is what the `Vagrantfile`
expects in the next steps)

  ```
  $ vagrant box add arch packer_arch_virtualbox.box
  ```

## Add Vagrant to aurweb

Copy or symlink `Vagrantfile` and `bootstrap.sh` into the root of your `aurweb`
repo. Change directory to `aurweb` and run `vagrant up`. This will boot a
virtual machine + install and setup everything needed for running aurweb. It
will also build `openssh-aur` which might take some time.

Copy `config` (from this repo) to `aurweb/conf/config` and modify to your needs.

When the machine is booted and ready the aur website will be available at
`http://localhost:8080` on your host machine. Phpmyadmin will be availble at
`http://localhost:8081`.

ssh is running at port 2222 and it is possible to login after you have added a
public key to a user in `aurweb` (The DB is initialized with 3 users, so it
easy to just add the pub-key to one of them through phpmyadmin).

`ssh -p 2222 aur@localhost`

to clone a package:

`git clone ssh://aur@localhost:2222/<package>.git`

## DB

The database is configured with the default values:

```
database: AUR
user: aur
password: aur
```
