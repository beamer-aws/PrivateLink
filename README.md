# Overview

This is a set of Terraform files and Ansible playbooks to deploy a PoC of
[AWS PrivateLink](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/aws-privatelink.html).

PrivateLink is a way of exposing resources in one AWS VPC to another VPC
without using VPC peering or VPNs. Instead, [endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html) 
and endpoint interfaces are created. This ensures that only a single service is
exposed at a time, and then only as an endpoint.

PrivateLink works for any protocol, including HTTP(S), SMTP etc. All traffic is
routed through an NLB and can be encrypted with TLS if so desired (recommended).

# Demonstration

To reiterate, this code functions as a proof of concept. These patterns can
be modified and re-used to build a production service based on PrivateLink.

# Architecture

The reference diagram on the above linked PrivateLink docs are implemented here.

This Terraform code deploys two VPCs and creates a VPC endpoint and a VPC endpoint
service, with an NLB encrypting TLS traffic over TCP port 443 and associated friendly
internal DNS names and routing.

The Ansible playbooks deploy two nginx webhosts, running `ProxyProtocol`. 
`ProxyProtocol` is described [here](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt). `ProxyProtocol` is also enabled on the NLB. Essentially,
this allows source IP preservation through the NLB. The practical upshot of this
is that the actual IPs of hosts accessing nginx are stored in the logs, instead
of the NLB's IP address.

# Pre-requisites

Update `terraform/cloud-init/base.yml` with your username and ssh keypair.

Create a new cert in AWS Certificate Manager for the NLB. This certificate will
be loaded into the NLB. By the default, data source looks for a cert with a domain
of `*.nlb.server`. This can be changed in `variables.tf`

# Deployment - Terraform

Initialize the Terraform provider:

`terraform init`

Validate the code is correct:

`terraform validate`

Run the Terrform code:

`terraform apply`

# Deployment - Ansible

In `ansible/files` update the certs and keys with ones you created in ACM.

Update the `/etc/ansible/hosts` file:

`ansible-playbook hosts.yml`

Configure the nginx web hosts:

`ansible-playbook deploy.yml`

Nginx should now be installed on the two hosts behind the NLB. With `ProxyProtocol`
configured, the hosts will not be directly reachable via `curl` or equivalents. The
web hosts will only respond via the NLB.

# Demonstration

From the `nlb-client-1` host, run the following:

`curl https://privatelink.nlb.dev`

If the ca-cert chain is not loaded into the `nlb-client-1` trusted certs, then
there may be a certificate error.

This can be ignored by adding the `-k` flag or directly specifying the trusted
cert with `--cacert /path/to/cacert.crt`.

In the `/var/log/nginx/access.log` on the nginx webhosts observe the source IP 
addresses are for the `nlb-client-1` and not for the NLB.