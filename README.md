# anti-ddos-terragrunt-aws
Automated Anti-DDoS Protection for websites / workloads on with the help of AWS

## Description:
During the last years company faced many DDoS attacks on websites and other web resources.
Traditionally, to mitigate I have been using
- SYN floods and UDP reflection attacks (L3, L4)
  - iproute2/blackhole, iptables/drop/connlimit
- HTTP floods (L7)
  - limit_req, limit_conn, blacklist, geo/map for  on reverse proxies nginx
  - Additional techniques I used on L7:
     - Responding with HTTP/200 OK to non-standard user-agents and collected IP addresses of botnet.
      - Returning 401/Unauthorized in case of password brute-force attempts.
        - In both cases, attackers continued to expend resources, unaware that they were not achieving their goal and not devising new strategies.

However, these approaches are not been efficient against recent large-scale attacks involving thousands of diverse IPs globally and request rates exceeding 40,000 requests per second (HTTP Flood).
While relying on CloudFlare for protection is quite good (but not a silver bullet), enterprise constraints often prevent such a solution, due to CloudFlare requiring delegating domain to them. 

That project documents my efforts on implementing AntiDDOS using AWS for colleagues who may not have experience with AWS. It might be helpful for others as well

## Objectives
1. Quickly deploy temporary protection even for those unfamiliar with AWS
1. Activate protection for multiple projects/sites at once
1. Enable protection across different AWS accounts, as enterprises often have separate accounts for financial reasons
   - And we can use several  "sleeping" AWS accounts credited 300$ USD by AWS to avoid paying on our own. Usually, such offer come to new accounts - all you need to do is fill out the form 

## Prerequisites
AWS CLI with configured profiles on each account through 
- `aws configure`
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- Access to SSL certificates

