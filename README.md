# F5XC lb dns updater

Prototype container capable of quering configured loadbalancer, domain and VIP and run
health check against those domains. The idea is to update A records in a DNS server via API.

This needs to be adjusted to get it working.

## Build

It blindfolds secrets required to access F5XC API, please adjust accordingly.

Build and push the docker container to your public registry. Adjust location accordingly.

```
$ make
```

If successful, the container has been built and pushed to docker hub.

```
$ docker images |grep lb-dns-updater
lb-dns-updater                          latest      ad51dbc16c84   38 seconds ago   152MB
marcelwiget/lb-dns-updater              latest      ad51dbc16c84   38 seconds ago   152MB
```

## Deploy

Deploy lb-dns-updater to your vk8s cluster in F5XC. You need to have this configured and kubeconfig
downloaded.

```
$ kubectl apply -f lb-dns-updater.yaml 
```

```
$ kubectl get pods -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP          NODE                                                   NOMINATED NODE   READINESS GATES
lb-dns-updater-5bf6cbbc79-8h7xv   2/2     Running   0          15m   10.1.0.11   mw-tgw-1-ip-100-64-0-199.eu-north-1.compute.internal   <none>           <none>
lb-dns-updater-7d7c66fddc-h5sbw   2/2     Running   0          15m   10.1.0.11   mw-tgw-2-ip-100-64-35-131.us-west-2.compute.internal   <none>           <none>
lb-dns-updater-85d96c799b-kqqfc   2/2     Running   0          15m   10.1.0.11   mw-azure-1-master-2                                    <none>           <none>
```

Check the log file of one of the pod containers:

```
$ kubectl logs --tail=10 lb-dns-updater-5bf6cbbc79-8h7xv -c lb-dns-updater
mw-tgw-workload-1-to-2: domain=workload.tgw2.example.internal ip=100.64.15.254 good
mw-tgw-workload-1-to-global: domain=workload.global.example.internal ip=100.64.15.254 bad
mw-tgw-workload-2-to-1: domain=workload.tgw1.example.internal ip=100.64.47.254 bad

mw-tgw-workload-1-to-2: domain=workload.tgw2.example.internal ip=100.64.15.254 good
mw-tgw-workload-1-to-global: domain=workload.global.example.internal ip=100.64.15.254 good
mw-tgw-workload-2-to-1: domain=workload.tgw1.example.internal ip=100.64.47.254 bad

mw-tgw-workload-1-to-2: domain=workload.tgw2.example.internal ip=100.64.15.254 good
mw-tgw-workload-1-to-global: domain=workload.global.example.internal ip=100.64.15.254 bad
```

Example A record updated:

```
$ host workload.tgw2.example.internal.mwlabs.net
workload.tgw2.example.internal.mwlabs.net has address 100.64.15.254

$ host workload.global.example.internal.mwlabs.net
workload.global.example.internal.mwlabs.net has address 100.64.15.254

$ host workload.tgw1.example.internal.mwlabs.net
workload.tgw1.example.internal.mwlabs.net has address 100.64.47.254
```

## Infos

Need to do health checks with dns updates only on sites hosting the lb. The pod
gets some nice env variables set to make that validation easy. In particular,
the variable VES_IO_SITENAME contains what we need:

```
$ kubectl exec -ti lb-dns-updater-5bf6cbbc79-8hcxg  -- ash
Defaulted container "lb-dns-updater" out of: lb-dns-updater, wingman
/ # printenvKEY1=value1
KEY2=value2
VES_IO_PROVIDER=ves-io-AWS
KUBERNETES_SERVICE_PORT=443
KUBERNETES_PORT=tcp://10.3.0.1:443
HOSTNAME=lb-dns-updater-5bf6cbbc79-8hcxgSHLVL=1
HW_VERSION=
HOME=/rootDOMAIN=eu-north-1.compute.internal
VES_IO_SITETYPE=ves-io-ce
TERM=xterm
VES_IO_SITENAME=mw-tgw-1
KUBERNETES_PORT_443_TCP_ADDR=10.3.0.1
HW_MODEL=t3-xlarge
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
KUBERNETES_PORT_443_TCP_PORT=443
VES_IO_FLEET=
SITE_GROUP=mw
KUBERNETES_PORT_443_TCP_PROTO=tcp
PROVIDER=AWS
HW_SERIAL_NUMBER=ec296232-5701-4b09-b309-75fc39a33906
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_PORT_443_TCP=tcp://10.3.0.1:443
HOST_OS_VERSION=centos-7-2003-13
KUBERNETES_SERVICE_HOST=10.3.0.1
PWD=/
HW_VENDOR=amazon-ec2
```


## References

- https://f5.com/cloud
- https://docs.cloud.f5.com/docs/how-to/secrets-management/app-secrets-using-wingman
