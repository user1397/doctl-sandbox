# doctl-sandbox
"As a developer, I want to be able to quickly stand up and tear down a remote Linux server with some sane defaults/basic security so that I can have a reasonably secure sandbox to play around in and get on with my projects."

Deploy a [DigitalOcean](https://www.digitalocean.com/) droplet (Linux server) with some basic security using doctl and cloud-init.

This will create a droplet with a static IP and a network firewall with an ssh inbound rule tied only to your local public IP.  The droplet will also have a passwordless sudo user, and the following will be disabled:
- password auth
- root login
- x11 forwarding

The default SSH port is also changed, and the OS packages should be fully up to date. Everything is variable-ized so feel free to change anything you want.  The cloud-init.sh file can be expanded quite a lot.

I intentionally chose the cheapest droplet ($5/month) as a starting point, feel free to change the droplet size to whatever you want (see Helpful Stuff at the bottom).

## Prereqs
0. This guide works on Linux/MacOS/Windows (either with Git Bash or WSL)
1. Create a [DO account](https://cloud.digitalocean.com/registrations/new)
2. Create a [Personal Access Token (PAT)](https://docs.digitalocean.com/reference/api/create-personal-access-token/) with read/write permissions and store it somewhere safe
3. Create a local ssh key pair (defaults are fine): `ssh-keygen`
4. Install [doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/)
5. Authenticate with your PAT: `doctl auth init`

## How to Deploy
1. Clone repo, and `cd` into the directory: `cd doctl-sandbox`
2. Change variables as needed in `main.sh` and `cloud-init.sh`
3. Run `./main.sh create`
5. Log into the [DO web console](https://cloud.digitalocean.com), and copy the reserved IP located in Networking > Reserved IP
6. Connect to the instance (change values as needed):
```
ssh -p <SSH PORT> <USERNAME>@<RESERVED IP>

# e.g. given the defaults in the scripts:
ssh -p 55022 yolouser@<RESERVED IP>
```

   Note: It might take a couple minutes for everything to be provisioned and cloud-init to complete all its tasks.

7. Once connected, check if cloud-init completed successfully: `cloud-init status`

## How to Remove
To delete all resources, run: `./main.sh destroy`

## Helpful Stuff
#### SSH Config
On your local machine, create a new file in this location:
`~/.ssh/config`

And paste the following (change values as needed):
```
Host do
  HostName <RESERVED IP>
  User <USERNAME>
  Port <SSH PORT>
  IdentityFile /path/to/private/ssh/key
```
Then you can just run this to connect to your droplet:
`ssh do`

#### How to get a list of droplet sizes/images/regions
You can view all this information [here](https://slugs.do-api.dev) or alternatively, do the following:

- To get droplet size name list: `doctl compute size list`
- To get droplet image name list: `doctl compute image list --public`
- To get droplet region name list: `doctl compute region list`