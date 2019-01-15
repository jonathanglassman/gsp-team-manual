
## Introduction

This material was collated as part of the Techops 2018/2019 Q4 Firebreak (see the  [Trello card](https://trello.com/c/zsM9bQys) for the background) and brings together some learnings about diagnosing issues with kubernetes clusters and some recommended tools.

## Table of contents

- [Setup](#Setup)
  - [Tools](#Tools)
  - [Install Tools](#Install-Tools)
  - [Account set up](#AWS-Account-setup)
  - [Add User to gsp-bootstrap](#Add-user-to-gsp-bootstrap)
  - [Test aws-vault ](#Test-aws-vault)
- [Provisioning a GSP Cluster](#Provisioning-a-GSP-Cluster)
  - [Generate Terraform Configuration](#Generate-Terraform-Configuration)
  - [Create cluster](#Create-cluster)
  - [Apply addons to cluster](#Apply-addons-to-cluster)
  - [Destroy a cluster](#Destroy-a-cluster)
- [Inspecting the cluster](#Inspecting-the-cluster)
  - [Launch aws console using aws-vault](#Launch-AWS-console-using-aws-vault)
  - [Run aws-shell against the infrastructure](#Run-aws-shell-against-the-AWS-infrastructure)
  - [Use the kubernetes dashboard](#Use-the-kubernetes-dashboard)  
  - [kubectl completion](#kubectl-completion)
  - [aliasing the kubectl binary](#Aliasing-the-kubectl-binary)
  - [Use kubectl](#Use-kubectl)
  - [Log into a Node (Master or worker)](#Log-into-a-Node-Master-or-worker)
  - [Dump a cluster configuration](#Dump-cluster-configuration)
- [Reference](#Reference)



## Setup

How to set up your tools to work with kubernetes


### Tools

Recommended tools to have at your disposal when working with kubernetes

|Package|Description|
|------------------|-----------|
|[aws-cli](https://aws.amazon.com/cli/) |AWS Command line interface|
|[aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator) |Additional app to allow authentication against IAM|
|[aws-shell](https://github.com/awslabs/aws-shell) |Helper package to help navigate the AWS infrastructure|
|[aws-vault](https://github.com/99designs/aws-vault) |Helper to manage keys using the osx keychain |
|[docker](https://www.docker.com/) |Docker Desktop for local container stuff, the install process uses gsp-docker-images/terraform to create a standardised cluster using a particular standardised terraform configuration |
|[go](https://golang.org/) |Go Language for aws-iam-athenticator|
|[homebrew](https://brew.sh/) |OSX package tool to install prerequisites |
|[helm](https://helm.sh/) |Kubernetes package manager|
|[jq](https://stedolan.github.io/jq/manual/)|json wrangling tool, recommended|
| [kail](https://github.com/boz/kail) | kubernetes log viewer, grab logs at node, ingress, namespace, pod or container level  
|[kompose](https://github.com/kubernetes/kompose)|Tool to convert docker-compose into kubernetes compatible yaml|
|[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) |Command line interface to kubernetes|
|[minikube](https://kubernetes.io/docs/setup/minikube/)|Local kubernetes environment for development and learning, requires virtualbox|
|[terraform](https://www.terraform.io/) |terraform to apply the configurations in gsp-bootstrap|
|[virtualbox](https://www.virtualbox.org/)|Hypervisor - only required if you want to user minikube|

### Install Tools

The following instructions assume you are using a mac.

[install docker](https://docs.docker.com/docker-for-mac/install/) 

![](https://docs.docker.com/docker-for-mac/images/docker-app-drag.png)

If you need homebrew you can install it as follows:

```/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"```

Install some tools individually
```
brew install awscli
brew install aws-shell
brew install aws-vault
brew install go
brew install jq
brew install kubernetes-cli
brew install kubernetes-helm
cask install virtualbox
cask install minikube
go get -u -v github.com/kubernetes-sigs/aws-iam-authenticator/cmd/aws-iam-authenticator
```

or create a local file called Brewfilew containing

```
tap "homebrew/bundle"
tap "homebrew/cask"
tap "homebrew/core"
tap "homebrew/services"
tap "boz/repo"

# essentials
brew "jq"
brew "kubernetes-cli"
brew "kubernetes-helm"

# worth having
cask "minikube"
cask "virtualbox"
brew "s3cmd"
brew "kubespy"
brew "boz/repo/kail"

```

and then run

```
brew bundle
```

and it will install all the dependencies

## AWS Account setup

Get a gds-user account [`here`](https://gds-request-an-aws-account.cloudapps.digital/) if you do not have one. At GDS we get access to AWS by assuming a role into the approriate account from their gds-user account.

## aws-vault setup

Full instructions in the [Reliability Engineering Team Manual](https://reliability-engineering.cloudapps.digital/iaas.html#installing-aws-vault) 

```aws-vault add gds-users```

Your config (~/.aws/config) needs to look something like:

```
[profile gds-users]
region=eu-west-2
mfa_serial=arn:aws:iam::622626885786:mfa/paul.dougan@digital.cabinet-office.gov.uk

[profile run-sandbox]
source_profile=gds-users
role_arn=arn:aws:iam::011571571136:role/admin
mfa_serial=arn:aws:iam::622626885786:mfa/paul.dougan@digital.cabinet-office.gov.uk
[default]
region = eu-west-2
output = text
```

## Add user to gsp-bootstrap

 

Raise a PR to [`this`](https://github.com/alphagov/gsp-bootstrap/blob/master/modules/users/main.tf) to add your profile and get a member of the RE build and run team o merge and apply the terraform.

Read more about [gsp-bootstrap
](https://github.com/alphagov/gsp-bootstrap)


## Test aws-vault 

aws-vault securely manages AWS credentials and automatically manages the following environment variables

|Variable| Description |
|-|-|
| AWS_ACCESS_KEY_ID     | set by aws-vault                        |
| AWS_SECRET_ACCESS_KEY | set by aws-vault                        |
| AWS_SESSION_TOKEN     | set by aws-vault                        |
| AWS_SECURITY_TOKEN    | set by aws-vault                         |

Display aws-vault managed environment variables
```
aws-vault exec run-sandbox -- env | grep AWS
```

aws-vault help
```
aws-vault 
usage: aws-vault [<flags>] <command> [<args> ...]

A vault for securely storing and accessing AWS credentials in development environments.

Flags:
  --help                  Show context-sensitive help (also try --help-long and --help-man).
  --version               Show application version.
  --debug                 Show debugging output
  --backend=BACKEND       Secret backend to use [keychain file]
  --prompt=terminal       Prompt driver to use [terminal osascript]
  --keychain="aws-vault"  Name of macOS keychain to use, if it doesn't exist it will be created

Commands:
  help [<command>...]
    Show help.

  add [<flags>] <profile>
    Adds credentials, prompts if none provided

  list [<flags>]
    List profiles, along with their credentials and sessions

  rotate [<flags>] <profile>
    Rotates credentials

  exec [<flags>] <profile> [<cmd>] [<args>...]
    Executes a command with AWS credentials in the environment

  remove [<flags>] <profile>
    Removes credentials, including sessions

  login [<flags>] <profile>
    Generate a login link for the AWS Console
```

Check that you have access to the AWS command line interface
```
aws-vault exec run-sandbox -- aws ec2 describe-regions
```

Check the profiles managed by aws-vault
```
aws-vault list

Profile                  Credentials              Sessions                 
=======                  ===========              ========                 
gds-users                gds-users                -                        
run-sandbox              gds-users                -                        
default                  -                        -   
```

## Provisioning a GSP Cluster

**NOTE THAT AS I TYPE THIS ENTIRE SECTION IS BECOMING OBSOLETE, BY MONDAY 14 JAN THE TERRAFORM WILL HAVE BEEN REFACTORED SO THAT IS IS CLEANER, THIS WILL BE REWORKED ONCE ITS CLEAR HOW THE NEW CLUSTERS WILL WORK**

How the clusters are provisioned, the full details are contained in the [gsp-teams](https://github.com/alphagov/gsp-teams) repo

### Generate Terraform Configuration

The terraform to provision the cluster is created by a script and the following environment variables need to be set before the configuration is generated. 

| Variable              | Value                        |
|-----------------------|------------------------------|
| AWS_ACCOUNT_NAME      | re-run-sandbox                   |
| AWS_REGION            | eu-west-2                    |
| AWS_DEFAULT_REGION    | eu-west-2                    |
| CLUSTER_NAME          | pauld                        |
| DOMAIN                | re-sandbox.aws.ext.govsvc.uk |
| ZONE_ID               | Z23SW7QP3LD4T                |
| ZONE_NAME             | XXXX                         |
| AWS_ACCESS_KEY_ID     | automatically set by aws-vault                        |
| AWS_SECRET_ACCESS_KEY | automatically set by aws-vault                        |
| AWS_SESSION_TOKEN     | automatically set by aws-vault                        |
| AWS_SECURITY_TOKEN    | automatically set by aws-vault                         |


Export the above variables:
```
export AWS_ACCOUNT_NAME=re-run-sandbox
export AWS_REGION=eu-west-2
export AWS_DEFAULT_REGION=${AWS_REGION}
export CLUSTER_NAME=pauld
export ZONE_ID=Z23SW7QP3LD4TS
export ZONE_NAME=run-sandbox.aws.ext.govsvc.uk
export DOMAIN=${CLUSTER_NAME}.${AWS_ACCOUNT_NAME}.aws.ext.govsvc.uk
```


With the above variables you can run:

`aws-vault exec run-sandbox -- ./scripts/create_cluster_config.sh`

This generates the terraform for the cluster at


`terraform/clusters/${CLUSTER_NAME}.${AWS_ACCOUNT_NAME}.aws.ext.govsvc.uk/cluster.tf`

[![asciicast](https://asciinema.org/a/217619.svg)](https://asciinema.org/a/217619)


### Create cluster


```
cd terraform/clusters/${DOMAIN}
```

Initialise Terraform
```
aws-vault exec run-sandbox -- docker run -it \
  --env AWS_DEFAULT_REGION \
  --env AWS_REGION \
  --env AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY \
  --env AWS_SESSION_TOKEN \
  --env AWS_SECURITY_TOKEN \
  --env DOMAIN \
  --volume=$(pwd)/../../../:/terraform -w /terraform/terraform/clusters/${DOMAIN} \
  govsvc/terraform init
```

Check the plan
```
aws-vault exec run-sandbox -- docker run -it \
  --env AWS_DEFAULT_REGION \
  --env AWS_REGION \
  --env AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY \
  --env AWS_SESSION_TOKEN \
  --env AWS_SECURITY_TOKEN \
  --env DOMAIN \
  --volume=$(pwd)/../../../:/terraform -w /terraform/terraform/clusters/${DOMAIN} \
  govsvc/terraform plan
```

apply the terraform
```
aws-vault exec run-sandbox -- docker run -it \
   --env AWS_DEFAULT_REGION \
   --env AWS_REGION \
   --env AWS_ACCESS_KEY_ID \
   --env AWS_SECRET_ACCESS_KEY \
   --env AWS_SESSION_TOKEN \
   --env AWS_SECURITY_TOKEN \
   --env DOMAIN \
   --volume=$(pwd)/../../../:/terraform -w /terraform/terraform/clusters/${DOMAIN} \
   govsvc/terraform apply 

```

[![asciicast](https://asciinema.org/a/217620.svg)](https://asciinema.org/a/217620)

### Apply addons to cluster

This adds a number of components to the freshly created cluster by recursively applying all the YAML in the addons directory

```
flux.yaml
gsp-base-helm-release.yaml
gsp-base-namespace.yaml
gsp-canary-helm-release.yaml
gsp-canary-namespace.yaml
monitoring-system-helm-release.yaml
monitoring-system-namespace.yaml
secrets-system-helm-release.yaml
secrets-system-namespace.yaml
```
to apply all the yaml to the cluster 
```
aws-vault exec run-sandbox -- kubectl apply -Rf addons/
```

`-R` recursively processes the directory

Note that if this throws an error you can re-run the commnd safely and it should resolve itself (errors likely due to interdependencies)

### Destroy a cluster

When you are done with the cluster go to the directory containing the terraform and run the following.

```
aws-vault exec run-sandbox -- docker run -it \
   --env AWS_DEFAULT_REGION \
   --env AWS_REGION \
   --env AWS_ACCESS_KEY_ID \
   --env AWS_SECRET_ACCESS_KEY \
   --env AWS_SESSION_TOKEN \
   --env AWS_SECURITY_TOKEN \
   --env DOMAIN \
   --volume=$(pwd)/../../../:/terraform -w /terraform/terraform/clusters/${DOMAIN} \
   govsvc/terraform destroy  

```

this will tear down the the cluster and delete all the AWS resources

## Inspecting the cluster

### Launch AWS console using aws-vault

This will handle authentication and launch the web based AWS console. Note that aws-vault will ask for the keychain password and also you may be prompted to enter an MFA token
```
aws-vault login run-sandbox
```

### kubectl completion

https://kubernetes.io/docs/tasks/tools/install-kubectl/#enabling-shell-autocompletion


### Aliasing the kubectl binary

All kubectl calls must be perfomed using aws-vault to manage the authentication

you may want to consider defining an alias to simplify using the command in your shell.

Normally a command would be of the form

`aws-vault exec run-sandbox -- kubectl get pods`

to avoid the long pre-amble add 

`alias k="aws-vault exec run-sandbox -- kubectl"`

to your shell configuration

you can then type

`k get po`

### Use kubectl

see: https://kubernetes.io/docs/reference/kubectl/cheatsheet/ 

#### kubectl api-resources
```
aws-vault exec run-sandbox -- kubectl api-resources
NAME                              SHORTNAMES   APIGROUP                       NAMESPACED   KIND
bindings                                                                      true         Binding
componentstatuses                 cs                                          false        ComponentStatus
configmaps                        cm                                          true         ConfigMap
endpoints                         ep                                          true         Endpoints
events                            ev                                          true         Event
limitranges                       limits                                      true         LimitRange
namespaces                        ns                                          false        Namespace
nodes                             no                                          false        Node
persistentvolumeclaims            pvc                                         true         PersistentVolumeClaim
persistentvolumes                 pv                                          false        PersistentVolume
pods                              po                                          true         Pod
podtemplates                                                                  true         PodTemplate
replicationcontrollers            rc                                          true         ReplicationController
resourcequotas                    quota                                       true         ResourceQuota
secrets                                                                       true         Secret
serviceaccounts                   sa                                          true         ServiceAccount
services                          svc                                         true         Service
mutatingwebhookconfigurations                  admissionregistration.k8s.io   false        MutatingWebhookConfiguration
validatingwebhookconfigurations                admissionregistration.k8s.io   false        ValidatingWebhookConfiguration
customresourcedefinitions         crd,crds     apiextensions.k8s.io           false        CustomResourceDefinition
apiservices                                    apiregistration.k8s.io         false        APIService
controllerrevisions                            apps                           true         ControllerRevision
daemonsets                        ds           apps                           true         DaemonSet
deployments                       deploy       apps                           true         Deployment
replicasets                       rs           apps                           true         ReplicaSet
statefulsets                      sts          apps                           true         StatefulSet
tokenreviews                                   authentication.k8s.io          false        TokenReview
localsubjectaccessreviews                      authorization.k8s.io           true         LocalSubjectAccessReview
selfsubjectaccessreviews                       authorization.k8s.io           false        SelfSubjectAccessReview
selfsubjectrulesreviews                        authorization.k8s.io           false        SelfSubjectRulesReview
subjectaccessreviews                           authorization.k8s.io           false        SubjectAccessReview
horizontalpodautoscalers          hpa          autoscaling                    true         HorizontalPodAutoscaler
cronjobs                          cj           batch                          true         CronJob
jobs                                           batch                          true         Job
sealedsecrets                                  bitnami.com                    true         SealedSecret
certificatesigningrequests        csr          certificates.k8s.io            false        CertificateSigningRequest
certificates                      cert,certs   certmanager.k8s.io             true         Certificate
clusterissuers                                 certmanager.k8s.io             false        ClusterIssuer
issuers                                        certmanager.k8s.io             true         Issuer
leases                                         coordination.k8s.io            true         Lease
bgpconfigurations                              crd.projectcalico.org          false        BGPConfiguration
bgppeers                                       crd.projectcalico.org          false        BGPPeer
clusterinformations                            crd.projectcalico.org          false        ClusterInformation
felixconfigurations                            crd.projectcalico.org          false        FelixConfiguration
globalnetworkpolicies                          crd.projectcalico.org          false        GlobalNetworkPolicy
globalnetworksets                              crd.projectcalico.org          false        GlobalNetworkSet
hostendpoints                                  crd.projectcalico.org          false        HostEndpoint
ippools                                        crd.projectcalico.org          false        IPPool
networkpolicies                                crd.projectcalico.org          true         NetworkPolicy
events                            ev           events.k8s.io                  true         Event
daemonsets                        ds           extensions                     true         DaemonSet
deployments                       deploy       extensions                     true         Deployment
ingresses                         ing          extensions                     true         Ingress
networkpolicies                   netpol       extensions                     true         NetworkPolicy
podsecuritypolicies               psp          extensions                     false        PodSecurityPolicy
replicasets                       rs           extensions                     true         ReplicaSet
helmreleases                      hr           flux.weave.works               true         HelmRelease
alertmanagers                                  monitoring.coreos.com          true         Alertmanager
prometheuses                                   monitoring.coreos.com          true         Prometheus
prometheusrules                                monitoring.coreos.com          true         PrometheusRule
servicemonitors                                monitoring.coreos.com          true         ServiceMonitor
networkpolicies                   netpol       networking.k8s.io              true         NetworkPolicy
poddisruptionbudgets              pdb          policy                         true         PodDisruptionBudget
podsecuritypolicies               psp          policy                         false        PodSecurityPolicy
clusterrolebindings                            rbac.authorization.k8s.io      false        ClusterRoleBinding
clusterroles                                   rbac.authorization.k8s.io      false        ClusterRole
rolebindings                                   rbac.authorization.k8s.io      true         RoleBinding
roles                                          rbac.authorization.k8s.io      true         Role
priorityclasses                   pc           scheduling.k8s.io              false        PriorityClass
storageclasses                    sc           storage.k8s.io                 false        StorageClass
volumeattachments                              storage.k8s.io                 false        VolumeAttachment
```


#### kubectl get apiservices
```
kubectl get apiservices
NAME                                   SERVICE   AVAILABLE   AGE
v1.                                    Local     True        14d
v1.apps                                Local     True        14d
v1.authentication.k8s.io               Local     True        14d
v1.authorization.k8s.io                Local     True        14d
v1.autoscaling                         Local     True        14d
v1.batch                               Local     True        14d
v1.crd.projectcalico.org               Local     True        14d
v1.monitoring.coreos.com               Local     True        14d
v1.networking.k8s.io                   Local     True        14d
v1.rbac.authorization.k8s.io           Local     True        14d
v1.storage.k8s.io                      Local     True        14d
v1alpha1.bitnami.com                   Local     True        9h
v1alpha1.certmanager.k8s.io            Local     True        14d
v1beta1.admissionregistration.k8s.io   Local     True        14d
v1beta1.apiextensions.k8s.io           Local     True        14d
v1beta1.apps                           Local     True        14d
v1beta1.authentication.k8s.io          Local     True        14d
v1beta1.authorization.k8s.io           Local     True        14d
v1beta1.batch                          Local     True        14d
v1beta1.certificates.k8s.io            Local     True        14d
v1beta1.coordination.k8s.io            Local     True        14d
v1beta1.events.k8s.io                  Local     True        14d
v1beta1.extensions                     Local     True        14d
v1beta1.flux.weave.works               Local     True        14d
v1beta1.policy                         Local     True        14d
v1beta1.rbac.authorization.k8s.io      Local     True        14d
v1beta1.scheduling.k8s.io              Local     True        14d
v1beta1.storage.k8s.io                 Local     True        14d
v1beta2.apps                           Local     True        14d
v2beta1.autoscaling                    Local     True        14d
v2beta2.autoscaling                    Local     True        14d

```

#### kubectl version

#### kubectl get nodes

#### kubectl get namespaces

#### kubectl get pods --all-namespaces


#### kubectl describe pod

#### kubectl get events --namespace=my-namespace

kubectl describe node kubernetes-node-861h
kubectl exec -it shell-demo -- /bin/bash
kubectl exec shell-demo env
kubectl exec -it my-pod --container main-app -- /bin/bash



```
aws-vault exec run-sandbox -- kubectl api-resources
aws-vault exec run-sandbox -- kubectl version
aws-vault exec run-sandbox -- kubectl cluster-info
aws-vault exec run-sandbox -- kubectl get nodes
aws-vault exec run-sandbox -- kubectl get namespaces
aws-vault exec run-sandbox -- kubectl get pods --all-namespaces
aws-vault exec run-sandbox -- kubectl plugin list
aws-vault exec run-sandbox -- kubectl get ep
aws-vault exec run-sandbox -- kubectl get services


```




### Use Helm

```
helm help

The Kubernetes package manager

To begin working with Helm, run the 'helm init' command:

	$ helm init

This will install Tiller to your running Kubernetes cluster.
It will also set up any necessary local configuration.

Common actions from this point include:

- helm search:    search for charts
- helm fetch:     download a chart to your local directory to view
- helm install:   upload the chart to Kubernetes
- helm list:      list releases of charts

Environment:
  $HELM_HOME           set an alternative location for Helm files. By default, these are stored in ~/.helm
  $HELM_HOST           set an alternative Tiller host. The format is host:port
  $HELM_NO_PLUGINS     disable plugins. Set HELM_NO_PLUGINS=1 to disable plugins.
  $TILLER_NAMESPACE    set an alternative Tiller namespace (default "kube-system")
  $KUBECONFIG          set an alternative Kubernetes configuration file (default "~/.kube/config")
  $HELM_TLS_CA_CERT    path to TLS CA certificate used to verify the Helm client and Tiller server certificates (default "$HELM_HOME/ca.pem")
  $HELM_TLS_CERT       path to TLS client certificate file for authenticating to Tiller (default "$HELM_HOME/cert.pem")
  $HELM_TLS_KEY        path to TLS client key file for authenticating to Tiller (default "$HELM_HOME/key.pem")
  $HELM_TLS_VERIFY     enable TLS connection between Helm and Tiller and verify Tiller server certificate (default "false")
  $HELM_TLS_ENABLE     enable TLS connection between Helm and Tiller (default "false")
  $HELM_KEY_PASSPHRASE set HELM_KEY_PASSPHRASE to the passphrase of your PGP private key. If set, you will not be prompted for
                       the passphrase while signing helm charts

Usage:
  helm [command]

Available Commands:
  completion  Generate autocompletions script for the specified shell (bash or zsh)
  create      create a new chart with the given name
  delete      given a release name, delete the release from Kubernetes
  dependency  manage a chart's dependencies
  fetch       download a chart from a repository and (optionally) unpack it in local directory
  get         download a named release
  help        Help about any command
  history     fetch release history
  home        displays the location of HELM_HOME
  init        initialize Helm on both client and server
  inspect     inspect a chart
  install     install a chart archive
  lint        examines a chart for possible issues
  list        list releases
  package     package a chart directory into a chart archive
  plugin      add, list, or remove Helm plugins
  repo        add, list, remove, update, and index chart repositories
  reset       uninstalls Tiller from a cluster
  rollback    roll back a release to a previous revision
  search      search for a keyword in charts
  serve       start a local http web server
  status      displays the status of the named release
  template    locally render templates
  test        test a release
  upgrade     upgrade a release
  verify      verify that a chart at the given path has been signed and is valid
  version     print the client/server version information

Flags:
      --debug                           enable verbose output
  -h, --help                            help for helm
      --home string                     location of your Helm config. Overrides $HELM_HOME (default "/Users/pauldougan/.helm")
      --host string                     address of Tiller. Overrides $HELM_HOST
      --kube-context string             name of the kubeconfig context to use
      --kubeconfig string               absolute path to the kubeconfig file to use
      --tiller-connection-timeout int   the duration (in seconds) Helm will wait to establish a connection to tiller (default 300)
      --tiller-namespace string         namespace of Tiller (default "kube-system")

Use "helm [command] --help" for more information about a command.
```

The main reason to use Helm is for the templating capability since it is used to generate the kubeyaml for the deployment. 

### Use the kubernetes dashboard

The standard kubernetes dashboard provides a useful web interface into the cluster to allow inspection of the various resources.

see https://github.com/alphagov/gsp-team-manual/blob/master/docs/accessing-dashboard.md

Access requires a token to be pasted into the dashboard as follows:

```
aws-vault exec run-sandbox -- kubectl proxy &
aws-vault exec run-sandbox -- aws-iam-authenticator token -i pauld.run-sandbox.aws.ext.govsvc.uk | jq -r .status.token | pbcopy
open 'http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login'
```

http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login

![](https://i.imgur.com/Ujw9EFh.png)

### Log into a Node (Master or worker)

This is probably not an approach that can be relied on going forward since we do not intend to allow such low level access to the cluster nodes. The long term objective is to drive all deployments from github using a Continuous Integration layer based on Concourse. However whilst learning about kubernetes it is instructive to be able to get onto the underlying virtual machines to take a look.


Note that since we are using coreos the profile used to login is `core` and in the example the public IP address will need to be entered. 
```
aws-vault exec run-sandbox -- aws ssm get-parameter --name "/$(basename $PWD)/ssh-key" --with-decryption --output text --query Parameter.Value > ./id_rsa_cluster
chmod 600 ./id_rsa_david_cluster

ssh -i ./id_rsa_cluster core@PUBLIC_IP_ADDRESS.eu-west-2.compute.amazonaws.com
```

### Run aws-shell against the AWS infrastructure

Auto completion for AWS


``` aws-vault exec run-sandbox -- aws-shell```

![](https://aws-developer-blog-media.s3-us-west-2.amazonaws.com/cli/Super-Charge-Your-AWS-Command-Line-Experience-with-aws-shell/aws-shell-final.gif)

### Use kube-shell against your cluster

Auto completion for kubectl see https://github.com/cloudnativelabs/kube-shell
```
pip install kube-shell
aws-vault exec run-sandbox -- kube-shell
```

![](http://i.imgur.com/dfelkKr.gif)


### Use kail against your cluster to inspect logs

Kail is a useful log utility that allows you to grab logs from a node as a whole a namespace, ingress, pod or container

[![asciicast](https://asciinema.org/a/133521.png)](https://asciinema.org/a/133521)

Install as follows

```
brew tap boz/repo
brew install boz/repo/kail
```

syntax

```
kail help
usage: kail [<flags>] <command> [<args> ...]

Tail for kubernetes pods

Flags:
  -h, --help                  Show context-sensitive help (also try --help-long and --help-man).
      --ignore=SELECTOR ...   ignore selector
  -l, --label=SELECTOR ...    label
  -p, --pod=NAME ...          pod
  -n, --ns=NAME ...           namespace
      --svc=NAME ...          service
      --rc=NAME ...           replication controller
      --rs=NAME ...           replica set
      --ds=NAME ...           daemonset
  -d, --deploy=NAME ...       deployment
      --node=NAME ...         node
      --ing=NAME ...          ingress
      --context=CONTEXT-NAME  kubernetes context
  -c, --containers=NAME ...   containers
      --dry-run               print matching pods and exit
      --log-file=/dev/stderr  log file output
      --log-level=error       log level
      --since=DURATION        Display logs generated since given duration, like 5s, 2m, 1.5h or 2h45m. Defaults to 1s.
      --glog-v="0"            glog -v value
      --glog-vmodule=""       glog -vmodule flag

Commands:
  help [<command>...]
    Show help.

  run*
    Display logs

  version
    Display current version

```

you may eant to consider setting up an alias

```
alias kail='aws-vault exec run-sandbox -- /usr/local/bin/kail '
```

Which will allow you to tail logs from the cluster 

```
pauldougankube-system/aws-iam-authenticator-nmrmc[aws-iam-authenticator]: time="2019-01-11T10:50:27Z" level=info msg="access granted" arn="arn:aws:iam::011571571136:role/admin" client="127.0.0.1:58584" groups="[system:masters]" method=POST path=/authenticate uid="heptio-authenticator-aws:011571571136:AROAIT4XH3HYANFPD3M3E" username=admin
kube-system/pod-checkpointer-k57p7-ip-10-0-13-36.eu-west-2.compute.internal[pod-checkpointer]: E0111 10:50:31.877929       1 kubelet.go:54] failed to list local parent pods, assuming none are running: Get http://127.0.0.1:10255/pods/: dial tcp 127.0.0.1:10255: connect: connection refused
monitoring-system/monitoring-system-promethe-operator-b4b9db948-5g2cs[prometheus-operator]: E0111 10:50:27.929826       1 reflector.go:134] github.com/coreos/prometheus-operator/pkg/prometheus/operator.go:394: Failed to list *v1.Prometheus: the server could not find the requested resource (get prometheuses.monitoring.coreos.com)
monitoring-system/monitoring-system-promethe-operator-b4b9db948-5g2cs[prometheus-operator]: E0111 10:50:28.931801       1 reflector.go:134] github.com/coreos/prometheus-operator/pkg/prometheus/operator.go:394: Failed to list *v1.Prometheus: the server could not find the requested resource (get prometheuses.monitoring.coreos.com)
monitoring-system/monitoring-system-prome
```



### Dump cluster configuration

[kubectl clust-info](https://www.mankier.com/1/kubectl-cluster-info)


```
aws-vault exec run-sandbox -- kubectl cluster-info
```

```
Kubernetes master is running at https://pauld.run-sandbox.aws.ext.govsvc.uk:6443
CoreDNS is running at https://pauld.run-sandbox.aws.ext.govsvc.uk:6443/api/v1/namespaces/kube-system/services/coredns:dns/proxy
```
[kubectl cluster-info dump](https://www.mankier.com/1/kubectl-cluster-info)

Do a full dump of the cluster - note this is very verbose and time consuming but at least the results are deposited into a hierarchical directory structure.
```
aws-vault exec run-sandbox -- kubectl cluster-info dump --output-directory=dump

```

the directory structure
```
.
├── default
│   ├── daemonsets.json
│   ├── deployments.json
│   ├── events.json
│   ├── myapp-7cdf448d84-45dhq
│   │   └── logs.txt
│   ├── myapp-7cdf448d84-8fzd6
│   │   └── logs.txt
│   ├── pods.json
│   ├── replicasets.json
│   ├── replication-controllers.json
│   └── services.json
├── kube-system
│   ├── aws-iam-authenticator-nmrmc
│   │   └── logs.txt
│   ├── calico-node-452sk
│   │   └── logs.txt
│   ├── calico-node-blmfg
│   │   └── logs.txt
│   ├── calico-node-lkfrm
│   │   └── logs.txt
│   ├── coredns-744ddf7d59-2tv59
│   │   └── logs.txt
│   ├── coredns-744ddf7d59-x627k
│   │   └── logs.txt
│   ├── daemonsets.json
│   ├── deployments.json
│   ├── events.json
│   ├── kube-apiserver-gwlnc
│   │   └── logs.txt
│   ├── kube-controller-manager-6bdf86df8-pxtzp
│   │   └── logs.txt
│   ├── kube-controller-manager-6bdf86df8-r475c
│   │   └── logs.txt
│   ├── kube-proxy-7j8gb
│   │   └── logs.txt
│   ├── kube-proxy-l6p7x
│   │   └── logs.txt
│   ├── kube-proxy-tp5bl
│   │   └── logs.txt
│   ├── kube-scheduler-974fb5d96-9l5cv
│   │   └── logs.txt
│   ├── kube-scheduler-974fb5d96-qvgrs
│   │   └── logs.txt
│   ├── kubernetes-dashboard-77fd78f978-r5pjn
│   │   └── logs.txt
│   ├── pod-checkpointer-k57p7
│   │   └── logs.txt
│   ├── pod-checkpointer-k57p7-ip-10-0-13-36.eu-west-2.compute.internal
│   │   └── logs.txt
│   ├── pods.json
│   ├── replicasets.json
│   ├── replication-controllers.json
│   ├── services.json
│   └── tiller-deploy-6f6fd74b68-rtjsk
│       └── logs.txt
└── nodes.json

22 directories, 35 files

```

### Access the Grafana dashboard

We deploy Grafana as part of our standard cluster, you can connect to the Grafana instance using the following.

Note that whan challenged the authorisation credentials are
|user:|admin|
|----|---------|
|**password:**|**password**|
```
aws-vault exec run-sandbox -- kubectl -n monitoring-system port-forward service/monitoring-system-grafana 8080:80
```

## Reference

A set of essential references

|Topic|Description|
|-|-|
| [gsp-minikube](https://bit.ly/gsp-minikube) | The GSP Kubernetes workshop explains the fundamentals of kubernetes though a worked example using minikube, a good way into the new approach |
| [kail](https://github.com/boz/kail) | kubernetes log viewer, grab logs at node, ingress, namespace, pod or container level  |
| [kube_shell](https://github.com/cloudnativelabs/kube-shell) | Auto completion for kubernetes similar to aws-shell which does the same for aws|
| [kubernetes concepts](https://kubernetes.io/docs/concepts/) | High level key concepts|
|[kubernetes Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/)|A node is a worker machine in Kubernetes, previously known as a minion. A node may be a VM or physical machine, depending on the cluster.|
|[kubernetes Pods](https://kubernetes.io/docs/concepts/workloads/pods/pod/)|Pods are the smallest deployable units of computing that can be created and managed in Kubernetes.|
|[kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)|A Deployment controller provides declarative updates for Pods and ReplicaSets|
|[kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)|A Kubernetes Service is an abstraction which defines a logical set of Pods and a policy by which to access them - sometimes called a micro-service.|
|[kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)|An API object that manages external access to the services in a cluster, typically HTTP.|
| [kubernetes monitoring and logging](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application-introspection) | Some advice on approaching debugging |
| [kubectl man pages](https://www.mankier.com/1/kubectl) | Handy manpages|
| [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) | Handy essential commands|
| [minikube](https://github.com/kubernetes/minikube) | Local single node kubernetes for learning and experimentation, it has some limitations on networking. |




