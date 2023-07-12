# ks-prometheus


## Quickstart

* Create the monitoring stack using the config in the manifests directory:

```sh
# Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
# Note that due to some CRD size we are using kubectl server-side apply feature which is generally available since kubernetes 1.22.
# If you are using previous kubernetes versions this feature may not be available and you would need to use kubectl create instead.
kubectl apply --server-side -f manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring
kubectl apply -f manifests/
```

We create the namespace and CustomResourceDefinitions first to avoid race conditions when deploying the monitoring components. Alternatively, the resources in both folders can be applied with a single command kubectl apply --server-side -f manifests/setup -f manifests, but it may be necessary to run the command multiple times for all components to be created successfully.

* And to teardown the stack:
```sh
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
```
## Customizing

```
go install github.com/google/go-jsonnet/cmd/jsonnet@latest
go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
```

```
make update
```

```
make manifests
```