## Implementation:
The protection is implemented using the following scheme:
> [!NOTE]
> [Global Accelerator](https://aws.amazon.com/global-accelerator/) → Application Load Balancer with AWS WAF/Shield → EC2 instance with Nginx reverse proxy, one set for each site

Protection against DDoS in AWS is managed by two services:
- Attacks at Layer 3 and 4 - AWS Shield
- Attacks at Layer 6 and 7 - AWS WAF (Web Application Firewall)
 
Every Elastic Load Balancer (ELB) is automatically protected by AWS Shield Standard, but ELB provides a DNS name, not an IP address. Since our DNS records are primarily not in Route 53, we won't be able to add the ELB name to the DNS for the root/apex domain (example.com)
- example.com :thumbsdown:
- www.example.com :thumbsup:

It is not what we are looking for

To solve this problem, we will use the AWS Global Accelerator service, which is also integrated with AWS Shield and provides two unicast IP addresses. This will allow us to shift the entry point to the IP addresses instead of the ELB names, and we can switch through our DNS records.

- example.com :thumbsup:
- www.example.com :thumbsup:

## Steps:
Under the hood, there is automation using Terraform/Terragrunt and custom bash scripts

### Clone the repository
```
git clone https://github.com/baydakovss/anti-ddos-terragrunt-aws
```

I decided to simplify the deployment process by using a Makefile as a task runner. I've created a Makefile with prompts to assist in the setup

<details>
<summary>Click me</summary>
  
```console
$ make
help                           This help.
make-skeleton                  Make project skeleton folders
fetch-certificates             Fetch SSL certificates
generate-userdata              Generate userdata for setup nginx on start proxy
terragrunting                  Terraforming all project/sites
destroying                     Destroying all project/sites
make-iam                       Make IAM role and EC2 instance profile
get-outputs                    Get global accelerator ips
```
</details>


All further actions are carried out from the project's root folder.

### Create folder structure for the site, specifying AWS profile name, region, and site name:
```console
$ make make-skeleton
./helper.sh -a make_skeleton
Specify aws profile name:
account1
Specify aws region:
eu-central-1
Specify domain name:
example.com
```

After executing the command, subfolders with artifacts and a folder with code for deploying infrastructure will be created.

Artifacts:

<details>
<summary>Click me</summary>
  
```console
$ tree -L 3 assets/
assets/
─── example.com
    ├── certs
    ├── config.env-orig
    ├── scripts
    │   ├── make-script.sh
    │   ├── TEMPLATE.default.conf
    │   ├── TEMPLATE.install-nginx-centos.sh
    │   ├── TEMPLATE.INSTALL.sh
    │   ├── TEMPLATE.preconf-centos.sh
    │   ├── TEMPLATE.vars
    │   └── TEMPLATE.virtualhost.conf
    └── user-data
```
</details>

Infrastructure:
<details>
<summary>Click me</summary>
   
```console
$ tree -L 4 infrastructure/live/
infrastructure/live/
├── example.com
│   ├── common.hcl
│   └── profiles
│       └── account1
│           └── eu-central-1
├── global
│   └── profiles
│       └── account1
│           └── terragrunt.hcl
└── terragrunt.hcl
```
</details>

You can see the path:
```console
tree -L 3 infrastructure/live/example.com/
infrastructure/live/example.com/
├── common.hcl
└── profiles
    └── **account01**
        └── **eu-central-1**
```
Actually, you can copy `_template` folder to achieve the same result.

> [!NOTE]
> Terraform itself will determine, based on folder names, which AWS account to deploy to and in which region. 
> Perhaps it's not the most elegant solution from an IaC perspective, but it's a deliberate choice made for the sake of simplicity for unexperienced with AWS sysadmin's/IT managers...

> [!NOTE]
> For those who wonder why we don't create S3 bucket for remote state, explain that remote state and locking resources are created [automatically](https://terragrunt.gruntwork.io/docs/features/keep-your-remote-state-configuration-dry/#create-remote-state-and-locking-resources-automatically) by Terragrant
> 
> The names of S3 buckets include aws_account id to not overlap, like antiddos-${local.aws_account}-terraform-state


### For the site you can specify settings.
For example, whether to immediately enable protection for the site using AWS WAF and specify a whitelist.
As I connect AWS rules:
- AWS-AWSManagedRulesAnonymousIpList
- AWS-AWSManagedRulesAmazonIpReputationList
These rules block traffic from Tor, proxies, data center IPs (not people), and IPs recognized as bots that have participated in attacks on AWS before.

If legitimate IPs from data centers, such as from webhooks or partners, are being blocked, feel free to add them to the whitelist
```
cat /infrastructure/live/example.com/common.hcl
... 
inputs = {
  under_attack = 1
  whitelist = [
    "1.1.1.1/32",
  ]
...
}
```

### Get certificates:
`$ make fetch-certificates`

In my case, certificates will be downloaded from the centralized Let's Encrypt certificate deployment system.

Directory structure after fetching certificates:
```
tree -L 4 assets/example.com/certs/
assets/example.com/certs/
├── TEMPLATE.cert.pem
├── TEMPLATE.chain.pem
├── TEMPLATE.fullchain.pem
└── TEMPLATE.privkey.pem
```
You can modify the certificate copying process in the `fetch_certs()` function of the bash script `./helper`. 
Alternatively, you can manually place files with names TEMPLATE.{cert,chain,fullchain,privkey}.pem in the assets/example.com/certs folder.
> [!NOTE]
> If there is no separate chain.pem, you can use fullchain.pem instead.

### Create global resources
Create global resources for all profiles in folder's hierarchy (IAM role, Instance Profile) - once for added websites and associated AWS accounts

`$ make make-global`


### Generate user-data script 
Generate user-data script INSTALL.sh using due first start EC2 instance (nginx).
`$ make generate-userdata`
As a result, script INSTALL.sh will be created with all necessary artifacts inside for all projects: certs, nginx confs
```
ls -1 assets/example.com/user-data/
INSTALL.sh
```
### Launch the deployment.
$ make terragrunting
The deployment process will start for all workloads at once and takes about 20 minutes, mainly due to the long initialization of AWS Global Accelerators.

### Obtain the IP addresses from AWS Global Accelerator
<details>
<summary>Click me</summary>
   
```
$ make get-outputs
Outputs:

_project = "example-com"
_region = {
  "description" = "Europe (Frankfurt)"
  "endpoint" = "ec2.eu-central-1.amazonaws.com"
  "id" = "eu-central-1"
  "name" = "eu-central-1"
}
ec2_public_ips = [
  "3.77.247.101",
]
ga_ips = tolist([
  {
    "ip_addresses" = tolist([
      "75.2.30.52",
      "99.83.211.6",
    ])
    "ip_family" = "IPv4"
  },
])
under_attack = 1
whitelist = tolist([
  {
    "ip_addresses" = tolist([
      "75.2.30.52",
      "99.83.211.6",
    ])
    "ip_family" = "IPv4"
  },
])
```
</details>

Since the reverse proxy connects to the upstream/backnend with the EC2's IP address, if you need to see the real client IPs, you should ask the sysadmins to add the EC2's IP to the trusted list like this
```
set_real_ip_from  ec2_ip_address;
real_ip_header    X-Forwarded-For;
real_ip_recursive on;
```
If configured correctly, the site logs will display different IPs from external users; if configured incorrectly, the logs will show the same IP as the upstream proxy

### Check it is working
```
curl -I --connect-to ::global_accelerator_ip https://www.example.comHTTP/2 200
server: nginx/1.23.1
date: Wed, 20 Dec 2023 06:31:07 GMT
content-type: text/html; charset=UTF-8
```

### Change DNS
Change [www.]example.com to be pointed to one of global accelerators IPs

### Advantages antiddos with AWS WAF
- Does not require DNS-delegation
- We can switch to AWS WAF and expose our SSL to third-party (AWS) only temporarily when we under attack and then switch over back
- Provides free protection against L3/4 level attacks.
- - This is because our Global Accelerator listeners are not TCP/UDP but HTTP/S (L7).
- Offers customization, including the use of third-party web firewalls that specialize in this.
- Successfully handled the DDoS higher than 40.000 requests per second)

### Costs
#### Infrastructure cost for 1 month for one project via infracost
<details>
   
<summary>Click me</summary>

```console
infracost breakdown --path .
Project: baydakovss/anti-ddos-aws-terragrunt/infrastructure/live/example.com/profiles/account1/us-east-1
Module path: profiles/sv/us-east-1

 Name                                                      Monthly Qty  Unit                  Monthly Cost

 aws_globalaccelerator_accelerator.this
 └─ Fixed fee                                                      730  hours                       $18.25

 aws_instance.proxy
 ├─ Instance usage (Linux/UNIX, on-demand, t3.micro)               730  hours                        $7.59
 └─ root_block_device
    └─ Storage (general purpose SSD, gp2)                            8  GB                           $0.80

 aws_lb.public
 ├─ Application load balancer                                      730  hours                       $16.43
 └─ Load balancer capacity units                      Monthly cost depends on usage: $5.84 per LCU

 aws_wafv2_web_acl.this
 ├─ Web ACL usage                                                    1  months                       $5.00
 ├─ Rules                                                            3  rules                        $3.00
 └─ Requests                                          Monthly cost depends on usage: $0.60 per 1M requests

 OVERALL TOTAL                                                                                      $51.07
```

</details>

#### Cost for requests
```$0.60 per million requests processed```

This is an actual example of the cost for the defense of one of our projects from October 30th to October 31st

```console
AWS WAF EUC1-RequestV2-Tier1
$0.60 per million requests processed 191,026,951 Request	USD 114.62
```

