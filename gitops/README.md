# korthops

install automatically with fluxcd

```sh
flux bootstrap github \
    --owner=digihunch \
    --repository=korthops \
    --branch=main \
    --personal \
    --path=environment/dev
```
