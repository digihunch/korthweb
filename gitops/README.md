# korthops

install automatically with fluxcd

```sh
flux bootstrap github \
    --owner=digihunch \
    --repository=korthweb \
    --branch=main \
    --personal \
    --path=gitops/environment/dev
```
